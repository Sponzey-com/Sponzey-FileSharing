class SelectiveAck {
  const SelectiveAck({
    required this.windowStart,
    required this.receivedChunkIndexes,
  });

  final int windowStart;
  final Set<int> receivedChunkIndexes;

  bool contains(int chunkIndex) => receivedChunkIndexes.contains(chunkIndex);
}

class MissingChunkDetector {
  const MissingChunkDetector();

  List<int> missingChunks({
    required int totalChunks,
    required Set<int> receivedChunkIndexes,
  }) {
    return [
      for (var index = 0; index < totalChunks; index++)
        if (!receivedChunkIndexes.contains(index)) index,
    ];
  }
}

class SlidingWindowPlan {
  const SlidingWindowPlan({
    required this.windowStart,
    required this.windowSize,
    required this.chunkIndexes,
  });

  final int windowStart;
  final int windowSize;
  final List<int> chunkIndexes;
}

class SlidingWindowScheduler {
  const SlidingWindowScheduler();

  SlidingWindowPlan plan({
    required int nextChunkIndex,
    required int totalChunks,
    required int windowSize,
    Set<int> inflightChunkIndexes = const {},
    Set<int> acknowledgedChunkIndexes = const {},
  }) {
    final chunkIndexes = <int>[];
    var candidate = nextChunkIndex;
    while (chunkIndexes.length < windowSize && candidate < totalChunks) {
      if (!inflightChunkIndexes.contains(candidate) &&
          !acknowledgedChunkIndexes.contains(candidate)) {
        chunkIndexes.add(candidate);
      }
      candidate++;
    }
    return SlidingWindowPlan(
      windowStart: nextChunkIndex,
      windowSize: windowSize,
      chunkIndexes: chunkIndexes,
    );
  }
}

class RetryPolicy {
  const RetryPolicy({
    required this.maxRetries,
    required this.initialWindowSize,
    required this.minimumWindowSize,
  });

  final int maxRetries;
  final int initialWindowSize;
  final int minimumWindowSize;

  bool shouldFail(int retryCount) => retryCount >= maxRetries;

  int shrinkWindow(int currentWindowSize) {
    final reduced = (currentWindowSize / 2).floor();
    if (reduced < minimumWindowSize) {
      return minimumWindowSize;
    }
    return reduced;
  }
}
