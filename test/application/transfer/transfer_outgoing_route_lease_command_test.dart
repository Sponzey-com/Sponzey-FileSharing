import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_route_lease_command.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';

void main() {
  group('TransferOutgoingRouteLeaseCommand', () {
    test('validates active matching route lease', () {
      final decision = TransferOutgoingRouteLeaseCommand.validate(
        expectedRouteLeaseId: 'path-a',
        currentRouteLeaseId: 'path-a',
        currentStatus: PeerPathStatus.active,
      );

      expect(decision.isValid, isTrue);
      expect(decision.reasonCode, isNull);
      expect(decision.message, isNull);
    });

    test('accepts refreshed active route for same interface and addresses', () {
      final decision = TransferOutgoingRouteLeaseCommand.validate(
        expectedRouteLeaseId:
            'path:peer|en0|10.211.55.3|10.211.55.2:62237|specificAddress',
        currentRouteLeaseId:
            'path:peer|en0|10.211.55.3|10.211.55.2:62280|specificAddress',
        currentStatus: PeerPathStatus.active,
        expectedLocalInterfaceId: 'en0',
        currentLocalInterfaceId: 'en0',
        expectedLocalAddress: '10.211.55.3',
        currentLocalAddress: '10.211.55.3',
        expectedRemoteAddress: '10.211.55.2',
        currentRemoteAddress: '10.211.55.2',
      );

      expect(decision.isValid, isTrue);
      expect(decision.reasonCode, isNull);
      expect(decision.message, isNull);
    });

    test('rejects missing or inactive route lease with expired reason', () {
      final missing = TransferOutgoingRouteLeaseCommand.validate(
        expectedRouteLeaseId: 'path-a',
        currentRouteLeaseId: null,
        currentStatus: null,
      );
      final inactive = TransferOutgoingRouteLeaseCommand.validate(
        expectedRouteLeaseId: 'path-a',
        currentRouteLeaseId: 'path-a',
        currentStatus: PeerPathStatus.probing,
      );

      expect(missing.isValid, isFalse);
      expect(missing.reasonCode, 'routeInactive');
      expect(missing.message, contains('연결 경로가 만료'));
      expect(inactive.isValid, isFalse);
      expect(inactive.reasonCode, 'routeInactive');
      expect(inactive.message, contains('연결 경로가 만료'));
    });

    test('rejects changed route lease with changed reason', () {
      final changedWithoutDetails = TransferOutgoingRouteLeaseCommand.validate(
        expectedRouteLeaseId: 'path-a',
        currentRouteLeaseId: 'path-b',
        currentStatus: PeerPathStatus.active,
      );
      final changedRemote = TransferOutgoingRouteLeaseCommand.validate(
        expectedRouteLeaseId: 'path-a',
        currentRouteLeaseId: 'path-b',
        currentStatus: PeerPathStatus.active,
        expectedLocalInterfaceId: 'en0',
        currentLocalInterfaceId: 'en0',
        expectedLocalAddress: '10.211.55.3',
        currentLocalAddress: '10.211.55.3',
        expectedRemoteAddress: '10.211.55.2',
        currentRemoteAddress: '192.168.0.10',
      );

      expect(changedWithoutDetails.isValid, isFalse);
      expect(changedWithoutDetails.reasonCode, 'routeChanged');
      expect(changedWithoutDetails.message, contains('연결 경로가 변경'));
      expect(changedRemote.isValid, isFalse);
      expect(changedRemote.reasonCode, 'routeChanged');
      expect(changedRemote.message, contains('연결 경로가 변경'));
    });

    test('controller delegates route lease validation to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingRouteLeaseCommand'));
      expect(
        source,
        isNot(
          contains('current?.pathId == context.routeSnapshot.routeLeaseId'),
        ),
      );
    });
  });
}
