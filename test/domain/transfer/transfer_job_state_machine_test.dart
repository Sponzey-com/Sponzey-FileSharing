import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_job_state_machine.dart';

void main() {
  const machine = TransferJobStateMachine();

  test('cancels active transfer job through explicit transition', () {
    final result = machine.transition(
      TransferJobStatus.sending,
      TransferJobEvent.cancelRequested,
    );

    expect(result.state, TransferJobStatus.cancelled);
    expect(result.disposition, TransitionDisposition.transitioned);
    expect(
      result.effects.map((effect) => effect.name),
      contains('cancelTransferResources'),
    );
  });

  test('does not cancel terminal transfer job', () {
    final result = machine.transition(
      TransferJobStatus.completed,
      TransferJobEvent.cancelRequested,
    );

    expect(result.state, TransferJobStatus.completed);
    expect(result.disposition, TransitionDisposition.warning);
    expect(result.issue?.code, 'transfer_job_already_terminal');
  });
}
