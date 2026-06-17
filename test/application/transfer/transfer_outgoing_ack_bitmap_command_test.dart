import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_ack_bitmap_command.dart';

void main() {
  group('TransferOutgoingAckBitmapCommand', () {
    test('returns empty packet fields for empty chunk indexes', () {
      final packet = TransferOutgoingAckBitmapCommand.build(
        chunkIndexes: const [],
      );

      expect(packet.chunkIndexes, isEmpty);
      expect(packet.primaryChunkIndex, isNull);
      expect(packet.ackBase, isNull);
      expect(packet.ackBitmapWords, isEmpty);
    });

    test('sorts, deduplicates, and builds bitmap words', () {
      final packet = TransferOutgoingAckBitmapCommand.build(
        chunkIndexes: const [53, 20, 20, 22, 3],
      );

      expect(packet.chunkIndexes, [3, 20, 22, 53]);
      expect(packet.primaryChunkIndex, 3);
      expect(packet.ackBase, 3);
      expect(packet.ackBitmapWords.length, 2);
      expect(packet.ackBitmapWords[0], (1 << 0) | (1 << 17) | (1 << 19));
      expect(packet.ackBitmapWords[1], 1 << 18);
    });

    test('controller delegates ACK bitmap creation to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingAckBitmapCommand'));
      expect(source, isNot(contains('List<int> _bitmapWordsFor')));
    });
  });
}
