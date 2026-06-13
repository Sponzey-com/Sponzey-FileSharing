import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_secure_storage.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';

const _sharedUserId = 'team';
const _sharedPassword = 'shared-secret';

void main() {
  late _MutableClock clock;
  late Directory workspaceDirectory;

  setUp(() async {
    clock = _MutableClock(DateTime(2026, 4, 9, 12, 0, 0));
    workspaceDirectory = await Directory.systemTemp.createTemp(
      'sponzey-transfer-controller-test-',
    );
  });

  tearDown(() async {
    if (await workspaceDirectory.exists()) {
      await workspaceDirectory.delete(recursive: true);
    }
  });

  test(
    'sends and receives a single file between authenticated peers',
    () async {
      final network = _LinkedFakeAuthNetwork();
      final alice = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41001,
        receivePath: '${workspaceDirectory.path}/alice',
      );
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41002,
        receivePath: '${workspaceDirectory.path}/bob',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await bob.container
          .read(settingsRepositoryProvider)
          .save(
            const AppSettings(
              defaultSavePath: '',
              autoReceiveEnabled: true,
              receivePolicy: ReceivePolicy.autoReceiveAll,
              logLevel: AppLogLevel.error,
            ).copyWith(defaultSavePath: '${workspaceDirectory.path}/bob'),
          );

      await _handshakePair(alice: alice, bob: bob, clock: clock.value);

      final sourceFile = File('${workspaceDirectory.path}/alice/source.txt');
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('hello from alice to bob');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(bobJob.destinationPath, isNotNull);
      expect(
        await File(bobJob.destinationPath!).readAsString(),
        'hello from alice to bob',
      );
    },
  );

  test('sends multiple files to one authenticated peer', () async {
    final network = _LinkedFakeAuthNetwork();
    final alice = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41101,
      receivePath: '${workspaceDirectory.path}/alice-multi-file',
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41102,
      receivePath: '${workspaceDirectory.path}/bob-multi-file',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-multi-file',
      bobPort: 41102,
      clock: clock,
    );

    final sourceA = File(
      '${workspaceDirectory.path}/alice-multi-file/alpha.txt',
    );
    final sourceB = File(
      '${workspaceDirectory.path}/alice-multi-file/beta.txt',
    );
    await sourceA.parent.create(recursive: true);
    await sourceA.writeAsString('alpha file');
    await sourceB.writeAsString('beta file');

    await alice.transferController.sendFiles(
      peerId: 'team@instance-device-b',
      filePaths: [sourceA.path, sourceB.path],
    );

    final aliceJobs = await _waitForTerminalTransferCount(alice.container, 2);
    final bobJobs = await _waitForTerminalTransferCount(bob.container, 2);

    expect(
      aliceJobs.map((job) => job.status),
      everyElement(TransferJobStatus.completed),
    );
    expect(
      bobJobs.map((job) => job.status),
      everyElement(TransferJobStatus.completed),
    );
    final receivedByName = {
      for (final job in bobJobs)
        job.fileName: await File(job.destinationPath!).readAsString(),
    };
    expect(receivedByName['alpha.txt'], 'alpha file');
    expect(receivedByName['beta.txt'], 'beta file');
  });

  test(
    'sends one file to multiple authenticated peers independently',
    () async {
      final network = _LinkedFakeAuthNetwork();
      final alice = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41111,
        receivePath: '${workspaceDirectory.path}/alice-one-to-many',
      );
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41112,
        receivePath: '${workspaceDirectory.path}/bob-one-to-many',
      );
      final carol = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-c',
        authPort: 41113,
        receivePath: '${workspaceDirectory.path}/carol-one-to-many',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      addTearDown(carol.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-one-to-many',
        bobPort: 41112,
        clock: clock,
      );
      await carol.container
          .read(settingsRepositoryProvider)
          .save(
            const AppSettings(
              defaultSavePath: '',
              autoReceiveEnabled: true,
              receivePolicy: ReceivePolicy.autoReceiveAll,
              logLevel: AppLogLevel.error,
            ).copyWith(
              defaultSavePath: '${workspaceDirectory.path}/carol-one-to-many',
            ),
          );
      alice.peerAuthController.syncDiscoveredPeer(
        _peerForDevice(clock.value, deviceId: 'device-c', port: 41113),
      );
      carol.peerAuthController.syncDiscoveredPeer(
        _peerForDevice(clock.value, deviceId: 'device-a', port: 41111),
      );
      await _flush();
      await alice.peerAuthController.startHandshake(
        _peerForDevice(clock.value, deviceId: 'device-c', port: 41113),
      );
      for (var i = 0; i < 100; i += 1) {
        final aliceCarolSession = alice.container.read(
          peerAuthSessionByPeerIdProvider('team@instance-device-c'),
        );
        final carolAliceSession = carol.container.read(
          peerAuthSessionByPeerIdProvider('team@instance-device-a'),
        );
        if (aliceCarolSession?.isAuthenticated == true &&
            carolAliceSession?.isAuthenticated == true) {
          break;
        }
        await _flush();
        if (i == 99) {
          fail('Alice and Carol did not become authenticated in time.');
        }
      }

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-one-to-many/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('fanout payload');

      await alice.transferController.sendFileToPeers(
        peerIds: const ['team@instance-device-b', 'team@instance-device-c'],
        filePath: sourceFile.path,
      );

      final aliceJobs = await _waitForTerminalTransferCount(alice.container, 2);
      final bobJob = await _waitForTerminalTransfer(bob.container);
      final carolJob = await _waitForTerminalTransfer(carol.container);

      expect(
        aliceJobs.map((job) => job.status),
        everyElement(TransferJobStatus.completed),
      );
      expect(
        await File(bobJob.destinationPath!).readAsString(),
        'fanout payload',
      );
      expect(
        await File(carolJob.destinationPath!).readAsString(),
        'fanout payload',
      );
    },
  );

  test('retransmits dropped chunks and completes under packet loss', () async {
    final droppedChunks = <int>{3};
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41021 &&
                targetPort == 41022 &&
                packet.transferChunkIndex != null &&
                droppedChunks.remove(packet.transferChunkIndex)) {
              return;
            }
            deliver(packet, address: address, port: sourcePort);
          },
    );
    final alice = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41021,
      receivePath: '${workspaceDirectory.path}/alice-loss',
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41022,
      receivePath: '${workspaceDirectory.path}/bob-loss',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-loss',
      bobPort: 41022,
      clock: clock,
    );

    final sourceFile = File('${workspaceDirectory.path}/alice-loss/source.bin');
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString(List<String>.filled(14000, 'abc123').join());

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    expect(aliceJob.status, TransferJobStatus.completed);
    expect(bobJob.status, TransferJobStatus.completed);
    expect(aliceJob.retryCount, greaterThan(0));
    expect(aliceJob.lossRate, greaterThan(0));
  });

  test('handles out-of-order and duplicate chunks', () async {
    AuthPacket? heldChunkFive;
    var duplicated = false;
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41031 &&
                targetPort == 41032 &&
                packet.transferChunkIndex == 5 &&
                heldChunkFive == null) {
              heldChunkFive = packet;
              return;
            }
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41031 &&
                targetPort == 41032 &&
                packet.transferChunkIndex == 6 &&
                heldChunkFive != null) {
              deliver(packet, address: address, port: sourcePort);
              deliver(heldChunkFive!, address: address, port: sourcePort);
              heldChunkFive = null;
              return;
            }
            deliver(packet, address: address, port: sourcePort);
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41031 &&
                targetPort == 41032 &&
                packet.transferChunkIndex == 8 &&
                !duplicated) {
              duplicated = true;
              deliver(packet, address: address, port: sourcePort);
            }
          },
    );
    final alice = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41031,
      receivePath: '${workspaceDirectory.path}/alice-order',
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41032,
      receivePath: '${workspaceDirectory.path}/bob-order',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-order',
      bobPort: 41032,
      clock: clock,
    );

    final sourceFile = File(
      '${workspaceDirectory.path}/alice-order/source.txt',
    );
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString('0123456789' * 9000);

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    expect(aliceJob.status, TransferJobStatus.completed);
    expect(bobJob.status, TransferJobStatus.completed);
    expect(bobJob.duplicateCount, greaterThan(0));
  });

  test('completes under deterministic 20 percent packet loss', () async {
    final droppedIndexes = <int>{2};
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41041 &&
                targetPort == 41042 &&
                packet.transferChunkIndex != null &&
                droppedIndexes.remove(packet.transferChunkIndex)) {
              return;
            }
            deliver(packet, address: address, port: sourcePort);
          },
    );
    final alice = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41041,
      receivePath: '${workspaceDirectory.path}/alice-20p',
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41042,
      receivePath: '${workspaceDirectory.path}/bob-20p',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-20p',
      bobPort: 41042,
      clock: clock,
    );

    final sourceFile = File('${workspaceDirectory.path}/alice-20p/source.bin');
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString(List<String>.filled(6500, 'chunk20').join());

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    expect(aliceJob.status, TransferJobStatus.completed);
    expect(bobJob.status, TransferJobStatus.completed);
    expect(aliceJob.retryCount, greaterThan(0));
    expect(aliceJob.lossRate, greaterThan(0.1));
  });

  test('keeps transfer metric logs throttled under noisy delivery', () async {
    final logger = _MemoryAppLogger(minimumLevel: AppLogLevel.debug);
    var delayed = false;
    var duplicated = false;
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41051 &&
                targetPort == 41052 &&
                packet.transferChunkIndex == 4 &&
                !delayed) {
              delayed = true;
              unawaited(
                Future<void>.delayed(const Duration(milliseconds: 50), () {
                  deliver(packet, address: address, port: sourcePort);
                }),
              );
              return;
            }
            deliver(packet, address: address, port: sourcePort);
            if (packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41051 &&
                targetPort == 41052 &&
                packet.transferChunkIndex == 7 &&
                !duplicated) {
              duplicated = true;
              unawaited(
                Future<void>.delayed(const Duration(milliseconds: 5), () {
                  deliver(packet, address: address, port: sourcePort);
                }),
              );
            }
          },
    );
    final alice = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41051,
      receivePath: '${workspaceDirectory.path}/alice-log',
      logger: logger,
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41052,
      receivePath: '${workspaceDirectory.path}/bob-log',
      logger: logger,
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-log',
      bobPort: 41052,
      clock: clock,
    );

    final sourceFile = File('${workspaceDirectory.path}/alice-log/source.txt');
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString('metric-log-test-' * 20000);

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    expect(aliceJob.status, TransferJobStatus.completed);
    expect(bobJob.status, TransferJobStatus.completed);
    final transferDebugLogs = logger.entries
        .where(
          (entry) =>
              entry.level == AppLogLevel.debug &&
              entry.category == AppLogCategory.transferData,
        )
        .toList(growable: false);
    expect(transferDebugLogs, isNotEmpty);
    expect(transferDebugLogs.length, lessThan(30));
  });

  test('fails transfer when a chunk is corrupted in transit', () async {
    var corrupted = false;
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (!corrupted &&
                packet.type == AuthPacketType.transferChunk &&
                sourcePort == 41011 &&
                targetPort == 41012) {
              corrupted = true;
              deliver(
                _copyPacket(
                  packet,
                  transferChunkDataBase64: base64Encode(
                    utf8.encode('corrupted'),
                  ),
                ),
                address: address,
                port: sourcePort,
              );
              return;
            }
            deliver(packet, address: address, port: sourcePort);
          },
    );
    final alice = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41011,
      receivePath: '${workspaceDirectory.path}/alice-corrupt',
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41012,
      receivePath: '${workspaceDirectory.path}/bob-corrupt',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await bob.container
        .read(settingsRepositoryProvider)
        .save(
          const AppSettings(
            defaultSavePath: '',
            autoReceiveEnabled: true,
            receivePolicy: ReceivePolicy.autoReceiveAll,
            logLevel: AppLogLevel.error,
          ).copyWith(defaultSavePath: '${workspaceDirectory.path}/bob-corrupt'),
        );

    await _handshakePair(
      alice: alice,
      bob: bob,
      clock: clock.value,
      bobPort: 41012,
      alicePort: 41011,
    );

    final sourceFile = File(
      '${workspaceDirectory.path}/alice-corrupt/source.txt',
    );
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString('this transfer should fail');

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    expect(aliceJob.status, TransferJobStatus.failed);
    expect(bobJob.status, TransferJobStatus.failed);
    expect(
      bobJob.message,
      anyOf(contains('해시'), contains('chunk'), contains('크기')),
    );
  });
}

