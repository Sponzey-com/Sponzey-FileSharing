import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_secure_storage.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';

void main() {
  late _MutableClock clock;

  setUp(() {
    clock = _MutableClock(DateTime(2026, 4, 9, 12, 0, 0));
  });

  test('keeps discovered peers idle until handshake completes', () async {
    final harness = await _createNode(
      clock: clock,
      loginUserId: 'team',
      loginPassword: 'shared-secret',
      localDeviceId: 'device-a',
      authPort: 40001,
    );
    addTearDown(harness.dispose);

    harness.controller.syncDiscoveredPeer(_peerNode(clock.value, port: 40002));
    await _flush();

    expect(
      harness.container
          .read(peerAuthSessionByPeerIdProvider('team@device-b'))
          ?.status,
      PeerAuthStatus.idle,
    );
  });

  test(
    'startHandshake sends connect request and authenticates using replied route',
    () async {
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);

      final peer = _peerNode(clock.value, port: 40002);
      harness.controller.syncDiscoveredPeer(peer);
      await _flush();

      await harness.controller.startHandshake(peer);
      await _flush();

      expect(
        harness.transport.sentPackets.single.packet.type,
        AuthPacketType.connectRequest,
      );
      expect(harness.transport.sentPackets.single.address.address, '127.0.0.1');
      expect(harness.transport.sentPackets.single.port, 40002);
      expect(
        harness.container
            .read(peerAuthSessionByPeerIdProvider('team@device-b'))
            ?.status,
        PeerAuthStatus.connecting,
      );

      final connectRequest = harness.transport.sentPackets.single.packet;
      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.authAccept,
          protocolVersion: '1.0',
          sessionId: connectRequest.sessionId,
          fromUserId: 'team',
          fromDeviceId: 'device-b',
          fromDisplayName: 'team',
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('127.0.0.1'),
        port: 49152,
      );
      await _flush();

      final session = harness.container.read(
        peerAuthSessionByPeerIdProvider('team@device-b'),
      );
      expect(session?.status, PeerAuthStatus.authenticated);
      expect(session?.peerPort, 49152);
      expect(session?.peerAddress, '127.0.0.1');
    },
  );

  test(
    'incoming connect request issues challenge from observed route',
    () async {
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.connectRequest,
          protocolVersion: '1.0',
          sessionId: 'session-incoming',
          fromUserId: 'team',
          fromDeviceId: 'device-b',
          fromDisplayName: 'team',
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('127.0.0.1'),
        port: 40222,
      );
      await _flush();

      final session = harness.container.read(
        peerAuthSessionByPeerIdProvider('team@device-b'),
      );
      expect(session?.status, PeerAuthStatus.challengeIssued);
      expect(session?.peerPort, 40222);
      expect(
        harness.transport.sentPackets.single.packet.type,
        AuthPacketType.authChallenge,
      );
      expect(harness.transport.sentPackets.single.packet.nonce, isNotNull);
      expect(harness.transport.sentPackets.single.port, 40222);
    },
  );

  test(
    'startHandshake without selected path still uses PeerNode address and port',
    () async {
      final peer = _peerNode(
        clock.value,
        port: 40002,
      ).copyWith(address: '10.20.30.40');
      final candidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: '192.168.1.200',
        remotePort: 49999,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '192.168.1.10',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final activePath = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: clock.value,
        selectionReason: PeerPathSelectionReason.sameSubnet,
      );
      final pathRegistry = PeerPathRegistry()
        ..select(activePath.copyWith(status: PeerPathStatus.active));
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
        candidateStore: [candidate],
        pathRegistry: pathRegistry,
      );
      addTearDown(harness.dispose);

      harness.controller.syncDiscoveredPeer(peer);
      await _flush();

      await harness.controller.startHandshake(peer);
      await _flush();

      expect(
        harness.transport.sentPackets.single.packet.type,
        AuthPacketType.connectRequest,
      );
      expect(
        harness.transport.sentPackets.single.address.address,
        peer.address,
      );
      expect(harness.transport.sentPackets.single.port, peer.port);
      expect(
        harness.transport.sentPackets.single.address.address,
        isNot(candidate.remoteAddress),
      );
      expect(
        harness.transport.sentPackets.single.port,
        isNot(candidate.remotePort),
      );
    },
  );

  test(
    'startHandshake sends connect request through selected path endpoint',
    () async {
      final peer = _peerNode(
        clock.value,
        port: 40002,
      ).copyWith(address: '10.20.30.40');
      final candidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: '192.168.1.200',
        remotePort: 49999,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '192.168.1.10',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final selectedPath = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: clock.value,
        selectionReason: PeerPathSelectionReason.sameSubnet,
      );
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);

      await harness.controller.startHandshake(peer, selectedPath: selectedPath);
      await _flush();

      final sent = harness.transport.sentPackets.single;
      expect(sent.packet.type, AuthPacketType.connectRequest);
      expect(sent.address.address, candidate.remoteAddress);
      expect(sent.port, candidate.remotePort);
      expect(sent.localEndpoint, selectedPath.controlEndpoint);
    },
  );

  test(
    'selected path stays authenticating during challenge response and becomes active after accept',
    () async {
      final peer = _peerNode(
        clock.value,
        port: 40002,
      ).copyWith(address: '10.20.30.40');
      final candidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: '192.168.1.200',
        remotePort: 49999,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '192.168.1.10',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final selectedPath = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: clock.value,
        selectionReason: PeerPathSelectionReason.sameSubnet,
      );
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);

      await harness.controller.startHandshake(peer, selectedPath: selectedPath);
      await _flush();

      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(peer.id)!
            .status,
        PeerPathStatus.authenticating,
      );

      final connectRequest = harness.transport.sentPackets.single.packet;
      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.authChallenge,
          protocolVersion: '1.0',
          sessionId: connectRequest.sessionId,
          fromUserId: 'team',
          fromDeviceId: 'device-b',
          fromDisplayName: 'team',
          nonce: 'nonce-from-peer',
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress(candidate.remoteAddress),
        port: candidate.remotePort,
      );
      await _flush();

      final token = harness.transport.sentPackets.last;
      expect(token.packet.type, AuthPacketType.authToken);
      expect(token.localEndpoint, selectedPath.controlEndpoint);
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(peer.id)!
            .status,
        PeerPathStatus.authenticating,
      );

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.authAccept,
          protocolVersion: '1.0',
          sessionId: connectRequest.sessionId,
          fromUserId: 'team',
          fromDeviceId: 'device-b',
          fromDisplayName: 'team',
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress(candidate.remoteAddress),
        port: candidate.remotePort,
      );
      await _flush();

      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(peer.id)!
            .status,
        PeerPathStatus.active,
      );
    },
  );

  test(
    'incoming connect request replies through the observed local endpoint',
    () async {
      final localEndpoint = UdpInterfaceEndpoint(
        role: UdpPortRole.control,
        interfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '192.168.1.10',
        port: 40001,
        bindMode: UdpInterfaceBindMode.specificAddress,
      );
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.connectRequest,
          protocolVersion: '1.0',
          sessionId: 'session-incoming-path',
          fromUserId: 'team',
          fromDeviceId: 'device-b',
          fromDisplayName: 'team',
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('192.168.1.200'),
        port: 40222,
        localEndpoint: localEndpoint,
      );
      await _flush();

      final challenge = harness.transport.sentPackets.single;
      expect(challenge.packet.type, AuthPacketType.authChallenge);
      expect(challenge.localEndpoint, localEndpoint);
    },
  );

  test(
    'incoming connect request selects the observed route path for authentication',
    () async {
      final peer = _peerNode(
        clock.value,
        port: 40222,
      ).copyWith(address: '192.168.1.200');
      final candidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: peer.address,
        remotePort: peer.port,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '192.168.1.10',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
        candidateStore: [candidate],
      );
      addTearDown(harness.dispose);

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.connectRequest,
          protocolVersion: '1.0',
          sessionId: 'session-incoming-path-selection',
          fromUserId: peer.userId,
          fromDeviceId: peer.deviceId,
          fromInstanceId: peer.instanceId,
          fromDisplayName: peer.displayName,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress(peer.address),
        port: peer.port,
      );
      await _flush();

      final selectedPath = harness.container
          .read(peerPathRegistryProvider)
          .selectedForPeer(peer.id);
      expect(selectedPath, isNotNull);
      expect(selectedPath!.candidate.candidateId, candidate.candidateId);
      expect(selectedPath.status, PeerPathStatus.authenticating);
    },
  );

  test(
    'duplicate incoming connect request reuses the in-progress challenge',
    () async {
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);

      final packet = AuthPacket(
        type: AuthPacketType.connectRequest,
        protocolVersion: '1.0',
        sessionId: 'session-duplicate-connect',
        fromUserId: 'team',
        fromDeviceId: 'device-b',
        fromDisplayName: 'team',
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      );
      harness.transport.emit(
        packet,
        address: InternetAddress('127.0.0.1'),
        port: 40222,
      );
      await _flush();
      harness.transport.emit(
        packet,
        address: InternetAddress('127.0.0.1'),
        port: 40222,
      );
      await _flush();

      expect(harness.transport.sentPackets, hasLength(2));
      expect(
        harness.transport.sentPackets.first.packet.type,
        AuthPacketType.authChallenge,
      );
      expect(
        harness.transport.sentPackets.last.packet.type,
        AuthPacketType.authChallenge,
      );
      expect(
        harness.transport.sentPackets.last.packet.nonce,
        harness.transport.sentPackets.first.packet.nonce,
      );
      expect(
        harness.container
            .read(peerAuthSessionByPeerIdProvider('team@device-b'))
            ?.sessionId,
        'session-duplicate-connect',
      );
    },
  );

  test(
    'duplicate incoming connect request publishes one peer link event',
    () async {
      final bus = InMemoryMessageBus();
      final events = <PeerLinkAppEvent>[];
      final subscription = bus.eventsOfType<PeerLinkAppEvent>().listen(
        events.add,
      );
      addTearDown(subscription.cancel);
      addTearDown(bus.dispose);
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
        messageBus: bus,
      );
      addTearDown(harness.dispose);

      final packet = AuthPacket(
        type: AuthPacketType.connectRequest,
        protocolVersion: '1.0',
        sessionId: 'session-duplicate-event',
        fromUserId: 'team',
        fromDeviceId: 'device-b',
        fromDisplayName: 'team',
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      );
      harness.transport.emit(
        packet,
        address: InternetAddress('127.0.0.1'),
        port: 40222,
      );
      await _flush();
      harness.transport.emit(
        packet,
        address: InternetAddress('127.0.0.1'),
        port: 40222,
      );
      await _flush();

      expect(
        events
            .where((event) => event.eventType == 'peerLinkchallengeIssued')
            .length,
        1,
      );
    },
  );

  test(
    'authenticated peer answers duplicate connect request without downgrading',
    () async {
      final peer = _peerNode(
        clock.value,
        port: 56951,
      ).copyWith(address: '10.211.55.3');
      final activeCandidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: peer.address,
        remotePort: peer.port,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '10.211.55.2',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final activePath = PeerConnectionPath.fromCandidate(
        candidate: activeCandidate,
        selectedAt: clock.value,
        selectionReason: PeerPathSelectionReason.sameSubnet,
      ).copyWith(status: PeerPathStatus.active);
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
        candidateStore: [activeCandidate],
        pathRegistry: PeerPathRegistry()..select(activePath),
      );
      addTearDown(harness.dispose);
      final authenticatedPeer = await _authenticatePeerOnRoute(
        harness,
        clock,
        address: peer.address,
        port: peer.port,
      );

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.connectRequest,
          protocolVersion: '1.0',
          sessionId: 'late-duplicate-connect',
          fromUserId: authenticatedPeer.userId,
          fromDeviceId: authenticatedPeer.deviceId,
          fromInstanceId: authenticatedPeer.instanceId,
          fromDisplayName: authenticatedPeer.displayName,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('10.211.55.3'),
        port: 56951,
      );
      await _flush();

      final challenge = harness.transport.sentPackets.last;
      final session = harness.container.read(
        peerAuthSessionByPeerIdProvider(authenticatedPeer.id),
      );
      expect(session?.status, PeerAuthStatus.authenticated);
      expect(session?.sessionId, isNot('late-duplicate-connect'));
      expect(harness.transport.sentPackets, hasLength(2));
      expect(challenge.packet.type, AuthPacketType.authChallenge);
      expect(challenge.packet.sessionId, 'late-duplicate-connect');
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(authenticatedPeer.id)
            ?.status,
        PeerPathStatus.active,
      );

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.authReject,
          protocolVersion: '1.0',
          sessionId: 'late-duplicate-connect',
          fromUserId: authenticatedPeer.userId,
          fromDeviceId: authenticatedPeer.deviceId,
          fromInstanceId: authenticatedPeer.instanceId,
          fromDisplayName: authenticatedPeer.displayName,
          rejectCode: 'lateFailure',
          rejectMessage: 'lateFailure',
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('10.211.55.3'),
        port: 56951,
      );
      await _flush();

      final afterRejectSession = harness.container.read(
        peerAuthSessionByPeerIdProvider(authenticatedPeer.id),
      );
      expect(afterRejectSession?.status, PeerAuthStatus.authenticated);
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(authenticatedPeer.id)
            ?.status,
        PeerPathStatus.active,
      );
    },
  );

  test(
    'authenticated peer with expired path answers connect request for route refresh',
    () async {
      final peer = _peerNode(
        clock.value,
        port: 56951,
      ).copyWith(address: '10.211.55.3');
      final expiredCandidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: peer.address,
        remotePort: peer.port,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '10.211.55.2',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final expiredPath =
          PeerConnectionPath.fromCandidate(
            candidate: expiredCandidate,
            selectedAt: clock.value,
            selectionReason: PeerPathSelectionReason.sameSubnet,
          ).copyWith(
            status: PeerPathStatus.failoverRequested,
            failureReasonCode: 'ttlExceeded',
          );
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
        candidateStore: [expiredCandidate],
        pathRegistry: PeerPathRegistry()..select(expiredPath),
      );
      addTearDown(harness.dispose);
      final authenticatedPeer = await _authenticatePeerOnRoute(
        harness,
        clock,
        address: peer.address,
        port: peer.port,
      );

      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.connectRequest,
          protocolVersion: '1.0',
          sessionId: 'route-refresh-connect',
          fromUserId: authenticatedPeer.userId,
          fromDeviceId: authenticatedPeer.deviceId,
          fromInstanceId: authenticatedPeer.instanceId,
          fromDisplayName: authenticatedPeer.displayName,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress(peer.address),
        port: peer.port,
      );
      await _flush();

      final challenge = harness.transport.sentPackets.last;
      expect(harness.transport.sentPackets, hasLength(2));
      expect(challenge.packet.type, AuthPacketType.authChallenge);
      expect(challenge.packet.sessionId, 'route-refresh-connect');
      expect(
        harness.container
            .read(peerAuthSessionByPeerIdProvider(authenticatedPeer.id))
            ?.status,
        PeerAuthStatus.challengeIssued,
      );
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(authenticatedPeer.id)
            ?.status,
        PeerPathStatus.authenticating,
      );
    },
  );

  test('auth reject marks the selected path failed', () async {
    final peer = _peerNode(clock.value, port: 40002);
    final candidate = PeerRouteCandidate.create(
      peerId: peer.id,
      remoteAddress: peer.address,
      remotePort: peer.port,
      localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
      localAddress: '127.0.0.1',
      discoveredBy: RouteCandidateDiscoverySource.broadcast,
      seenAt: clock.value,
      localInterfaceTypeHint: InterfaceTypeHint.ethernet,
    );
    final selectedPath = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: clock.value,
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );
    final harness = await _createNode(
      clock: clock,
      loginUserId: 'team',
      loginPassword: 'shared-secret',
      localDeviceId: 'device-a',
      authPort: 40001,
    );
    addTearDown(harness.dispose);

    await harness.controller.startHandshake(peer, selectedPath: selectedPath);
    await _flush();
    final request = harness.transport.sentPackets.single.packet;
    harness.transport.emit(
      AuthPacket(
        type: AuthPacketType.authReject,
        protocolVersion: '1.0',
        sessionId: request.sessionId,
        fromUserId: peer.userId,
        fromDeviceId: peer.deviceId,
        fromDisplayName: peer.displayName,
        rejectCode: 'jwtInvalid',
        rejectMessage: 'jwtInvalid',
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
      address: InternetAddress(peer.address),
      port: peer.port,
    );
    await _flush();

    final path = harness.container
        .read(peerPathRegistryProvider)
        .selectedForPeer(peer.id)!;
    expect(path.status, PeerPathStatus.failed);
    expect(path.failureReasonCode, 'jwtInvalid');
  });

  test('late auth reject cannot downgrade an authenticated session', () async {
    final peer = _peerNode(clock.value, port: 40002);
    final candidate = PeerRouteCandidate.create(
      peerId: peer.id,
      remoteAddress: peer.address,
      remotePort: peer.port,
      localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
      localAddress: '127.0.0.1',
      discoveredBy: RouteCandidateDiscoverySource.broadcast,
      seenAt: clock.value,
      localInterfaceTypeHint: InterfaceTypeHint.ethernet,
    );
    final selectedPath = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: clock.value,
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );
    final harness = await _createNode(
      clock: clock,
      loginUserId: 'team',
      loginPassword: 'shared-secret',
      localDeviceId: 'device-a',
      authPort: 40001,
    );
    addTearDown(harness.dispose);

    await harness.controller.startHandshake(peer, selectedPath: selectedPath);
    await _flush();
    final request = harness.transport.sentPackets.single.packet;
    harness.transport.emit(
      AuthPacket(
        type: AuthPacketType.authAccept,
        protocolVersion: '1.0',
        sessionId: request.sessionId,
        fromUserId: peer.userId,
        fromDeviceId: peer.deviceId,
        fromDisplayName: peer.displayName,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
      address: InternetAddress(peer.address),
      port: peer.port,
    );
    await _flush();

    harness.transport.emit(
      AuthPacket(
        type: AuthPacketType.authReject,
        protocolVersion: '1.0',
        sessionId: request.sessionId,
        fromUserId: peer.userId,
        fromDeviceId: peer.deviceId,
        fromDisplayName: peer.displayName,
        rejectCode: 'lateFailure',
        rejectMessage: 'lateFailure',
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
      address: InternetAddress(peer.address),
      port: peer.port,
    );
    await _flush();

    final session = harness.container.read(
      peerAuthSessionByPeerIdProvider(peer.id),
    );
    final path = harness.container
        .read(peerPathRegistryProvider)
        .selectedForPeer(peer.id);
    expect(session?.status, PeerAuthStatus.authenticated);
    expect(path?.status, PeerPathStatus.active);
  });

  test('direct startHandshake skips already authenticated peer', () async {
    final harness = await _createNode(
      clock: clock,
      loginUserId: 'team',
      loginPassword: 'shared-secret',
      localDeviceId: 'device-a',
      authPort: 40001,
    );
    addTearDown(harness.dispose);
    final peer = _peerNode(clock.value, port: 40002);

    await harness.controller.startHandshake(peer);
    await _flush();
    final request = harness.transport.sentPackets.single.packet;
    harness.transport.emit(
      AuthPacket(
        type: AuthPacketType.authAccept,
        protocolVersion: '1.0',
        sessionId: request.sessionId,
        fromUserId: peer.userId,
        fromDeviceId: peer.deviceId,
        fromDisplayName: peer.displayName,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
      address: InternetAddress(peer.address),
      port: peer.port,
    );
    await _flush();

    await harness.controller.startHandshake(peer);
    await _flush();

    expect(
      harness.container.read(peerAuthSessionByPeerIdProvider(peer.id))?.status,
      PeerAuthStatus.authenticated,
    );
    expect(harness.transport.sentPackets, hasLength(1));
  });

  test(
    'discovery updates do not replace an authenticated route endpoint',
    () async {
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);
      final authenticatedPeer = await _authenticatePeerOnRoute(
        harness,
        clock,
        address: '10.211.55.3',
        port: 56951,
      );

      harness.controller.syncDiscoveredPeer(
        authenticatedPeer.copyWith(address: '192.168.0.236'),
      );
      await _flush();

      final session = harness.container.read(
        peerAuthSessionByPeerIdProvider(authenticatedPeer.id),
      );
      expect(session?.status, PeerAuthStatus.authenticated);
      expect(session?.peerAddress, '10.211.55.3');
      expect(session?.peerPort, 56951);
    },
  );

  test(
    'online presence sync preserves an authenticated route endpoint',
    () async {
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);
      final authenticatedPeer = await _authenticatePeerOnRoute(
        harness,
        clock,
        address: '10.211.55.3',
        port: 56951,
      );

      harness.controller.syncPeerPresence([
        authenticatedPeer.copyWith(address: '192.168.0.236'),
      ]);
      await _flush();

      final session = harness.container.read(
        peerAuthSessionByPeerIdProvider(authenticatedPeer.id),
      );
      expect(session?.status, PeerAuthStatus.authenticated);
      expect(session?.peerAddress, '10.211.55.3');
      expect(session?.peerPort, 56951);
    },
  );

  test(
    'offline presence clears authenticated session and active path',
    () async {
      final harness = await _createNode(
        clock: clock,
        loginUserId: 'team',
        loginPassword: 'shared-secret',
        localDeviceId: 'device-a',
        authPort: 40001,
      );
      addTearDown(harness.dispose);
      final peer = _peerNode(clock.value, port: 40002);
      final candidate = PeerRouteCandidate.create(
        peerId: peer.id,
        remoteAddress: peer.address,
        remotePort: peer.port,
        localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
        localAddress: '127.0.0.1',
        discoveredBy: RouteCandidateDiscoverySource.broadcast,
        seenAt: clock.value,
        localInterfaceTypeHint: InterfaceTypeHint.ethernet,
      );
      final path = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: clock.value,
        selectionReason: PeerPathSelectionReason.sameSubnet,
      ).copyWith(status: PeerPathStatus.active);
      harness.container.read(peerPathRegistryMutationsProvider).select(path);
      harness.controller.syncDiscoveredPeer(peer);
      await harness.controller.startHandshake(peer);
      await _flush();
      final request = harness.transport.sentPackets.single.packet;
      harness.transport.emit(
        AuthPacket(
          type: AuthPacketType.authAccept,
          protocolVersion: '1.0',
          sessionId: request.sessionId,
          fromUserId: peer.userId,
          fromDeviceId: peer.deviceId,
          fromDisplayName: peer.displayName,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress(peer.address),
        port: peer.port,
      );
      await _flush();

      harness.controller.syncPeerPresence([
        peer.copyWith(presence: PeerPresence.offline),
      ]);
      await _flush();

      expect(
        harness.container.read(peerAuthSessionByPeerIdProvider(peer.id)),
        isNull,
      );
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(peer.id),
        isNull,
      );
    },
  );

  test('startHandshake marks session failed when control bind fails', () async {
    final peer = _peerNode(clock.value, port: 40002);
    final candidate = PeerRouteCandidate.create(
      peerId: peer.id,
      remoteAddress: peer.address,
      remotePort: peer.port,
      localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 4),
      localAddress: '10.20.30.5',
      discoveredBy: RouteCandidateDiscoverySource.broadcast,
      seenAt: clock.value,
      localInterfaceTypeHint: InterfaceTypeHint.ethernet,
    );
    final selectedPath = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: clock.value,
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );
    final harness = await _createNode(
      clock: clock,
      loginUserId: 'team',
      loginPassword: 'shared-secret',
      localDeviceId: 'device-a',
      authPort: 40001,
      sendException: ControlTransportBindException(
        reasonCode: 'controlBindFailed',
        localEndpoint: selectedPath.controlEndpoint,
      ),
    );
    addTearDown(harness.dispose);

    await harness.controller.startHandshake(peer, selectedPath: selectedPath);
    await _flush();

    final session = harness.container.read(
      peerAuthSessionByPeerIdProvider(peer.id),
    );
    expect(session?.status, PeerAuthStatus.failed);
    expect(session?.message, 'controlBindFailed');
    expect(harness.transport.sentPackets, isEmpty);
  });
}

