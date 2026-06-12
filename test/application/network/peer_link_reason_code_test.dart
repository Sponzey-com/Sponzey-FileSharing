import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/network/peer_link_reason_code.dart';

void main() {
  test('maps connection failure reasons to product and debug messages', () {
    const mapper = PeerLinkReasonMapper();

    final reasons = {
      for (final code in PeerLinkReasonCode.values)
        code: mapper.map(code, detail: 'peer=team@device'),
    };

    expect(reasons, hasLength(PeerLinkReasonCode.values.length));
    expect(
      reasons[PeerLinkReasonCode.discoveryReceiveFailed]!.productMessage,
      '피어 검색 응답을 받지 못했습니다.',
    );
    expect(
      reasons[PeerLinkReasonCode.routeCandidateMissing]!.productMessage,
      '연결 가능한 네트워크 경로를 찾지 못했습니다.',
    );
    expect(
      reasons[PeerLinkReasonCode.controlBindFailed]!.debugMessage,
      contains('control transport bind failed'),
    );
    expect(
      reasons[PeerLinkReasonCode.authTimeout]!.debugMessage,
      contains('auth handshake timeout'),
    );
    expect(
      reasons[PeerLinkReasonCode.authTokenRejected]!.productMessage,
      '상대 피어가 인증을 거절했습니다.',
    );
    expect(
      reasons[PeerLinkReasonCode.peerOffline]!.productMessage,
      '상대 피어가 오프라인 상태입니다.',
    );
    expect(
      reasons.values.every(
        (reason) => reason.debugMessage.contains('peer=team@device'),
      ),
      isTrue,
    );
  });

  test('does not append empty debug detail', () {
    const mapper = PeerLinkReasonMapper();

    expect(
      mapper
          .map(PeerLinkReasonCode.routeCandidateMissing, detail: ' ')
          .debugMessage,
      'no selectable route candidate',
    );
  });
}
