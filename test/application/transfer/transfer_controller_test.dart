import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_history_repository.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_secure_storage.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/transfer_history_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_transport.dart';

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
      expect(aliceJob.routeSnapshot?.routeLeaseId, isNotNull);
      expect(aliceJob.routeSnapshot?.controlRemoteAddress, '127.0.0.1');
      expect(aliceJob.routeSnapshot?.dataRemoteAddress, '127.0.0.1');
      expect(bobJob.routeSnapshot?.routeLeaseId, isNotNull);
      expect(bobJob.routeSnapshot?.dataLocalAddress, isNotNull);
      expect(bobJob.destinationPath, isNotNull);
      expect(
        await File(bobJob.destinationPath!).readAsString(),
        'hello from alice to bob',
      );
      final senderTraces = alice.transferController.diagnosticFrameSnapshot(
        aliceJob.transferId,
      );
      final receiverTraces = bob.transferController.diagnosticFrameSnapshot(
        bobJob.transferId,
      );
      expect(senderTraces, isNotEmpty);
      expect(receiverTraces, isNotEmpty);
      expect(senderTraces.map((trace) => trace.direction), contains('out'));
      expect(receiverTraces.map((trace) => trace.direction), contains('in'));
      expect(
        [...senderTraces, ...receiverTraces].map((trace) => trace.endpoint),
        everyElement(isNot(contains(sourceFile.path))),
      );

      final aliceHistory = await _waitForHistory(alice.container, 1);
      final bobHistory = await _waitForHistory(bob.container, 1);
      expect(aliceHistory.single.job.status, TransferJobStatus.completed);
      expect(bobHistory.single.job.status, TransferJobStatus.completed);
      expect(aliceHistory.single.files.single.fileName, 'source.txt');
      expect(bobHistory.single.files.single.fileName, 'source.txt');
    },
  );

  test(
    'uses active route remote address instead of stale session loopback target',
    () async {
      String? transferInitTargetAddress;
      final network = _LinkedFakeAuthNetwork(
        interceptor:
            ({
              required packet,
              required address,
              required sourcePort,
              required targetPort,
              required deliver,
            }) async {
              if (packet.type == AuthPacketType.transferInit &&
                  sourcePort == 41201 &&
                  targetPort == 41202) {
                transferInitTargetAddress = address.address;
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
        authPort: 41201,
        receivePath: '${workspaceDirectory.path}/alice-route-target',
      );
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41202,
        receivePath: '${workspaceDirectory.path}/bob-route-target',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-route-target',
        bobPort: 41202,
        alicePort: 41201,
        clock: clock,
      );
      alice.container
          .read(peerPathRegistryMutationsProvider)
          .select(
            _testActivePath(
              peerId: 'team@instance-device-b',
              localAddress: '10.211.55.2',
              remoteAddress: '10.211.55.3',
              remotePort: 41202,
            ),
          );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-route-target/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('route target must not use loopback');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      expect(transferInitTargetAddress, '10.211.55.3');
      final aliceJob = await _waitForTerminalTransfer(alice.container);
      expect(aliceJob.routeSnapshot?.controlRemoteAddress, '10.211.55.3');
      expect(aliceJob.routeSnapshot?.dataRemoteAddress, '10.211.55.3');
    },
  );

  test(
    'fails before data chunks when data bind local address differs from route lease',
    () async {
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final aliceDataTransport = dataNetwork.attach();
      final bobDataTransport = dataNetwork.attach();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: aliceDataTransport,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41211,
        receivePath: '${workspaceDirectory.path}/alice-bind-mismatch',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: bobDataTransport,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41212,
        receivePath: '${workspaceDirectory.path}/bob-bind-mismatch',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-bind-mismatch',
        bobPort: 41212,
        alicePort: 41211,
        clock: clock,
      );
      aliceDataTransport.endpoint = const UdpInterfaceEndpoint(
        role: UdpPortRole.data,
        localAddress: '10.211.55.2',
        port: 43000,
        bindMode: UdpInterfaceBindMode.specificAddress,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-bind-mismatch/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('data chunks must not start');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      expect(aliceJob.status, TransferJobStatus.failed);
      expect(aliceJob.message, contains('Data socket local address'));
      expect(
        dataNetwork.sentFrames.where(
          (frame) => frame.type == DataFrameType.dataChunk,
        ),
        isEmpty,
      );
    },
  );

  test(
    'allows wildcard data socket for a verified routed transfer path',
    () async {
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final aliceDataTransport = dataNetwork.attach();
      final bobDataTransport = dataNetwork.attach();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: aliceDataTransport,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41231,
        receivePath: '${workspaceDirectory.path}/alice-wildcard-data',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: bobDataTransport,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41232,
        receivePath: '${workspaceDirectory.path}/bob-wildcard-data',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-wildcard-data',
        bobPort: 41232,
        alicePort: 41231,
        clock: clock,
      );
      alice.container
          .read(peerPathRegistryMutationsProvider)
          .select(
            _testActivePath(
              peerId: 'team@instance-device-b',
              localAddress: '10.211.55.2',
              remoteAddress: '10.211.55.3',
              remotePort: 41232,
            ),
          );
      bob.container
          .read(peerPathRegistryMutationsProvider)
          .select(
            _testActivePath(
              peerId: 'team@instance-device-a',
              localAddress: '10.211.55.3',
              remoteAddress: '10.211.55.2',
              remotePort: 41231,
            ),
          );
      bobDataTransport.endpoint = const UdpInterfaceEndpoint(
        role: UdpPortRole.data,
        localAddress: '0.0.0.0',
        port: 43020,
        bindMode: UdpInterfaceBindMode.any,
      );
      dataNetwork.register(43020, bobDataTransport);

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-wildcard-data/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('wildcard data sockets are valid');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);
      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(bobJob.routeSnapshot?.controlLocalAddress, '10.211.55.3');
      expect(bobJob.routeSnapshot?.dataLocalAddress, '0.0.0.0');
      expect(
        await File(bobJob.destinationPath!).readAsString(),
        'wildcard data sockets are valid',
      );
    },
  );

  test('fails before data chunks when route lease expires', () async {
    late _TransferHarness alice;
    final dataNetwork = _LinkedFakeDataNetwork();
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (packet.type == AuthPacketType.transferInitAck &&
                sourcePort == 41222 &&
                targetPort == 41221) {
              alice.container
                  .read(peerPathRegistryMutationsProvider)
                  .markFailed(
                    peerId: 'team@instance-device-b',
                    reasonCode: 'testRouteExpired',
                  );
            }
            deliver(packet, address: address, port: sourcePort);
          },
    );
    alice = await _createNode(
      network: network,
      dataTransport: dataNetwork.attach(),
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41221,
      receivePath: '${workspaceDirectory.path}/alice-lease-expired',
    );
    final bob = await _createNode(
      network: network,
      dataTransport: dataNetwork.attach(),
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41222,
      receivePath: '${workspaceDirectory.path}/bob-lease-expired',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-lease-expired',
      bobPort: 41222,
      alicePort: 41221,
      clock: clock,
    );

    final sourceFile = File(
      '${workspaceDirectory.path}/alice-lease-expired/source.txt',
    );
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString('route lease expires before chunks');

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    expect(aliceJob.status, TransferJobStatus.failed);
    expect(aliceJob.message, contains('연결 경로가 만료'));
    expect(
      dataNetwork.sentFrames.where(
        (frame) => frame.type == DataFrameType.dataChunk,
      ),
      isEmpty,
    );
  });

  test(
    'receiver recovers failover route from authenticated transfer init',
    () async {
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41251,
        receivePath: '${workspaceDirectory.path}/alice-recover-route',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41252,
        receivePath: '${workspaceDirectory.path}/bob-recover-route',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-recover-route',
        bobPort: 41252,
        alicePort: 41251,
        clock: clock,
      );
      final bobPathToAlice = bob.container
          .read(peerPathRegistryProvider)
          .selectedForPeer('team@instance-device-a')!;
      bob.container
          .read(peerPathRegistryMutationsProvider)
          .expireLeaseForCandidate(
            candidate: bobPathToAlice.candidate,
            reasonCode: 'ttlExceeded',
          );
      expect(
        bob.container
            .read(peerPathRegistryProvider)
            .selectedForPeer('team@instance-device-a')!
            .status,
        PeerPathStatus.failoverRequested,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-recover-route/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('incoming transfer init revives route');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );
      expect(
        alice.container.read(transferControllerProvider).errorMessage,
        isNull,
      );
      expect(alice.container.read(transferJobsProvider), isNotEmpty);

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(
        bob.container
            .read(peerPathRegistryProvider)
            .selectedForPeer('team@instance-device-a')!
            .status,
        PeerPathStatus.active,
      );
      expect(
        await File(
          '${workspaceDirectory.path}/bob-recover-route/source.txt',
        ).readAsString(),
        'incoming transfer init revives route',
      );
    },
  );

  test(
    'receiver temp draft failure rejects transfer init before data starts',
    () async {
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41231,
        receivePath: '${workspaceDirectory.path}/alice-draft-fail',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        transferFileService: _DraftFailingTransferFileService(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41232,
        receivePath: '${workspaceDirectory.path}/bob-draft-fail',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-draft-fail',
        bobPort: 41232,
        alicePort: 41231,
        clock: clock,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-draft-fail/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('receiver cannot prepare temp file');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      expect(aliceJob.status, TransferJobStatus.rejected);
      expect(aliceJob.message, contains('수신 임시 파일'));
      expect(
        dataNetwork.sentFrames
            .where(
              (frame) =>
                  frame.type == DataFrameType.dataStart ||
                  frame.type == DataFrameType.dataChunk,
            )
            .toList(growable: false),
        isEmpty,
      );
      expect(bob.container.read(transferJobsProvider), isEmpty);
    },
  );

  test(
    'receiver finalize failure reports failure to sender and cleans draft',
    () async {
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final failingFileService = _FinalizeFailingTransferFileService();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41241,
        receivePath: '${workspaceDirectory.path}/alice-finalize-fail',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        transferFileService: failingFileService,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41242,
        receivePath: '${workspaceDirectory.path}/bob-finalize-fail',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-finalize-fail',
        bobPort: 41242,
        alicePort: 41241,
        clock: clock,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-finalize-fail/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('receiver cannot finalize file');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);
      expect(aliceJob.status, TransferJobStatus.failed);
      expect(aliceJob.message, contains('수신 파일을 완료하지 못했습니다'));
      expect(bobJob.status, TransferJobStatus.failed);
      expect(failingFileService.discardedDraftPaths, isNotEmpty);
      expect(failingFileService.lastTempFilePath, isNotNull);
      expect(
        await File(failingFileService.lastTempFilePath!).exists(),
        isFalse,
      );
    },
  );

  test(
    'receiver data chunk write failure notifies sender and classifies storage',
    () async {
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final failingFileService = _AppendFailingTransferFileService();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41243,
        receivePath: '${workspaceDirectory.path}/alice-append-fail',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        transferFileService: failingFileService,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41244,
        receivePath: '${workspaceDirectory.path}/bob-append-fail',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-append-fail',
        bobPort: 41244,
        alicePort: 41243,
        clock: clock,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-append-fail/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('receiver cannot append data chunk');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);
      expect(aliceJob.status, TransferJobStatus.failed);
      expect(bobJob.status, TransferJobStatus.failed);
      expect(aliceJob.message, contains('수신 data chunk'));
      expect(bobJob.message, contains('저장 경로'));
      expect(
        const TransferFailurePolicy().classify(bobJob).category,
        TransferFailureCategory.storage,
      );
      expect(failingFileService.discardedDraftPaths, isNotEmpty);
    },
  );

  test(
    'accepts transfer init when packet peer id differs from authenticated session alias',
    () async {
      final network = _LinkedFakeAuthNetwork(
        interceptor:
            ({
              required packet,
              required address,
              required sourcePort,
              required targetPort,
              required deliver,
            }) async {
              if (packet.type == AuthPacketType.transferInit &&
                  sourcePort == 41022 &&
                  targetPort == 41021) {
                deliver(
                  _copyPacket(packet, clearFromInstanceId: true),
                  address: address,
                  port: sourcePort,
                );
                return;
              }
              deliver(packet, address: address, port: sourcePort);
            },
      );
      final aliceReceivePath = '${workspaceDirectory.path}/alice-alias';
      final bobReceivePath = '${workspaceDirectory.path}/bob-alias';
      final alice = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41021,
        receivePath: aliceReceivePath,
      );
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41022,
        receivePath: bobReceivePath,
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await alice.container
          .read(settingsRepositoryProvider)
          .save(
            const AppSettings(
              defaultSavePath: '',
              autoReceiveEnabled: true,
              receivePolicy: ReceivePolicy.autoReceiveAll,
              logLevel: AppLogLevel.error,
            ).copyWith(defaultSavePath: aliceReceivePath),
          );

      await _handshakePair(
        alice: alice,
        bob: bob,
        clock: clock.value,
        alicePort: 41021,
        bobPort: 41022,
      );

      final sourceFile = File('$bobReceivePath/alias-source.txt');
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('session id should resolve peer alias');

      await bob.transferController.sendFile(
        peerId: 'team@instance-device-a',
        filePath: sourceFile.path,
      );
      expect(
        bob.container.read(transferControllerProvider).errorMessage,
        isNull,
      );
      expect(bob.container.read(transferJobsProvider), isNotEmpty);

      final bobJob = await _waitForTerminalTransfer(bob.container);
      final aliceJob = await _waitForTerminalTransfer(alice.container);

      expect(bobJob.status, TransferJobStatus.completed);
      expect(aliceJob.status, TransferJobStatus.completed);
      expect(aliceJob.peerId, 'team@instance-device-b');
      expect(
        await File('$aliceReceivePath/alias-source.txt').readAsString(),
        'session id should resolve peer alias',
      );
    },
  );

  test(
    'receiver uses default receive path when settings repository cannot load',
    () async {
      final network = _LinkedFakeAuthNetwork();
      final alice = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41001,
        receivePath: '${workspaceDirectory.path}/alice-settings-fallback',
      );
      final bobReceivePath = '${workspaceDirectory.path}/bob-settings-fallback';
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41002,
        receivePath: bobReceivePath,
        useSwitchableSettingsRepository: true,
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: bobReceivePath,
        bobPort: 41002,
        clock: clock,
      );
      bob.settingsRepository?.failLoadOrCreate = true;

      final sourceFile = File(
        '${workspaceDirectory.path}/settings-fallback.txt',
      );
      await sourceFile.writeAsString('settings repository is not required');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(
        await File('$bobReceivePath/settings-fallback.txt').readAsString(),
        'settings repository is not required',
      );
    },
  );

  test(
    'receiver uses saved receive path when default receive path cannot be prepared',
    () async {
      final network = _LinkedFakeAuthNetwork();
      final alice = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41011,
        receivePath: '${workspaceDirectory.path}/alice-saved-path',
      );
      final bobReceivePath = '${workspaceDirectory.path}/bob-saved-path';
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41012,
        receivePath: bobReceivePath,
        storagePathProvider: const _ThrowingStoragePathProvider(),
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: bobReceivePath,
        bobPort: 41012,
        clock: clock,
      );

      final sourceFile = File('${workspaceDirectory.path}/saved-path.txt');
      await sourceFile.writeAsString('saved path should win');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(
        await File('$bobReceivePath/saved-path.txt').readAsString(),
        'saved path should win',
      );
    },
  );

  test(
    'receiver ignores legacy macOS sandbox receive path and uses default path',
    () async {
      final network = _LinkedFakeAuthNetwork();
      final alice = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41013,
        receivePath: '${workspaceDirectory.path}/alice-legacy-path',
      );
      final bobReceivePath = '${workspaceDirectory.path}/bob-normal-path';
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41014,
        receivePath: bobReceivePath,
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);
      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: bobReceivePath,
        bobPort: 41014,
        clock: clock,
      );
      const legacySandboxPath =
          '/Users/alice/Library/Containers/com.sponzey.filesharing/Data/Downloads/Sponzey FileSharing';
      await bob.container
          .read(settingsRepositoryProvider)
          .save(
            AppSettings.initial().copyWith(defaultSavePath: legacySandboxPath),
          );

      final sourceFile = File('${workspaceDirectory.path}/legacy-path.txt');
      await sourceFile.writeAsString('legacy path should not be used');

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(
        await File('$bobReceivePath/legacy-path.txt').readAsString(),
        'legacy path should not be used',
      );
    },
  );

  test('does not send file chunks through the Control channel', () async {
    final transferChunkPacketSizes = <int>[];
    var transferWindowUpdateCount = 0;
    final network = _LinkedFakeAuthNetwork(
      interceptor:
          ({
            required packet,
            required address,
            required sourcePort,
            required targetPort,
            required deliver,
          }) async {
            if (packet.type == AuthPacketType.transferChunk) {
              transferChunkPacketSizes.add(packet.encode().length);
            }
            if (packet.type == AuthPacketType.transferWindowUpdate) {
              transferWindowUpdateCount += 1;
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
      authPort: 41003,
      receivePath: '${workspaceDirectory.path}/alice-mtu',
    );
    final bob = await _createNode(
      network: network,
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41004,
      receivePath: '${workspaceDirectory.path}/bob-mtu',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-mtu',
      bobPort: 41004,
      clock: clock,
    );

    final sourceFile = File('${workspaceDirectory.path}/alice-mtu/source.bin');
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsBytes(List<int>.filled(4096, 7));

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    expect(aliceJob.status, TransferJobStatus.completed);
    expect(bobJob.status, TransferJobStatus.completed);
    expect(transferChunkPacketSizes, isEmpty);
    expect(transferWindowUpdateCount, 0);
    expect(const DataFrameCodec().maxPayloadBytes(), lessThanOrEqualTo(1400));
  });

  test('batches Data channel ACK frames below chunk count', () async {
    final controlNetwork = _LinkedFakeAuthNetwork();
    final dataNetwork = _LinkedFakeDataNetwork();
    final alice = await _createNode(
      network: controlNetwork,
      dataTransport: dataNetwork.attach(),
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-a',
      authPort: 41031,
      receivePath: '${workspaceDirectory.path}/alice-batch-ack',
    );
    final bob = await _createNode(
      network: controlNetwork,
      dataTransport: dataNetwork.attach(),
      clock: clock,
      loginUserId: _sharedUserId,
      loginPassword: _sharedPassword,
      localDeviceId: 'device-b',
      authPort: 41032,
      receivePath: '${workspaceDirectory.path}/bob-batch-ack',
    );
    addTearDown(alice.dispose);
    addTearDown(bob.dispose);

    await _prepareAuthenticatedPair(
      alice: alice,
      bob: bob,
      bobReceivePath: '${workspaceDirectory.path}/bob-batch-ack',
      bobPort: 41032,
      clock: clock,
    );

    final sourceFile = File(
      '${workspaceDirectory.path}/alice-batch-ack/source.bin',
    );
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsBytes(
      List<int>.filled(const DataFrameCodec().maxPayloadBytes() * 20 + 31, 3),
    );

    await alice.transferController.sendFile(
      peerId: 'team@instance-device-b',
      filePath: sourceFile.path,
    );

    final aliceJob = await _waitForTerminalTransfer(alice.container);
    final bobJob = await _waitForTerminalTransfer(bob.container);

    final chunkFrameCount = dataNetwork.sentFrames
        .where((frame) => frame.type == DataFrameType.dataChunk)
        .length;
    final ackFrameCount = dataNetwork.sentFrames
        .where((frame) => frame.type == DataFrameType.dataAck)
        .length;

    expect(aliceJob.status, TransferJobStatus.completed);
    expect(bobJob.status, TransferJobStatus.completed);
    expect(chunkFrameCount, greaterThanOrEqualTo(20));
    expect(ackFrameCount, lessThan(chunkFrameCount));
  });

  test(
    'digest mismatch fails sender and receiver after corrupted Data frame',
    () async {
      var corrupted = false;
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork(
        interceptor:
            ({
              required frame,
              required address,
              required sourcePort,
              required targetPort,
              required deliver,
            }) async {
              if (!corrupted &&
                  frame.type == DataFrameType.dataChunk &&
                  frame.chunkIndex == 1) {
                corrupted = true;
                final corruptedPayload = Uint8List.fromList(frame.payload);
                corruptedPayload[0] ^= 0xff;
                deliver(
                  frame.copyWith(payload: corruptedPayload),
                  address: address,
                  port: sourcePort,
                );
                return;
              }
              deliver(frame, address: address, port: sourcePort);
            },
      );
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41061,
        receivePath: '${workspaceDirectory.path}/alice-digest-mismatch',
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41062,
        receivePath: '${workspaceDirectory.path}/bob-digest-mismatch',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-digest-mismatch',
        bobPort: 41062,
        alicePort: 41061,
        clock: clock,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-digest-mismatch/source.bin',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsBytes(
        List<int>.filled(const DataFrameCodec().maxPayloadBytes() * 3, 11),
      );

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(corrupted, isTrue);
      expect(aliceJob.status, TransferJobStatus.failed);
      expect(bobJob.status, TransferJobStatus.failed);
      expect(aliceJob.message, contains('파일 해시'));
      expect(bobJob.message, contains('파일 해시'));
    },
  );

  test(
    'does not emit packet-level product logs for Data channel chunks',
    () async {
      final logger = _MemoryAppLogger(minimumLevel: AppLogLevel.debug);
      final controlNetwork = _LinkedFakeAuthNetwork();
      final dataNetwork = _LinkedFakeDataNetwork();
      final alice = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-a',
        authPort: 41071,
        receivePath: '${workspaceDirectory.path}/alice-product-log',
        logger: logger,
      );
      final bob = await _createNode(
        network: controlNetwork,
        dataTransport: dataNetwork.attach(),
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41072,
        receivePath: '${workspaceDirectory.path}/bob-product-log',
        logger: logger,
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-product-log',
        bobPort: 41072,
        alicePort: 41071,
        clock: clock,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-product-log/source.bin',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsBytes(
        List<int>.filled(const DataFrameCodec().maxPayloadBytes() * 32, 5),
      );

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);
      final productDataLogs = logger.entries.where(
        (entry) =>
            entry.category == AppLogCategory.transferData &&
            entry.level != AppLogLevel.debug,
      );
      final messages = logger.entries.map((entry) => entry.message).join('\n');

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(
        dataNetwork.sentFrames.where(
          (frame) => frame.type == DataFrameType.dataChunk,
        ),
        hasLength(greaterThanOrEqualTo(32)),
      );
      expect(productDataLogs, isEmpty);
      expect(messages, isNot(contains(sourceFile.path)));
      expect(messages, isNot(contains('payload')));
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
        selectedPath: _testDiscoveredPath(
          peerId: 'team@instance-device-c',
          remotePort: 41113,
        ),
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

  test(
    'keeps Data channel transfer isolated from legacy Control chunk drops',
    () async {
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

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-loss/source.bin',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString(
        List<String>.filled(14000, 'abc123').join(),
      );

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(aliceJob.retryCount, 0);
      expect(aliceJob.lossRate, 0);
    },
  );

  test(
    'completes Data channel transfer when legacy duplicate interceptor sees no chunks',
    () async {
      AuthPacket? firstChunkZero;
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
                  packet.transferChunkIndex == 0 &&
                  firstChunkZero == null) {
                firstChunkZero = packet;
              }
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
                if (firstChunkZero != null && !duplicated) {
                  duplicated = true;
                  deliver(firstChunkZero!, address: address, port: sourcePort);
                }
                heldChunkFive = null;
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
      expect(duplicated, isFalse);
      expect(bobJob.duplicateCount, 0);
    },
  );

  test(
    'completes when legacy Control chunk ACK interceptor sees no chunks',
    () async {
      var earlyAckInjected = false;
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
                  sourcePort == 41033 &&
                  targetPort == 41034 &&
                  packet.transferChunkIndex == 1 &&
                  !earlyAckInjected) {
                earlyAckInjected = true;
                deliver(packet, address: address, port: sourcePort);
                await Future<void>.delayed(const Duration(milliseconds: 10));
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
        authPort: 41033,
        receivePath: '${workspaceDirectory.path}/alice-fast-ack',
      );
      final bob = await _createNode(
        network: network,
        clock: clock,
        loginUserId: _sharedUserId,
        loginPassword: _sharedPassword,
        localDeviceId: 'device-b',
        authPort: 41034,
        receivePath: '${workspaceDirectory.path}/bob-fast-ack',
      );
      addTearDown(alice.dispose);
      addTearDown(bob.dispose);

      await _prepareAuthenticatedPair(
        alice: alice,
        bob: bob,
        bobReceivePath: '${workspaceDirectory.path}/bob-fast-ack',
        bobPort: 41034,
        clock: clock,
      );

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-fast-ack/source.txt',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsString('fast-ack-' * 6000);

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(earlyAckInjected, isFalse);
      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
    },
  );

  test(
    'completes Data channel transfer when legacy Control packet loss is inactive',
    () async {
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

      final sourceFile = File(
        '${workspaceDirectory.path}/alice-20p/source.bin',
      );
      await sourceFile.parent.create(recursive: true);
      await sourceFile.writeAsBytes(List<int>.filled(1920, 9));

      await alice.transferController.sendFile(
        peerId: 'team@instance-device-b',
        filePath: sourceFile.path,
      );

      final aliceJob = await _waitForTerminalTransfer(alice.container);
      final bobJob = await _waitForTerminalTransfer(bob.container);

      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
      expect(aliceJob.retryCount, 0);
      expect(aliceJob.lossRate, 0);
    },
  );

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

  test(
    'ignores legacy Control chunk corruption because chunks use Data channel',
    () async {
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
            ).copyWith(
              defaultSavePath: '${workspaceDirectory.path}/bob-corrupt',
            ),
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

      expect(corrupted, isFalse);
      expect(aliceJob.status, TransferJobStatus.completed);
      expect(bobJob.status, TransferJobStatus.completed);
    },
  );
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

