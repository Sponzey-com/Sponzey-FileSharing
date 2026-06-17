class TransferMetricCalculationCommand {
  const TransferMetricCalculationCommand._();

  static double throughputBytesPerSec({
    required int transferredBytes,
    required DateTime startedAt,
    required DateTime now,
  }) {
    final elapsedMs = now.difference(startedAt).inMilliseconds;
    if (elapsedMs <= 0 || transferredBytes <= 0) {
      return 0;
    }
    return transferredBytes / (elapsedMs / 1000);
  }

  static double lossRate({
    required int acknowledgedChunkCount,
    required int retryCount,
  }) {
    final denominator = acknowledgedChunkCount + retryCount;
    if (denominator <= 0) {
      return 0;
    }
    return retryCount / denominator;
  }
}
