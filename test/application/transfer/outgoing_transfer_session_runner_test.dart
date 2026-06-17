import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/outgoing_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/outgoing_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

void main() {
  group('OutgoingTransferSessionRunner', () {
    test('start transitions and delegates sendTransferInit effect', () async {
      final executor = _RecordingOutgoingExecutor();
      final runner = OutgoingTransferSessionRunner(executor: executor);

      final result = await runner.start();

      expect(
        result.state,
        OutgoingTransferSessionState.waitingForReceiverPrepare,
      );
      expect(result.disposition, TransitionDisposition.transitioned);
      expect(
        runner.state,
        OutgoingTransferSessionState.waitingForReceiverPrepare,
      );
      expect(executor.calls, ['sendTransferInit']);
    });

    test('acceptReceiver transitions and delegates bindDataEndpoint', () async {
      final executor = _RecordingOutgoingExecutor();
      final runner = OutgoingTransferSessionRunner(executor: executor);

      await runner.start();
      executor.calls.clear();
      final result = await runner.acceptReceiver();

      expect(result.state, OutgoingTransferSessionState.bindingDataEndpoint);
      expect(executor.calls, ['bindDataEndpoint']);
    });

    test('rejectReceiver fails transfer and delegates failTransfer', () async {
      final executor = _RecordingOutgoingExecutor();
      final runner = OutgoingTransferSessionRunner(executor: executor);

      await runner.start();
      executor.calls.clear();
      final result = await runner.rejectReceiver();

      expect(result.state, OutgoingTransferSessionState.failed);
      expect(runner.state, OutgoingTransferSessionState.failed);
      expect(executor.calls, ['failTransfer']);
    });

    test('terminal no-op does not execute effects', () async {
      final executor = _RecordingOutgoingExecutor();
      final runner = OutgoingTransferSessionRunner(
        initialState: OutgoingTransferSessionState.completed,
        executor: executor,
      );

      final result = await runner.dispatch(
        OutgoingTransferSessionEvent.failureOccurred,
      );

      expect(result.disposition, TransitionDisposition.warning);
      expect(result.state, OutgoingTransferSessionState.completed);
      expect(runner.state, OutgoingTransferSessionState.completed);
      expect(executor.calls, isEmpty);
    });

    test('delegates every current outgoing state machine effect', () async {
      final executor = _RecordingOutgoingExecutor();
      final runner = OutgoingTransferSessionRunner(executor: executor);

      await runner.start();
      await runner.acceptReceiver();
      await runner.markDataEndpointBound();
      await runner.markStartFrameSent();
      await runner.markWindowSaturated();
      await runner.markAckOpenedWindow();
      await runner.markAllChunksAcked();
      await runner.markFinishFrameSent();
      await runner.markFinishAccepted();

      expect(executor.calls, [
        'sendTransferInit',
        'bindDataEndpoint',
        'sendDataStartFrame',
        'pumpChunkWindow',
        'sendDataFinishFrame',
        'completeTransfer',
      ]);

      final cancelExecutor = _RecordingOutgoingExecutor();
      final cancelRunner = OutgoingTransferSessionRunner(
        executor: cancelExecutor,
      );
      await cancelRunner.cancel();
      await cancelRunner.markCancellationCompleted();

      expect(cancelExecutor.calls, ['cancelTransfer', 'cleanupTransfer']);
    });

    test('markFailure delegates failTransfer', () async {
      final executor = _RecordingOutgoingExecutor();
      final runner = OutgoingTransferSessionRunner(executor: executor);

      final result = await runner.markFailure();

      expect(result.state, OutgoingTransferSessionState.failed);
      expect(executor.calls, ['failTransfer']);
    });
  });
}

class _RecordingOutgoingExecutor
    implements OutgoingTransferSessionEffectExecutor {
  final List<String> calls = [];

  @override
  Future<void> bindDataEndpoint() async {
    calls.add('bindDataEndpoint');
  }

  @override
  Future<void> cancelTransfer() async {
    calls.add('cancelTransfer');
  }

  @override
  Future<void> cleanupTransfer() async {
    calls.add('cleanupTransfer');
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
  Future<void> pumpChunkWindow() async {
    calls.add('pumpChunkWindow');
  }

  @override
  Future<void> sendDataFinishFrame() async {
    calls.add('sendDataFinishFrame');
  }

  @override
  Future<void> sendDataStartFrame() async {
    calls.add('sendDataStartFrame');
  }

  @override
  Future<void> sendTransferInit() async {
    calls.add('sendTransferInit');
  }
}
