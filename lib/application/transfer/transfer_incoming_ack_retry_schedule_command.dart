class TransferIncomingAckRetryScheduleCommand {
  const TransferIncomingAckRetryScheduleCommand._();

  static bool shouldFlushAfterAckEnqueue({
    required int pendingAckCountBeforeEnqueue,
    required int ackBatchThreshold,
    required int nextExpectedChunk,
    required int expectedChunkCount,
  }) {
    return pendingAckCountBeforeEnqueue + 1 >= ackBatchThreshold ||
        nextExpectedChunk >= expectedChunkCount;
  }

  static bool shouldScheduleDataAckRetry({required bool hasAckFlushTimer}) {
    return !hasAckFlushTimer;
  }

  static bool shouldScheduleMissingNackRetry({
    required int bufferedChunkCount,
    required bool hasMissingNackRetryTimer,
  }) {
    return bufferedChunkCount > 0 && !hasMissingNackRetryTimer;
  }
}
