import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

enum TransferJobEvent { cancelRequested }

class TransferJobStateMachine
    implements StateMachine<TransferJobStatus, TransferJobEvent> {
  const TransferJobStateMachine();

  @override
  TransitionResult<TransferJobStatus> transition(
    TransferJobStatus state,
    TransferJobEvent event,
  ) {
    switch (event) {
      case TransferJobEvent.cancelRequested:
        if (_isTerminal(state)) {
          return TransitionResult.warning(
            state,
            issue: TransitionIssue(
              code: 'transfer_job_already_terminal',
              message: 'Cannot cancel a terminal transfer job: ${state.name}.',
            ),
          );
        }
        return TransitionResult.transitioned(
          TransferJobStatus.cancelled,
          effects: const [TransitionEffect('cancelTransferResources')],
        );
    }
  }

  bool _isTerminal(TransferJobStatus status) {
    return status == TransferJobStatus.completed ||
        status == TransferJobStatus.rejected ||
        status == TransferJobStatus.failed ||
        status == TransferJobStatus.cancelled;
  }
}
