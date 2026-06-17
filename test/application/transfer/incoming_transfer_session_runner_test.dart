import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

void main() {
  group('IncomingTransferSessionRunner', () {
    test('receiveInit transitions and delegates prepareStorage', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(executor: executor);

      final result = await runner.receiveInit();

      expect(result.state, IncomingTransferSessionState.preparingStorage);
      expect(result.disposition, TransitionDisposition.transitioned);
      expect(runner.state, IncomingTransferSessionState.preparingStorage);
      expect(executor.calls, ['prepareStorage']);
    });

    test('markStoragePrepared delegates accepted init ack', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(executor: executor);

      await runner.receiveInit();
      executor.calls.clear();
      final result = await runner.markStoragePrepared();

      expect(result.state, IncomingTransferSessionState.readyForData);
      expect(executor.calls, ['sendTransferInitAck']);
    });

    test('receiveDataStart delegates writer opening', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(executor: executor);

      await runner.receiveInit();
      await runner.markStoragePrepared();
      executor.calls.clear();
      final result = await runner.receiveDataStart();

      expect(result.state, IncomingTransferSessionState.receiving);
      expect(executor.calls, ['openIncomingWriter']);
    });

    test('markStoragePrepareFailed delegates reject and failure', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(executor: executor);

      await runner.receiveInit();
      executor.calls.clear();
      final result = await runner.markStoragePrepareFailed();

      expect(result.state, IncomingTransferSessionState.failed);
      expect(runner.state, IncomingTransferSessionState.failed);
      expect(executor.calls, ['rejectTransferInit', 'failTransfer']);
    });

    test('terminal no-op does not execute effects', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(
        initialState: IncomingTransferSessionState.completed,
        executor: executor,
      );

      final result = await runner.dispatch(
        IncomingTransferSessionEvent.fileWriteFailed,
      );

      expect(result.disposition, TransitionDisposition.warning);
      expect(result.state, IncomingTransferSessionState.completed);
      expect(runner.state, IncomingTransferSessionState.completed);
      expect(executor.calls, isEmpty);
    });

    test('delegates every current incoming state machine effect', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(executor: executor);

      await runner.receiveInit();
      await runner.markStoragePrepared();
      await runner.receiveDataStart();
      await runner.receiveChunk();
      await runner.receiveOutOfOrderChunk();
      await runner.markBufferGapClosed();
      await runner.receiveDataFinish();
      await runner.markDigestVerified();
      await runner.markFinalizeCompleted();

      expect(executor.calls, [
        'prepareStorage',
        'sendTransferInitAck',
        'openIncomingWriter',
        'writeChunk',
        'scheduleAckBatch',
        'bufferOutOfOrderChunk',
        'scheduleNackBatch',
        'flushBufferedChunks',
        'scheduleAckBatch',
        'verifyIncomingDigest',
        'finalizeFile',
        'completeTransfer',
      ]);

      final failureExecutor = _RecordingIncomingExecutor();
      final failureRunner = IncomingTransferSessionRunner(
        initialState: IncomingTransferSessionState.verifying,
        executor: failureExecutor,
      );
      await failureRunner.markDigestMismatch();
      expect(failureExecutor.calls, ['failTransfer', 'cleanupPartialFile']);

      final cancelExecutor = _RecordingIncomingExecutor();
      final cancelRunner = IncomingTransferSessionRunner(
        executor: cancelExecutor,
      );
      await cancelRunner.cancel();
      await cancelRunner.markCleanupCompleted();
      expect(cancelExecutor.calls, [
        'cancelTransfer',
        'cleanupPartialFile',
        'completeCancellation',
      ]);
    });

    test('markFileWriteFailed delegates failTransfer', () async {
      final executor = _RecordingIncomingExecutor();
      final runner = IncomingTransferSessionRunner(
        initialState: IncomingTransferSessionState.receiving,
        executor: executor,
      );

      final result = await runner.markFileWriteFailed();

      expect(result.state, IncomingTransferSessionState.failed);
      expect(executor.calls, ['failTransfer']);
    });
  });
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