PeerNode _peerForBob(DateTime now, {int port = 41002}) {
  return _peerForDevice(now, deviceId: 'device-b', port: port);
}

PeerNode _peerForDevice(
  DateTime now, {
  required String deviceId,
  required int port,
}) {
  return PeerNode(
    deviceId: deviceId,
    instanceId: 'instance-$deviceId',
    userId: _sharedUserId,
    displayName: _sharedUserId,
    deviceName: 'Node-$deviceId',
    osType: 'macos',
    protocolVersion: '1.0',
    lastSeenAt: now,
    address: '127.0.0.1',
    port: port,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}

Future<_TransferHarness> _createNode({
  required _LinkedFakeAuthNetwork network,
  required _MutableClock clock,
  required String loginUserId,
  required String loginPassword,
  required String localDeviceId,
  required int authPort,
  required String receivePath,
  AppLogger? logger,
}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final transport = network.attach(authPort);
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
        _FakeStoragePathProvider(receivePath),
      ),
      appLoggerProvider.overrideWithValue(
        logger ?? const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      ),
      authTransportProvider.overrideWithValue(transport),
      controlTransportProvider.overrideWithValue(
        AuthControlTransportAdapter(authTransport: transport),
      ),
      localDeviceIdentityServiceProvider.overrideWithValue(
        _FakeLocalDeviceIdentityService(localDeviceId),
      ),
      authNowProvider.overrideWithValue(() => clock.value),
      transferNowProvider.overrideWithValue(() => clock.value),
    ],
  );

  container.read(authControllerProvider);
  await _flush();
  await container
      .read(authControllerProvider.notifier)
      .signIn(userId: loginUserId, password: loginPassword);
  container.read(peerAuthControllerProvider);
  container.read(transferControllerProvider);
  await _flush();

  return _TransferHarness(
    container: container,
    peerAuthController: container.read(peerAuthControllerProvider.notifier),
    transferController: container.read(transferControllerProvider.notifier),
    database: database,
  );
}

