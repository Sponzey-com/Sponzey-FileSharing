import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_next_chunk_command.dart';

void main() {
  group('TransferOutgoingNextChunkCommand', () {
    test('selects eligible retransmission before sequential chunk', () {
      final decision = TransferOutgoingNextChunkCommand.decide(
        retransmissionCandidate: 4,
        nextChunkToSend: 2,
        chunkCount: 10,
        remoteWindowStart: 2,
        advertisedWindowSize: 4,
        acknowledgedChunks: const {},
        inFlightChunks: const {},
      );

      expect(decision.chunkIndex, 4);
      expect(decision.nextChunkToSend, 2);
      expect(decision.isRetransmission, isTrue);
    });

    test(
      'does not select retransmission already acknowledged or in-flight',
      () {
        expect(
          TransferOutgoingNextChunkCommand.decide(
            retransmissionCandidate: 4,
            nextChunkToSend: 2,
            chunkCount: 10,
            remoteWindowStart: 2,
            advertisedWindowSize: 4,
            acknowledgedChunks: const {4},
            inFlightChunks: const {},
          ).chunkIndex,
          2,
        );
        expect(
          TransferOutgoingNextChunkCommand.decide(
            retransmissionCandidate: 4,
            nextChunkToSend: 2,
            chunkCount: 10,
            remoteWindowStart: 2,
            advertisedWindowSize: 4,
            acknowledgedChunks: const {},
            inFlightChunks: const {4},
          ).chunkIndex,
          2,
        );
      },
    );

    test('blocks sequential sends outside remote advertised window', () {
      final decision = TransferOutgoingNextChunkCommand.decide(
        retransmissionCandidate: null,
        nextChunkToSend: 6,
        chunkCount: 10,
        remoteWindowStart: 2,
        advertisedWindowSize: 4,
        acknowledgedChunks: const {},
        inFlightChunks: const {},
      );

      expect(decision.chunkIndex, isNull);
      expect(decision.nextChunkToSend, 6);
    });

    test('skips acknowledged and in-flight sequential chunks', () {
      final decision = TransferOutgoingNextChunkCommand.decide(
        retransmissionCandidate: null,
        nextChunkToSend: 0,
        chunkCount: 8,
        remoteWindowStart: 0,
        advertisedWindowSize: 8,
        acknowledgedChunks: const {0, 2},
        inFlightChunks: const {1},
      );

      expect(decision.chunkIndex, 3);
      expect(decision.nextChunkToSend, 4);
      expect(decision.isRetransmission, isFalse);
    });

    test('controller delegates next chunk selection to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingNextChunkCommand'));
      expect(
        source,
        isNot(
          contains(
            'context.remoteWindowStart + max(1, context.advertisedWindowSize)',
          ),
        ),
      );
    });
  });
}
