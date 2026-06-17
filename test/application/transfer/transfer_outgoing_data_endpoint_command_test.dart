import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_data_endpoint_command.dart';

void main() {
  group('TransferOutgoingDataEndpointCommand', () {
    test('rejects missing or empty address', () {
      expect(
        TransferOutgoingDataEndpointCommand.validate(
          address: null,
          port: 23200,
        ).isValid,
        isFalse,
      );
      expect(
        TransferOutgoingDataEndpointCommand.validate(
          address: ' ',
          port: 23200,
        ).isValid,
        isFalse,
      );
    });

    test('rejects missing or invalid port', () {
      expect(
        TransferOutgoingDataEndpointCommand.validate(
          address: '10.211.55.3',
          port: null,
        ).isValid,
        isFalse,
      );
      expect(
        TransferOutgoingDataEndpointCommand.validate(
          address: '10.211.55.3',
          port: 0,
        ).isValid,
        isFalse,
      );
    });

    test('accepts valid endpoint primitive values', () {
      final decision = TransferOutgoingDataEndpointCommand.validate(
        address: '10.211.55.3',
        port: 23200,
      );

      expect(decision.isValid, isTrue);
      expect(decision.address, '10.211.55.3');
      expect(decision.port, 23200);
    });

    test('controller delegates data endpoint validation to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingDataEndpointCommand'));
      expect(
        source,
        isNot(contains('remoteAddress == null || remotePort == null')),
      );
    });
  });
}
