import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/receive_policy/receive_policy_state_machine.dart';

void main() {
  test('rejects unknown peers when policy requires known peers', () {
    const machine = ReceivePolicyStateMachine(
      mode: ReceivePolicyMode.rejectUnknownPeers,
    );

    var result = machine.transition(
      ReceivePolicyStatus.offered,
      ReceivePolicyEvent.offerReceived,
    );
    result = machine.transition(
      result.state,
      ReceivePolicyEvent.authSessionValid,
    );
    result = machine.transition(result.state, ReceivePolicyEvent.peerUnknown);

    expect(result.state, ReceivePolicyStatus.rejected);
    expect(result.issue?.code, 'unknown_peer_rejected');
  });

  test('waits for approval in ask every time mode', () {
    const machine = ReceivePolicyStateMachine(
      mode: ReceivePolicyMode.askEveryTime,
    );

    var result = machine.transition(
      ReceivePolicyStatus.offered,
      ReceivePolicyEvent.offerReceived,
    );
    result = machine.transition(
      result.state,
      ReceivePolicyEvent.authSessionValid,
    );
    result = machine.transition(result.state, ReceivePolicyEvent.peerAllowed);
    result = machine.transition(result.state, ReceivePolicyEvent.metadataValid);
    result = machine.transition(
      result.state,
      ReceivePolicyEvent.destinationAllowed,
    );
    result = machine.transition(result.state, ReceivePolicyEvent.noConflict);

    expect(result.state, ReceivePolicyStatus.waitingForApproval);
  });

  test('accepts allowed peers automatically', () {
    const machine = ReceivePolicyStateMachine(
      mode: ReceivePolicyMode.autoAcceptAllowedPeers,
    );

    var result = machine.transition(
      ReceivePolicyStatus.offered,
      ReceivePolicyEvent.offerReceived,
    );
    result = machine.transition(
      result.state,
      ReceivePolicyEvent.authSessionValid,
    );
    result = machine.transition(result.state, ReceivePolicyEvent.peerAllowed);
    result = machine.transition(result.state, ReceivePolicyEvent.metadataValid);
    result = machine.transition(
      result.state,
      ReceivePolicyEvent.destinationAllowed,
    );
    result = machine.transition(result.state, ReceivePolicyEvent.noConflict);

    expect(result.state, ReceivePolicyStatus.accepted);
  });
}