Future<PeerNode> _authenticatePeerOnRoute(
  _NodeHarness harness,
  _MutableClock clock, {
  required String address,
  required int port,
}) async {
  final peer = _peerNode(clock.value, port: port).copyWith(address: address);

  await harness.controller.startHandshake(peer);
  await _flush();
  final request = harness.transport.sentPackets.single.packet;
  harness.transport.emit(
    AuthPacket(
      type: AuthPacketType.authAccept,
      protocolVersion: '1.0',
      sessionId: request.sessionId,
      fromUserId: peer.userId,
      fromDeviceId: peer.deviceId,
      fromDisplayName: peer.displayName,
      sentAtEpochMs: clock.value.millisecondsSinceEpoch,
    ),
    address: InternetAddress(address),
    port: port,
  );
  await _flush();

  final session = harness.container.read(
    peerAuthSessionByPeerIdProvider(peer.id),
  );
  expect(session?.status, PeerAuthStatus.authenticated);
  expect(session?.peerAddress, address);
  expect(session?.peerPort, port);
  return peer;
}

PeerNode _peerNode(DateTime now, {required int port}) {
  return PeerNode(
    deviceId: 'device-b',
    userId: 'team',
    displayName: 'team',
    deviceName: 'Node-device-b',
    osType: 'macos',
    protocolVersion: '1.0',
    lastSeenAt: now,
    address: '127.0.0.1',
    port: port,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}

Future<_NodeHarness> _createNode({
  required _MutableClock clock,
  required String loginUserId,
  required String loginPassword,
  required String localDeviceId,
  required int authPort,
  List<PeerRouteCandidate> candidateStore = const [],
  PeerPathRegistry? pathRegistry,
  ControlTransportBindException? sendException,
  MessageBus? messageBus,
}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final transport = _InspectableControlTransport(
    authPort,
    sendException: sendException,
  );
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          environment: AppEnvironment.development,
          appName: 'Sponzey FileSharing',
          protocolVersion: '1.0',
          discoveryPort: 38400,
          authPort: 38401,
          authTokenLifetime: Duration(seconds: 20),
          authAllowedClockSkew: Duration(seconds: 5),
          authHandshakeTimeout: Duration(seconds: 15),
          discoveryBroadcastInterval: Duration(seconds: 3),
          discoveryStaleAfter: Duration(seconds: 10),
          discoveryOfflineAfter: Duration(seconds: 30),
          defaultLogLevel: AppLogLevel.error,
        ),
      ),
      appDatabaseProvider.overrideWithValue(database),
      appSecureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      appStoragePathProvider.overrideWithValue(
        const _FakeStoragePathProvider('/tmp/sponzey-test'),
      ),
      appLoggerProvider.overrideWithValue(
        const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      ),
      controlTransportProvider.overrideWithValue(transport),
      localDeviceIdentityServiceProvider.overrideWithValue(
        _FakeLocalDeviceIdentityService(localDeviceId),
      ),
      if (messageBus != null) messageBusProvider.overrideWithValue(messageBus),
      authNowProvider.overrideWithValue(() => clock.value),
      peerRouteCandidateStoreProvider.overrideWith((ref) => candidateStore),
      peerPathRegistryProvider.overrideWithValue(
        pathRegistry ?? PeerPathRegistry(),
      ),
    ],
  );
  container.read(authControllerProvider);
  await _flush();
  await container
      .read(authControllerProvider.notifier)
      .signIn(userId: loginUserId, password: loginPassword);
  container.read(peerAuthControllerProvider);
  await _flush();

  return _NodeHarness(
    container: container,
    controller: container.read(peerAuthControllerProvider.notifier),
    transport: transport,
    database: database,
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

class _NodeHarness {
  const _NodeHarness({
    required this.container,
    required this.controller,
    required this.transport,
    required this.database,
  });

  final ProviderContainer container;
  final PeerAuthController controller;
  final _InspectableControlTransport transport;
  final AppDatabase database;

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;
}

class _FakeSecureStorage implements AppSecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> ensureReady() async {
    _values.putIfAbsent('__memory_ready__', () => 'ready');
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

class _FakeStoragePathProvider implements AppStoragePathProvider {
  const _FakeStoragePathProvider(this.path);

  final String path;

  @override
  Future<String> getDefaultReceivePath() async => path;
}

class _FakeLocalDeviceIdentityService implements LocalDeviceIdentityService {
  const _FakeLocalDeviceIdentityService(this.deviceId);

  final String deviceId;

  @override
  Future<LocalDeviceIdentity> load() async {
    return LocalDeviceIdentity(
      deviceId: deviceId,
      instanceId: 'instance-$deviceId',
      osType: 'macos',
    );
  }
}

class _SentPacket {
  const _SentPacket({
    required this.packet,
    required this.address,
    required this.port,
    this.localEndpoint,
  });

  final AuthPacket packet;
  final InternetAddress address;
  final int port;
  final UdpInterfaceEndpoint? localEndpoint;
}

class _InspectableControlTransport implements ControlTransport {
  _InspectableControlTransport(this.port, {this.sendException});

  final int port;
  final ControlTransportBindException? sendException;
  final StreamController<ControlDatagram> _controller =
      StreamController<ControlDatagram>.broadcast();
  final List<_SentPacket> sentPackets = [];

  @override
  Stream<ControlDatagram> get packets => _controller.stream;

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  }) async {
    final sendException = this.sendException;
    if (sendException != null) {
      throw sendException;
    }
    sentPackets.add(
      _SentPacket(
        packet: packet,
        address: address,
        port: port,
        localEndpoint: localEndpoint,
      ),
    );
  }

  @override
  Future<int> start({required int preferredPort}) async => port;

  void emit(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    _controller.add(
      ControlDatagram(
        packet: packet,
        address: address,
        port: port,
        localEndpoint: localEndpoint,
      ),
    );
  }
}