PeerConnectionPath _testDiscoveredPath({
  required String peerId,
  required int remotePort,
  String localAddress = '127.0.0.1',
  String remoteAddress = '127.0.0.1',
}) {
  final candidate = PeerRouteCandidate.create(
    peerId: peerId,
    remoteAddress: remoteAddress,
    remotePort: remotePort,
    localInterfaceId: NetworkInterfaceId(
      name: 'test-${localAddress.replaceAll('.', '-')}',
      index: -1,
      stableId: 'test-${localAddress.replaceAll('.', '-')}',
    ),
    localAddress: localAddress,
    discoveredBy: RouteCandidateDiscoverySource.localRegistry,
    seenAt: DateTime(2026, 4, 9, 12),
    status: RouteCandidateStatus.reachable,
    localInterfaceTypeHint: localAddress.startsWith('127.')
        ? InterfaceTypeHint.loopback
        : InterfaceTypeHint.ethernet,
    bindMode: UdpInterfaceBindMode.any,
  );
  return PeerConnectionPath.fromCandidate(
    candidate: candidate,
    selectedAt: DateTime(2026, 4, 9, 12),
    selectionReason: PeerPathSelectionReason.previousSuccess,
  );
}

PeerConnectionPath _testActivePath({
  required String peerId,
  required int remotePort,
  String localAddress = '127.0.0.1',
  String remoteAddress = '127.0.0.1',
}) {
  return _testDiscoveredPath(
    peerId: peerId,
    remotePort: remotePort,
    localAddress: localAddress,
    remoteAddress: remoteAddress,
  ).copyWith(status: PeerPathStatus.active);
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
  DataTransport? dataTransport,
  TransferFileService? transferFileService,
  AppStoragePathProvider? storagePathProvider,
  bool useSwitchableSettingsRepository = false,
}) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final settingsRepository = useSwitchableSettingsRepository
      ? _SwitchableSettingsRepository(database)
      : null;
  final transport = network.attach(authPort);
  final resolvedDataTransport = dataTransport ?? network.attachDataTransport();
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
      if (settingsRepository != null)
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
      appSecureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      appStoragePathProvider.overrideWithValue(
        storagePathProvider ?? _FakeStoragePathProvider(receivePath),
      ),
      appLoggerProvider.overrideWithValue(
        logger ?? const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      ),
      authTransportProvider.overrideWithValue(transport),
      controlTransportProvider.overrideWithValue(
        AuthControlTransportAdapter(authTransport: transport),
      ),
      dataTransportProvider.overrideWithValue(resolvedDataTransport),
      if (transferFileService != null)
        transferFileServiceProvider.overrideWithValue(transferFileService),
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
    settingsRepository: settingsRepository,
  );
}

