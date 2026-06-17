import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_active_route_validation_command.dart';

void main() {
  group('TransferActiveRouteValidationCommand', () {
    test('accepts a valid non-loopback transfer route', () {
      final decision = TransferActiveRouteValidationCommand.validate(
        controlLocalAddress: '10.211.55.2',
        routeRemoteAddress: '10.211.55.3',
        routeRemotePort: 38401,
        sessionPeerAddress: '10.211.55.3',
      );

      expect(decision.isValid, isTrue);
      expect(decision.code, isNull);
      expect(decision.message, isNull);
    });

    test('rejects missing endpoint fields', () {
      final cases = [
        ('', '10.211.55.3', 38401),
        ('10.211.55.2', '', 38401),
        ('10.211.55.2', '10.211.55.3', 0),
      ];

      for (final (local, remote, port) in cases) {
        final decision = TransferActiveRouteValidationCommand.validate(
          controlLocalAddress: local,
          routeRemoteAddress: remote,
          routeRemotePort: port,
          sessionPeerAddress: '10.211.55.3',
        );

        expect(decision.isValid, isFalse, reason: '$local/$remote/$port');
        expect(decision.code, 'transfer_active_route_invalid');
        expect(decision.message, '연결 경로의 endpoint 정보가 올바르지 않습니다.');
      }
    });

    test('rejects loopback route for an external peer session', () {
      final decision = TransferActiveRouteValidationCommand.validate(
        controlLocalAddress: '127.0.0.1',
        routeRemoteAddress: '127.0.0.1',
        routeRemotePort: 38401,
        sessionPeerAddress: '10.211.55.3',
      );

      expect(decision.isValid, isFalse);
      expect(decision.code, 'transfer_loopback_route_mismatch');
      expect(decision.message, '외부 피어 전송에는 loopback 경로를 사용할 수 없습니다.');
    });

    test('accepts loopback route for a loopback peer session', () {
      final decision = TransferActiveRouteValidationCommand.validate(
        controlLocalAddress: '127.0.0.1',
        routeRemoteAddress: '127.0.0.1',
        routeRemotePort: 38401,
        sessionPeerAddress: 'localhost',
      );

      expect(decision.isValid, isTrue);
    });
  });
}
