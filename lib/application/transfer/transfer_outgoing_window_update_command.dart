import 'dart:math';

class TransferOutgoingWindowUpdateDecision {
  const TransferOutgoingWindowUpdateDecision({
    required this.remoteWindowStart,
    required this.advertisedWindowSize,
  });

  final int remoteWindowStart;
  final int advertisedWindowSize;
}

class TransferOutgoingWindowUpdateCommand {
  const TransferOutgoingWindowUpdateCommand._();

  static TransferOutgoingWindowUpdateDecision decide({
    required int windowStart,
    required int windowSize,
  }) {
    return TransferOutgoingWindowUpdateDecision(
      remoteWindowStart: windowStart,
      advertisedWindowSize: max(1, windowSize),
    );
  }
}
