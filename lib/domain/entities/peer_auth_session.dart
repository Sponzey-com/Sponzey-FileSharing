enum PeerAuthStatus {
  idle,
  connecting,
  challengeIssued,
  tokenSent,
  verifying,
  authenticated,
  rejected,
  failed,
}

class PeerAuthSession {
  const PeerAuthSession({
    required this.sessionId,
    required this.peerId,
    required this.peerUserId,
    required this.peerDisplayName,
    required this.peerAddress,
    required this.peerPort,
    required this.status,
    required this.updatedAt,
    this.message,
  });

  final String sessionId;
  final String peerId;
  final String peerUserId;
  final String peerDisplayName;
  final String peerAddress;
  final int peerPort;
  final PeerAuthStatus status;
  final DateTime updatedAt;
  final String? message;

  String get statusLabel {
    switch (status) {
      case PeerAuthStatus.idle:
        return '발견됨';
      case PeerAuthStatus.connecting:
        return '연결 중';
      case PeerAuthStatus.challengeIssued:
        return '연결 중';
      case PeerAuthStatus.tokenSent:
        return '연결 중';
      case PeerAuthStatus.verifying:
        return '연결 중';
      case PeerAuthStatus.authenticated:
        return '인증 완료';
      case PeerAuthStatus.rejected:
        return '거절됨';
      case PeerAuthStatus.failed:
        return '실패';
    }
  }

  bool get isAuthenticated => status == PeerAuthStatus.authenticated;

  PeerAuthSession copyWith({
    String? sessionId,
    String? peerId,
    String? peerUserId,
    String? peerDisplayName,
    String? peerAddress,
    int? peerPort,
    PeerAuthStatus? status,
    DateTime? updatedAt,
    String? message,
    bool clearMessage = false,
  }) {
    return PeerAuthSession(
      sessionId: sessionId ?? this.sessionId,
      peerId: peerId ?? this.peerId,
      peerUserId: peerUserId ?? this.peerUserId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      peerAddress: peerAddress ?? this.peerAddress,
      peerPort: peerPort ?? this.peerPort,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
