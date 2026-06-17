import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_ack_indexes_command.dart';

void main() {
  group('TransferOutgoingAckIndexesCommand', () {
    test('always includes primary acknowledged chunk', () {
      final indexes = TransferOutgoingAckIndexesCommand.decode(
        primaryChunkIndex: 12,
        ackBase: 40,
        ackBitmapWords: const [],
      );

      expect(indexes, {12});
    });

    test('decodes ACK bitmap words into absolute chunk indexes', () {
      final indexes = TransferOutgoingAckIndexesCommand.decode(
        primaryChunkIndex: 3,
        ackBase: 20,
        ackBitmapWords: const [5, 2],
      );

      expect(indexes, {3, 20, 22, 53});
    });

    test('deduplicates primary ACK if bitmap includes the same chunk', () {
      final indexes = TransferOutgoingAckIndexesCommand.decode(
        primaryChunkIndex: 20,
        ackBase: 20,
        ackBitmapWords: const [1],
      );

      expect(indexes, {20});
    });

    test('controller delegates Data ACK index decoding to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingAckIndexesCommand'));
      expect(source, isNot(contains('Set<int> _chunkIndexesFromAckFrame')));
    });
  });
}
