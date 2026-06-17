import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_window_reduction_command.dart';

void main() {
  group('TransferOutgoingWindowReductionCommand', () {
    test('halves outgoing window size', () {
      expect(TransferOutgoingWindowReductionCommand.reduce(24), 12);
      expect(TransferOutgoingWindowReductionCommand.reduce(25), 12);
    });

    test('keeps minimum outgoing window size at one', () {
      expect(TransferOutgoingWindowReductionCommand.reduce(1), 1);
      expect(TransferOutgoingWindowReductionCommand.reduce(0), 1);
    });

    test('controller delegates window reduction to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingWindowReductionCommand'));
      expect(
        source,
        isNot(contains('context.windowSize = max(1, context.windowSize ~/ 2)')),
      );
    });
  });
}
