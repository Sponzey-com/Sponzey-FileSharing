import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_inventory.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/shared_verifier_service.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_group_tag_service.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/network/dart_io_network_interface_inventory.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_secure_storage.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';

void main() {
  late AppDatabase database;
  late _FakeDiscoveryTransport transport;
  late _MutableClock clock;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    transport = _FakeDiscoveryTransport();
    clock = _MutableClock(DateTime(2026, 4, 9, 12, 0, 0));
  });

  tearDown(() async {
    await database.close();
    await transport.close();
  });

  test(
    'discovers peers, responds with ack, and transitions presence by TTL',
    () async {
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'admin', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      expect(transport.startedPort, 38400);
      expect(transport.broadcasts, hasLength(1));
      expect(
        transport.broadcasts.single.packet.type,
        DiscoveryPacketType.discover,
      );

      transport.emit(
        DiscoveryPacket(
          type: DiscoveryPacketType.discover,
          protocolVersion: '1.0',
          userId: 'admin',
          discoveryGroupTag: _discoveryGroupTag('admin', 'secret'),
          instanceId: 'instance-ops',
          displayName: 'Ops Room',
          deviceId: 'device-ops',
          deviceName: 'Windows Tower',
          osType: 'windows',
          port: 38401,
          receiveAvailable: true,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
      );
      await _flush();

      final afterDiscover = container.read(discoveryControllerProvider);
      expect(afterDiscover.peers, hasLength(1));
      expect(afterDiscover.peers.single.displayName, 'Ops Room');
      expect(afterDiscover.peers.single.presence, PeerPresence.online);
      expect(
        container
            .read(peerAuthSessionByPeerIdProvider('admin@device-ops'))
            ?.status,
        PeerAuthStatus.authenticated,
      );
      expect(transport.unicasts, hasLength(1));
      expect(
        transport.unicasts.single.packet.type,
        DiscoveryPacketType.discoverAck,
      );

      clock.advance(const Duration(seconds: 12));
      await container
          .read(discoveryControllerProvider.notifier)
          .refreshPresence();
      expect(
        container.read(discoveryControllerProvider).peers.single.presence,
        PeerPresence.stale,
      );
      expect(
        container
            .read(peerAuthSessionByPeerIdProvider('admin@device-ops'))
            ?.status,
        PeerAuthStatus.idle,
      );

      clock.advance(const Duration(seconds: 25));
      await container
          .read(discoveryControllerProvider.notifier)
          .refreshPresence();
      expect(
        container.read(discoveryControllerProvider).peers.single.presence,
        PeerPresence.offline,
      );
      expect(
        container.read(peerAuthSessionByPeerIdProvider('admin@device-ops')),
        isNull,
      );
    },
  );

  test('marks mismatched protocol peers as incompatible', () async {
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'admin', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    transport.emit(
      DiscoveryPacket(
        type: DiscoveryPacketType.discoverAck,
        protocolVersion: '0.9',
        userId: 'admin',
        discoveryGroupTag: _discoveryGroupTag('admin', 'secret'),
        instanceId: 'instance-legacy',
        displayName: 'Legacy Node',
        deviceId: 'legacy-node',
        deviceName: 'Ubuntu Desktop',
        osType: 'linux',
        port: 38401,
        receiveAvailable: false,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
    );
    await _flush();

    expect(
      container.read(discoveryControllerProvider).peers.single.presence,
      PeerPresence.incompatible,
    );
  });

  test('merges local machine peers from registry entries', () async {
    final registry = _FakeLocalInstanceRegistry(
      entries: <LocalInstancePresence>[
        LocalInstancePresence(
          userId: 'admin',
          discoveryGroupTag: _discoveryGroupTag('admin', 'secret'),
          instanceId: 'instance-peer',
          displayName: 'Peer Node',
          deviceId: 'peer-device',
          deviceName: 'MacBook Peer',
          osType: 'macos',
          protocolVersion: '1.0',
          port: 40210,
          receiveAvailable: true,
          seenAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
      ],
    );
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
      registry: registry,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'admin', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    final peers = container.read(discoveryControllerProvider).peers;
    expect(peers, hasLength(1));
    expect(peers.single.deviceId, 'peer-device');
    expect(peers.single.address, InternetAddress.loopbackIPv4.address);
    expect(peers.single.presence, PeerPresence.online);
    expect(
      container
          .read(peerAuthSessionByPeerIdProvider('admin@peer-device'))
          ?.status,
      PeerAuthStatus.authenticated,
    );
  });

  test(
    'starts discovery after sign-in even if provider was read earlier',
    () async {
      final registry = _FakeLocalInstanceRegistry(
        entries: <LocalInstancePresence>[
          LocalInstancePresence(
            userId: 'admin',
            discoveryGroupTag: _discoveryGroupTag('admin', 'secret'),
            instanceId: 'instance-peer',
            displayName: 'Peer Node',
            deviceId: 'peer-device',
            deviceName: 'MacBook Peer',
            osType: 'macos',
            protocolVersion: '1.0',
            port: 40210,
            receiveAvailable: true,
            seenAtEpochMs: clock.value.millisecondsSinceEpoch,
          ),
        ],
      );
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
        registry: registry,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      container.read(discoveryControllerProvider);
      await _flush();

      expect(container.read(discoveryControllerProvider).isRunning, isFalse);

      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'admin', password: 'secret');
      await _flush();

      final state = container.read(discoveryControllerProvider);
      expect(state.isRunning, isTrue);
      expect(state.peers, hasLength(1));
      expect(state.peers.single.deviceId, 'peer-device');
    },
  );

  test('ignores discovery packets from other pairing groups', () async {
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'team', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    transport.emit(
      DiscoveryPacket(
        type: DiscoveryPacketType.discoverAck,
        protocolVersion: '1.0',
        userId: 'other-team',
        discoveryGroupTag: _discoveryGroupTag('other-team', 'different-secret'),
        instanceId: 'instance-other',
        displayName: 'Peer Node',
        deviceId: 'zz-peer-device',
        deviceName: 'MacBook Peer',
        osType: 'macos',
        port: 38401,
        receiveAvailable: true,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
    );
    await _flush();

    expect(container.read(discoveryControllerProvider).peers, isEmpty);
  });

  test(
    'broadcasts current discovery group tag without auth verifier',
    () async {
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'team', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      expect(transport.broadcasts.single.packet.userId, 'team');
      final groupTag = _discoveryGroupTag('team', 'secret');
      expect(transport.broadcasts.single.packet.discoveryGroupTag, groupTag);
      expect(
        transport.broadcasts.single.packet.discoveryGroupTag,
        isNot(_authVerifier('team', 'secret')),
      );
      expect(
        container
            .read(discoveryControllerProvider)
            .currentDiscoveryGroupTagPreview,
        groupTag.substring(0, 12),
      );
      expect(
        container
            .read(discoveryControllerProvider)
            .currentDiscoveryGroupTagPreview,
        isNot(groupTag),
      );
    },
  );

  test('broadcasts the actual listening control port', () async {
    final controlTransport = _SilentControlTransport(localPort: 40210);
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
      controlTransport: controlTransport,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'team', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    expect(transport.broadcasts.single.packet.port, 40210);
    expect(transport.broadcasts.single.packet.controlPort, 40210);
  });

  test('ignores discovery packets from the same runtime instance', () async {
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'team', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    transport.emit(
      DiscoveryPacket(
        type: DiscoveryPacketType.discoverAck,
        protocolVersion: '1.0',
        userId: 'team',
        discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
        instanceId: 'local-instance',
        displayName: 'Self Echo',
        deviceId: 'shadow-device',
        deviceName: 'Shadow',
        osType: 'macos',
        port: 38401,
        receiveAvailable: true,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
    );
    await _flush();

    expect(container.read(discoveryControllerProvider).peers, isEmpty);
  });

  test('accepts a different runtime instance on the same device id', () async {
    final controlTransport = _SilentControlTransport();
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
      controlTransport: controlTransport,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'team', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    transport.emit(
      DiscoveryPacket(
        type: DiscoveryPacketType.discoverAck,
        protocolVersion: '1.0',
        userId: 'team',
        discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
        instanceId: 'other-local-instance',
        displayName: 'Second Window',
        deviceId: 'local-device',
        deviceName: 'Same Mac',
        osType: 'macos',
        port: 40210,
        controlPort: 40210,
        receiveAvailable: true,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      ),
    );
    await _flush();

    final state = container.read(discoveryControllerProvider);
    expect(state.peers, hasLength(1));
    expect(state.peers.single.deviceId, 'local-device');
    expect(state.peers.single.port, 40210);
    expect(
      controlTransport.sentPackets.single.type,
      AuthPacketType.connectRequest,
    );
  });

  test(
    'collapses discovery source hints into PeerNode endpoint before auth',
    () async {
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'team', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      transport.emit(
        DiscoveryPacket(
          type: DiscoveryPacketType.discoverAck,
          protocolVersion: '1.0',
          userId: 'team',
          discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
          instanceId: 'peer-instance',
          displayName: 'Peer Node',
          deviceId: 'peer-device',
          deviceName: 'Ethernet Peer',
          osType: 'linux',
          port: 38400,
          controlPort: 46000,
          sourceInterfaceId: 'en7#7',
          sourceInterfaceHint: 'ethernet',
          sourceAddress: '10.20.30.10',
          receiveAvailable: true,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('10.20.30.40'),
        port: 38400,
      );
      await _flush();

      final peer = container.read(discoveryControllerProvider).peers.single;
      expect(peer.address, '10.20.30.40');
      expect(peer.port, 46000);
      final candidates = container.read(peerRouteCandidateStoreProvider);
      expect(candidates, hasLength(1));
      expect(candidates.single.peerId, 'team@peer-device');
      expect(candidates.single.localAddress, '0.0.0.0');
      expect(candidates.single.remoteAddress, '10.20.30.40');
      expect(candidates.single.remotePort, 46000);
      expect(candidates.single.bindMode, UdpInterfaceBindMode.any);

      final session = container.read(
        peerAuthSessionByPeerIdProvider('team@peer-device'),
      );
      expect(session?.status, PeerAuthStatus.authenticated);
      expect(session?.peerAddress, '10.20.30.40');
      expect(session?.peerPort, 46000);
    },
  );

  test(
    'discovery packet updates peer list and keeps two local route candidates',
    () async {
      final bus = InMemoryMessageBus();
      addTearDown(bus.dispose);
      final events = <PeerRouteCandidateAppEvent>[];
      final subscription = bus
          .eventsOfType<PeerRouteCandidateAppEvent>()
          .listen(events.add);
      addTearDown(subscription.cancel);
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
        messageBus: bus,
        interfaceSnapshots: [
          _interfaceSnapshot(
            name: 'en0',
            index: 1,
            typeHint: InterfaceTypeHint.ethernet,
            address: '192.168.10.5',
          ),
          _interfaceSnapshot(
            name: 'bridge100',
            index: 2,
            typeHint: InterfaceTypeHint.bridge,
            address: '192.168.10.6',
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'team', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      transport.emit(
        DiscoveryPacket(
          type: DiscoveryPacketType.discoverAck,
          protocolVersion: '1.0',
          userId: 'team',
          discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
          instanceId: 'peer-instance',
          displayName: 'Peer Node',
          deviceId: 'peer-device',
          deviceName: 'Ethernet Peer',
          osType: 'linux',
          port: 38400,
          controlPort: 46000,
          receiveAvailable: true,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('192.168.10.20'),
      );
      await _flush();

      expect(container.read(discoveryControllerProvider).peers, hasLength(1));
      final candidates = container.read(
        peerRouteCandidatesProvider('team@peer-device'),
      );
      expect(candidates, hasLength(2));
      expect(candidates.map((candidate) => candidate.localAddress).toSet(), {
        '192.168.10.5',
        '192.168.10.6',
      });
      expect(
        container
            .read(peerPathDiagnosticsProvider('team@peer-device'))
            .debugSummary,
        contains('candidates=2'),
      );
      expect(
        events.map((event) => event.eventType),
        containsAll(['PeerRouteCandidateFound', 'PeerRouteCandidateFound']),
      );
      expect(
        events.map((event) => '${event.peerId} ${event.candidateId}').join(' '),
        isNot(contains('secret')),
      );
      expect(
        events.map((event) => '${event.peerId} ${event.candidateId}').join(' '),
        isNot(contains('token')),
      );
    },
  );

  test(
    'duplicate discovery packet publishes candidate updated event',
    () async {
      final bus = InMemoryMessageBus();
      addTearDown(bus.dispose);
      final events = <PeerRouteCandidateAppEvent>[];
      final subscription = bus
          .eventsOfType<PeerRouteCandidateAppEvent>()
          .listen(events.add);
      addTearDown(subscription.cancel);
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
        messageBus: bus,
        interfaceSnapshots: [
          _interfaceSnapshot(
            name: 'en0',
            index: 1,
            typeHint: InterfaceTypeHint.ethernet,
            address: '10.20.30.5',
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'team', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      final packet = DiscoveryPacket(
        type: DiscoveryPacketType.discoverAck,
        protocolVersion: '1.0',
        userId: 'team',
        discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
        instanceId: 'peer-instance',
        displayName: 'Peer Node',
        deviceId: 'peer-device',
        deviceName: 'Ethernet Peer',
        osType: 'linux',
        controlPort: 46000,
        port: 38400,
        receiveAvailable: true,
        sentAtEpochMs: clock.value.millisecondsSinceEpoch,
      );
      transport.emit(packet, address: InternetAddress('10.20.30.40'));
      await _flush();
      clock.advance(const Duration(seconds: 1));
      transport.emit(
        DiscoveryPacket(
          type: packet.type,
          protocolVersion: packet.protocolVersion,
          userId: packet.userId,
          discoveryGroupTag: packet.discoveryGroupTag,
          instanceId: packet.instanceId,
          displayName: packet.displayName,
          deviceId: packet.deviceId,
          deviceName: packet.deviceName,
          osType: packet.osType,
          port: packet.port,
          controlPort: packet.controlPort,
          receiveAvailable: packet.receiveAvailable,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('10.20.30.40'),
      );
      await _flush();

      expect(
        container.read(peerRouteCandidatesProvider('team@peer-device')),
        hasLength(1),
      );
      expect(
        events.map((event) => event.eventType),
        containsAll(['PeerRouteCandidateFound', 'PeerRouteCandidateUpdated']),
      );
    },
  );

  test('local registry entry creates loopback route candidate', () async {
    final registry = _FakeLocalInstanceRegistry(
      entries: <LocalInstancePresence>[
        LocalInstancePresence(
          userId: 'admin',
          discoveryGroupTag: _discoveryGroupTag('admin', 'secret'),
          instanceId: 'instance-peer',
          displayName: 'Peer Node',
          deviceId: 'peer-device',
          deviceName: 'MacBook Peer',
          osType: 'macos',
          protocolVersion: '1.0',
          port: 40210,
          receiveAvailable: true,
          seenAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
      ],
    );
    final container = _createContainer(
      database: database,
      transport: transport,
      clock: clock,
      registry: registry,
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'admin', password: 'secret');

    container.read(discoveryControllerProvider);
    await _flush();

    final candidates = container.read(
      peerRouteCandidatesProvider('admin@peer-device'),
    );
    expect(candidates, hasLength(1));
    expect(
      candidates.single.remoteAddress,
      InternetAddress.loopbackIPv4.address,
    );
    expect(candidates.single.discoveredBy.name, 'localRegistry');
    expect(
      candidates.single.localInterfaceTypeHint,
      InterfaceTypeHint.loopback,
    );
  });

  test(
    'expired route candidate is not selectable and publishes event',
    () async {
      final bus = InMemoryMessageBus();
      addTearDown(bus.dispose);
      final events = <PeerRouteCandidateAppEvent>[];
      final subscription = bus
          .eventsOfType<PeerRouteCandidateAppEvent>()
          .listen(events.add);
      addTearDown(subscription.cancel);
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
        messageBus: bus,
        interfaceSnapshots: [
          _interfaceSnapshot(
            name: 'en0',
            index: 1,
            typeHint: InterfaceTypeHint.ethernet,
            address: '10.20.30.5',
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'team', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      transport.emit(
        DiscoveryPacket(
          type: DiscoveryPacketType.discoverAck,
          protocolVersion: '1.0',
          userId: 'team',
          discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
          instanceId: 'peer-instance',
          displayName: 'Peer Node',
          deviceId: 'peer-device',
          deviceName: 'Ethernet Peer',
          osType: 'linux',
          controlPort: 46000,
          port: 38400,
          receiveAvailable: true,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('10.20.30.40'),
      );
      await _flush();

      clock.advance(const Duration(seconds: 31));
      await container
          .read(discoveryControllerProvider.notifier)
          .refreshPresence();

      final candidates = container.read(
        peerRouteCandidatesProvider('team@peer-device'),
      );
      expect(candidates.single.status.name, 'expired');
      expect(candidates.where((candidate) => candidate.isSelectable), isEmpty);
      expect(
        events.map((event) => event.eventType),
        contains('PeerRouteCandidateExpired'),
      );
    },
  );

  test(
    'same group tag discovers peer but does not authenticate by discovery',
    () async {
      final controlTransport = _SilentControlTransport();
      final container = _createContainer(
        database: database,
        transport: transport,
        clock: clock,
        controlTransport: controlTransport,
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _flush();
      await container
          .read(authControllerProvider.notifier)
          .signIn(userId: 'team', password: 'secret');

      container.read(discoveryControllerProvider);
      await _flush();

      transport.emit(
        DiscoveryPacket(
          type: DiscoveryPacketType.discoverAck,
          protocolVersion: '1.0',
          userId: 'team',
          discoveryGroupTag: _discoveryGroupTag('team', 'secret'),
          instanceId: 'peer-instance',
          displayName: 'Peer Node',
          deviceId: 'peer-device',
          deviceName: 'Ethernet Peer',
          osType: 'linux',
          port: 38401,
          receiveAvailable: true,
          sentAtEpochMs: clock.value.millisecondsSinceEpoch,
        ),
        address: InternetAddress('10.20.30.40'),
      );
      await _flush();

      expect(container.read(discoveryControllerProvider).peers, hasLength(1));
      expect(
        controlTransport.sentPackets.single.type,
        AuthPacketType.connectRequest,
      );
      expect(
        container
            .read(peerAuthSessionByPeerIdProvider('team@peer-device'))
            ?.status,
        PeerAuthStatus.connecting,
      );
    },
  );
}

ProviderContainer _createContainer({
  required AppDatabase database,
  required _FakeDiscoveryTransport transport,
  required _MutableClock clock,
  LocalInstanceRegistry? registry,
  ControlTransport? controlTransport,
  MessageBus? messageBus,
  List<NetworkInterfaceSnapshot> interfaceSnapshots = const [],
}) {
  final selectedControlTransport =
      controlTransport ?? _AutoAcceptControlTransport();
  return ProviderContainer(
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
      controlTransportProvider.overrideWithValue(selectedControlTransport),
      localDeviceIdentityServiceProvider.overrideWithValue(
        const _FakeLocalDeviceIdentityService(),
      ),
      localInstanceRegistryProvider.overrideWithValue(
        registry ?? _FakeLocalInstanceRegistry(),
      ),
      localAuthPortProvider.overrideWithValue(38401),
      discoveryTransportProvider.overrideWithValue(transport),
      networkInterfaceInventoryProvider.overrideWithValue(
        FakeNetworkInterfaceInventory(interfaceSnapshots),
      ),
      if (messageBus != null) messageBusProvider.overrideWithValue(messageBus),
      nowProvider.overrideWithValue(() => clock.value),
    ],
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 120));
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  void advance(Duration duration) {
    value = value.add(duration);
  }
}

String _authVerifier(String userId, String password) {
  return const SharedVerifierService().deriveVerifierBase64(
    userId: userId,
    password: password,
  );
}

String _discoveryGroupTag(String userId, String password) {
  return const DiscoveryGroupTagService().deriveTag(
    protocolVersion: '1.0',
    userId: userId,
    password: password,
  );
}

NetworkInterfaceSnapshot _interfaceSnapshot({
  required String name,
  required int index,
  required InterfaceTypeHint typeHint,
  required String address,
}) {
  return NetworkInterfaceSnapshot(
    id: NetworkInterfaceId(name: name, index: index),
    name: name,
    displayName: name,
    typeHint: typeHint,
    isUp: true,
    supportsMulticast: true,
    isLoopback: false,
    addresses: [InterfaceAddress.ipv4(address: address, prefixLength: 24)],
    capturedAt: DateTime.utc(2026),
  );
}

class _FakeDiscoveryTransport implements DiscoveryTransport {
  final StreamController<DiscoveryDatagram> _controller =
      StreamController<DiscoveryDatagram>.broadcast();
  final List<_OutboundDatagram> broadcasts = [];
  final List<_OutboundDatagram> unicasts = [];

  int? startedPort;

  @override
  Stream<DiscoveryDatagram> get packets => _controller.stream;

  void emit(
    DiscoveryPacket packet, {
    InternetAddress? address,
    int port = 38400,
  }) {
    _controller.add(
      DiscoveryDatagram(
        packet: packet,
        address: address ?? InternetAddress.loopbackIPv4,
        port: port,
      ),
    );
  }

  @override
  Future<void> start({required int port}) async {
    startedPort = port;
  }

  @override
  Future<void> sendBroadcast(
    DiscoveryPacket packet, {
    required int port,
  }) async {
    broadcasts.add(
      _OutboundDatagram(
        packet: packet,
        address: InternetAddress('255.255.255.255'),
        port: port,
      ),
    );
  }

  @override
  Future<void> sendUnicast(
    DiscoveryPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {
    unicasts.add(
      _OutboundDatagram(packet: packet, address: address, port: port),
    );
  }

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

class _OutboundDatagram {
  const _OutboundDatagram({
    required this.packet,
    required this.address,
    required this.port,
  });

  final DiscoveryPacket packet;
  final InternetAddress address;
  final int port;
}

class _FakeStoragePathProvider implements AppStoragePathProvider {
  const _FakeStoragePathProvider(this.path);

  final String path;

  @override
  Future<String> getDefaultReceivePath() async => path;
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

class _FakeLocalDeviceIdentityService implements LocalDeviceIdentityService {
  const _FakeLocalDeviceIdentityService();

  @override
  Future<LocalDeviceIdentity> load() async {
    return const LocalDeviceIdentity(
      deviceId: 'local-device',
      instanceId: 'local-instance',
      osType: 'macos',
    );
  }
}

class _FakeLocalInstanceRegistry implements LocalInstanceRegistry {
  _FakeLocalInstanceRegistry({List<LocalInstancePresence>? entries})
    : _entries = entries ?? <LocalInstancePresence>[];

  final List<LocalInstancePresence> _entries;

  @override
  Future<List<LocalInstancePresence>> listActive({
    required DateTime now,
    required Duration maxAge,
  }) async {
    return List<LocalInstancePresence>.from(_entries);
  }

  @override
  Future<void> publish(LocalInstancePresence presence) async {
    _entries.removeWhere((entry) => entry.instanceId == presence.instanceId);
    _entries.add(presence);
  }

  @override
  Future<void> remove(String instanceId) async {
    _entries.removeWhere((entry) => entry.instanceId == instanceId);
  }
}

class _AutoAcceptControlTransport implements ControlTransport {
  final StreamController<ControlDatagram> _controller =
      StreamController<ControlDatagram>.broadcast();

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
    if (packet.type != AuthPacketType.connectRequest) {
      return;
    }
    _controller.add(
      ControlDatagram(
        packet: AuthPacket(
          type: AuthPacketType.authAccept,
          protocolVersion: packet.protocolVersion,
          sessionId: packet.sessionId,
          fromUserId: packet.fromUserId,
          fromDeviceId: 'peer-reply',
          fromDisplayName: packet.fromDisplayName,
          sentAtEpochMs: packet.sentAtEpochMs,
        ),
        address: address,
        port: port,
      ),
    );
  }

  @override
  Future<int> start({required int preferredPort}) async => preferredPort;
}

class _SilentControlTransport implements ControlTransport {
  _SilentControlTransport({this.localPort});

  final int? localPort;
  final StreamController<ControlDatagram> _controller =
      StreamController<ControlDatagram>.broadcast();
  final List<AuthPacket> sentPackets = [];

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
    sentPackets.add(packet);
  }

  @override
  Future<int> start({required int preferredPort}) async =>
      localPort ?? preferredPort;
}
