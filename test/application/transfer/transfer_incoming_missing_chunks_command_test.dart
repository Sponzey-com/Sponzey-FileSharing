import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_missing_chunks_command.dart';

void main() {
  group('TransferIncomingMissingChunksCommand', () {
    test('finds missing chunks before highest received index', () {
      final missing = TransferIncomingMissingChunksCommand.untilHighestReceived(
        nextExpectedChunk: 3,
        highestReceivedIndex: 8,
        acknowledgedChunks: {3, 5, 7, 8},
        limit: 8,
      );

      expect(missing, [4, 6]);
    });

    test('respects missing chunk limit', () {
      final missing = TransferIncomingMissingChunksCommand.untilHighestReceived(
        nextExpectedChunk: 0,
        highestReceivedIndex: 10,
        acknowledgedChunks: {0},
        limit: 3,
      );

      expect(missing, [1, 2, 3]);
    });

    test('finds remaining missing chunks until expected chunk count', () {
      final missing = TransferIncomingMissingChunksCommand.remaining(
        nextExpectedChunk: 4,
        expectedChunkCount: 10,
        acknowledgedChunks: {4, 6, 9},
        limit: 8,
      );

      expect(missing, [5, 7, 8]);
    });

    test('returns no missing chunks for empty or reversed ranges', () {
      expect(
        TransferIncomingMissingChunksCommand.untilHighestReceived(
          nextExpectedChunk: 5,
          highestReceivedIndex: 5,
          acknowledgedChunks: const {},
          limit: 8,
        ),
        isEmpty,
      );
      expect(
        TransferIncomingMissingChunksCommand.remaining(
          nextExpectedChunk: 10,
          expectedChunkCount: 8,
          acknowledgedChunks: const {},
          limit: 8,
        ),
        isEmpty,
      );
    });

    test('controller delegates missing index calculation to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferIncomingMissingChunksCommand'));
      expect(source, isNot(contains('List<int> _missingIndexesUntil')));
      expect(source, isNot(contains('List<int> _remainingMissingIndexes')));
    });
  });
}
