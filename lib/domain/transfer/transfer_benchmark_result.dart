class TransferBenchmarkResult {
  const TransferBenchmarkResult({
    required this.routeType,
    required this.operatingSystem,
    required this.buildMode,
    required this.fileSizeBytes,
    required this.durationMs,
    required this.averageBytesPerSecond,
    required this.lossRate,
    required this.retryCount,
    required this.receiverDigestVerified,
  });

  final String routeType;
  final String operatingSystem;
  final String buildMode;
  final int fileSizeBytes;
  final int durationMs;
  final double averageBytesPerSecond;
  final double lossRate;
  final int retryCount;
  final bool receiverDigestVerified;

  double get averageMegabytesPerSecond {
    return averageBytesPerSecond / (1024 * 1024);
  }

  bool get isReleaseGateEligible {
    return receiverDigestVerified &&
        fileSizeBytes > 0 &&
        durationMs > 0 &&
        averageBytesPerSecond > 0 &&
        lossRate >= 0 &&
        lossRate <= 1 &&
        retryCount >= 0;
  }

  Map<String, Object?> toJson() {
    return {
      'routeType': routeType,
      'operatingSystem': operatingSystem,
      'buildMode': buildMode,
      'fileSizeBytes': fileSizeBytes,
      'durationMs': durationMs,
      'averageBytesPerSecond': averageBytesPerSecond,
      'averageMegabytesPerSecond': averageMegabytesPerSecond,
      'lossRate': lossRate,
      'retryCount': retryCount,
      'receiverDigestVerified': receiverDigestVerified,
    };
  }
}
