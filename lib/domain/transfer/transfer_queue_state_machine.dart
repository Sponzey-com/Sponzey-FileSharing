import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum TransferQueueStatus {
  empty,
  queued,
  dispatching,
  running,
  throttled,
  draining,
  completed,
  failed,
  cancelled,
}

enum TransferQueueEvent {
  jobAdded,
  jobRemoved,
  dispatchRequested,
  jobStarted,
  jobProgressed,
  jobCompleted,
  jobFailed,
  jobRetryScheduled,
  cancelRequested,
  queueDrained,
}

class TransferQueueSnapshot {
  const TransferQueueSnapshot({
    required this.status,
    this.authenticatedPeerCount = 0,
    this.childSessionCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
  });

  final TransferQueueStatus status;
  final int authenticatedPeerCount;
  final int childSessionCount;
  final int successCount;
  final int failureCount;

  TransferQueueSnapshot copyWith({
    TransferQueueStatus? status,
    int? authenticatedPeerCount,
    int? childSessionCount,
    int? successCount,
    int? failureCount,
  }) {
    return TransferQueueSnapshot(
      status: status ?? this.status,
      authenticatedPeerCount:
          authenticatedPeerCount ?? this.authenticatedPeerCount,
      childSessionCount: childSessionCount ?? this.childSessionCount,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
    );
  }
}

class TransferQueueStateMachine
    implements StateMachine<TransferQueueSnapshot, TransferQueueEvent> {
  const TransferQueueStateMachine();

  @override
  TransitionResult<TransferQueueSnapshot> transition(
    TransferQueueSnapshot state,
    TransferQueueEvent event,
  ) {
    switch ((state.status, event)) {
      case (TransferQueueStatus.empty, TransferQueueEvent.jobAdded):
      case (TransferQueueStatus.completed, TransferQueueEvent.jobAdded):
        return TransitionResult.transitioned(
          state.copyWith(status: TransferQueueStatus.queued),
          effects: const [TransitionEffect('createParentTransferJob')],
        );
      case (TransferQueueStatus.queued, TransferQueueEvent.dispatchRequested):
        if (state.authenticatedPeerCount <= 0) {
          return TransitionResult.failure(
            state,
            issue: const TransitionIssue(
              code: 'no_authenticated_peers',
              message: 'Transfer jobs require at least one authenticated peer.',
            ),
          );
        }
        return TransitionResult.transitioned(
          state.copyWith(
            status: TransferQueueStatus.dispatching,
            childSessionCount: state.authenticatedPeerCount,
          ),
          effects: const [TransitionEffect('createChildTransferSessions')],
        );
      case (TransferQueueStatus.dispatching, TransferQueueEvent.jobStarted):
        return TransitionResult.transitioned(
          state.copyWith(status: TransferQueueStatus.running),
        );
      case (TransferQueueStatus.running, TransferQueueEvent.jobProgressed):
        return TransitionResult.noOp(state);
      case (TransferQueueStatus.running, TransferQueueEvent.jobRetryScheduled):
        return TransitionResult.transitioned(
          state.copyWith(status: TransferQueueStatus.throttled),
        );
      case (TransferQueueStatus.throttled, TransferQueueEvent.jobProgressed):
        return TransitionResult.transitioned(
          state.copyWith(status: TransferQueueStatus.running),
        );
      case (TransferQueueStatus.running, TransferQueueEvent.jobCompleted):
      case (TransferQueueStatus.throttled, TransferQueueEvent.jobCompleted):
        final successCount = state.successCount + 1;
        final status =
            successCount + state.failureCount >= state.childSessionCount
            ? TransferQueueStatus.completed
            : state.status;
        return TransitionResult.transitioned(
          state.copyWith(status: status, successCount: successCount),
        );
      case (TransferQueueStatus.running, TransferQueueEvent.jobFailed):
      case (TransferQueueStatus.throttled, TransferQueueEvent.jobFailed):
        final failureCount = state.failureCount + 1;
        final status =
            state.successCount + failureCount >= state.childSessionCount
            ? TransferQueueStatus.failed
            : state.status;
        return TransitionResult.transitioned(
          state.copyWith(status: status, failureCount: failureCount),
        );
      case (_, TransferQueueEvent.cancelRequested):
        return TransitionResult.transitioned(
          state.copyWith(status: TransferQueueStatus.cancelled),
          effects: const [TransitionEffect('cancelChildTransferSessions')],
        );
      case (TransferQueueStatus.running, TransferQueueEvent.queueDrained):
      case (TransferQueueStatus.throttled, TransferQueueEvent.queueDrained):
        return TransitionResult.transitioned(
          state.copyWith(status: TransferQueueStatus.draining),
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_transfer_queue_transition',
            message: 'Cannot apply $event while queue is ${state.status}.',
          ),
        );
    }
  }
}
