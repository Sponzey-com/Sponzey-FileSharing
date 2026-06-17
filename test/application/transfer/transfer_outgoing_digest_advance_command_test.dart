import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_digest_advance_command.dart';

void main() {
  group('TransferOutgoingDigestAdvanceCommand', () {
    test('advances digest for in-order first send chunk', () {
      final decision = TransferOutgoingDigestAdvanceCommand.decide(
        isRetransmission: false,
        chunkIndex: 4,
        nextDigestChunk: 4,
      );

      expect(decision.shouldAppendToDigest, isTrue);
      expect(decision.nextDigestChunk, 5);
    });

    test('does not advance digest for retransmission', () {
      final decision = TransferOutgoingDigestAdvanceCommand.decide(
        isRetransmission: true,
        chunkIndex: 4,
        nextDigestChunk: 4,
      );

      expect(decision.shouldAppendToDigest, isFalse);
      expect(decision.nextDigestChunk, 4);
    });

    test('does not advance digest for out-of-order first send chunk', () {
      final decision = TransferOutgoingDigestAdvanceCommand.decide(
        isRetransmission: false,
        chunkIndex: 6,
        nextDigestChunk: 4,
      );

      expect(decision.shouldAppendToDigest, isFalse);
      expect(decision.nextDigestChunk, 4);
    });

    test('controller delegates digest advance decision to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingDigestAdvanceCommand'));
      expect(source, isNot(contains('chunkIndex == context.nextDigestChunk')));
    });
  });
}