Future<void> _prepareAuthenticatedPair({
  required _TransferHarness alice,
  required _TransferHarness bob,
  required String bobReceivePath,
  required int bobPort,
  required _MutableClock clock,
}) async {
  await bob.container
      .read(settingsRepositoryProvider)
      .save(
        const AppSettings(
          defaultSavePath: '',
          autoReceiveEnabled: true,
          receivePolicy: ReceivePolicy.autoReceiveAll,
          logLevel: AppLogLevel.error,
        ).copyWith(defaultSavePath: bobReceivePath),
      );
  await _handshakePair(
    alice: alice,
    bob: bob,
    clock: clock.value,
    bobPort: bobPort,
  );
}

Future<void> _handshakePair({
  required _TransferHarness alice,
  required _TransferHarness bob,
  required DateTime clock,
  int bobPort = 41002,
  int alicePort = 41001,
}) async {
  alice.peerAuthController.syncDiscoveredPeer(
    _peerForBob(clock, port: bobPort),
  );
  bob.peerAuthController.syncDiscoveredPeer(
    PeerNode(
      deviceId: 'device-a',
      instanceId: 'instance-device-a',
      userId: _sharedUserId,
      displayName: _sharedUserId,
      deviceName: 'Node-device-a',
      osType: 'macos',
      protocolVersion: '1.0',
      lastSeenAt: clock,
      address: '127.0.0.1',
      port: alicePort,
      receiveAvailable: true,
      presence: PeerPresence.online,
    ),
  );
  await _flush();
  await alice.peerAuthController.startHandshake(
    _peerForBob(clock, port: bobPort),
  );

  for (var i = 0; i < 100; i += 1) {
    final aliceSession = alice.container.read(
      peerAuthSessionByPeerIdProvider('team@instance-device-b'),
    );
    final bobSession = bob.container.read(
      peerAuthSessionByPeerIdProvider('team@instance-device-a'),
    );
    if (aliceSession?.isAuthenticated == true &&
        bobSession?.isAuthenticated == true) {
      return;
    }
    await _flush();
  }

  fail('Handshake pair did not become authenticated in time.');
}

