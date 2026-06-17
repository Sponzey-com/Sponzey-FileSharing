import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum TransferRouteLeaseState { candidate, probing, verified, expired, rejected }

enum TransferRouteLeaseEvent {
  probeRequested,
  probeSucceeded,
  probeFailed,
  routeExpired,
  rejectRequested,
}

class TransferRouteLeaseStateMachine
    implements StateMachine<TransferRouteLeaseState, TransferRouteLeaseEvent> {
  const TransferRouteLeaseStateMachine();

  static const _probeRoute = TransitionEffect('probeRoute');
  static const _bindRouteLease = TransitionEffect('bindRouteLease');
  static const _rejectRouteLease = TransitionEffect('rejectRouteLease');
  static const _notifyRouteExpired = TransitionEffect('notifyRouteExpired');

  @override
  TransitionResult<TransferRouteLeaseState> transition(
    TransferRouteLeaseState state,
    TransferRouteLeaseEvent event,
  ) {
    if (_isTerminal(state)) {
      return TransitionResult.warning(
        state,
        issue: const TransitionIssue(
          code: 'transfer_route_lease_already_terminal',
          message: 'Transfer route lease is already terminal.',
        ),
      );
    }

    if (event == TransferRouteLeaseEvent.rejectRequested) {
      return TransitionResult.transitioned(
        TransferRouteLeaseState.rejected,
        effects: const [_rejectRouteLease],
      );
    }

    return switch (state) {
      TransferRouteLeaseState.candidate => _fromCandidate(event),
      TransferRouteLeaseState.probing => _fromProbing(event),
      TransferRouteLeaseState.verified => _fromVerified(event),
      TransferRouteLeaseState.expired ||
      TransferRouteLeaseState.rejected => _invalid(state, event),
    };
  }

  bool isUsableForTransfer(TransferRouteLeaseState state) {
    return state == TransferRouteLeaseState.verified;
  }

  static TransitionResult<TransferRouteLeaseState> _fromCandidate(
    TransferRouteLeaseEvent event,
  ) {
    if (event == TransferRouteLeaseEvent.probeRequested) {
      return TransitionResult.transitioned(
        TransferRouteLeaseState.probing,
        effects: const [_probeRoute],
      );
    }
    return _invalid(TransferRouteLeaseState.candidate, event);
  }

  static TransitionResult<TransferRouteLeaseState> _fromProbing(
    TransferRouteLeaseEvent event,
  ) {
    return switch (event) {
      TransferRouteLeaseEvent.probeSucceeded => TransitionResult.transitioned(
        TransferRouteLeaseState.verified,
        effects: const [_bindRouteLease],
      ),
      TransferRouteLeaseEvent.probeFailed => TransitionResult.transitioned(
        TransferRouteLeaseState.rejected,
        effects: const [_rejectRouteLease],
      ),
      _ => _invalid(TransferRouteLeaseState.probing, event),
    };
  }

  static TransitionResult<TransferRouteLeaseState> _fromVerified(
    TransferRouteLeaseEvent event,
  ) {
    if (event == TransferRouteLeaseEvent.routeExpired) {
      return TransitionResult.transitioned(
        TransferRouteLeaseState.expired,
        effects: const [_notifyRouteExpired],
      );
    }
    return _invalid(TransferRouteLeaseState.verified, event);
  }

  static bool _isTerminal(TransferRouteLeaseState state) {
    return state == TransferRouteLeaseState.expired ||
        state == TransferRouteLeaseState.rejected;
  }

  static TransitionResult<TransferRouteLeaseState> _invalid(
    TransferRouteLeaseState state,
    TransferRouteLeaseEvent event,
  ) {
    return TransitionResult.failure(
      state,
      issue: TransitionIssue(
        code: 'transfer_route_lease_invalid_transition',
        message: 'Invalid transfer route lease transition: $state + $event.',
      ),
    );
  }
}
