import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';

class TransferOutgoingRouteLeaseDecision {
  const TransferOutgoingRouteLeaseDecision({required this.isValid});

  final bool isValid;
}

class TransferOutgoingRouteLeaseCommand {
  const TransferOutgoingRouteLeaseCommand._();

  static TransferOutgoingRouteLeaseDecision validate({
    required String expectedRouteLeaseId,
    required String? currentRouteLeaseId,
    required PeerPathStatus? currentStatus,
  }) {
    return TransferOutgoingRouteLeaseDecision(
      isValid:
          currentRouteLeaseId == expectedRouteLeaseId &&
          currentStatus == PeerPathStatus.active,
    );
  }
}
