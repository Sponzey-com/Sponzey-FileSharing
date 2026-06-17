class TransferOutgoingRetransmissionScanDecision {
  const TransferOutgoingRetransmissionScanDecision({
    required this.acknowledgedInFlightIndexes,
    required this.timedOutIndexes,
    required this.retainedInFlightIndexes,
  });

  final List<int> acknowledgedInFlightIndexes;
  final List<int> timedOutIndexes;
  final List<int> retainedInFlightIndexes;
}

class TransferOutgoingRetransmissionScanCommand {
  const TransferOutgoingRetransmissionScanCommand._();

  static TransferOutgoingRetransmissionScanDecision scan({
    required DateTime now,
    required Duration timeout,
    required Iterable<int> inFlightChunks,
    required Iterable<int> acknowledgedChunks,
    required Map<int, DateTime> sentAtByChunk,
  }) {
    final acknowledged = acknowledgedChunks.toSet();
    final acknowledgedInFlight = <int>[];
    final timedOut = <int>[];
    final retained = <int>[];

    for (final chunkIndex in inFlightChunks.toList(growable: false)) {
      if (acknowledged.contains(chunkIndex)) {
        acknowledgedInFlight.add(chunkIndex);
        continue;
      }
      final sentAt = sentAtByChunk[chunkIndex];
      if (sentAt == null || now.difference(sentAt) < timeout) {
        retained.add(chunkIndex);
        continue;
      }
      timedOut.add(chunkIndex);
    }

    return TransferOutgoingRetransmissionScanDecision(
      acknowledgedInFlightIndexes: List.unmodifiable(acknowledgedInFlight),
      timedOutIndexes: List.unmodifiable(timedOut),
      retainedInFlightIndexes: List.unmodifiable(retained),
    );
  }
}
