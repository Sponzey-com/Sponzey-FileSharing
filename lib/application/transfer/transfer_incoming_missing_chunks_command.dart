class TransferIncomingMissingChunksCommand {
  const TransferIncomingMissingChunksCommand._();

  static List<int> untilHighestReceived({
    required int nextExpectedChunk,
    required int highestReceivedIndex,
    required Iterable<int> acknowledgedChunks,
    required int limit,
  }) {
    return _collectMissing(
      startInclusive: nextExpectedChunk,
      endExclusive: highestReceivedIndex,
      acknowledgedChunks: acknowledgedChunks,
      limit: limit,
    );
  }

  static List<int> remaining({
    required int nextExpectedChunk,
    required int expectedChunkCount,
    required Iterable<int> acknowledgedChunks,
    required int limit,
  }) {
    return _collectMissing(
      startInclusive: nextExpectedChunk,
      endExclusive: expectedChunkCount,
      acknowledgedChunks: acknowledgedChunks,
      limit: limit,
    );
  }

  static List<int> _collectMissing({
    required int startInclusive,
    required int endExclusive,
    required Iterable<int> acknowledgedChunks,
    required int limit,
  }) {
    if (limit <= 0 || startInclusive >= endExclusive) {
      return const [];
    }

    final acknowledged = acknowledgedChunks.toSet();
    final missing = <int>[];
    for (
      var index = startInclusive;
      index < endExclusive && missing.length < limit;
      index += 1
    ) {
      if (!acknowledged.contains(index)) {
        missing.add(index);
      }
    }
    return List.unmodifiable(missing);
  }
}
