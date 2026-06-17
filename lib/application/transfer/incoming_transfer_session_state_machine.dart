import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum IncomingTransferSessionState {
  offered,
  preparingStorage,
  readyForData,
  receiving,
  bufferingOutOfOrder,
  verifying,
  finalizing,
  completed,
  canceling,
  canceled,
  failed,
}

enum IncomingTransferSessionEvent {
  transferInitReceived,
  storagePrepared,
  storagePrepareFailed,
  dataStartReceived,
  dataChunkReceived,
  outOfOrderChunkReceived,
  bufferGapClosed,
  dataFinishReceived,
  dataAbortReceived,
  fileWriteFailed,
  digestVerified,
  digestMismatch,
  finalizeCompleted,
  timeoutElapsed,
  cancelRequested,
  cleanupCompleted,
}

class IncomingTransferSessionStateMachine
    implements
        StateMachine<
          IncomingTransferSessionState,
          IncomingTransferSessionEvent
        > {
  const IncomingTransferSessionStateMachine();

  static const _prepareStorage = TransitionEffect('prepareStorage');
  static const _sendTransferInitAck = TransitionEffect('sendTransferInitAck');
  static const _rejectTransferInit = TransitionEffect('rejectTransferInit');
  static const _openIncomingWriter = TransitionEffect('openIncomingWriter');
  static const _writeChunk = TransitionEffect('writeChunk');
  static const _scheduleAckBatch = TransitionEffect('scheduleAckBatch');
  static const _bufferOutOfOrderChunk = TransitionEffect(
    'bufferOutOfOrderChunk',
  );
  static const _scheduleNackBatch = TransitionEffect('scheduleNackBatch');
  static const _flushBufferedChunks = TransitionEffect('flushBufferedChunks');
  static const _verifyIncomingDigest = TransitionEffect('verifyIncomingDigest');
  static const _finalizeFile = TransitionEffect('finalizeFile');
  static const _completeTransfer = TransitionEffect('completeTransfer');
  static const _failTransfer = TransitionEffect('failTransfer');
  static const _cleanupPartialFile = TransitionEffect('cleanupPartialFile');
  static const _cancelTransfer = TransitionEffect('cancelTransfer');
  static const _completeCancellation = TransitionEffect('completeCancellation');

  @override
  TransitionResult<IncomingTransferSessionState> transition(
    IncomingTransferSessionState state,
    IncomingTransferSessionEvent event,
  ) {
    if (_isTerminal(state)) {
      return TransitionResult.warning(
        state,
        issue: const TransitionIssue(
          code: 'incoming_transfer_already_terminal',
          message: 'Incoming transfer session is already terminal.',
        ),
      );
    }

    if (event == IncomingTransferSessionEvent.cancelRequested ||
        event == IncomingTransferSessionEvent.dataAbortReceived) {
      return TransitionResult.transitioned(
        IncomingTransferSessionState.canceling,
        effects: const [_cancelTransfer, _cleanupPartialFile],
      );
    }

    if (event == IncomingTransferSessionEvent.fileWriteFailed ||
        event == IncomingTransferSessionEvent.timeoutElapsed) {
      return TransitionResult.transitioned(
        IncomingTransferSessionState.failed,
        effects: const [_failTransfer],
      );
    }

    return switch (state) {
      IncomingTransferSessionState.offered => _fromOffered(event),
      IncomingTransferSessionState.preparingStorage => _fromPreparingStorage(
        event,
      ),
      IncomingTransferSessionState.readyForData => _fromReadyForData(event),
      IncomingTransferSessionState.receiving => _fromReceiving(event),
      IncomingTransferSessionState.bufferingOutOfOrder =>
        _fromBufferingOutOfOrder(event),
      IncomingTransferSessionState.verifying => _fromVerifying(event),
      IncomingTransferSessionState.finalizing => _fromFinalizing(event),
      IncomingTransferSessionState.canceling => _fromCanceling(event),
      IncomingTransferSessionState.completed ||
      IncomingTransferSessionState.canceled ||
      IncomingTransferSessionState.failed => _invalid(state, event),
    };
  }

  static TransitionResult<IncomingTransferSessionState> _fromOffered(
    IncomingTransferSessionEvent event,
  ) {
    if (event == IncomingTransferSessionEvent.transferInitReceived) {
      return TransitionResult.transitioned(
        IncomingTransferSessionState.preparingStorage,
        effects: const [_prepareStorage],
      );
    }
    return _invalid(IncomingTransferSessionState.offered, event);
  }

  static TransitionResult<IncomingTransferSessionState> _fromPreparingStorage(
    IncomingTransferSessionEvent event,
  ) {
    return switch (event) {
      IncomingTransferSessionEvent.storagePrepared =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.readyForData,
          effects: const [_sendTransferInitAck],
        ),
      IncomingTransferSessionEvent.storagePrepareFailed =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.failed,
          effects: const [_rejectTransferInit, _failTransfer],
        ),
      _ => _invalid(IncomingTransferSessionState.preparingStorage, event),
    };
  }

  static TransitionResult<IncomingTransferSessionState> _fromReadyForData(
    IncomingTransferSessionEvent event,
  ) {
    if (event == IncomingTransferSessionEvent.dataStartReceived) {
      return TransitionResult.transitioned(
        IncomingTransferSessionState.receiving,
        effects: const [_openIncomingWriter],
      );
    }
    return _invalid(IncomingTransferSessionState.readyForData, event);
  }

  static TransitionResult<IncomingTransferSessionState> _fromReceiving(
    IncomingTransferSessionEvent event,
  ) {
    return switch (event) {
      IncomingTransferSessionEvent.dataChunkReceived =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.receiving,
          effects: const [_writeChunk, _scheduleAckBatch],
        ),
      IncomingTransferSessionEvent.outOfOrderChunkReceived =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.bufferingOutOfOrder,
          effects: const [_bufferOutOfOrderChunk, _scheduleNackBatch],
        ),
      IncomingTransferSessionEvent.dataFinishReceived =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.verifying,
          effects: const [_verifyIncomingDigest],
        ),
      _ => _invalid(IncomingTransferSessionState.receiving, event),
    };
  }

  static TransitionResult<IncomingTransferSessionState>
  _fromBufferingOutOfOrder(IncomingTransferSessionEvent event) {
    return switch (event) {
      IncomingTransferSessionEvent.bufferGapClosed =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.receiving,
          effects: const [_flushBufferedChunks, _scheduleAckBatch],
        ),
      IncomingTransferSessionEvent.dataChunkReceived =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.bufferingOutOfOrder,
          effects: const [_writeChunk, _scheduleAckBatch],
        ),
      IncomingTransferSessionEvent.outOfOrderChunkReceived =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.bufferingOutOfOrder,
          effects: const [_bufferOutOfOrderChunk, _scheduleNackBatch],
        ),
      IncomingTransferSessionEvent.dataFinishReceived =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.verifying,
          effects: const [_verifyIncomingDigest],
        ),
      _ => _invalid(IncomingTransferSessionState.bufferingOutOfOrder, event),
    };
  }

  static TransitionResult<IncomingTransferSessionState> _fromVerifying(
    IncomingTransferSessionEvent event,
  ) {
    return switch (event) {
      IncomingTransferSessionEvent.digestVerified =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.finalizing,
          effects: const [_finalizeFile],
        ),
      IncomingTransferSessionEvent.digestMismatch =>
        TransitionResult.transitioned(
          IncomingTransferSessionState.failed,
          effects: const [_failTransfer, _cleanupPartialFile],
        ),
      _ => _invalid(IncomingTransferSessionState.verifying, event),
    };
  }

  static TransitionResult<IncomingTransferSessionState> _fromFinalizing(
    IncomingTransferSessionEvent event,
  ) {
    if (event == IncomingTransferSessionEvent.finalizeCompleted) {
      return TransitionResult.transitioned(
        IncomingTransferSessionState.completed,
        effects: const [_completeTransfer],
      );
    }
    return _invalid(IncomingTransferSessionState.finalizing, event);
  }

  static TransitionResult<IncomingTransferSessionState> _fromCanceling(
    IncomingTransferSessionEvent event,
  ) {
    if (event == IncomingTransferSessionEvent.cleanupCompleted) {
      return TransitionResult.transitioned(
        IncomingTransferSessionState.canceled,
        effects: const [_completeCancellation],
      );
    }
    return _invalid(IncomingTransferSessionState.canceling, event);
  }

  static bool _isTerminal(IncomingTransferSessionState state) {
    return state == IncomingTransferSessionState.completed ||
        state == IncomingTransferSessionState.canceled ||
        state == IncomingTransferSessionState.failed;
  }

  static TransitionResult<IncomingTransferSessionState> _invalid(
    IncomingTransferSessionState state,
    IncomingTransferSessionEvent event,
  ) {
    return TransitionResult.failure(
      state,
      issue: TransitionIssue(
        code: 'incoming_transfer_invalid_transition',
        message: 'Invalid incoming transfer transition: $state + $event.',
      ),
    );
  }
}
