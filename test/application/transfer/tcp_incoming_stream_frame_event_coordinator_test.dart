import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test('passes valid stream frame to incoming pipeline', () async {
    final executor = _RecordingIncomingExecutor();
    final coordinator = _coordinator(
      dataChannelRegistry: _dataRegistry(),
      runnerRegistry: _runnerRegistry(executor),
    );

    final result = await coordinator.handleFrame(_received());

    expect(result.applied, isTrue);
    expect(result.issueCode, isNull);
    expect(executor.calls, ['writeChunk', 'scheduleAckBatch']);
  });

  test('maps frame error without touching runner', () async {
    final executor = _RecordingIncomingExecutor();
    final coordinator = _coordinator(
      dataChannelRegistry: _dataRegistry(),
      runnerRegistry: _runnerRegistry(executor),
    );

    final result = coordinator.handleFrameError(
      const TcpDataReceivedStreamFrameError(
        channelId: TcpDataChannelId('channel-1'),
        issueCode: 'malformed_tcp_data_stream_frame',
        error: 'bad frame',
      ),
    );

    expect(result.applied, isFalse);
    expect(result.issueCode, 'malformed_tcp_data_stream_frame');
    expect(executor.calls, isEmpty);
  });

  test('returns pipeline issue when channel context is missing', () async {
    final coordinator = _coordinator(
      dataChannelRegistry: InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      ),
      runnerRegistry: TransferSessionRegistry<IncomingTransferSessionRunner>(
        direction: TransferDirection.incoming,
      ),
    );

    final result = await coordinator.handleFrame(_received());

    expect(result.applied, isFalse);
    expect(result.issueCode, 'missing_tcp_data_channel_context');
  });
}

TcpIncomingStreamFrameEventCoordinator _coordinator({
  required DataChannelSessionRegistry dataChannelRegistry,
  required TransferSessionRegistry<IncomingTransferSessionRunner>
  runnerRegistry,
}) {
  return TcpIncomingStreamFrameEventCoordinator(
    dataChannelRegistry: dataChannelRegistry,
    incomingRunnerRegistry: runnerRegistry,
    frameContextStore: InMemoryTcpIncomingTransferFrameContextStore(),
    pipeline: const TcpIncomingStreamFramePipelineCommand(
      dispatchCommand: TcpDataStreamFrameDispatchCommand(
        contextCommand: TcpDataStreamFrameChannelContextCommand(),
        dispatcher: TcpDataStreamFrameDispatcher(),
      ),
      stageCommand: TcpIncomingTransferFrameContextStageCommand(),
      runnerAdapter: TcpIncomingStreamFrameRunnerAdapter(),
    ),
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
  IncomingTransferSessionEffectExecutor executor,
) {
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
      initialState: IncomingTransferSessionState.receiving,
    ),
  );
  return registry;
}

TcpDataReceivedStreamFrame _received() {
  return TcpDataReceivedStreamFrame(
    channelId: const TcpDataChannelId('channel-1'),
    frame: TcpDataStreamFrame(
      type: TcpDataStreamFrameType.chunk,
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
