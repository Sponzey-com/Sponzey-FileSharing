class TransferOutgoingDigestAdvanceDecision {
  const TransferOutgoingDigestAdvanceDecision({
    required this.shouldAppendToDigest,
    required this.nextDigestChunk,
  });

  final bool shouldAppendToDigest;
  final int nextDigestChunk;
}

class TransferOutgoingDigestAdvanceCommand {
  const TransferOutgoingDigestAdvanceCommand._();

  static TransferOutgoingDigestAdvanceDecision decide({
    required bool isRetransmission,
    required int chunkIndex,
    required int nextDigestChunk,
  }) {
    if (!isRetransmission && chunkIndex == nextDigestChunk) {
      return TransferOutgoingDigestAdvanceDecision(
        shouldAppendToDigest: true,
        nextDigestChunk: nextDigestChunk + 1,
      );
    }
    return TransferOutgoingDigestAdvanceDecision(
      shouldAppendToDigest: false,
      nextDigestChunk: nextDigestChunk,
    );
  }
}
