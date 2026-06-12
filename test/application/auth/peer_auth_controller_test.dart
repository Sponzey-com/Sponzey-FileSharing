import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';
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
}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final transport = _InspectableAuthTransport(authPort);
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
      authTransportProvider.overrideWithValue(transport),
      localDeviceIdentityServiceProvider.overrideWithValue(
        _FakeLocalDeviceIdentityService(localDeviceId),
      ),
      authNowProvider.overrideWithValue(() => clock.value),
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
  final _InspectableAuthTransport transport;
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
  });

  final AuthPacket packet;
  final InternetAddress address;
  final int port;
}

class _InspectableAuthTransport implements AuthTransport {
  _InspectableAuthTransport(this.port);

  final int port;
  final StreamController<AuthDatagram> _controller =
      StreamController<AuthDatagram>.broadcast();
  final List<_SentPacket> sentPackets = [];

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
    sentPackets.add(_SentPacket(packet: packet, address: address, port: port));
  }

  @override
  Future<int> start({required int preferredPort}) async => port;

  void emit(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  }) {
    _controller.add(AuthDatagram(packet: packet, address: address, port: port));
  }
}
