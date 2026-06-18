import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test(
    'metadata route opens incoming writer through runner state machine',
    () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(
        executor: executor,
        initialState: IncomingTransferSessionState.readyForData,
      );
      const adapter = TcpIncomingStreamFrameRunnerAdapter();

      final result = await adapter.apply(
        decision: _decision(TcpDataStreamFrameRoute.metadata),
        runner: runner,
      );

      expect(result.applied, isTrue);
      expect(result.state, IncomingTransferSessionState.receiving);
      expect(executor.calls, ['openIncomingWriter']);
    },
  );

  test('chunk route writes chunk through runner state machine', () async {
    final executor = _RecordingIncomingExecutor();
    final runner = IncomingTransferSessionRunner(
      executor: executor,
      initialState: IncomingTransferSessionState.receiving,
    );
    const adapter = TcpIncomingStreamFrameRunnerAdapter();

    final result = await adapter.apply(
      decision: _decision(TcpDataStreamFrameRoute.chunk),
      runner: runner,
    );

    expect(result.applied, isTrue);
    expect(result.state, IncomingTransferSessionState.receiving);
    expect(executor.calls, ['writeChunk', 'scheduleAckBatch']);
  });

  test(
    'complete route verifies, finalizes, and completes through runner state machine',
    () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(
        executor: executor,
        initialState: IncomingTransferSessionState.receiving,
      );
      const adapter = TcpIncomingStreamFrameRunnerAdapter();

      final result = await adapter.apply(
        decision: _decision(TcpDataStreamFrameRoute.complete),
        runner: runner,
      );

      expect(result.applied, isTrue);
      expect(result.state, IncomingTransferSessionState.completed);
      expect(executor.calls, [
        'verifyIncomingDigest',
        'finalizeFile',
        'completeTransfer',
      ]);
    },
  );

  test('cancel and error routes abort through runner state machine', () async {
    final cancelExecutor = _RecordingIncomingExecutor();
    final cancelRunner = IncomingTransferSessionRunner(
      executor: cancelExecutor,
      initialState: IncomingTransferSessionState.receiving,
    );
    const adapter = TcpIncomingStreamFrameRunnerAdapter();

    final cancelResult = await adapter.apply(
      decision: _decision(TcpDataStreamFrameRoute.cancel),
      runner: cancelRunner,
    );

    expect(cancelResult.state, IncomingTransferSessionState.canceling);
    expect(cancelExecutor.calls, ['cancelTransfer', 'cleanupPartialFile']);

    final errorExecutor = _RecordingIncomingExecutor();
    final errorRunner = IncomingTransferSessionRunner(
      executor: errorExecutor,
      initialState: IncomingTransferSessionState.receiving,
    );

    final errorResult = await adapter.apply(
      decision: _decision(TcpDataStreamFrameRoute.error),
      runner: errorRunner,
    );

    expect(errorResult.state, IncomingTransferSessionState.canceling);
    expect(errorExecutor.calls, ['cancelTransfer', 'cleanupPartialFile']);
  });

  test('denied decision is not delivered to runner', () async {
    final executor = _RecordingIncomingExecutor();
    final runner = IncomingTransferSessionRunner(
      executor: executor,
      initialState: IncomingTransferSessionState.receiving,
    );
    const adapter = TcpIncomingStreamFrameRunnerAdapter();

    final result = await adapter.apply(
      decision: const TcpDataStreamFrameDispatchDecision(
        allowed: false,
        issueCode: 'missing_tcp_data_channel_context',
      ),
      runner: runner,
    );

    expect(result.applied, isFalse);
    expect(result.issueCode, 'missing_tcp_data_channel_context');
    expect(result.state, IncomingTransferSessionState.receiving);
    expect(executor.calls, isEmpty);
  });
}

TcpDataStreamFrameDispatchDecision _decision(TcpDataStreamFrameRoute route) {
  return TcpDataStreamFrameDispatchDecision(
    allowed: true,
    route: route,
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    session: const TcpDataPeerSessionSnapshot(
      peerId: 'peer-1',
      sessionId: TcpDataSessionId('session-1'),
      channelId: TcpDataChannelId('channel-1'),
      direction: TcpDataChannelDirection.inbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: '10.0.0.1:50000',
      remoteEndpointLabel: '10.0.0.2:50001',
    ),
    transferId: 'transfer-1',
    frame: TcpDataStreamFrame(
      type: TcpDataStreamFrameType.chunk,
      transferId: 'transfer-1',
      sequence: 1,
      payload: Uint8List.fromList([1]),
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