Future<void> _prepareAuthenticatedPair({
  required _TransferHarness alice,
  required _TransferHarness bob,
  required String bobReceivePath,
  required int bobPort,
  required _MutableClock clock,
  int alicePort = 41001,
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
    alicePort: alicePort,
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
    selectedPath: _testDiscoveredPath(
      peerId: 'team@instance-device-b',
      remotePort: bobPort,
    ),
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

Future<List<TransferHistorySnapshot>> _waitForHistory(
  ProviderContainer container,
  int expectedCount,
) async {
  final repository = container.read(transferHistoryRepositoryProvider);
  for (var i = 0; i < 100; i += 1) {
    final history = await repository.loadRecentHistory();
    if (history.length >= expectedCount) {
      return history;
    }
    await _flush();
  }
  final history = await repository.loadRecentHistory();
  fail(
    'Expected $expectedCount persisted history rows, got ${history.length}.',
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

AuthPacket _copyPacket(
  AuthPacket packet, {
  String? transferChunkDataBase64,
  bool clearFromInstanceId = false,
}) {
  return AuthPacket(
    type: packet.type,
    protocolVersion: packet.protocolVersion,
    sessionId: packet.sessionId,
    fromUserId: packet.fromUserId,
    fromDeviceId: packet.fromDeviceId,
    fromInstanceId: clearFromInstanceId ? null : packet.fromInstanceId,
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
    transferDataAddress: packet.transferDataAddress,
    transferDataPort: packet.transferDataPort,
    transferAcceptedChunkSize: packet.transferAcceptedChunkSize,
    transferAcceptedWindowSize: packet.transferAcceptedWindowSize,
    transferReceiverBufferBudget: packet.transferReceiverBufferBudget,
    transferDataProtocol: packet.transferDataProtocol,
    transferCapabilities: packet.transferCapabilities,
    transferDataAuthContextId: packet.transferDataAuthContextId,
    sentAtEpochMs: packet.sentAtEpochMs,
  );
}

class _TransferHarness {
  const _TransferHarness({
    required this.container,
    required this.peerAuthController,
    required this.transferController,
    required this.database,
    this.settingsRepository,
  });

  final ProviderContainer container;
  final PeerAuthController peerAuthController;
  final TransferController transferController;
  final AppDatabase database;
  final _SwitchableSettingsRepository? settingsRepository;

  Future<void> dispose() async {
    container.dispose();
    await database.close();
  }
}

class _SwitchableSettingsRepository extends SettingsRepository {
  _SwitchableSettingsRepository(super.database);

  bool failLoadOrCreate = false;

  @override
  Future<AppSettings> loadOrCreate({required String defaultSavePath}) {
    if (failLoadOrCreate) {
      throw StateError('settings repository load failed for test');
    }
    return super.loadOrCreate(defaultSavePath: defaultSavePath);
  }
}

class _DraftFailingTransferFileService extends LocalTransferFileService {
  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) {
    throw const AppException(
      code: 'incoming_draft_prepare_failed',
      message: '수신 임시 파일을 준비하지 못했습니다. 테스트 저장소 권한 오류입니다.',
    );
  }
}

class _FinalizeFailingTransferFileService extends LocalTransferFileService {
  String? lastTempFilePath;
  final List<String> discardedDraftPaths = [];

  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) async {
    final draft = await super.createIncomingDraft(
      transferId: transferId,
      fileName: fileName,
    );
    lastTempFilePath = draft.tempFilePath;
    return draft;
  }

  @override
  Future<String> finalizeIncomingFile({
    required String tempFilePath,
    required String destinationDirectory,
    required String fileName,
  }) {
    throw const FileSystemException('test finalize failure');
  }

  @override
  Future<void> discardDraft(String tempFilePath) {
    discardedDraftPaths.add(tempFilePath);
    return super.discardDraft(tempFilePath);
  }
}

class _AppendFailingTransferFileService extends LocalTransferFileService {
  final List<String> discardedDraftPaths = [];

  @override
  Future<IncomingDigestingTransferWriter> openIncomingDigestingWriter(
    String tempFilePath,
  ) async {
    return _AppendFailingIncomingWriter();
  }

  @override
  Future<void> discardDraft(String tempFilePath) {
    discardedDraftPaths.add(tempFilePath);
    return super.discardDraft(tempFilePath);
  }
}

class _AppendFailingIncomingWriter implements IncomingDigestingTransferWriter {
  @override
  Future<void> append(List<int> bytes) {
    throw const FileSystemException('simulated data chunk write failure');
  }

  @override
  Future<void> close() async {}

  @override
  Future<String> closeWithDigest() async {
    return '';
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

typedef _DataFrameInterceptor =
    Future<void> Function({
      required DataFrame frame,
      required InternetAddress address,
      required int sourcePort,
      required int targetPort,
      required void Function(
        DataFrame frame, {
        required InternetAddress address,
        required int port,
      })
      deliver,
    });

class _LinkedFakeAuthNetwork {
  _LinkedFakeAuthNetwork({this.interceptor});

  final _PacketInterceptor? interceptor;
  final Map<int, _FakeAuthTransport> _transports = {};
  final _LinkedFakeDataNetwork _dataNetwork = _LinkedFakeDataNetwork();

  DataTransport attachDataTransport() {
    return _dataNetwork.attach();
  }

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

class _LinkedFakeDataNetwork {
  _LinkedFakeDataNetwork({this.interceptor});

  final _DataFrameInterceptor? interceptor;
  final Map<int, _FakeDataTransport> _transportsByPort = {};
  final List<DataFrame> sentFrames = [];

  _FakeDataTransport attach() {
    return _FakeDataTransport(this);
  }

  bool isPortAvailable(int port) => !_transportsByPort.containsKey(port);

  void register(int port, _FakeDataTransport transport) {
    _transportsByPort[port] = transport;
  }

  void unregister(int port, _FakeDataTransport transport) {
    if (_transportsByPort[port] == transport) {
      _transportsByPort.remove(port);
    }
  }

  Future<DataSendResult> sendFrame({
    required _FakeDataTransport source,
    required DataFrame frame,
    required InternetAddress address,
    required int port,
  }) async {
    sentFrames.add(frame);
    final target = _transportsByPort[port];
    if (target != null) {
      if (interceptor != null) {
        await interceptor!(
          frame: frame,
          address: address,
          sourcePort: source.endpoint?.port ?? 0,
          targetPort: port,
          deliver: (deliveredFrame, {required address, required port}) {
            target.emitFrame(deliveredFrame, address: address, port: port);
          },
        );
      } else {
        target.emitFrame(
          frame,
          address: address,
          port: source.endpoint?.port ?? 0,
        );
      }
    }
    final bytesRequested = const DataFrameCodec().encode(frame).length;
    return DataSendResult(
      success: true,
      bytesRequested: bytesRequested,
      bytesSent: bytesRequested,
    );
  }
}

class _FakeDataTransport implements DataTransport {
  _FakeDataTransport(this._network);

  final _LinkedFakeDataNetwork _network;
  final StreamController<DataDatagram> _packetController =
      StreamController<DataDatagram>.broadcast();
  final StreamController<DataFrameDatagram> _frameController =
      StreamController<DataFrameDatagram>.broadcast();
  UdpInterfaceEndpoint? endpoint;

  @override
  Stream<DataDatagram> get packets => _packetController.stream;

  @override
  Stream<DataFrameDatagram> get frames => _frameController.stream;

  @override
  Future<DataBindResult> bind({
    required UdpInterfaceEndpoint localEndpoint,
    required UdpPortRange portRange,
  }) async {
    if (endpoint != null) {
      return DataBindResult(endpoint: endpoint!);
    }

    for (final port in portRange.ports) {
      if (!_network.isPortAvailable(port)) {
        continue;
      }
      endpoint = UdpInterfaceEndpoint(
        role: UdpPortRole.data,
        interfaceId: localEndpoint.interfaceId,
        localAddress: localEndpoint.localAddress,
        port: port,
        bindMode: localEndpoint.bindMode,
        reuseAddress: localEndpoint.reuseAddress,
        reusePort: localEndpoint.reusePort,
      );
      _network.register(port, this);
      return DataBindResult(endpoint: endpoint!);
    }

    throw StateError('No fake data port available in $portRange.');
  }

  @override
  Future<void> send(
    DataPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {}

  @override
  Future<DataSendResult> sendFrame(
    DataFrame frame, {
    required InternetAddress address,
    required int port,
  }) {
    return _network.sendFrame(
      source: this,
      frame: frame,
      address: address,
      port: port,
    );
  }

  void emitFrame(
    DataFrame frame, {
    required InternetAddress address,
    required int port,
  }) {
    final localEndpoint = endpoint;
    if (localEndpoint == null) {
      return;
    }
    _frameController.add(
      DataFrameDatagram(
        frame: frame,
        address: address,
        port: port,
        localEndpoint: localEndpoint,
        datagramBytes: const DataFrameCodec().encode(frame).length,
      ),
    );
  }

  @override
  Future<void> close() async {
    final localEndpoint = endpoint;
    if (localEndpoint != null) {
      _network.unregister(localEndpoint.port, this);
      endpoint = null;
    }
    if (!_packetController.isClosed) {
      await _packetController.close();
    }
    if (!_frameController.isClosed) {
      await _frameController.close();
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

class _ThrowingStoragePathProvider implements AppStoragePathProvider {
  const _ThrowingStoragePathProvider();

  @override
  Future<String> getDefaultReceivePath() {
    throw StateError('default receive path is unavailable for test');
  }
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
