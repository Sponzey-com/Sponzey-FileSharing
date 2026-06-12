import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_link_reason_code.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';

enum PeerConnectionProductStatus {
  checking,
  authenticating,
  connected,
  failed,
  stale,
  offline,
  incompatible,
}

class PeerConnectionSummary {
  const PeerConnectionSummary({
    required this.status,
    required this.label,
    required this.description,
    required this.canSendFiles,
  });

  final PeerConnectionProductStatus status;
  final String label;
  final String description;
  final bool canSendFiles;

  factory PeerConnectionSummary.resolve({
    required PeerNode peer,
    required PeerAuthSession? authSession,
    required PeerPathDiagnostics diagnostics,
  }) {
    if (peer.presence == PeerPresence.incompatible) {
      return const PeerConnectionSummary(
        status: PeerConnectionProductStatus.incompatible,
        label: '버전 다름',
        description: '프로토콜 버전이 달라 자동 연결할 수 없습니다.',
        canSendFiles: false,
      );
    }
    if (peer.presence == PeerPresence.offline) {
      return PeerConnectionSummary(
        status: PeerConnectionProductStatus.offline,
        label: '오프라인',
        description: const PeerLinkReasonMapper()
            .map(PeerLinkReasonCode.peerOffline)
            .productMessage,
        canSendFiles: false,
      );
    }
    if (peer.presence == PeerPresence.stale) {
      return const PeerConnectionSummary(
        status: PeerConnectionProductStatus.stale,
        label: '응답 대기',
        description: '최근 응답이 없어 다시 확인하는 중입니다.',
        canSendFiles: false,
      );
    }

    final session = authSession;
    if (session != null) {
      switch (session.status) {
        case PeerAuthStatus.authenticated:
          final activePath = diagnostics.activePath;
          if (activePath != null &&
              activePath.status == PeerPathStatus.active) {
            return const PeerConnectionSummary(
              status: PeerConnectionProductStatus.connected,
              label: '연결됨',
              description: '파일 전송 준비가 완료되었습니다.',
              canSendFiles: true,
            );
          }
          return const PeerConnectionSummary(
            status: PeerConnectionProductStatus.checking,
            label: '경로 확인 중',
            description: '인증은 완료되었고 네트워크 경로 상태를 확인 중입니다.',
            canSendFiles: false,
          );
        case PeerAuthStatus.connecting:
        case PeerAuthStatus.challengeIssued:
        case PeerAuthStatus.tokenSent:
        case PeerAuthStatus.verifying:
          return const PeerConnectionSummary(
            status: PeerConnectionProductStatus.authenticating,
            label: '인증 중',
            description: '자동 핸드셰이크를 진행하는 중입니다.',
            canSendFiles: false,
          );
        case PeerAuthStatus.rejected:
          return PeerConnectionSummary(
            status: PeerConnectionProductStatus.failed,
            label: '연결 실패',
            description: const PeerLinkReasonMapper()
                .map(PeerLinkReasonCode.authTokenRejected)
                .productMessage,
            canSendFiles: false,
          );
        case PeerAuthStatus.failed:
          return PeerConnectionSummary(
            status: PeerConnectionProductStatus.failed,
            label: '연결 실패',
            description: session.message?.trim().isNotEmpty == true
                ? session.message!
                : '자동 연결에 실패했습니다.',
            canSendFiles: false,
          );
        case PeerAuthStatus.idle:
          break;
      }
    }

    if (diagnostics.allCandidatesFailed) {
      return PeerConnectionSummary(
        status: PeerConnectionProductStatus.failed,
        label: '경로 실패',
        description: const PeerLinkReasonMapper()
            .map(PeerLinkReasonCode.routeCandidateMissing)
            .productMessage,
        canSendFiles: false,
      );
    }
    if (diagnostics.candidates.isNotEmpty) {
      return const PeerConnectionSummary(
        status: PeerConnectionProductStatus.checking,
        label: '연결 확인 중',
        description: '사용 가능한 네트워크 경로를 확인하는 중입니다.',
        canSendFiles: false,
      );
    }
    return const PeerConnectionSummary(
      status: PeerConnectionProductStatus.checking,
      label: '발견됨',
      description: '피어를 발견했고 자동 연결을 준비하는 중입니다.',
      canSendFiles: false,
    );
  }
}

final peerConnectionSummaryProvider =
    Provider.family<PeerConnectionSummary, PeerNode>((ref, peer) {
      final authSession = ref.watch(peerAuthSessionByPeerIdProvider(peer.id));
      final diagnostics = ref.watch(peerPathDiagnosticsProvider(peer.id));
      return PeerConnectionSummary.resolve(
        peer: peer,
        authSession: authSession,
        diagnostics: diagnostics,
      );
    });