Future<TransferJob> _waitForTerminalTransfer(
  ProviderContainer container,
) async {
  for (var i = 0; i < 600; i += 1) {
    final jobs = container.read(transferJobsProvider);
    if (jobs.isNotEmpty && jobs.first.isTerminal) {
      return jobs.first;
    }
    await _flush();
  }
  final jobs = container.read(transferJobsProvider);
  fail(
    'Transfer job did not reach a terminal state. '
    'Current jobs: ${jobs.map((job) => '${job.statusLabel}:${job.message}').join(' | ')}',
  );
}

Future<List<TransferJob>> _waitForTerminalTransferCount(
  ProviderContainer container,
  int expectedCount,
) async {
  for (var i = 0; i < 600; i += 1) {
    final jobs = container.read(transferJobsProvider);
    if (jobs.length >= expectedCount &&
        jobs.take(expectedCount).every((job) => job.isTerminal)) {
      return jobs.take(expectedCount).toList(growable: false);
    }
    await _flush();
  }
  final jobs = container.read(transferJobsProvider);
  fail(
    'Expected $expectedCount terminal transfer jobs. '
    'Current jobs: ${jobs.map((job) => '${job.statusLabel}:${job.message}').join(' | ')}',
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

AuthPacket _copyPacket(AuthPacket packet, {String? transferChunkDataBase64}) {
  return AuthPacket(
    type: packet.type,
    protocolVersion: packet.protocolVersion,
    sessionId: packet.sessionId,
    fromUserId: packet.fromUserId,
    fromDeviceId: packet.fromDeviceId,
    fromInstanceId: packet.fromInstanceId,
    fromDisplayName: packet.fromDisplayName,
    nonce: packet.nonce,
    token: packet.token,
    rejectCode: packet.rejectCode,
    rejectMessage: packet.rejectMessage,
    transferId: packet.transferId,
    transferFileName: packet.transferFileName,
    transferFileSize: packet.transferFileSize,
    transferSha256: packet.transferSha256,
    transferChunkCount: packet.transferChunkCount,
    transferChunkIndex: packet.transferChunkIndex,
    transferChunkIndexes: packet.transferChunkIndexes,
    transferChunkDataBase64:
        transferChunkDataBase64 ?? packet.transferChunkDataBase64,
    transferAccepted: packet.transferAccepted,
    transferSavePath: packet.transferSavePath,
    transferWindowStart: packet.transferWindowStart,
    transferWindowSize: packet.transferWindowSize,
    sentAtEpochMs: packet.sentAtEpochMs,
  );
}

class _TransferHarness {
  const _TransferHarness({
    required this.container,
    required this.peerAuthController,
    required this.transferController,
    required this.database,
  });

  final ProviderContainer container;
  final PeerAuthController peerAuthController;
  final TransferController transferController;
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

class _LogEntry {
  const _LogEntry({
    required this.level,
    required this.category,
    required this.message,
  });

  final AppLogLevel level;
  final AppLogCategory category;
  final String message;
}

class _MemoryAppLogger implements AppLogger {
  _MemoryAppLogger({required this.minimumLevel});

  @override
  final AppLogLevel minimumLevel;

  final List<_LogEntry> entries = [];

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.debug, category, message);

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.info, category, message);

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.warning, category, message);

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.error, category, message);

  void _add(AppLogLevel level, AppLogCategory category, String message) {
    if (level.index < minimumLevel.index) {
      return;
    }
    entries.add(_LogEntry(level: level, category: category, message: message));
  }
}

