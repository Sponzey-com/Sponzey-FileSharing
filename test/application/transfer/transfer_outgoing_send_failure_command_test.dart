import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_send_failure_command.dart';

void main() {
  group('TransferOutgoingSendFailureCommand', () {
    test('increments attempt only for retransmission before send', () {
      expect(
        TransferOutgoingSendFailureCommand.nextSendAttempt(
          currentAttempts: 2,
          isRetransmission: true,
        ),
        3,
      );
      expect(
        TransferOutgoingSendFailureCommand.nextSendAttempt(
          currentAttempts: 2,
          isRetransmission: false,
        ),
        2,
      );
    });

    test('marks retry exhausted when next attempt exceeds max', () {
      final decision = TransferOutgoingSendFailureCommand.onRetryableFailure(
        nextAttempts: 5,
        recordedAttempts: 5,
        maxRetransmissions: 5,
        isRetransmission: true,
      );

      expect(decision.action, TransferOutgoingSendFailureAction.exhausted);
      expect(decision.attemptsAfterFailure, 6);
      expect(decision.shouldReduceWindow, isFalse);
    });

    test('retryable first-send failure schedules retry and reduces window', () {
      final decision = TransferOutgoingSendFailureCommand.onRetryableFailure(
        nextAttempts: 0,
        recordedAttempts: 0,
        maxRetransmissions: 5,
        isRetransmission: false,
      );

      expect(decision.action, TransferOutgoingSendFailureAction.retry);
      expect(decision.attemptsAfterFailure, 1);
      expect(decision.shouldReduceWindow, isTrue);
    });

    test(
      'retryable retransmission failure keeps window reduction external',
      () {
        final decision = TransferOutgoingSendFailureCommand.onRetryableFailure(
          nextAttempts: 2,
          recordedAttempts: 1,
          maxRetransmissions: 5,
          isRetransmission: true,
        );

        expect(decision.action, TransferOutgoingSendFailureAction.retry);
        expect(decision.attemptsAfterFailure, 2);
        expect(decision.shouldReduceWindow, isFalse);
      },
    );

    test('controller delegates retryable send failure decision to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingSendFailureCommand'));
      expect(source, isNot(contains('attemptsAfterFailure = max(')));
    });
  });
}
