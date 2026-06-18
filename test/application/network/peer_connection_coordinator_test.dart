import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_connection_coordinator.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
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
    clock = _MutableClock(DateTime.utc(2026, 4, 9, 12));
  });

  test(
    'selects same-subnet ethernet path and starts handshake explicitly',
    () async {
      final harness = await _createHarness(clock);
      addTearDown(harness.dispose);
      final peer = _peer(clock.value);
      final ethernet = _candidate(
        peerId: peer.id,
        id: 'en0',
        localAddress: '10.20.30.5',
        remoteAddress: peer.address,
        typeHint: InterfaceTypeHint.ethernet,
      );
      final unknown = _candidate(
        peerId: peer.id,
        id: 'p2p0',
        localAddress: '0.0.0.0',
        remoteAddress: peer.address,
        typeHint: InterfaceTypeHint.unknown,
        bindMode: UdpInterfaceBindMode.any,
      );
      harness.seedCandidate(unknown);
      harness.seedCandidate(ethernet);

      final result = await harness.coordinator.connect(peer);
      await _flush();

      expect(result.status, PeerConnectionAttemptStatus.started);
      expect(result.path!.candidate.candidateId, ethernet.candidateId);
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(peer.id)!
            .candidate
            .candidateId,
        ethernet.candidateId,
      );
      expect(
        harness.container
            .read(peerPathDiagnosticsProvider(peer.id))
            .debugSummary,
        contains('active=en0#101'),
      );
      expect(harness.transport.sentPackets, hasLength(1));
      expect(harness.pathEvents.single.eventType, 'PeerPathSelected');
    },
  );

  test('does not start handshake when candidate list is empty', () async {
    final harness = await _createHarness(clock);
    addTearDown(harness.dispose);

    final result = await harness.coordinator.connect(_peer(clock.value));
    await _flush();

    expect(result.status, PeerConnectionAttemptStatus.noSelectableCandidate);
    expect(harness.transport.sentPackets, isEmpty);
    expect(
      harness.container
          .read(peerConnectionCoordinatorProvider)
          .reasonCodeForPeer(_peer(clock.value).id),
      'noSelectableRouteCandidate',
    );
  });

  test('does not start handshake from MessageBus event alone', () async {
    final harness = await _createHarness(clock);
    addTearDown(harness.dispose);
    final peer = _peer(clock.value);
    final candidate = _candidate(peerId: peer.id, id: 'en0');
    harness.seedCandidate(candidate);

    harness.bus.publish(
      PeerRouteCandidateAppEvent(
        eventId: 'candidate-event',
        occurredAt: clock.value,
        correlationId: peer.id,
        source: 'test',
        severity: AppEventSeverity.debug,
        eventType: 'PeerRouteCandidateFound',
        peerId: peer.id,
        candidateId: candidate.candidateId,
      ),
    );
    await _flush();

    expect(harness.transport.sentPackets, isEmpty);

    await harness.coordinator.connect(peer);
    await _flush();

    expect(harness.transport.sentPackets, hasLength(1));
  });

  test('skips duplicate handshake for an authenticated peer', () async {
    final harness = await _createHarness(clock);
    addTearDown(harness.dispose);
    final peer = _peer(clock.value);
    harness.seedCandidate(_candidate(peerId: peer.id, id: 'en0'));

    await harness.coordinator.connect(peer);
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
      port: 49152,
    );
    await _flush();

    final result = await harness.coordinator.connect(peer);
    await _flush();

    expect(result.status, PeerConnectionAttemptStatus.skippedAuthenticated);
    expect(harness.transport.sentPackets, hasLength(1));
  });

  test(
    'authenticated peer keeps active path when matching candidate expires',
    () async {
      final harness = await _createHarness(clock);
      addTearDown(harness.dispose);
      final peer = _peer(clock.value);
      final first = _candidate(
        peerId: peer.id,
        id: 'en0',
        localAddress: '10.20.30.5',
        remoteAddress: peer.address,
      );
      final second = _candidate(
        peerId: peer.id,
        id: 'en1',
        localAddress: '10.20.30.6',
        remoteAddress: peer.address,
      );
      harness.seedCandidate(first);

      final firstResult = await harness.coordinator.connect(peer);
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
        port: 49152,
      );
      await _flush();
      expect(
        harness.container
            .read(peerPathRegistryProvider)
            .selectedForPeer(peer.id)!
            .status,
        PeerPathStatus.active,
      );

      final expiredFirst = harness.container
          .read(peerRouteCandidateProjectionProvider.notifier)
          .expire(now: clock.value, ttl: const Duration(seconds: 30))
          .singleWhere(
            (candidate) => candidate.candidateId == first.candidateId,
          );
      final expired = harness.container
          .read(peerPathRegistryMutationsProvider)
          .expireLeaseForCandidate(
            candidate: expiredFirst,
            reasonCode: 'ttlExceeded',
          );
      harness.seedCandidate(second);

      final retryResult = await harness.coordinator.connect(peer);
      await _flush();

      expect(firstResult.path!.candidate.candidateId, first.candidateId);
      expect(expired, isFalse);
      expect(
        retryResult.status,
        PeerConnectionAttemptStatus.skippedAuthenticated,
      );
      expect(harness.transport.sentPackets, hasLength(1));
      final selected = harness.container
          .read(peerPathRegistryProvider)
          .selectedForPeer(peer.id);
      expect(selected?.candidate.candidateId, first.candidateId);
      expect(
        selected?.status,
        PeerPathStatus.active,
      );
    },
  );

  test('failed selected candidate is skipped on retry', () async {
    final harness = await _createHarness(clock);
    addTearDown(harness.dispose);
    final peer = _peer(clock.value);
    final first = _candidate(
      peerId: peer.id,
      id: 'en0',
      rttMs: 1,
      localAddress: '10.20.30.5',
      remoteAddress: peer.address,
    );
    final second = _candidate(
      peerId: peer.id,
      id: 'en1',
      rttMs: 20,
      localAddress: '10.20.30.6',
      remoteAddress: peer.address,
    );
    harness.seedCandidate(first);
    harness.seedCandidate(second);

    final firstResult = await harness.coordinator.connect(peer);
    await _flush();
    final retryResult = await harness.coordinator.failCandidateAndRetry(
      peer: peer,
      candidateId: firstResult.path!.candidate.candidateId,
      reasonCode: 'probeFailed',
    );
    await _flush();

    expect(firstResult.path!.candidate.candidateId, first.candidateId);
    expect(retryResult.status, PeerConnectionAttemptStatus.started);
    expect(retryResult.path!.candidate.candidateId, second.candidateId);
    expect(harness.transport.sentPackets, hasLength(2));
  });

  test('handshake timeout fails selected candidate before retry', () async {
    final harness = await _createHarness(
      clock,
      authHandshakeTimeout: const Duration(milliseconds: 30),
    );
    addTearDown(harness.dispose);
    final peer = _peer(clock.value);
    final first = _candidate(
      peerId: peer.id,
      id: 'en0',
      rttMs: 1,
      localAddress: '10.20.30.5',
      remoteAddress: peer.address,
    );
    final second = _candidate(
      peerId: peer.id,
      id: 'en1',
      rttMs: 20,
      localAddress: '10.20.30.6',
      remoteAddress: peer.address,
    );
    harness.seedCandidate(first);
    harness.seedCandidate(second);

    final firstResult = await harness.coordinator.connect(peer);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _flush();

    final failedCandidate = harness.container
        .read(peerRouteCandidatesProvider(peer.id))
        .singleWhere((candidate) => candidate.candidateId == first.candidateId);
    expect(firstResult.path!.candidate.candidateId, first.candidateId);
    expect(failedCandidate.status, RouteCandidateStatus.failed);
    expect(
      harness.container
          .read(peerPathRegistryProvider)
          .selectedForPeer(peer.id)!
          .status,
      PeerPathStatus.failed,
    );

    final retryResult = await harness.coordinator.connect(peer);
    await _flush();

    expect(retryResult.status, PeerConnectionAttemptStatus.started);
    expect(retryResult.path!.candidate.candidateId, second.candidateId);
    expect(harness.transport.sentPackets, hasLength(2));
  });

  test('returns no selectable candidate when every candidate failed', () async {
    final harness = await _createHarness(clock);
    addTearDown(harness.dispose);
    final peer = _peer(clock.value);
    final candidate = _candidate(peerId: peer.id, id: 'en0');
    harness.seedCandidate(candidate);

    final firstResult = await harness.coordinator.connect(peer);
    await _flush();
    final retryResult = await harness.coordinator.failCandidateAndRetry(
      peer: peer,
      candidateId: firstResult.path!.candidate.candidateId,
      reasonCode: 'probeFailed',
    );
    await _flush();

    expect(retryResult.status, PeerConnectionAttemptStatus.failed);
    expect(retryResult.reasonCode, 'allRouteCandidatesFailed');
    expect(harness.transport.sentPackets, hasLength(1));
  });
}

