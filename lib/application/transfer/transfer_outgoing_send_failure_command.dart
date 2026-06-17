import 'dart:math';

enum TransferOutgoingSendFailureAction { retry, exhausted }

class TransferOutgoingSendFailureDecision {
  const TransferOutgoingSendFailureDecision({
    required this.action,
    required this.attemptsAfterFailure,
    required this.shouldReduceWindow,
  });

  final TransferOutgoingSendFailureAction action;
  final int attemptsAfterFailure;
  final bool shouldReduceWindow;
}

class TransferOutgoingSendFailureCommand {
  const TransferOutgoingSendFailureCommand._();

  static int nextSendAttempt({
    required int currentAttempts,
    required bool isRetransmission,
  }) {
    return currentAttempts + (isRetransmission ? 1 : 0);
  }

  static TransferOutgoingSendFailureDecision onRetryableFailure({
    required int nextAttempts,
    required int recordedAttempts,
    required int maxRetransmissions,
    required bool isRetransmission,
  }) {
    final attemptsAfterFailure = max(nextAttempts, recordedAttempts + 1);
    if (attemptsAfterFailure > maxRetransmissions) {
      return TransferOutgoingSendFailureDecision(
        action: TransferOutgoingSendFailureAction.exhausted,
        attemptsAfterFailure: attemptsAfterFailure,
        shouldReduceWindow: false,
      );
    }
    return TransferOutgoingSendFailureDecision(
      action: TransferOutgoingSendFailureAction.retry,
      attemptsAfterFailure: attemptsAfterFailure,
      shouldReduceWindow: !isRetransmission,
    );
  }
}
