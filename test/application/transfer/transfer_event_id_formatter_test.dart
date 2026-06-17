import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_event_id_formatter.dart';

void main() {
  group('TransferEventIdFormatter', () {
    test('formats prefix with explicit timestamp micros', () {
      final now = DateTime.fromMicrosecondsSinceEpoch(123456789);

      expect(
        TransferEventIdFormatter.format(prefix: 'transfer-completed', now: now),
        'transfer-completed-123456789',
      );
    });
  });
}
