import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_metadata_frame_prepare_port.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_effect_executor.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test('dispatches valid chunk frame to registered incoming runner', () async {
    final executor = _RecordingIncomingExecutor();
    final dataRegistry = _dataRegistry();
    final runnerRegistry = _runnerRegistry(executor);
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final command = _pipeline();

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.chunk),
    );

    expect(result.applied, isTrue);
    expect(result.issueCode, isNull);
    expect(executor.calls, ['writeChunk', 'scheduleAckBatch']);
    expect(
      contextStore.lookup(
        const TcpIncomingTransferFrameContextKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          transferId: 'transfer-1',
        ),
      ),
      isNotNull,
    );
  });

  test('rejects valid channel frame when incoming runner is missing', () async {
    final dataRegistry = _dataRegistry();
    final runnerRegistry =
        TransferSessionRegistry<IncomingTransferSessionRunner>(
          direction: TransferDirection.incoming,
        );
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final command = _pipeline();

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.chunk),
    );

    expect(result.applied, isFalse);
    expect(result.issueCode, 'missing_tcp_incoming_transfer_runner');
    expect(contextStore.entries, isEmpty);
  });

  test('metadata frame creates incoming runner when missing', () async {
    final dataRegistry = _dataRegistry();
    final runnerRegistry =
        TransferSessionRegistry<IncomingTransferSessionRunner>(
          direction: TransferDirection.incoming,
        );
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final writer = _RecordingPayloadWriter();
    final command = _pipeline(
      payloadWriter: writer,
      metadataPreparePort: _RecordingMetadataPreparePort(
        result: const TcpIncomingMetadataFramePrepareResult(
          prepared: true,
          metadata: TcpIncomingMetadataProjection(
            fileName: 'tcp-source.txt',
            fileSize: 12,
            chunkCount: 2,
            destinationDirectory: '/tmp/receive',
          ),
        ),
      ),
    );

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.metadata),
    );

    expect(result.applied, isTrue);
    expect(result.state, IncomingTransferSessionState.receiving);
    expect(result.peerId, 'peer-1');
    expect(result.authSessionId, 'auth-1');
    expect(result.transferId, 'transfer-1');
    expect(result.route, TcpDataStreamFrameRoute.metadata);
    expect(result.metadata?.fileName, 'tcp-source.txt');
    expect(result.metadata?.fileSize, 12);
    expect(result.metadata?.chunkCount, 2);
    expect(result.metadata?.destinationDirectory, '/tmp/receive');
    expect(writer.calls, ['open:transfer-1']);
    expect(
      runnerRegistry.lookup(
        const TransferSessionKey(
          direction: TransferDirection.incoming,
          transferId: 'transfer-1',
          peerId: 'peer-1',
          authSessionId: 'auth-1',
        ),
      ),
      isNotNull,
    );
  });

  test('rejects frame when data channel context is missing', () async {
    final dataRegistry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final runnerRegistry =
        TransferSessionRegistry<IncomingTransferSessionRunner>(
          direction: TransferDirection.incoming,
        );
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final command = _pipeline();

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.chunk),
    );

    expect(result.applied, isFalse);
    expect(result.issueCode, 'missing_tcp_data_channel_context');
    expect(contextStore.entries, isEmpty);
  });

  test('prepares metadata before opening incoming writer', () async {
    final executor = _RecordingIncomingExecutor();
    final dataRegistry = _dataRegistry();
    final runnerRegistry = _runnerRegistry(
      executor,
      initialState: IncomingTransferSessionState.readyForData,
    );
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final preparePort = _RecordingMetadataPreparePort();
    final command = _pipeline(metadataPreparePort: preparePort);

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.metadata),
    );

    expect(result.applied, isTrue);
    expect(preparePort.calls, ['prepare:transfer-1:3']);
    expect(executor.calls, ['openIncomingWriter']);
  });

  test('does not open incoming writer when metadata prepare fails', () async {
    final executor = _RecordingIncomingExecutor();
    final dataRegistry = _dataRegistry();
    final runnerRegistry = _runnerRegistry(
      executor,
      initialState: IncomingTransferSessionState.readyForData,
    );
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final command = _pipeline(
      metadataPreparePort: _RecordingMetadataPreparePort(
        result: const TcpIncomingMetadataFramePrepareResult(
          prepared: false,
          issueCode: 'tcp_incoming_metadata_decode_failed',
        ),
      ),
    );

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.metadata),
    );

    expect(result.applied, isFalse);
    expect(result.issueCode, 'tcp_incoming_metadata_decode_failed');
    expect(executor.calls, isEmpty);
  });

  test('preserves transfer identity when runner effect fails', () async {
    final contextStore = InMemoryTcpIncomingTransferFrameContextStore();
    final dataRegistry = _dataRegistry();
    final runnerRegistry = _runnerRegistry(
      TcpIncomingTransferEffectExecutor(
        key: const TcpIncomingTransferFrameContextKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          transferId: 'transfer-1',
        ),
        frameContextStore: contextStore,
        writer: _RecordingPayloadWriter(failWrite: true),
      ),
    );
    final command = _pipeline();

    final result = await command.handle(
      dataChannelRegistry: dataRegistry,
      incomingRunnerRegistry: runnerRegistry,
      frameContextStore: contextStore,
      received: _received(TcpDataStreamFrameType.chunk),
    );

    expect(result.applied, isFalse);
    expect(result.peerId, 'peer-1');
    expect(result.authSessionId, 'auth-1');
    expect(result.transferId, 'transfer-1');
    expect(result.route, TcpDataStreamFrameRoute.chunk);
    expect(result.issueCode, 'tcp_incoming_payload_write_failed');
  });
}

