import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_route_context_command.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferDataFrameRouteContextCommand', () {
    test('allows incoming route only when incoming context exists', () {
      expect(
        TransferDataFrameRouteContextCommand.allows(
          expectedDirection: TransferDirection.incoming,
          hasIncomingContext: true,
          hasOutgoingContext: false,
        ),
        isTrue,
      );
      expect(
        TransferDataFrameRouteContextCommand.allows(
          expectedDirection: TransferDirection.incoming,
          hasIncomingContext: false,
          hasOutgoingContext: true,
        ),
        isFalse,
      );
    });

    test('allows outgoing route only when outgoing context exists', () {
      expect(
        TransferDataFrameRouteContextCommand.allows(
          expectedDirection: TransferDirection.outgoing,
          hasIncomingContext: false,
          hasOutgoingContext: true,
        ),
        isTrue,
      );
      expect(
        TransferDataFrameRouteContextCommand.allows(
          expectedDirection: TransferDirection.outgoing,
          hasIncomingContext: true,
          hasOutgoingContext: false,
        ),
        isFalse,
      );
    });
  });
}
