import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

void main() {
  group('IncomingTransferSessionStateMachine', () {
    const machine = IncomingTransferSessionStateMachine();

    test('transitions through the happy path', () {
      var result = machine.transition(
        IncomingTransferSessionState.offered,
        IncomingTransferSessionEvent.transferInitReceived,
      );
      expect(result.state, IncomingTransferSessionState.preparingStorage);
      expect(result.disposition, TransitionDisposition.transitioned);
      expect(result.effects.map((effect) => effect.name), ['prepareStorage']);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.storagePrepared,
      );
      expect(result.state, IncomingTransferSessionState.readyForData);
      expect(result.effects.map((effect) => effect.name), [
        'sendTransferInitAck',
      ]);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.dataStartReceived,
      );
      expect(result.state, IncomingTransferSessionState.receiving);
      expect(result.effects.map((effect) => effect.name), [
        'openIncomingWriter',
      ]);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.dataChunkReceived,
      );
      expect(result.state, IncomingTransferSessionState.receiving);
      expect(result.effects.map((effect) => effect.name), [
        'writeChunk',
        'scheduleAckBatch',
      ]);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.dataFinishReceived,
      );
      expect(result.state, IncomingTransferSessionState.verifying);
      expect(result.effects.map((effect) => effect.name), [
        'verifyIncomingDigest',
      ]);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.digestVerified,
      );
      expect(result.state, IncomingTransferSessionState.finalizing);
      expect(result.effects.map((effect) => effect.name), ['finalizeFile']);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.finalizeCompleted,
      );
      expect(result.state, IncomingTransferSessionState.completed);
      expect(result.effects.map((effect) => effect.name), ['completeTransfer']);
    });

    test('marks failed when storage, write, or digest validation fails', () {
      final storageFailed = machine.transition(
        IncomingTransferSessionState.preparingStorage,
        IncomingTransferSessionEvent.storagePrepareFailed,
      );
      expect(storageFailed.state, IncomingTransferSessionState.failed);
      expect(storageFailed.effects.map((effect) => effect.name), [
        'rejectTransferInit',
        'failTransfer',
      ]);

      final writeFailed = machine.transition(
        IncomingTransferSessionState.receiving,
        IncomingTransferSessionEvent.fileWriteFailed,
      );
      expect(writeFailed.state, IncomingTransferSessionState.failed);
      expect(writeFailed.effects.map((effect) => effect.name), [
        'failTransfer',
      ]);

      final digestMismatch = machine.transition(
        IncomingTransferSessionState.verifying,
        IncomingTransferSessionEvent.digestMismatch,
      );
      expect(digestMismatch.state, IncomingTransferSessionState.failed);
      expect(digestMismatch.effects.map((effect) => effect.name), [
        'failTransfer',
        'cleanupPartialFile',
      ]);
    });

    test('buffers out-of-order chunks and resumes receiving', () {
      var result = machine.transition(
        IncomingTransferSessionState.receiving,
        IncomingTransferSessionEvent.outOfOrderChunkReceived,
      );
      expect(result.state, IncomingTransferSessionState.bufferingOutOfOrder);
      expect(result.effects.map((effect) => effect.name), [
        'bufferOutOfOrderChunk',
        'scheduleNackBatch',
      ]);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.bufferGapClosed,
      );
      expect(result.state, IncomingTransferSessionState.receiving);
      expect(result.effects.map((effect) => effect.name), [
        'flushBufferedChunks',
        'scheduleAckBatch',
      ]);
    });

    test('cancels non-terminal states and completes cancellation', () {
      var result = machine.transition(
        IncomingTransferSessionState.receiving,
        IncomingTransferSessionEvent.cancelRequested,
      );
      expect(result.state, IncomingTransferSessionState.canceling);
      expect(result.effects.map((effect) => effect.name), [
        'cancelTransfer',
        'cleanupPartialFile',
      ]);

      result = machine.transition(
        result.state,
        IncomingTransferSessionEvent.cleanupCompleted,
      );
      expect(result.state, IncomingTransferSessionState.canceled);
      expect(result.effects.map((effect) => effect.name), [
        'completeCancellation',
      ]);
    });

    test('data abort moves non-terminal state to canceling', () {
      final result = machine.transition(
        IncomingTransferSessionState.bufferingOutOfOrder,
        IncomingTransferSessionEvent.dataAbortReceived,
      );

      expect(result.state, IncomingTransferSessionState.canceling);
      expect(result.effects.map((effect) => effect.name), [
        'cancelTransfer',
        'cleanupPartialFile',
      ]);
    });

    test('terminal states reject later events with warning no-op', () {
      final result = machine.transition(
        IncomingTransferSessionState.completed,
        IncomingTransferSessionEvent.fileWriteFailed,
      );

      expect(result.state, IncomingTransferSessionState.completed);
      expect(result.disposition, TransitionDisposition.warning);
      expect(result.issue?.code, 'incoming_transfer_already_terminal');
    });

    test('invalid non-terminal transition returns failure', () {
      final result = machine.transition(
        IncomingTransferSessionState.readyForData,
        IncomingTransferSessionEvent.dataChunkReceived,
      );

      expect(result.state, IncomingTransferSessionState.readyForData);
      expect(result.disposition, TransitionDisposition.failure);
      expect(result.issue?.code, 'incoming_transfer_invalid_transition');
    });
  });
}