TcpIncomingStreamFramePipelineCommand _pipeline({
  TcpIncomingMetadataFramePreparePort metadataPreparePort =
      const PassthroughTcpIncomingMetadataFramePreparePort(),
  TcpIncomingTransferPayloadWriterPort? payloadWriter,
}) {
  return TcpIncomingStreamFramePipelineCommand(
    dispatchCommand: const TcpDataStreamFrameDispatchCommand(
      contextCommand: TcpDataStreamFrameChannelContextCommand(),
      dispatcher: TcpDataStreamFrameDispatcher(),
    ),
    stageCommand: const TcpIncomingTransferFrameContextStageCommand(),
    runnerAdapter: const TcpIncomingStreamFrameRunnerAdapter(),
    metadataPreparePort: metadataPreparePort,
    payloadWriter: payloadWriter,
  );
}

InMemoryDataChannelSessionRegistry _dataRegistry() {
  final registry = InMemoryDataChannelSessionRegistry(
    mode: DataChannelMode.tcp,
  );
  registry.register(
    const DataChannelSessionKey(
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      direction: TcpDataChannelDirection.inbound,
    ),
    const TcpDataPeerSessionSnapshot(
      peerId: 'peer-1',
      sessionId: TcpDataSessionId('session-1'),
      channelId: TcpDataChannelId('channel-1'),
      direction: TcpDataChannelDirection.inbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: '10.0.0.1:50000',
      remoteEndpointLabel: '10.0.0.2:50001',
    ),
  );
  return registry;
}

TransferSessionRegistry<IncomingTransferSessionRunner> _runnerRegistry(
  IncomingTransferSessionEffectExecutor executor, {
  IncomingTransferSessionState initialState =
      IncomingTransferSessionState.receiving,
}) {
  final registry = TransferSessionRegistry<IncomingTransferSessionRunner>(
    direction: TransferDirection.incoming,
  );
  registry.register(
    const TransferSessionKey(
      direction: TransferDirection.incoming,
      transferId: 'transfer-1',
      peerId: 'peer-1',
      authSessionId: 'auth-1',
    ),
    IncomingTransferSessionRunner(
      executor: executor,
      initialState: initialState,
    ),
  );
  return registry;
}

TcpDataReceivedStreamFrame _received(TcpDataStreamFrameType type) {
  return TcpDataReceivedStreamFrame(
    channelId: const TcpDataChannelId('channel-1'),
    frame: TcpDataStreamFrame(
      type: type,
      transferId: 'transfer-1',
      sequence: 1,
      payload: Uint8List.fromList([1, 2, 3]),
    ),
  );
}

