import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_retransmission_scan_command.dart';

void main() {
  group('TransferOutgoingRetransmissionScanCommand', () {
    test('separates acknowledged cleanup and timed-out retransmissions', () {
      final now = DateTime(2026, 1, 1, 12);
      final decision = TransferOutgoingRetransmissionScanCommand.scan(
        now: now,
        timeout: const Duration(milliseconds: 100),
        inFlightChunks: const {1, 2, 3, 4},
        acknowledgedChunks: const {1},
        sentAtByChunk: {
          2: now.subtract(const Duration(milliseconds: 101)),
          3: now.subtract(const Duration(milliseconds: 99)),
        },
      );

      expect(decision.acknowledgedInFlightIndexes, [1]);
      expect(decision.timedOutIndexes, [2]);
      expect(decision.retainedInFlightIndexes, [3, 4]);
    });

    test('does not time out chunks without sentAt', () {
      final now = DateTime(2026, 1, 1, 12);
      final decision = TransferOutgoingRetransmissionScanCommand.scan(
        now: now,
        timeout: const Duration(milliseconds: 100),
        inFlightChunks: const {4},
        acknowledgedChunks: const {},
        sentAtByChunk: const {},
      );

      expect(decision.timedOutIndexes, isEmpty);
      expect(decision.retainedInFlightIndexes, [4]);
    });

    test('controller delegates retransmission timeout scan to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingRetransmissionScanCommand'));
      expect(source, isNot(contains('now.difference(sentAt) < timeout')));
    });
  });
}
