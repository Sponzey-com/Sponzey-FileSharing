import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

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

enum PeerAuthEvent {
  discovered,
  connectStarted,
  challengeIssued,
  tokenSent,
  tokenVerificationStarted,
  authSucceeded,
  authRejected,
  authFailed,
  stale,
  offline,
}

class PeerAuthSessionStateMachine
    implements StateMachine<PeerAuthSession, PeerAuthEvent> {
  const PeerAuthSessionStateMachine();

  @override
  TransitionResult<PeerAuthSession> transition(
    PeerAuthSession state,
    PeerAuthEvent event,
  ) {
    switch ((state.status, event)) {
      case (PeerAuthStatus.idle, PeerAuthEvent.discovered):
        return TransitionResult.noOp(state);
      case (PeerAuthStatus.idle, PeerAuthEvent.connectStarted):
      case (PeerAuthStatus.failed, PeerAuthEvent.connectStarted):
      case (PeerAuthStatus.rejected, PeerAuthEvent.connectStarted):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.connecting),
          effects: const [TransitionEffect('sendConnectRequest')],
        );
      case (PeerAuthStatus.idle, PeerAuthEvent.challengeIssued):
      case (PeerAuthStatus.connecting, PeerAuthEvent.challengeIssued):
      case (PeerAuthStatus.failed, PeerAuthEvent.challengeIssued):
      case (PeerAuthStatus.rejected, PeerAuthEvent.challengeIssued):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.challengeIssued),
          effects: const [TransitionEffect('sendAuthChallenge')],
        );
      case (PeerAuthStatus.connecting, PeerAuthEvent.tokenSent):
      case (PeerAuthStatus.challengeIssued, PeerAuthEvent.tokenSent):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.tokenSent),
          effects: const [TransitionEffect('sendAuthToken')],
        );
      case (
        PeerAuthStatus.challengeIssued,
        PeerAuthEvent.tokenVerificationStarted,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.verifying),
          effects: const [TransitionEffect('verifyAuthToken')],
        );
      case (PeerAuthStatus.connecting, PeerAuthEvent.authSucceeded):
      case (PeerAuthStatus.tokenSent, PeerAuthEvent.authSucceeded):
      case (PeerAuthStatus.verifying, PeerAuthEvent.authSucceeded):
      case (PeerAuthStatus.challengeIssued, PeerAuthEvent.authSucceeded):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.authenticated),
          effects: const [TransitionEffect('markRouteAuthenticated')],
        );
      case (PeerAuthStatus.authenticated, PeerAuthEvent.authSucceeded):
        return TransitionResult.noOp(state);
      case (PeerAuthStatus.connecting, PeerAuthEvent.authRejected):
      case (PeerAuthStatus.challengeIssued, PeerAuthEvent.authRejected):
      case (PeerAuthStatus.tokenSent, PeerAuthEvent.authRejected):
      case (PeerAuthStatus.verifying, PeerAuthEvent.authRejected):
        return TransitionResult.failure(
          state.copyWith(status: PeerAuthStatus.rejected),
          issue: const TransitionIssue(
            code: 'peer_auth_rejected',
            message: 'Peer authentication was rejected.',
          ),
        );
      case (PeerAuthStatus.connecting, PeerAuthEvent.authFailed):
      case (PeerAuthStatus.challengeIssued, PeerAuthEvent.authFailed):
      case (PeerAuthStatus.tokenSent, PeerAuthEvent.authFailed):
      case (PeerAuthStatus.verifying, PeerAuthEvent.authFailed):
        return TransitionResult.failure(
          state.copyWith(status: PeerAuthStatus.failed),
          issue: const TransitionIssue(
            code: 'peer_auth_failed',
            message: 'Peer authentication failed.',
          ),
        );
      case (PeerAuthStatus.authenticated, PeerAuthEvent.authRejected):
      case (PeerAuthStatus.authenticated, PeerAuthEvent.authFailed):
        return TransitionResult.warning(
          state,
          issue: const TransitionIssue(
            code: 'late_peer_auth_failure_ignored',
            message: 'Late auth failure cannot downgrade authenticated state.',
          ),
        );
      case (PeerAuthStatus.authenticated, PeerAuthEvent.stale):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.idle),
          effects: const [TransitionEffect('clearActivePeerPath')],
        );
      case (_, PeerAuthEvent.offline):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerAuthStatus.idle),
          effects: const [TransitionEffect('removePeerSession')],
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_peer_auth_transition',
            message: 'Cannot apply $event while auth is ${state.status}.',
          ),
        );
    }
  }
}
