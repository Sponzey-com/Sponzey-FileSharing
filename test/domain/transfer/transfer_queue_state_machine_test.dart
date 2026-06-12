import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_queue_state_machine.dart';

void main() {
  const machine = TransferQueueStateMachine();

  test('does not dispatch without authenticated peers', () {
    final result = machine.transition(
      const TransferQueueSnapshot(status: TransferQueueStatus.queued),
      TransferQueueEvent.dispatchRequested,
    );

    expect(result.isFailure, isTrue);
    expect(result.issue?.code, 'no_authenticated_peers');
  });

  test('creates child sessions per authenticated peer', () {
    final result = machine.transition(
      const TransferQueueSnapshot(
        status: TransferQueueStatus.queued,
        authenticatedPeerCount: 3,
      ),
      TransferQueueEvent.dispatchRequested,
    );

    expect(result.state.status, TransferQueueStatus.dispatching);
    expect(result.state.childSessionCount, 3);
    expect(
      result.effects.map((effect) => effect.name),
      contains('createChildTransferSessions'),
    );
  });

  test('keeps success and failure counts independent', () {
    var state = const TransferQueueSnapshot(
      status: TransferQueueStatus.running,
      authenticatedPeerCount: 2,
      childSessionCount: 2,
    );

    var result = machine.transition(state, TransferQueueEvent.jobCompleted);
    expect(result.state.successCount, 1);
    expect(result.state.status, TransferQueueStatus.running);

    state = result.state;
    result = machine.transition(state, TransferQueueEvent.jobFailed);
    expect(result.state.successCount, 1);
    expect(result.state.failureCount, 1);
    expect(result.state.status, TransferQueueStatus.failed);
  });
}
