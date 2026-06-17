import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_ack_retry_schedule_command.dart';

void main() {
  group('TransferIncomingAckRetryScheduleCommand', () {
    test('flushes ack when enqueue reaches threshold', () {
      expect(
        TransferIncomingAckRetryScheduleCommand.shouldFlushAfterAckEnqueue(
          pendingAckCountBeforeEnqueue: 3,
          ackBatchThreshold: 4,
          nextExpectedChunk: 1,
          expectedChunkCount: 10,
        ),
        isTrue,
      );
    });

    test('flushes ack when receive window reaches the final chunk', () {
      expect(
        TransferIncomingAckRetryScheduleCommand.shouldFlushAfterAckEnqueue(
          pendingAckCountBeforeEnqueue: 0,
          ackBatchThreshold: 4,
          nextExpectedChunk: 10,
          expectedChunkCount: 10,
        ),
        isTrue,
      );
    });

    test('does not flush ack before threshold or completion', () {
      expect(
        TransferIncomingAckRetryScheduleCommand.shouldFlushAfterAckEnqueue(
          pendingAckCountBeforeEnqueue: 1,
          ackBatchThreshold: 4,
          nextExpectedChunk: 5,
          expectedChunkCount: 10,
        ),
        isFalse,
      );
    });

    test('schedules data ack retry only when timer is absent', () {
      expect(
        TransferIncomingAckRetryScheduleCommand.shouldScheduleDataAckRetry(
          hasAckFlushTimer: false,
        ),
        isTrue,
      );
      expect(
        TransferIncomingAckRetryScheduleCommand.shouldScheduleDataAckRetry(
          hasAckFlushTimer: true,
        ),
        isFalse,
      );
    });

    test(
      'schedules missing nack retry only for buffered chunks without timer',
      () {
        expect(
          TransferIncomingAckRetryScheduleCommand.shouldScheduleMissingNackRetry(
            bufferedChunkCount: 1,
            hasMissingNackRetryTimer: false,
          ),
          isTrue,
        );
        expect(
          TransferIncomingAckRetryScheduleCommand.shouldScheduleMissingNackRetry(
            bufferedChunkCount: 0,
            hasMissingNackRetryTimer: false,
          ),
          isFalse,
        );
        expect(
          TransferIncomingAckRetryScheduleCommand.shouldScheduleMissingNackRetry(
            bufferedChunkCount: 1,
            hasMissingNackRetryTimer: true,
          ),
          isFalse,
        );
      },
    );

    test('controller delegates ack retry scheduling decisions to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('shouldFlushAfterAckEnqueue'));
      expect(source, contains('shouldScheduleDataAckRetry'));
      expect(source, contains('shouldScheduleMissingNackRetry'));
    });
  });
}
