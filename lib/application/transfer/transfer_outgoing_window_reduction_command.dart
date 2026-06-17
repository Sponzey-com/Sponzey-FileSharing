import 'dart:math';

class TransferOutgoingWindowReductionCommand {
  const TransferOutgoingWindowReductionCommand._();

  static int reduce(int currentWindowSize) {
    return max(1, currentWindowSize ~/ 2);
  }
}
