import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/shared_verifier_service.dart';
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
          pairingProof: _pairingProof('admin', 'secret'),
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
        pairingProof: _pairingProof('admin', 'secret'),
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
          pairingProof: _pairingProof('admin', 'secret'),
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
            pairingProof: _pairingProof('admin', 'secret'),
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
        pairingProof: _pairingProof('other-team', 'different-secret'),
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

  test('broadcasts current pairing proof', () async {
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
    expect(
      transport.broadcasts.single.packet.pairingProof,
      _pairingProof('team', 'secret'),
    );
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
        pairingProof: _pairingProof('team', 'secret'),
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
}

ProviderContainer _createContainer({
  required AppDatabase database,
  required _FakeDiscoveryTransport transport,
  required _MutableClock clock,
  LocalInstanceRegistry? registry,
}) {
  final authTransport = _AutoAcceptAuthTransport();
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
      authTransportProvider.overrideWithValue(authTransport),
      localDeviceIdentityServiceProvider.overrideWithValue(
        const _FakeLocalDeviceIdentityService(),
      ),
      localInstanceRegistryProvider.overrideWithValue(
        registry ?? _FakeLocalInstanceRegistry(),
      ),
      localAuthPortProvider.overrideWithValue(38401),
      discoveryTransportProvider.overrideWithValue(transport),
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

String _pairingProof(String userId, String password) {
  return const SharedVerifierService().deriveVerifierBase64(
    userId: userId,
    password: password,
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
    _entries.removeWhere((entry) => entry.deviceId == presence.deviceId);
    _entries.add(presence);
  }

  @override
  Future<void> remove(String deviceId) async {
    _entries.removeWhere((entry) => entry.deviceId == deviceId);
  }
}

class _AutoAcceptAuthTransport implements AuthTransport {
  final StreamController<AuthDatagram> _controller =
      StreamController<AuthDatagram>.broadcast();

  @override
  Stream<AuthDatagram> get packets => _controller.stream;

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
  }) async {
    if (packet.type != AuthPacketType.connectRequest) {
      return;
    }
    _controller.add(
      AuthDatagram(
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
