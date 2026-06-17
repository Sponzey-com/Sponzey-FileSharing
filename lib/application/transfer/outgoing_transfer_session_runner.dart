import 'package:sponzey_file_sharing/application/transfer/outgoing_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

abstract interface class OutgoingTransferSessionEffectExecutor {
  Future<void> sendTransferInit();

  Future<void> bindDataEndpoint();

  Future<void> sendDataStartFrame();

  Future<void> pumpChunkWindow();

  Future<void> sendDataFinishFrame();

  Future<void> completeTransfer();

  Future<void> failTransfer();

  Future<void> cancelTransfer();

  Future<void> cleanupTransfer();
}

class OutgoingTransferSessionRunner {
  OutgoingTransferSessionRunner({
    required OutgoingTransferSessionEffectExecutor executor,
    OutgoingTransferSessionStateMachine stateMachine =
        const OutgoingTransferSessionStateMachine(),
    OutgoingTransferSessionState initialState =
        OutgoingTransferSessionState.created,
  }) : _executor = executor,
       _stateMachine = stateMachine,
       _state = initialState;

  final OutgoingTransferSessionEffectExecutor _executor;
  final OutgoingTransferSessionStateMachine _stateMachine;
  OutgoingTransferSessionState _state;

  OutgoingTransferSessionState get state => _state;

  Future<TransitionResult<OutgoingTransferSessionState>> start() {
    return dispatch(OutgoingTransferSessionEvent.startRequested);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> acceptReceiver() {
    return dispatch(OutgoingTransferSessionEvent.receiverAccepted);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> rejectReceiver() {
    return dispatch(OutgoingTransferSessionEvent.receiverRejected);
  }

  Future<TransitionResult<OutgoingTransferSessionState>>
  markDataEndpointBound() {
    return dispatch(OutgoingTransferSessionEvent.dataEndpointBound);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markStartFrameSent() {
    return dispatch(OutgoingTransferSessionEvent.startFrameSent);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markWindowSaturated() {
    return dispatch(OutgoingTransferSessionEvent.windowSaturated);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markAckOpenedWindow() {
    return dispatch(OutgoingTransferSessionEvent.ackOpenedWindow);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markAllChunksAcked() {
    return dispatch(OutgoingTransferSessionEvent.allChunksAcked);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markFinishFrameSent() {
    return dispatch(OutgoingTransferSessionEvent.finishFrameSent);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markFinishAccepted() {
    return dispatch(OutgoingTransferSessionEvent.finishAccepted);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> cancel() {
    return dispatch(OutgoingTransferSessionEvent.cancelRequested);
  }

  Future<TransitionResult<OutgoingTransferSessionState>>
  markCancellationCompleted() {
    return dispatch(OutgoingTransferSessionEvent.cancelCompleted);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> markFailure() {
    return dispatch(OutgoingTransferSessionEvent.failureOccurred);
  }

  Future<TransitionResult<OutgoingTransferSessionState>> dispatch(
    OutgoingTransferSessionEvent event,
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
      'sendTransferInit' => _executor.sendTransferInit(),
      'bindDataEndpoint' => _executor.bindDataEndpoint(),
      'sendDataStartFrame' => _executor.sendDataStartFrame(),
      'pumpChunkWindow' => _executor.pumpChunkWindow(),
      'sendDataFinishFrame' => _executor.sendDataFinishFrame(),
      'completeTransfer' => _executor.completeTransfer(),
      'failTransfer' => _executor.failTransfer(),
      'cancelTransfer' => _executor.cancelTransfer(),
      'cleanupTransfer' => _executor.cleanupTransfer(),
      _ => Future<void>.error(
        StateError('Unsupported outgoing transfer effect: ${effect.name}'),
      ),
    };
  }
}
