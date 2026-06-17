import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_retryable_send_failure_command.dart';

void main() {
  group('TransferOutgoingRetryableSendFailureCommand', () {
    test('accepts known retryable send error codes', () {
      expect(
        TransferOutgoingRetryableSendFailureCommand.isRetryable('sendFailed'),
        isTrue,
      );
      expect(
        TransferOutgoingRetryableSendFailureCommand.isRetryable('partialSend'),
        isTrue,
      );
      expect(
        TransferOutgoingRetryableSendFailureCommand.isRetryable(
          'data_frame_send_failed',
        ),
        isTrue,
      );
    });

    test('rejects non-retryable send error codes', () {
      expect(
        TransferOutgoingRetryableSendFailureCommand.isRetryable(
          'transfer_data_endpoint_missing',
        ),
        isFalse,
      );
      expect(
        TransferOutgoingRetryableSendFailureCommand.isRetryable(''),
        isFalse,
      );
    });

    test('controller delegates retryable send failure decision to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingRetryableSendFailureCommand'));
      expect(source, isNot(contains('bool _isRetryableDataFrameSendFailure')));
    });
  });
}
