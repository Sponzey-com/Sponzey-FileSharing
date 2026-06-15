enum DiscoveryReceiveDecisionCode {
  accepted,
  ignoredSelf,
  groupMismatch,
  localIdentityMissing,
  malformed,
}

class DiscoveryReceiveDecision {
  const DiscoveryReceiveDecision({
    required this.code,
    required this.remoteAddress,
    required this.remotePort,
    this.peerId,
    this.reason,
  });

  final DiscoveryReceiveDecisionCode code;
  final String remoteAddress;
  final int remotePort;
  final String? peerId;
  final String? reason;

  String get summary {
    final peer = peerId == null ? '' : ' peer=$peerId';
    final why = reason == null ? '' : ' reason=$reason';
    return '${code.name} source=$remoteAddress:$remotePort$peer$why';
  }
}
