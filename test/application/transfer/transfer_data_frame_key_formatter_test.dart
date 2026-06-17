import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_key_formatter.dart';

void main() {
  group('TransferDataFrameKeyFormatter', () {
    test('formats transfer id bytes with base64Url encoding', () {
      final bytes = Uint8List.fromList([1, 2, 3, 250, 251, 252]);

      expect(
        TransferDataFrameKeyFormatter.format(bytes),
        base64Url.encode(bytes),
      );
    });

    test('returns stable keys for equal byte sequences', () {
      final left = Uint8List.fromList([9, 8, 7, 6]);
      final right = Uint8List.fromList([9, 8, 7, 6]);

      expect(
        TransferDataFrameKeyFormatter.format(left),
        TransferDataFrameKeyFormatter.format(right),
      );
    });
  });
}
