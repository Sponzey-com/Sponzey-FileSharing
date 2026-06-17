import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferDataFrameRouteContextCommand {
  const TransferDataFrameRouteContextCommand._();

  static bool allows({
    required TransferDirection expectedDirection,
    required bool hasIncomingContext,
    required bool hasOutgoingContext,
  }) {
    switch (expectedDirection) {
      case TransferDirection.incoming:
        return hasIncomingContext;
      case TransferDirection.outgoing:
        return hasOutgoingContext;
    }
  }
}
