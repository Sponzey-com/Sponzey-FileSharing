class TransferOutgoingAckIndexesCommand {
  const TransferOutgoingAckIndexesCommand._();

  static Set<int> decode({
    required int primaryChunkIndex,
    required int ackBase,
    required List<int> ackBitmapWords,
  }) {
    final chunkIndexes = <int>{primaryChunkIndex};
    for (var wordIndex = 0; wordIndex < ackBitmapWords.length; wordIndex += 1) {
      final word = ackBitmapWords[wordIndex];
      for (var bit = 0; bit < 32; bit += 1) {
        if ((word & (1 << bit)) != 0) {
          chunkIndexes.add(ackBase + wordIndex * 32 + bit);
        }
      }
    }
    return Set.unmodifiable(chunkIndexes);
  }
}
