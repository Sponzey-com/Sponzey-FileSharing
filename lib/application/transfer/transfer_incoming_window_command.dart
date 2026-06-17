import 'dart:math';

class TransferIncomingWindowCommand {
  const TransferIncomingWindowCommand._();

  static int receiverWindowSize({
    required int advertisedWindowSize,
    required int bufferedChunkCount,
  }) {
    return max(1, advertisedWindowSize - bufferedChunkCount);
  }
}
