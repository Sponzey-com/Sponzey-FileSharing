class TransferOutgoingAckBitmapPacket {
  const TransferOutgoingAckBitmapPacket({
    required this.chunkIndexes,
    required this.primaryChunkIndex,
    required this.ackBase,
    required this.ackBitmapWords,
  });

  final List<int> chunkIndexes;
  final int? primaryChunkIndex;
  final int? ackBase;
  final List<int> ackBitmapWords;
}

class TransferOutgoingAckBitmapCommand {
  const TransferOutgoingAckBitmapCommand._();

  static TransferOutgoingAckBitmapPacket build({
    required Iterable<int> chunkIndexes,
  }) {
    final compactIndexes = chunkIndexes.toSet().toList(growable: false)..sort();
    if (compactIndexes.isEmpty) {
      return const TransferOutgoingAckBitmapPacket(
        chunkIndexes: [],
        primaryChunkIndex: null,
        ackBase: null,
        ackBitmapWords: [],
      );
    }

    final base = compactIndexes.first;
    var maxOffset = 0;
    for (final index in compactIndexes) {
      final offset = index - base;
      if (offset > maxOffset) {
        maxOffset = offset;
      }
    }

    final words = List<int>.filled(maxOffset ~/ 32 + 1, 0);
    for (final index in compactIndexes) {
      final offset = index - base;
      words[offset ~/ 32] |= 1 << (offset % 32);
    }

    return TransferOutgoingAckBitmapPacket(
      chunkIndexes: List.unmodifiable(compactIndexes),
      primaryChunkIndex: base,
      ackBase: base,
      ackBitmapWords: List.unmodifiable(words),
    );
  }
}
