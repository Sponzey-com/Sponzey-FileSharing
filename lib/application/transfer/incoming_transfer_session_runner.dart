import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

abstract interface class IncomingTransferSessionEffectExecutor {
  Future<void> prepareStorage();

  Future<void> sendTransferInitAck();

  Future<void> rejectTransferInit();

  Future<void> openIncomingWriter();

  Future<void> writeChunk();

  Future<void> scheduleAckBatch();

  Future<void> bufferOutOfOrderChunk();

  Future<void> scheduleNackBatch();

  Future<void> flushBufferedChunks();

  Future<void> verifyIncomingDigest();

  Future<void> finalizeFile();

  Future<void> completeTransfer();

  Future<void> failTransfer();

  Future<void> cleanupPartialFile();

  Future<void> cancelTransfer();

  Future<void> completeCancellation();
}

class IncomingTransferSessionRunner {
  IncomingTransferSessionRunner({
    required IncomingTransferSessionEffectExecutor executor,
    IncomingTransferSessionStateMachine stateMachine =
        const IncomingTransferSessionStateMachine(),
    IncomingTransferSessionState initialState =
        IncomingTransferSessionState.offered,
  }) : _executor = executor,
       _stateMachine = stateMachine,
       _state = initialState;

  final IncomingTransferSessionEffectExecutor _executor;
  final IncomingTransferSessionStateMachine _stateMachine;
  IncomingTransferSessionState _state;

  IncomingTransferSessionState get state => _state;

  Future<TransitionResult<IncomingTransferSessionState>> receiveInit() {
    return dispatch(IncomingTransferSessionEvent.transferInitReceived);
  }

  Future<TransitionResult<IncomingTransferSessionState>> markStoragePrepared() {
    return dispatch(IncomingTransferSessionEvent.storagePrepared);
  }

  Future<TransitionResult<IncomingTransferSessionState>>
  markStoragePrepareFailed() {
    return dispatch(IncomingTransferSessionEvent.storagePrepareFailed);
  }

  Future<TransitionResult<IncomingTransferSessionState>> receiveDataStart() {
    return dispatch(IncomingTransferSessionEvent.dataStartReceived);
  }

  Future<TransitionResult<IncomingTransferSessionState>> receiveChunk() {
    return dispatch(IncomingTransferSessionEvent.dataChunkReceived);
  }

  Future<TransitionResult<IncomingTransferSessionState>>
  receiveOutOfOrderChunk() {
    return dispatch(IncomingTransferSessionEvent.outOfOrderChunkReceived);
  }

  Future<TransitionResult<IncomingTransferSessionState>> markBufferGapClosed() {
    return dispatch(IncomingTransferSessionEvent.bufferGapClosed);
  }

  Future<TransitionResult<IncomingTransferSessionState>> receiveDataFinish() {
    return dispatch(IncomingTransferSessionEvent.dataFinishReceived);
  }

  Future<TransitionResult<IncomingTransferSessionState>> markDigestVerified() {
    return dispatch(IncomingTransferSessionEvent.digestVerified);
  }

  Future<TransitionResult<IncomingTransferSessionState>> markDigestMismatch() {
    return dispatch(IncomingTransferSessionEvent.digestMismatch);
  }

  Future<TransitionResult<IncomingTransferSessionState>>
  markFinalizeCompleted() {
    return dispatch(IncomingTransferSessionEvent.finalizeCompleted);
  }

  Future<TransitionResult<IncomingTransferSessionState>> markFileWriteFailed() {
    return dispatch(IncomingTransferSessionEvent.fileWriteFailed);
  }

  Future<TransitionResult<IncomingTransferSessionState>> cancel() {
    return dispatch(IncomingTransferSessionEvent.cancelRequested);
  }

  Future<TransitionResult<IncomingTransferSessionState>>
  markCleanupCompleted() {
    return dispatch(IncomingTransferSessionEvent.cleanupCompleted);
  }

  Future<TransitionResult<IncomingTransferSessionState>> dispatch(
    IncomingTransferSessionEvent event,
  ) async {
    final result = _stateMachine.transition(_state, event);
    if (!result.didTransition) {
      return result;
    }

    _state = result.state;
    for (final effect in result.effects) {
      await _execute(effect);
    }
    return result;
  }

  Future<void> _execute(TransitionEffect effect) {
    return switch (effect.name) {
      'prepareStorage' => _executor.prepareStorage(),
      'sendTransferInitAck' => _executor.sendTransferInitAck(),
      'rejectTransferInit' => _executor.rejectTransferInit(),
      'openIncomingWriter' => _executor.openIncomingWriter(),
      'writeChunk' => _executor.writeChunk(),
      'scheduleAckBatch' => _executor.scheduleAckBatch(),
      'bufferOutOfOrderChunk' => _executor.bufferOutOfOrderChunk(),
      'scheduleNackBatch' => _executor.scheduleNackBatch(),
      'flushBufferedChunks' => _executor.flushBufferedChunks(),
      'verifyIncomingDigest' => _executor.verifyIncomingDigest(),
      'finalizeFile' => _executor.finalizeFile(),
      'completeTransfer' => _executor.completeTransfer(),
      'failTransfer' => _executor.failTransfer(),
      'cleanupPartialFile' => _executor.cleanupPartialFile(),
      'cancelTransfer' => _executor.cancelTransfer(),
      'completeCancellation' => _executor.completeCancellation(),
      _ => Future<void>.error(
        StateError('Unsupported incoming transfer effect: ${effect.name}'),
      ),
    };
  }
}
