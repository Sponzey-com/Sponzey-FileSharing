import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_bind_endpoint_route_command.dart';

void main() {
  group('TransferDataBindEndpointRouteCommand', () {
    test('accepts wildcard bind mode', () {
      final decision = TransferDataBindEndpointRouteCommand.validate(
        routeLocalAddress: '10.211.55.2',
        bindLocalAddress: '192.168.0.236',
        isWildcardBind: true,
      );

      expect(decision.isValid, isTrue);
      expect(decision.message, isNull);
    });

    test('accepts wildcard bind addresses', () {
      for (final address in ['0.0.0.0', '::', '0:0:0:0:0:0:0:0']) {
        final decision = TransferDataBindEndpointRouteCommand.validate(
          routeLocalAddress: '10.211.55.2',
          bindLocalAddress: address,
          isWildcardBind: false,
        );

        expect(decision.isValid, isTrue, reason: address);
        expect(decision.message, isNull, reason: address);
      }
    });

    test('accepts the same route and bind local address', () {
      final decision = TransferDataBindEndpointRouteCommand.validate(
        routeLocalAddress: ' Host.Local ',
        bindLocalAddress: 'host.local',
        isWildcardBind: false,
      );

      expect(decision.isValid, isTrue);
      expect(decision.message, isNull);
    });

    test('rejects bind local address mismatch', () {
      final decision = TransferDataBindEndpointRouteCommand.validate(
        routeLocalAddress: '10.211.55.2',
        bindLocalAddress: '0.0.0.1',
        isWildcardBind: false,
      );

      expect(decision.isValid, isFalse);
      expect(
        decision.message,
        'Data socket local address가 검증된 연결 경로와 다릅니다. '
        'route=10.211.55.2, data=0.0.0.1',
      );
    });
  });
}