Future<_CoordinatorHarness> _createHarness(
  _MutableClock clock, {
  Duration authHandshakeTimeout = const Duration(seconds: 15),
}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final transport = _InspectableControlTransport(40001);
  final bus = InMemoryMessageBus();
  final pathEvents = <PeerPathAppEvent>[];
  final subscription = bus.eventsOfType<PeerPathAppEvent>().listen(
    pathEvents.add,
  );
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig(
          environment: AppEnvironment.development,
          appName: 'Sponzey FileSharing',
          protocolVersion: '1.0',
          discoveryPort: 38400,
          authPort: 38401,
          authTokenLifetime: Duration(seconds: 20),
          authAllowedClockSkew: Duration(seconds: 5),
          authHandshakeTimeout: authHandshakeTimeout,
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
        const _FakeLocalDeviceIdentityService(),
      ),
      authNowProvider.overrideWithValue(() => clock.value),
      peerConnectionNowProvider.overrideWithValue(() => clock.value),
      messageBusProvider.overrideWithValue(bus),
    ],
  );

  container.read(authControllerProvider);
  await _flush();
  await container
      .read(authControllerProvider.notifier)
      .signIn(userId: 'team', password: 'secret');
  container.read(peerAuthControllerProvider);
  await _flush();

  return _CoordinatorHarness(
    container: container,
    database: database,
    transport: transport,
    bus: bus,
    pathEvents: pathEvents,
    subscription: subscription,
  );
}

