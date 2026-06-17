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
    });

    test('rejects missing, mismatched, or inactive route lease', () {
      expect(
        TransferOutgoingRouteLeaseCommand.validate(
          expectedRouteLeaseId: 'path-a',
          currentRouteLeaseId: null,
          currentStatus: null,
        ).isValid,
        isFalse,
      );
      expect(
        TransferOutgoingRouteLeaseCommand.validate(
          expectedRouteLeaseId: 'path-a',
          currentRouteLeaseId: 'path-b',
          currentStatus: PeerPathStatus.active,
        ).isValid,
        isFalse,
      );
      expect(
        TransferOutgoingRouteLeaseCommand.validate(
          expectedRouteLeaseId: 'path-a',
          currentRouteLeaseId: 'path-a',
          currentStatus: PeerPathStatus.probing,
        ).isValid,
        isFalse,
      );
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
