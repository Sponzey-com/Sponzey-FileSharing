enum TransferIncomingDataChunkAction {
  rejectOutOfRange,
  ackDuplicate,
  appendInOrder,
  bufferOutOfOrder,
}

class TransferIncomingDataChunkDecision {
  const TransferIncomingDataChunkDecision({
    required this.action,
    this.nackChunkIndex,
  });

  final TransferIncomingDataChunkAction action;
  final int? nackChunkIndex;
}

class TransferIncomingDataChunkCommand {
  const TransferIncomingDataChunkCommand._();

  static TransferIncomingDataChunkDecision decide({
    required int chunkIndex,
    required int expectedChunkCount,
    required int nextExpectedChunk,
    required Iterable<int> acknowledgedChunks,
  }) {
    if (chunkIndex >= expectedChunkCount) {
      return TransferIncomingDataChunkDecision(
        action: TransferIncomingDataChunkAction.rejectOutOfRange,
        nackChunkIndex: nextExpectedChunk,
      );
    }
    if (acknowledgedChunks.contains(chunkIndex)) {
      return const TransferIncomingDataChunkDecision(
        action: TransferIncomingDataChunkAction.ackDuplicate,
      );
    }
    if (chunkIndex == nextExpectedChunk) {
      return const TransferIncomingDataChunkDecision(
        action: TransferIncomingDataChunkAction.appendInOrder,
      );
    }
    return const TransferIncomingDataChunkDecision(
      action: TransferIncomingDataChunkAction.bufferOutOfOrder,
    );
  }
}
