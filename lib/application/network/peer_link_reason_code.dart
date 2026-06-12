enum PeerLinkReasonCode {
  discoveryReceiveFailed,
  routeCandidateMissing,
  controlBindFailed,
  authTimeout,
  authTokenRejected,
  peerOffline,
}

class PeerLinkReason {
  const PeerLinkReason({
    required this.code,
    required this.productMessage,
    required this.debugMessage,
  });

  final PeerLinkReasonCode code;
  final String productMessage;
  final String debugMessage;
}

class PeerLinkReasonMapper {
  const PeerLinkReasonMapper();

  PeerLinkReason map(
    PeerLinkReasonCode code, {
    String? detail,
  }) {
    final suffix = _debugSuffix(detail);
    switch (code) {
      case PeerLinkReasonCode.discoveryReceiveFailed:
        return PeerLinkReason(
          code: code,
          productMessage: '피어 검색 응답을 받지 못했습니다.',
          debugMessage: 'discovery receive failed$suffix',
        );
      case PeerLinkReasonCode.routeCandidateMissing:
        return PeerLinkReason(
          code: code,
          productMessage: '연결 가능한 네트워크 경로를 찾지 못했습니다.',
          debugMessage: 'no selectable route candidate$suffix',
        );
      case PeerLinkReasonCode.controlBindFailed:
        return PeerLinkReason(
          code: code,
          productMessage: '연결용 로컬 네트워크 경로를 열지 못했습니다.',
          debugMessage: 'control transport bind failed$suffix',
        );
      case PeerLinkReasonCode.authTimeout:
        return PeerLinkReason(
          code: code,
          productMessage: '상대 피어의 인증 응답 시간이 초과되었습니다.',
          debugMessage: 'auth handshake timeout$suffix',
        );
      case PeerLinkReasonCode.authTokenRejected:
        return PeerLinkReason(
          code: code,
          productMessage: '상대 피어가 인증을 거절했습니다.',
          debugMessage: 'auth token rejected$suffix',
        );
      case PeerLinkReasonCode.peerOffline:
        return PeerLinkReason(
          code: code,
          productMessage: '상대 피어가 오프라인 상태입니다.',
          debugMessage: 'peer is offline$suffix',
        );
    }
  }

  String _debugSuffix(String? detail) {
    if (detail == null || detail.trim().isEmpty) {
      return '';
    }
    return ': ${detail.trim()}';
  }
}
