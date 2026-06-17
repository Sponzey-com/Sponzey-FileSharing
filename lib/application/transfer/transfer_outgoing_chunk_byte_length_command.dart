class TransferOutgoingChunkByteLengthCommand {
  const TransferOutgoingChunkByteLengthCommand._();

  static int calculate({
    required int fileSize,
    required int chunkSize,
    required int chunkIndex,
  }) {
    final start = chunkIndex * chunkSize;
    final remaining = fileSize - start;
    return remaining > chunkSize ? chunkSize : remaining;
  }
}
