class TransferOutgoingDataAckDecision {
  const TransferOutgoingDataAckDecision({
    required this.validAckIndexes,
    required this.newlyAckedIndexes,
    required this.duplicateAckCount,
  });

  final List<int> validAckIndexes;
  final List<int> newlyAckedIndexes;
  final int duplicateAckCount;
}

class TransferOutgoingDataAckCommand {
  const TransferOutgoingDataAckCommand._();

  static TransferOutgoingDataAckDecision decide({
    required Iterable<int> rawAckIndexes,
    required int chunkCount,
    required Iterable<int> acknowledgedChunks,
  }) {
    final acknowledged = acknowledgedChunks.toSet();
    final validAckIndexes =
        rawAckIndexes
            .where((index) => index >= 0 && index < chunkCount)
            .toList()
          ..sort();
    final newlyAckedIndexes = <int>[];
    final frameNewAcks = <int>{};
    var duplicateAckCount = 0;

    for (final chunkIndex in validAckIndexes) {
      if (acknowledged.contains(chunkIndex) ||
          frameNewAcks.contains(chunkIndex)) {
        duplicateAckCount += 1;
        continue;
      }
      frameNewAcks.add(chunkIndex);
      newlyAckedIndexes.add(chunkIndex);
    }

    return TransferOutgoingDataAckDecision(
      validAckIndexes: List.unmodifiable(validAckIndexes),
      newlyAckedIndexes: List.unmodifiable(newlyAckedIndexes),
      duplicateAckCount: duplicateAckCount,
    );
  }
}
