class TransferEndpointLabelFormatter {
  const TransferEndpointLabelFormatter._();

  static String format({
    required String? localAddress,
    required int? port,
    required String? bindModeName,
  }) {
    if (localAddress == null || port == null || bindModeName == null) {
      return 'any';
    }
    return '$localAddress:$port/$bindModeName';
  }
}
