import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_remote_data_endpoint_route_command.dart';

void main() {
  group('TransferOutgoingRemoteDataEndpointRouteCommand', () {
    test('accepts the same route and data remote address', () {
      final decision = TransferOutgoingRemoteDataEndpointRouteCommand.validate(
        routeRemoteAddress: '10.211.55.3',
        dataRemoteAddress: '10.211.55.3',
      );

      expect(decision.isValid, isTrue);
      expect(decision.message, isNull);
    });

    test('normalizes whitespace and case before comparing addresses', () {
      final decision = TransferOutgoingRemoteDataEndpointRouteCommand.validate(
        routeRemoteAddress: ' Host.Local ',
        dataRemoteAddress: 'host.local',
      );

      expect(decision.isValid, isTrue);
      expect(decision.message, isNull);
    });

    test('rejects a data remote address that differs from the route', () {
      final decision = TransferOutgoingRemoteDataEndpointRouteCommand.validate(
        routeRemoteAddress: '10.211.55.3',
        dataRemoteAddress: '192.168.0.236',
      );

      expect(decision.isValid, isFalse);
      expect(
        decision.message,
        'Data endpoint가 검증된 연결 경로와 다릅니다. '
        'route=10.211.55.3, data=192.168.0.236',
      );
    });
  });
}
