class TransferIncomingRouteMatchCommand {
  const TransferIncomingRouteMatchCommand._();

  static bool matches({
    required String candidateRemoteAddress,
    required int candidateRemotePort,
    required String datagramRemoteAddress,
    required int datagramRemotePort,
    required String? datagramLocalAddress,
    required bool datagramIsWildcardBind,
    required bool candidateIsAnyBind,
    String? candidateLocalAddress,
  }) {
    if (candidateRemoteAddress != datagramRemoteAddress ||
        candidateRemotePort != datagramRemotePort) {
      return false;
    }
    if (datagramLocalAddress == null || datagramIsWildcardBind) {
      return true;
    }
    return candidateLocalAddress == datagramLocalAddress || candidateIsAnyBind;
  }
}
