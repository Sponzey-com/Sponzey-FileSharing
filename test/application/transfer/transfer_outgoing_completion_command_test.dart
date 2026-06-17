import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_completion_command.dart';

void main() {
  group('TransferOutgoingCompletionCommand', () {
    test('completes only when all chunks are acked and none are in-flight', () {
      expect(
        TransferOutgoingCompletionCommand.shouldComplete(
          isAlreadyCompleted: false,
          acknowledgedChunkCount: 4,
          chunkCount: 4,
          inFlightChunkCount: 0,
        ),
        isTrue,
      );
      expect(
        TransferOutgoingCompletionCommand.shouldComplete(
          isAlreadyCompleted: false,
          acknowledgedChunkCount: 3,
          chunkCount: 4,
          inFlightChunkCount: 0,
        ),
        isFalse,
      );
      expect(
        TransferOutgoingCompletionCommand.shouldComplete(
          isAlreadyCompleted: false,
          acknowledgedChunkCount: 4,
          chunkCount: 4,
          inFlightChunkCount: 1,
        ),
        isFalse,
      );
    });

    test('does not complete twice', () {
      expect(
        TransferOutgoingCompletionCommand.shouldComplete(
          isAlreadyCompleted: true,
          acknowledgedChunkCount: 4,
          chunkCount: 4,
          inFlightChunkCount: 0,
        ),
        isFalse,
      );
    });

    test('controller delegates outgoing completion decision to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingCompletionCommand'));
      expect(
        source,
        isNot(
          contains(
            'context.acknowledgedChunks.length == context.preparedFile.chunkCount',
          ),
        ),
      );
    });
  });
}
