class TransferOutgoingCompletionCommand {
  const TransferOutgoingCompletionCommand._();

  static bool shouldComplete({
    required bool isAlreadyCompleted,
    required int acknowledgedChunkCount,
    required int chunkCount,
    required int inFlightChunkCount,
  }) {
    return !isAlreadyCompleted &&
        acknowledgedChunkCount == chunkCount &&
        inFlightChunkCount == 0;
  }
}
