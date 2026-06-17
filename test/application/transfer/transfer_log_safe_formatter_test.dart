import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_log_safe_formatter.dart';

void main() {
  group('TransferLogSafeFormatter', () {
    test('limits session id to eight characters', () {
      expect(TransferLogSafeFormatter.session('12345678'), '12345678');
      expect(TransferLogSafeFormatter.session('1234567890'), '12345678');
    });

    test('formats transfer id safely', () {
      expect(TransferLogSafeFormatter.transfer(null), '-');
      expect(TransferLogSafeFormatter.transfer(''), '-');
      expect(TransferLogSafeFormatter.transfer('abcdef'), 'abcdef');
      expect(TransferLogSafeFormatter.transfer('abcdefghijk'), 'abcdefgh');
    });

    test('keeps only basename for POSIX and Windows paths', () {
      expect(
        TransferLogSafeFormatter.fileName('/Users/me/Documents/a.pdf'),
        'a.pdf',
      );
      expect(
        TransferLogSafeFormatter.fileName(r'C:\Users\me\Documents\b.pdf'),
        'b.pdf',
      );
    });

    test('uses dash for empty file name', () {
      expect(TransferLogSafeFormatter.fileName('   '), '-');
    });

    test('truncates long basename to eighty visible characters', () {
      final value = TransferLogSafeFormatter.fileName('${'a' * 100}.pdf');

      expect(value.length, 80);
      expect(value.endsWith('...'), isTrue);
    });
  });
}
