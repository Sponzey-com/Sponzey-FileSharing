import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_hello_expectation_resolver.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_transfer_send_use_case.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_peer_file_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_transfer_pipeline_providers.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

void main() {
  const key = TcpIncomingTransferFrameContextKey(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    transferId: 'transfer-1',
  );

  test(
    'incoming metadata and payload writer providers share registry',
    () async {
      final fileService = _RecordingTransferFileService();
      final container = ProviderContainer(
        overrides: [
          transferFileServiceProvider.overrideWithValue(fileService),
          appLoggerProvider.overrideWithValue(_NoopLogger()),
        ],
      );
      addTearDown(container.dispose);

      final metadataPrepare = container.read(
        tcpIncomingMetadataFramePreparePortProvider('/downloads'),
      );
      final writer = container.read(
        tcpIncomingTransferPayloadWriterPortProvider,
      );

      final prepareResult = await metadataPrepare.prepare(
        key: key,
        payload: const TcpIncomingTransferMetadataCodec().encode(
          const TcpIncomingTransferMetadata(
            fileName: 'report.pdf',
            fileSize: 5,
            chunkCount: 1,
            sha256: 'digest',
          ),
        ),
      );
      await writer.writeChunk(key, [1, 2, 3, 4, 5]);

      final registry = container.read(
        tcpIncomingTransferPayloadWriterSessionRegistryProvider,
      );
      expect(prepareResult.prepared, isTrue);
      expect(registry.lookup(key)?.destinationDirectory, '/downloads');
      expect(fileService.writer.appended, [
        [1, 2, 3, 4, 5],
      ]);
    },
  );

  test('outgoing sender command provider accepts test doubles', () {
    final fileService = _RecordingTransferFileService();
    final connector = _NoopTcpConnector();
    final container = ProviderContainer(
      overrides: [
        transferFileServiceProvider.overrideWithValue(fileService),
        tcpDataConnectorProvider.overrideWithValue(connector),
        appLoggerProvider.overrideWithValue(_NoopLogger()),
        tcpDataHelloExpectationResolverProvider.overrideWithValue(
          const _NoopHelloExpectationResolver(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final command = container.read(
      tcpOutgoingTransferStreamSendCommandProvider,
    );

    expect(command, isA<TcpOutgoingTransferStreamSendCommand>());
  });

  test('incoming coordinator provider shares registries and store', () {
    final fileService = _RecordingTransferFileService();
    final container = ProviderContainer(
      overrides: [
        transferFileServiceProvider.overrideWithValue(fileService),
        appLoggerProvider.overrideWithValue(_NoopLogger()),
      ],
    );
    addTearDown(container.dispose);

    final coordinator = container.read(
      tcpIncomingStreamFrameEventCoordinatorProvider('/downloads'),
    );

    expect(coordinator, isA<TcpIncomingStreamFrameEventCoordinator>());
    expect(
      identical(
        coordinator.dataChannelRegistry,
        container.read(tcpDataChannelSessionRegistryProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        coordinator.incomingRunnerRegistry,
        container.read(tcpIncomingTransferRunnerRegistryProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        coordinator.frameContextStore,
        container.read(tcpIncomingTransferFrameContextStoreProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        coordinator.pipeline,
        container.read(
          tcpIncomingStreamFramePipelineCommandProvider('/downloads'),
        ),
      ),
      isTrue,
    );
  });

  test('peer file send provider uses connected registry channel', () async {
    final fileService = _RecordingTransferFileService();
    final connector = _RecordingTcpConnector();
    final container = ProviderContainer(
      overrides: [
        transferFileServiceProvider.overrideWithValue(fileService),
        tcpDataConnectorProvider.overrideWithValue(connector),
        appLoggerProvider.overrideWithValue(_NoopLogger()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(tcpDataChannelSessionRegistryProvider)
        .register(
          const DataChannelSessionKey(
            peerId: 'peer-1',
            authSessionId: 'auth-1',
            direction: TcpDataChannelDirection.outbound,
          ),
          const TcpDataPeerSessionSnapshot(
            peerId: 'peer-1',
            sessionId: TcpDataSessionId('session-1'),
            channelId: TcpDataChannelId('channel-1'),
            direction: TcpDataChannelDirection.outbound,
            status: TcpDataPeerSessionStatus.connected,
            localEndpointLabel: '10.0.0.1:50000',
            remoteEndpointLabel: '10.0.0.2:50001',
          ),
        );

    final command = container.read(tcpPeerFileSendCommandProvider);
    final result = await command.send(
      registry: container.read(tcpDataChannelSessionRegistryProvider),
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      transferId: 'transfer-1',
      filePath: '/files/report.pdf',
      chunkSize: 5,
    );

    expect(command, isA<TcpPeerFileSendCommand>());
    expect(result.sent, isTrue);
    expect(connector.sentFrames.map((frame) => frame.type), [
      TcpDataStreamFrameType.metadata,
      TcpDataStreamFrameType.chunk,
      TcpDataStreamFrameType.complete,
    ]);
  });

  test('listener subscription provider shares listener and coordinator', () {
    final container = ProviderContainer(
      overrides: [
        transferFileServiceProvider.overrideWithValue(
          _RecordingTransferFileService(),
        ),
        appLoggerProvider.overrideWithValue(_NoopLogger()),
        tcpDataHelloExpectationResolverProvider.overrideWithValue(
          const _NoopHelloExpectationResolver(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.read(
      tcpIncomingListenerStreamSubscriptionCoordinatorProvider('/downloads'),
    );

    expect(
      subscription,
      isA<TcpIncomingListenerStreamSubscriptionCoordinator>(),
    );
    expect(
      identical(subscription.listener, container.read(tcpDataListenerProvider)),
      isTrue,
    );
    expect(
      identical(
        subscription.inboundCoordinator,
        container.read(tcpDataInboundListenerEventCoordinatorProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        subscription.helloExpectationResolver,
        container.read(tcpDataHelloExpectationResolverProvider),
      ),
      isTrue,
    );
    expect(
      identical(
        subscription.coordinator,
        container.read(
          tcpIncomingStreamFrameEventCoordinatorProvider('/downloads'),
        ),
      ),
      isTrue,
    );
  });

  test(
    'listener subscription interface provider returns shared coordinator',
    () {
      final container = ProviderContainer(
        overrides: [
          transferFileServiceProvider.overrideWithValue(
            _RecordingTransferFileService(),
          ),
          appLoggerProvider.overrideWithValue(_NoopLogger()),
          tcpDataHelloExpectationResolverProvider.overrideWithValue(
            const _NoopHelloExpectationResolver(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final concrete = container.read(
        tcpIncomingListenerStreamSubscriptionCoordinatorProvider('/downloads'),
      );
      final port = container.read(
        tcpIncomingListenerSubscriptionProvider('/downloads'),
      );

      expect(identical(port, concrete), isTrue);
    },
  );

  test('tcp transfer send use case provider uses shared registry', () async {
    final fileService = _RecordingTransferFileService();
    final connector = _RecordingTcpConnector();
    final container = ProviderContainer(
      overrides: [
        transferFileServiceProvider.overrideWithValue(fileService),
        tcpDataConnectorProvider.overrideWithValue(connector),
        appLoggerProvider.overrideWithValue(_NoopLogger()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(tcpDataChannelSessionRegistryProvider)
        .register(
          const DataChannelSessionKey(
            peerId: 'peer-1',
            authSessionId: 'auth-1',
            direction: TcpDataChannelDirection.outbound,
          ),
          const TcpDataPeerSessionSnapshot(
            peerId: 'peer-1',
            sessionId: TcpDataSessionId('session-1'),
            channelId: TcpDataChannelId('channel-1'),
            direction: TcpDataChannelDirection.outbound,
            status: TcpDataPeerSessionStatus.connected,
            localEndpointLabel: '10.0.0.1:50000',
            remoteEndpointLabel: '10.0.0.2:50001',
          ),
        );

    final useCase = container.read(tcpTransferSendUseCaseProvider);
    final result = await useCase.send(
      const TcpTransferSendUseCaseInput(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        transferId: 'transfer-1',
        filePath: '/files/report.pdf',
        chunkSize: 5,
      ),
    );

    expect(useCase, isA<TcpTransferSendUseCase>());
    expect(result.sent, isTrue);
    expect(result.fileName, 'report.pdf');
    expect(connector.sentFrames, hasLength(3));
  });

  test(
    'outbound channel open command provider uses shared connector and registry',
    () async {
      final connector = _OpeningTcpConnector();
      final container = ProviderContainer(
        overrides: [
          tcpDataConnectorProvider.overrideWithValue(connector),
          appLoggerProvider.overrideWithValue(_NoopLogger()),
        ],
      );
      addTearDown(container.dispose);

      final command = container.read(tcpDataOutboundChannelOpenCommandProvider);
      final result = await command.open(
        connectRequest: const TcpDataConnectRequest(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          sessionId: TcpDataSessionId('session-1'),
          host: '10.0.0.2',
          port: 50100,
        ),
        hello: const TcpDataSessionHello(
          sessionId: TcpDataSessionId('session-1'),
          peerId: 'peer-1',
          instanceId: 'instance-1',
          authSessionId: 'auth-1',
          protocolVersion: 1,
          dataProtocolVersion: 1,
          proof: 'auth-1',
        ),
      );

      expect(result.opened, isTrue);
      expect(connector.calls, ['connect:10.0.0.2:50100', 'hello:channel-open']);
      expect(
        container
            .read(tcpDataChannelSessionRegistryProvider)
            .lookup(
              const DataChannelSessionKey(
                peerId: 'peer-1',
                authSessionId: 'auth-1',
                direction: TcpDataChannelDirection.outbound,
              ),
            )
            ?.channelId,
        const TcpDataChannelId('channel-open'),
      );
    },
  );
}

class _RecordingTransferFileService implements TransferFileService {
  final writer = _RecordingDigestingWriter();

  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) async {
    return IncomingTransferDraft(
      transferId: transferId,
      fileName: fileName,
      tempDirectoryPath: '/tmp/$transferId',
      tempFilePath: '/tmp/$transferId/$fileName.part',
    );
  }

  @override
  Future<IncomingDigestingTransferWriter> openIncomingDigestingWriter(
    String tempFilePath,
  ) async {
    return writer;
  }

  @override
  Future<PreparedTransferFile> prepareOutgoingFile(
    String filePath, {
    required int chunkSize,
  }) async {
    return const PreparedTransferFile(
      filePath: '/files/report.pdf',
      fileName: 'report.pdf',
      fileSize: 5,
      sha256: 'digest',
      chunkSize: 5,
      chunkCount: 1,
    );
  }

  @override
  Future<OutgoingTransferReader> openOutgoingReader(String filePath) async {
    return _NoopOutgoingReader();
  }

  @override
  Future<void> appendChunk({
    required String tempFilePath,
    required List<int> bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> computeSha256(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<void> discardDraft(String tempFilePath) async {}

  @override
  Future<String> finalizeIncomingFile({
    required String tempFilePath,
    required String destinationDirectory,
    required String fileName,
  }) async {
    return '$destinationDirectory/$fileName';
  }

  @override
  Future<IncomingTransferWriter> openIncomingWriter(String tempFilePath) {
    throw UnimplementedError();
  }

  @override
  Future<PreparedTransferMetadata> prepareOutgoingMetadata(
    String filePath, {
    required int chunkSize,
  }) async {
    return const PreparedTransferMetadata(
      filePath: '/files/report.pdf',
      fileName: 'report.pdf',
      fileSize: 5,
      chunkSize: 5,
      chunkCount: 1,
    );
  }

  @override
  Future<List<int>> readChunkAt(
    String filePath, {
    required int chunkSize,
    required int chunkIndex,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<TransferChunk> readChunks(String filePath, {required int chunkSize}) {
    throw UnimplementedError();
  }
}

class _RecordingDigestingWriter implements IncomingDigestingTransferWriter {
  final List<List<int>> appended = [];

  @override
  Future<void> append(List<int> bytes) async {
    appended.add(List<int>.from(bytes));
  }

  @override
  Future<void> close() async {}

  @override
  Future<String> closeWithDigest() async {
    return 'digest';
  }
}

class _NoopOutgoingReader implements OutgoingTransferReader {
  @override
  Future<void> close() async {}

  @override
  Future<List<int>> readAt({
    required int chunkSize,
    required int chunkIndex,
  }) async {
    return [1, 2, 3, 4, 5];
  }
}

class _NoopTcpConnector implements TcpDataConnectorPort {
  @override
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> sendHello(
    TcpDataChannelId channelId,
    TcpDataSessionHello hello,
  ) async {}

  @override
  Future<void> sendFrame(
    TcpDataChannelId channelId,
    TcpDataStreamFrame frame,
  ) async {}
}

class _RecordingTcpConnector implements TcpDataConnectorPort {
  final List<TcpDataStreamFrame> sentFrames = [];

  @override
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> sendHello(
    TcpDataChannelId channelId,
    TcpDataSessionHello hello,
  ) async {}

  @override
  Future<void> sendFrame(
    TcpDataChannelId channelId,
    TcpDataStreamFrame frame,
  ) async {
    sentFrames.add(frame);
  }
}

class _OpeningTcpConnector implements TcpDataConnectorPort {
  final List<String> calls = [];

  @override
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request) async {
    calls.add('connect:${request.host}:${request.port}');
    return const TcpDataChannelId('channel-open');
  }

  @override
  Future<void> sendHello(
    TcpDataChannelId channelId,
    TcpDataSessionHello hello,
  ) async {
    calls.add('hello:${channelId.value}');
  }

  @override
  Future<void> sendFrame(
    TcpDataChannelId channelId,
    TcpDataStreamFrame frame,
  ) async {}

  @override
  Future<void> close() async {}
}

class _NoopHelloExpectationResolver
    implements TcpDataHelloExpectationResolverPort {
  const _NoopHelloExpectationResolver();

  @override
  TcpDataHelloExpectationResolution resolve(TcpDataReceivedHello received) {
    return const TcpDataHelloExpectationResolution.rejected(
      issueCode: 'not_used',
    );
  }
}

class _NoopLogger implements AppLogger {
  @override
  AppLogLevel get minimumLevel => AppLogLevel.error;

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
