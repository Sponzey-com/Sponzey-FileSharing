import 'dart:math';

class TransferOutgoingNextChunkDecision {
  const TransferOutgoingNextChunkDecision({
    required this.chunkIndex,
    required this.nextChunkToSend,
    required this.isRetransmission,
  });

  final int? chunkIndex;
  final int nextChunkToSend;
  final bool isRetransmission;
}

class TransferOutgoingNextChunkCommand {
  const TransferOutgoingNextChunkCommand._();

  static TransferOutgoingNextChunkDecision decide({
    required int? retransmissionCandidate,
    required int nextChunkToSend,
    required int chunkCount,
    required int remoteWindowStart,
    required int advertisedWindowSize,
    required Iterable<int> acknowledgedChunks,
    required Iterable<int> inFlightChunks,
  }) {
    final acknowledged = acknowledgedChunks.toSet();
    final inFlight = inFlightChunks.toSet();

    if (retransmissionCandidate != null &&
        !acknowledged.contains(retransmissionCandidate) &&
        !inFlight.contains(retransmissionCandidate)) {
      return TransferOutgoingNextChunkDecision(
        chunkIndex: retransmissionCandidate,
        nextChunkToSend: nextChunkToSend,
        isRetransmission: true,
      );
    }

    final remoteLimit = remoteWindowStart + max(1, advertisedWindowSize);
    var cursor = nextChunkToSend;
    while (cursor < chunkCount) {
      final index = cursor;
      if (index >= remoteLimit) {
        return TransferOutgoingNextChunkDecision(
          chunkIndex: null,
          nextChunkToSend: cursor,
          isRetransmission: false,
        );
      }
      cursor += 1;
      if (acknowledged.contains(index) || inFlight.contains(index)) {
        continue;
      }
      return TransferOutgoingNextChunkDecision(
        chunkIndex: index,
        nextChunkToSend: cursor,
        isRetransmission: false,
      );
    }

    return TransferOutgoingNextChunkDecision(
      chunkIndex: null,
      nextChunkToSend: cursor,
      isRetransmission: false,
    );
  }
}
