class TransferOutgoingRemoteDataEndpointRouteDecision {
  const TransferOutgoingRemoteDataEndpointRouteDecision({
    required this.isValid,
    this.message,
  });

  final bool isValid;
  final String? message;
}

class TransferOutgoingRemoteDataEndpointRouteCommand {
  const TransferOutgoingRemoteDataEndpointRouteCommand._();

  static TransferOutgoingRemoteDataEndpointRouteDecision validate({
    required String routeRemoteAddress,
    required String dataRemoteAddress,
  }) {
    if (_sameAddress(routeRemoteAddress, dataRemoteAddress)) {
      return const TransferOutgoingRemoteDataEndpointRouteDecision(
        isValid: true,
      );
    }

    return TransferOutgoingRemoteDataEndpointRouteDecision(
      isValid: false,
      message:
          'Data endpoint가 검증된 연결 경로와 다릅니다. '
          'route=$routeRemoteAddress, data=$dataRemoteAddress',
    );
  }

  static bool _sameAddress(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }
}
