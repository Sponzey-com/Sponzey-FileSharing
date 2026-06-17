import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_random_hex_formatter.dart';

void main() {
  group('TransferRandomHexFormatter', () {
    test('formats bytes as two-character lowercase hex', () {
      expect(
        TransferRandomHexFormatter.formatBytes([0, 1, 15, 16, 255]),
        '00010f10ff',
      );
    });

    test('formats empty bytes as an empty string', () {
      expect(TransferRandomHexFormatter.formatBytes(const []), '');
    });

    test('controller delegates byte to hex formatting to formatter', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferRandomHexFormatter.formatBytes'));
      expect(source, isNot(contains("toRadixString(16).padLeft(2, '0')")));
    });
  });
}