PeerNode _peer(DateTime now) {
  return PeerNode(
    deviceId: 'device-b',
    userId: 'team',
    displayName: 'team',
    deviceName: 'Node-device-b',
    osType: 'macos',
    protocolVersion: '1.0',
    lastSeenAt: now,
    address: '10.20.30.40',
    port: 40002,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}

PeerRouteCandidate _candidate({
  required String peerId,
  required String id,
  String localAddress = '10.20.30.5',
  String remoteAddress = '10.20.30.40',
  InterfaceTypeHint typeHint = InterfaceTypeHint.ethernet,
  UdpInterfaceBindMode bindMode = UdpInterfaceBindMode.specificAddress,
  int? rttMs,
}) {
  return PeerRouteCandidate.create(
    peerId: peerId,
    remoteAddress: remoteAddress,
    remotePort: 40002,
    localInterfaceId: NetworkInterfaceId(
      name: id,
      index: switch (id) {
        'en0' => 101,
        'en1' => 102,
        'p2p0' => 201,
        _ => id.codeUnitAt(id.length - 1),
      },
    ),
    localAddress: localAddress,
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    localInterfaceTypeHint: typeHint,
    bindMode: bindMode,
    rttMs: rttMs,
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

class _CoordinatorHarness {
  const _CoordinatorHarness({
    required this.container,
    required this.database,
    required this.transport,
    required this.bus,
    required this.pathEvents,
    required this.subscription,
  });

  final ProviderContainer container;
  final AppDatabase database;
  final _InspectableControlTransport transport;
  final InMemoryMessageBus bus;
  final List<PeerPathAppEvent> pathEvents;
  final StreamSubscription<PeerPathAppEvent> subscription;

  PeerConnectionCoordinator get coordinator {
    return container.read(peerConnectionCoordinatorProvider.notifier);
  }

  void seedCandidate(PeerRouteCandidate candidate) {
    container
        .read(peerRouteCandidateProjectionProvider.notifier)
        .upsertCandidate(candidate);
  }

  Future<void> dispose() async {
    await subscription.cancel();
    container.dispose();
    bus.dispose();
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
  const _FakeLocalDeviceIdentityService();

  @override
  Future<LocalDeviceIdentity> load() async {
    return const LocalDeviceIdentity(
      deviceId: 'device-a',
      instanceId: 'instance-device-a',
      osType: 'macos',
    );
  }
}

class _SentPacket {
  const _SentPacket({
    required this.packet,
    required this.address,
    required this.port,
  });

  final AuthPacket packet;
  final InternetAddress address;
  final int port;
}

class _InspectableControlTransport implements ControlTransport {
  _InspectableControlTransport(this.port);

  final int port;
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
    sentPackets.add(_SentPacket(packet: packet, address: address, port: port));
  }

  @override
  Future<int> start({required int preferredPort}) async => port;

  void emit(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  }) {
    _controller.add(
      ControlDatagram(packet: packet, address: address, port: port),
    );
  }
}
