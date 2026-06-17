import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_window_command.dart';

void main() {
  group('TransferIncomingWindowCommand', () {
    test('subtracts buffered chunks from advertised window', () {
      final windowSize = TransferIncomingWindowCommand.receiverWindowSize(
        advertisedWindowSize: 32,
        bufferedChunkCount: 7,
      );

      expect(windowSize, 25);
    });

    test('keeps at least one receive window slot available', () {
      expect(
        TransferIncomingWindowCommand.receiverWindowSize(
          advertisedWindowSize: 4,
          bufferedChunkCount: 4,
        ),
        1,
      );
      expect(
        TransferIncomingWindowCommand.receiverWindowSize(
          advertisedWindowSize: 4,
          bufferedChunkCount: 99,
        ),
        1,
      );
    });

    test('controller delegates receiver window calculation to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferIncomingWindowCommand'));
      expect(source, isNot(contains('int _receiverWindowSize')));
    });
  });
}
