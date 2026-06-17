class TransferOutgoingDataNackDecision {
  const TransferOutgoingDataNackDecision({required this.retransmissionIndexes});

  final List<int> retransmissionIndexes;
}

class TransferOutgoingDataNackCommand {
  const TransferOutgoingDataNackCommand._();

  static TransferOutgoingDataNackDecision decide({
    required int primaryChunkIndex,
    required int ackBase,
    required List<int> ackBitmapWords,
    required Iterable<int> acknowledgedChunks,
  }) {
    final acknowledged = acknowledgedChunks.toSet();
    final indexes = <int>{primaryChunkIndex};
    for (var wordIndex = 0; wordIndex < ackBitmapWords.length; wordIndex += 1) {
      final word = ackBitmapWords[wordIndex];
      for (var bit = 0; bit < 32; bit += 1) {
        if ((word & (1 << bit)) != 0) {
          indexes.add(ackBase + wordIndex * 32 + bit);
        }
      }
    }
    indexes.removeWhere(acknowledged.contains);
    final retransmissionIndexes = indexes.toList()..sort();
    return TransferOutgoingDataNackDecision(
      retransmissionIndexes: List.unmodifiable(retransmissionIndexes),
    );
  }
}
