enum TransferIncomingDataFinishAction { readyToFinalize, waitForMissing }

class TransferIncomingDataFinishDecision {
  const TransferIncomingDataFinishDecision({
    required this.action,
    required this.missingIndexes,
  });

  final TransferIncomingDataFinishAction action;
  final List<int> missingIndexes;
}

class TransferIncomingDataFinishCommand {
  const TransferIncomingDataFinishCommand._();

  static TransferIncomingDataFinishDecision decide({
    required int nextExpectedChunk,
    required int expectedChunkCount,
    required Iterable<int> acknowledgedChunks,
    required int bufferedChunkCount,
    required int missingLimit,
  }) {
    final ready =
        nextExpectedChunk == expectedChunkCount && bufferedChunkCount == 0;
    if (ready) {
      return const TransferIncomingDataFinishDecision(
        action: TransferIncomingDataFinishAction.readyToFinalize,
        missingIndexes: [],
      );
    }

    final acknowledged = acknowledgedChunks.toSet();
    final missingIndexes = <int>[];
    for (
      var index = nextExpectedChunk;
      index < expectedChunkCount && missingIndexes.length < missingLimit;
      index += 1
    ) {
      if (!acknowledged.contains(index)) {
        missingIndexes.add(index);
      }
    }
    return TransferIncomingDataFinishDecision(
      action: TransferIncomingDataFinishAction.waitForMissing,
      missingIndexes: List.unmodifiable(missingIndexes),
    );
  }
}