typedef _PacketInterceptor =
    Future<void> Function({
      required AuthPacket packet,
      required InternetAddress address,
      required int sourcePort,
      required int targetPort,
      required void Function(
        AuthPacket packet, {
        required InternetAddress address,
        required int port,
      })
      deliver,
    });

class _LinkedFakeAuthNetwork {
  _LinkedFakeAuthNetwork({this.interceptor});

  final _PacketInterceptor? interceptor;
  final Map<int, _FakeAuthTransport> _transports = {};

  _FakeAuthTransport attach(int port) {
    final transport = _FakeAuthTransport(
      localPort: port,
      onSend: (packet, address, targetPort, sourcePort) async {
        final target = _transports[targetPort];
        if (target == null) {
          return;
        }
        if (interceptor != null) {
          await interceptor!(
            packet: packet,
            address: address,
            sourcePort: sourcePort,
            targetPort: targetPort,
            deliver: (deliveredPacket, {required address, required port}) {
              target.emit(deliveredPacket, address: address, port: port);
            },
          );
          return;
        }
        target.emit(packet, address: address, port: sourcePort);
      },
    );
    _transports[port] = transport;
    return transport;
  }
}

class _FakeAuthTransport implements AuthTransport {
  _FakeAuthTransport({required this.localPort, required this.onSend});

  final int localPort;
  final Future<void> Function(AuthPacket, InternetAddress, int, int) onSend;
  final StreamController<AuthDatagram> _controller =
      StreamController<AuthDatagram>.broadcast();

  @override
  Stream<AuthDatagram> get packets => _controller.stream;

  void emit(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  }) {
    _controller.add(AuthDatagram(packet: packet, address: address, port: port));
  }

  @override
  Future<int> start({required int preferredPort}) async => localPort;

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  }) {
    return onSend(packet, address, port, localPort);
  }

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
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
