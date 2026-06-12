import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum DataPathStatus {
  binding,
  ready,
  transferring,
  degraded,
  retryingSameInterface,
  failingOverInterface,
  failed,
  completed,
}

enum DataPathFailoverEvent {
  bindSucceeded,
  bindFailed,
  transferStarted,
  packetLossExceeded,
  rttDegraded,
  sameInterfaceRetrySucceeded,
  sameInterfaceRetryFailed,
  alternateInterfaceSucceeded,
  alternateInterfaceFailed,
  transferCompleted,
}

class DataPathFailoverSnapshot {
  const DataPathFailoverSnapshot({
    required this.transferId,
    required this.peerId,
    required this.status,
    this.retryCount = 0,
    this.failoverCount = 0,
    this.ackedChunkIndexes = const {},
    this.missingChunkIndexes = const {},
    this.packetLossThreshold = 3,
    this.rttDegradedThresholdMs = 800,
  });

  final String transferId;
  final String peerId;
  final DataPathStatus status;
  final int retryCount;
  final int failoverCount;
  final Set<int> ackedChunkIndexes;
  final Set<int> missingChunkIndexes;
  final int packetLossThreshold;
  final int rttDegradedThresholdMs;

  DataPathFailoverSnapshot copyWith({
    DataPathStatus? status,
    int? retryCount,
    int? failoverCount,
    Set<int>? ackedChunkIndexes,
    Set<int>? missingChunkIndexes,
  }) {
    return DataPathFailoverSnapshot(
      transferId: transferId,
      peerId: peerId,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      failoverCount: failoverCount ?? this.failoverCount,
      ackedChunkIndexes: ackedChunkIndexes ?? this.ackedChunkIndexes,
      missingChunkIndexes: missingChunkIndexes ?? this.missingChunkIndexes,
      packetLossThreshold: packetLossThreshold,
      rttDegradedThresholdMs: rttDegradedThresholdMs,
    );
  }
}

class DataPathFailoverStateMachine
    implements StateMachine<DataPathFailoverSnapshot, DataPathFailoverEvent> {
  const DataPathFailoverStateMachine();

  @override
  TransitionResult<DataPathFailoverSnapshot> transition(
    DataPathFailoverSnapshot state,
    DataPathFailoverEvent event,
  ) {
    switch ((state.status, event)) {
      case (DataPathStatus.binding, DataPathFailoverEvent.bindSucceeded):
        return TransitionResult.transitioned(
          state.copyWith(status: DataPathStatus.ready),
        );
      case (DataPathStatus.binding, DataPathFailoverEvent.bindFailed):
        return TransitionResult.transitioned(
          state.copyWith(
            status: DataPathStatus.retryingSameInterface,
            retryCount: state.retryCount + 1,
          ),
          effects: const [TransitionEffect('retrySameInterfaceDataPort')],
        );
      case (DataPathStatus.ready, DataPathFailoverEvent.transferStarted):
        return TransitionResult.transitioned(
          state.copyWith(status: DataPathStatus.transferring),
        );
      case (DataPathStatus.transferring, DataPathFailoverEvent.rttDegraded):
        return TransitionResult.transitioned(
          state.copyWith(status: DataPathStatus.degraded),
          effects: const [TransitionEffect('publishDataPathDegraded')],
        );
      case (
        DataPathStatus.transferring,
        DataPathFailoverEvent.packetLossExceeded,
      ):
      case (DataPathStatus.degraded, DataPathFailoverEvent.packetLossExceeded):
        return TransitionResult.transitioned(
          state.copyWith(
            status: DataPathStatus.retryingSameInterface,
            retryCount: state.retryCount + 1,
          ),
          effects: const [TransitionEffect('retrySameInterfaceDataPort')],
        );
      case (
        DataPathStatus.retryingSameInterface,
        DataPathFailoverEvent.sameInterfaceRetrySucceeded,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: DataPathStatus.transferring),
          effects: const [TransitionEffect('resumeTransfer')],
        );
      case (
        DataPathStatus.retryingSameInterface,
        DataPathFailoverEvent.sameInterfaceRetryFailed,
      ):
        return TransitionResult.transitioned(
          state.copyWith(
            status: DataPathStatus.failingOverInterface,
            failoverCount: state.failoverCount + 1,
          ),
          effects: const [TransitionEffect('selectAlternateRouteCandidate')],
        );
      case (
        DataPathStatus.failingOverInterface,
        DataPathFailoverEvent.alternateInterfaceSucceeded,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: DataPathStatus.transferring),
          effects: const [TransitionEffect('retransmitMissingChunks')],
        );
      case (
        DataPathStatus.failingOverInterface,
        DataPathFailoverEvent.alternateInterfaceFailed,
      ):
        return TransitionResult.failure(
          state.copyWith(status: DataPathStatus.failed),
          issue: const TransitionIssue(
            code: 'data_path_failover_failed',
            message: 'No usable data path remains for the transfer.',
          ),
        );
      case (_, DataPathFailoverEvent.transferCompleted):
        return TransitionResult.transitioned(
          state.copyWith(status: DataPathStatus.completed),
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_data_path_transition',
            message: 'Cannot apply $event while data path is ${state.status}.',
          ),
        );
    }
  }
}
