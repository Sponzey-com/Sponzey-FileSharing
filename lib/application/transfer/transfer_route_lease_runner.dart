import 'package:sponzey_file_sharing/application/transfer/transfer_route_lease_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

abstract interface class TransferRouteLeaseEffectExecutor {
  Future<void> probeRoute();

  Future<void> bindRouteLease();

  Future<void> rejectRouteLease();

  Future<void> notifyRouteExpired();
}

class TransferRouteLeaseRunner {
  TransferRouteLeaseRunner({
    required TransferRouteLeaseEffectExecutor executor,
    TransferRouteLeaseStateMachine stateMachine =
        const TransferRouteLeaseStateMachine(),
    TransferRouteLeaseState initialState = TransferRouteLeaseState.candidate,
  }) : _executor = executor,
       _stateMachine = stateMachine,
       _state = initialState;

  final TransferRouteLeaseEffectExecutor _executor;
  final TransferRouteLeaseStateMachine _stateMachine;
  TransferRouteLeaseState _state;

  TransferRouteLeaseState get state => _state;

  bool get isUsableForTransfer => _stateMachine.isUsableForTransfer(_state);

  Future<TransitionResult<TransferRouteLeaseState>> requestProbe() {
    return dispatch(TransferRouteLeaseEvent.probeRequested);
  }

  Future<TransitionResult<TransferRouteLeaseState>> markProbeSucceeded() {
    return dispatch(TransferRouteLeaseEvent.probeSucceeded);
  }

  Future<TransitionResult<TransferRouteLeaseState>> markProbeFailed() {
    return dispatch(TransferRouteLeaseEvent.probeFailed);
  }

  Future<TransitionResult<TransferRouteLeaseState>> markExpired() {
    return dispatch(TransferRouteLeaseEvent.routeExpired);
  }

  Future<TransitionResult<TransferRouteLeaseState>> dispatch(
    TransferRouteLeaseEvent event,
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
      'probeRoute' => _executor.probeRoute(),
      'bindRouteLease' => _executor.bindRouteLease(),
      'rejectRouteLease' => _executor.rejectRouteLease(),
      'notifyRouteExpired' => _executor.notifyRouteExpired(),
      _ => Future<void>.error(
        StateError('Unsupported transfer route lease effect: ${effect.name}'),
      ),
    };
  }
}
