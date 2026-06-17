class TransferActiveRouteValidationDecision {
  const TransferActiveRouteValidationDecision({
    required this.isValid,
    this.code,
    this.message,
  });

  final bool isValid;
  final String? code;
  final String? message;
}

class TransferActiveRouteValidationCommand {
  const TransferActiveRouteValidationCommand._();

  static TransferActiveRouteValidationDecision validate({
    required String controlLocalAddress,
    required String routeRemoteAddress,
    required int routeRemotePort,
    required String sessionPeerAddress,
  }) {
    if (controlLocalAddress.trim().isEmpty ||
        routeRemoteAddress.trim().isEmpty ||
        routeRemotePort <= 0) {
      return const TransferActiveRouteValidationDecision(
        isValid: false,
        code: 'transfer_active_route_invalid',
        message: '연결 경로의 endpoint 정보가 올바르지 않습니다.',
      );
    }
    if (_isLoopbackAddress(routeRemoteAddress) &&
        !_isLoopbackAddress(sessionPeerAddress)) {
      return const TransferActiveRouteValidationDecision(
        isValid: false,
        code: 'transfer_loopback_route_mismatch',
        message: '외부 피어 전송에는 loopback 경로를 사용할 수 없습니다.',
      );
    }
    return const TransferActiveRouteValidationDecision(isValid: true);
  }

  static bool _isLoopbackAddress(String address) {
    final normalized = address.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '::1' ||
        normalized.startsWith('127.');
  }
}
