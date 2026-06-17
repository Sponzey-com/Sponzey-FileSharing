class TransferOutgoingDataEndpointDecision {
  const TransferOutgoingDataEndpointDecision({
    required this.isValid,
    required this.address,
    required this.port,
  });

  final bool isValid;
  final String? address;
  final int? port;
}

class TransferOutgoingDataEndpointCommand {
  const TransferOutgoingDataEndpointCommand._();

  static TransferOutgoingDataEndpointDecision validate({
    required String? address,
    required int? port,
  }) {
    final trimmedAddress = address?.trim();
    final validAddress = trimmedAddress != null && trimmedAddress.isNotEmpty;
    final validPort = port != null && port > 0;
    if (!validAddress || !validPort) {
      return const TransferOutgoingDataEndpointDecision(
        isValid: false,
        address: null,
        port: null,
      );
    }
    return TransferOutgoingDataEndpointDecision(
      isValid: true,
      address: trimmedAddress,
      port: port,
    );
  }
}
