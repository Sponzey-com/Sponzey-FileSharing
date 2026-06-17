class TransferDataBindEndpointRouteDecision {
  const TransferDataBindEndpointRouteDecision({
    required this.isValid,
    this.message,
  });

  final bool isValid;
  final String? message;
}

class TransferDataBindEndpointRouteCommand {
  const TransferDataBindEndpointRouteCommand._();

  static TransferDataBindEndpointRouteDecision validate({
    required String routeLocalAddress,
    required String bindLocalAddress,
    required bool isWildcardBind,
  }) {
    if (isWildcardBind || _isWildcardAddress(bindLocalAddress)) {
      return const TransferDataBindEndpointRouteDecision(isValid: true);
    }
    if (_sameAddress(bindLocalAddress, routeLocalAddress)) {
      return const TransferDataBindEndpointRouteDecision(isValid: true);
    }

    return TransferDataBindEndpointRouteDecision(
      isValid: false,
      message:
          'Data socket local address가 검증된 연결 경로와 다릅니다. '
          'route=$routeLocalAddress, data=$bindLocalAddress',
    );
  }

  static bool _sameAddress(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  static bool _isWildcardAddress(String address) {
    final normalized = address.trim().toLowerCase();
    return normalized == '0.0.0.0' ||
        normalized == '::' ||
        normalized == '0:0:0:0:0:0:0:0';
  }
}
