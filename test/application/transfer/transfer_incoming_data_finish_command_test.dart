import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_data_finish_command.dart';

void main() {
  test(
    'returns ready when all chunks are contiguous and no buffer remains',
    () {
      final decision = TransferIncomingDataFinishCommand.decide(
        nextExpectedChunk: 4,
        expectedChunkCount: 4,
        acknowledgedChunks: const {0, 1, 2, 3},
        bufferedChunkCount: 0,
        missingLimit: 8,
      );

      expect(decision.action, TransferIncomingDataFinishAction.readyToFinalize);
      expect(decision.missingIndexes, isEmpty);
    },
  );

  test('returns limited missing indexes when chunks are incomplete', () {
    final decision = TransferIncomingDataFinishCommand.decide(
      nextExpectedChunk: 2,
      expectedChunkCount: 8,
      acknowledgedChunks: const {0, 1, 4, 7},
      bufferedChunkCount: 0,
      missingLimit: 3,
    );

    expect(decision.action, TransferIncomingDataFinishAction.waitForMissing);
    expect(decision.missingIndexes, [2, 3, 5]);
  });

  test(
    'waits when buffered chunks remain even if next expected reached end',
    () {
      final decision = TransferIncomingDataFinishCommand.decide(
        nextExpectedChunk: 4,
        expectedChunkCount: 4,
        acknowledgedChunks: const {0, 1, 2, 3},
        bufferedChunkCount: 1,
        missingLimit: 8,
      );

      expect(decision.action, TransferIncomingDataFinishAction.waitForMissing);
      expect(decision.missingIndexes, isEmpty);
    },
  );

  test('command stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_incoming_data_finish_command.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });

  test(
    'TransferController does not duplicate finish readiness condition',
    () async {
      final source = await File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsString();

      expect(
        source,
        isNot(
          contains('context.nextExpectedChunk != context.expectedChunkCount'),
        ),
      );
      expect(source, isNot(contains('context.bufferedChunks.isNotEmpty')));
    },
  );
}
