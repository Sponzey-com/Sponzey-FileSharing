import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_endpoint_label_formatter.dart';

void main() {
  group('TransferEndpointLabelFormatter', () {
    test('returns any when endpoint fields are absent', () {
      expect(
        TransferEndpointLabelFormatter.format(
          localAddress: null,
          port: null,
          bindModeName: null,
        ),
        'any',
      );
    });

    test('formats endpoint fields with existing label shape', () {
      expect(
        TransferEndpointLabelFormatter.format(
          localAddress: '10.211.55.2',
          port: 23200,
          bindModeName: 'interface',
        ),
        '10.211.55.2:23200/interface',
      );
    });
  });
}
