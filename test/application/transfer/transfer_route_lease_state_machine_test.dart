import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_route_lease_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

void main() {
  group('TransferRouteLeaseStateMachine', () {
    const machine = TransferRouteLeaseStateMachine();

    test('transitions through route probe happy path', () {
      var result = machine.transition(
        TransferRouteLeaseState.candidate,
        TransferRouteLeaseEvent.probeRequested,
      );
      expect(result.state, TransferRouteLeaseState.probing);
      expect(result.disposition, TransitionDisposition.transitioned);
      expect(result.effects.map((effect) => effect.name), ['probeRoute']);

      result = machine.transition(
        result.state,
        TransferRouteLeaseEvent.probeSucceeded,
      );
      expect(result.state, TransferRouteLeaseState.verified);
      expect(result.effects.map((effect) => effect.name), ['bindRouteLease']);
    });

    test('rejects route when probe fails or explicit reject is requested', () {
      final probeFailed = machine.transition(
        TransferRouteLeaseState.probing,
        TransferRouteLeaseEvent.probeFailed,
      );
      expect(probeFailed.state, TransferRouteLeaseState.rejected);
      expect(probeFailed.effects.map((effect) => effect.name), [
        'rejectRouteLease',
      ]);

      final rejected = machine.transition(
        TransferRouteLeaseState.candidate,
        TransferRouteLeaseEvent.rejectRequested,
      );
      expect(rejected.state, TransferRouteLeaseState.rejected);
      expect(rejected.effects.map((effect) => effect.name), [
        'rejectRouteLease',
      ]);
    });

    test('expires verified route and notifies active sessions', () {
      final result = machine.transition(
        TransferRouteLeaseState.verified,
        TransferRouteLeaseEvent.routeExpired,
      );

      expect(result.state, TransferRouteLeaseState.expired);
      expect(result.effects.map((effect) => effect.name), [
        'notifyRouteExpired',
      ]);
    });

    test('allows only verified route leases for transfer data path', () {
      expect(
        machine.isUsableForTransfer(TransferRouteLeaseState.verified),
        isTrue,
      );
      expect(
        machine.isUsableForTransfer(TransferRouteLeaseState.candidate),
        isFalse,
      );
      expect(
        machine.isUsableForTransfer(TransferRouteLeaseState.expired),
        isFalse,
      );
      expect(
        machine.isUsableForTransfer(TransferRouteLeaseState.rejected),
        isFalse,
      );
    });

    test('terminal states reject later events with warning no-op', () {
      final result = machine.transition(
        TransferRouteLeaseState.expired,
        TransferRouteLeaseEvent.probeRequested,
      );

      expect(result.state, TransferRouteLeaseState.expired);
      expect(result.disposition, TransitionDisposition.warning);
      expect(result.issue?.code, 'transfer_route_lease_already_terminal');
    });

    test('invalid non-terminal transition returns failure', () {
      final result = machine.transition(
        TransferRouteLeaseState.candidate,
        TransferRouteLeaseEvent.probeSucceeded,
      );

      expect(result.state, TransferRouteLeaseState.candidate);
      expect(result.disposition, TransitionDisposition.failure);
      expect(result.issue?.code, 'transfer_route_lease_invalid_transition');
    });
  });
}
