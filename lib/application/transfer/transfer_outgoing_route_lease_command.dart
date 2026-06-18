import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';

class TransferOutgoingRouteLeaseDecision {
  const TransferOutgoingRouteLeaseDecision._({
    required this.isValid,
    this.reasonCode,
    this.message,
  });

  const TransferOutgoingRouteLeaseDecision.valid() : this._(isValid: true);

  const TransferOutgoingRouteLeaseDecision.invalid({
    required String reasonCode,
    required String message,
  }) : this._(isValid: false, reasonCode: reasonCode, message: message);

  final bool isValid;
  final String? reasonCode;
  final String? message;
}

class TransferOutgoingRouteLeaseCommand {
  const TransferOutgoingRouteLeaseCommand._();

  static TransferOutgoingRouteLeaseDecision validate({
    required String expectedRouteLeaseId,
    required String? currentRouteLeaseId,
    required PeerPathStatus? currentStatus,
    String? expectedLocalInterfaceId,
    String? currentLocalInterfaceId,
    String? expectedLocalAddress,
    String? currentLocalAddress,
    String? expectedRemoteAddress,
    String? currentRemoteAddress,
  }) {
    if (currentStatus != PeerPathStatus.active) {
      return const TransferOutgoingRouteLeaseDecision.invalid(
        reasonCode: 'routeInactive',
        message: '전송 중 연결 경로가 만료되어 전송을 중단했습니다.',
      );
    }
    if (currentRouteLeaseId == expectedRouteLeaseId) {
      return const TransferOutgoingRouteLeaseDecision.valid();
    }
    final sameRoute = _sameRoute(
      expectedLocalInterfaceId: expectedLocalInterfaceId,
      currentLocalInterfaceId: currentLocalInterfaceId,
      expectedLocalAddress: expectedLocalAddress,
      currentLocalAddress: currentLocalAddress,
      expectedRemoteAddress: expectedRemoteAddress,
      currentRemoteAddress: currentRemoteAddress,
    );
    if (sameRoute) {
      return const TransferOutgoingRouteLeaseDecision.valid();
    }
    return const TransferOutgoingRouteLeaseDecision.invalid(
      reasonCode: 'routeChanged',
      message: '전송 중 연결 경로가 변경되어 전송을 중단했습니다.',
    );
  }

  static bool _sameRoute({
    required String? expectedLocalInterfaceId,
    required String? currentLocalInterfaceId,
    required String? expectedLocalAddress,
    required String? currentLocalAddress,
    required String? expectedRemoteAddress,
    required String? currentRemoteAddress,
  }) {
    return _sameText(expectedLocalInterfaceId, currentLocalInterfaceId) &&
        _sameText(expectedLocalAddress, currentLocalAddress) &&
        _sameText(expectedRemoteAddress, currentRemoteAddress);
  }

  static bool _sameText(String? left, String? right) {
    if (left == null || right == null) {
      return false;
    }
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }
}