class _RecordingIncomingExecutor
    implements IncomingTransferSessionEffectExecutor {
  final List<String> calls = [];

  @override
  Future<void> bufferOutOfOrderChunk() async {
    calls.add('bufferOutOfOrderChunk');
  }

  @override
  Future<void> cancelTransfer() async {
    calls.add('cancelTransfer');
  }

  @override
  Future<void> cleanupPartialFile() async {
    calls.add('cleanupPartialFile');
  }

  @override
  Future<void> completeCancellation() async {
    calls.add('completeCancellation');
  }

  @override
  Future<void> completeTransfer() async {
    calls.add('completeTransfer');
  }

  @override
  Future<void> failTransfer() async {
    calls.add('failTransfer');
  }

  @override
  Future<void> finalizeFile() async {
    calls.add('finalizeFile');
  }

  @override
  Future<void> flushBufferedChunks() async {
    calls.add('flushBufferedChunks');
  }

  @override
  Future<void> openIncomingWriter() async {
    calls.add('openIncomingWriter');
  }

  @override
  Future<void> prepareStorage() async {
    calls.add('prepareStorage');
  }

  @override
  Future<void> rejectTransferInit() async {
    calls.add('rejectTransferInit');
  }

  @override
  Future<void> scheduleAckBatch() async {
    calls.add('scheduleAckBatch');
  }

  @override
  Future<void> scheduleNackBatch() async {
    calls.add('scheduleNackBatch');
  }

  @override
  Future<void> sendTransferInitAck() async {
    calls.add('sendTransferInitAck');
  }

  @override
  Future<void> verifyIncomingDigest() async {
    calls.add('verifyIncomingDigest');
  }

  @override
  Future<void> writeChunk() async {
    calls.add('writeChunk');
  }
}

class _RecordingMetadataPreparePort
    implements TcpIncomingMetadataFramePreparePort {
  _RecordingMetadataPreparePort({
    this.result = const TcpIncomingMetadataFramePrepareResult(prepared: true),
  });

  final TcpIncomingMetadataFramePrepareResult result;
  final List<String> calls = [];

  @override
  Future<TcpIncomingMetadataFramePrepareResult> prepare({
    required TcpIncomingTransferFrameContextKey key,
    required List<int> payload,
  }) async {
    calls.add('prepare:${key.transferId}:${payload.length}');
    return result;
  }
}

class _RecordingPayloadWriter implements TcpIncomingTransferPayloadWriterPort {
  _RecordingPayloadWriter({this.failWrite = false});

  final bool failWrite;
  final List<String> calls = [];

  @override
  Future<void> cancel(TcpIncomingTransferFrameContextKey key) async {
    calls.add('cancel:${key.transferId}');
  }

  @override
  Future<void> cleanup(TcpIncomingTransferFrameContextKey key) async {
    calls.add('cleanup:${key.transferId}');
  }

  @override
  Future<void> complete(TcpIncomingTransferFrameContextKey key) async {
    calls.add('complete:${key.transferId}');
  }

  @override
  Future<void> fail(TcpIncomingTransferFrameContextKey key) async {
    calls.add('fail:${key.transferId}');
  }

  @override
  Future<void> finalize(TcpIncomingTransferFrameContextKey key) async {
    calls.add('finalize:${key.transferId}');
  }

  @override
  Future<void> open(TcpIncomingTransferFrameContextKey key) async {
    calls.add('open:${key.transferId}');
  }

  @override
  Future<void> verify(TcpIncomingTransferFrameContextKey key) async {
    calls.add('verify:${key.transferId}');
  }

  @override
  Future<void> writeChunk(
    TcpIncomingTransferFrameContextKey key,
    List<int> payload,
  ) async {
    if (failWrite) {
      throw const AppException(
        code: 'tcp_incoming_payload_write_failed',
        message: 'write failed',
      );
    }
    calls.add('write:${key.transferId}:${payload.length}');
  }
}
