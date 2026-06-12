import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum SecureSessionStatus {
  none,
  negotiating,
  established,
  refreshing,
  expired,
  revoked,
  failed,
  destroyed,
}

enum PeerLinkStatus {
  discovered,
  linkRequested,
  challengeReceived,
  challengeSent,
  authenticating,
  authenticated,
  rejected,
  expired,
  disconnected,
  failed,
}

enum PeerLinkEvent {
  linkRequested,
  challengeIssued,
  challengeReceived,
  tokenCreated,
  tokenReceived,
  tokenVerified,
  tokenRejected,
  linkAccepted,
  linkRejected,
  sessionExpired,
  disconnectRequested,
  controlTimeout,
  secureSessionNegotiationStarted,
  secureSessionEstablished,
  secureSessionFailed,
  secureSessionDestroyed,
  transferOfferRequested,
  encryptedDataRequested,
}

class PeerLinkSnapshot {
  const PeerLinkSnapshot({
    required this.linkStatus,
    this.secureSessionStatus = SecureSessionStatus.none,
  });

  final PeerLinkStatus linkStatus;
  final SecureSessionStatus secureSessionStatus;

  PeerLinkSnapshot copyWith({
    PeerLinkStatus? linkStatus,
    SecureSessionStatus? secureSessionStatus,
  }) {
    return PeerLinkSnapshot(
      linkStatus: linkStatus ?? this.linkStatus,
      secureSessionStatus: secureSessionStatus ?? this.secureSessionStatus,
    );
  }
}

class PeerLinkStateMachine
    implements StateMachine<PeerLinkSnapshot, PeerLinkEvent> {
  const PeerLinkStateMachine();

  @override
  TransitionResult<PeerLinkSnapshot> transition(
    PeerLinkSnapshot state,
    PeerLinkEvent event,
  ) {
    if (event == PeerLinkEvent.transferOfferRequested) {
      if (state.linkStatus == PeerLinkStatus.authenticated) {
        return TransitionResult.noOp(state);
      }
      return TransitionResult.failure(
        state,
        issue: const TransitionIssue(
          code: 'transfer_offer_not_allowed',
          message: 'Transfer offers require an authenticated peer link.',
        ),
      );
    }

    if (event == PeerLinkEvent.encryptedDataRequested) {
      if (state.secureSessionStatus == SecureSessionStatus.established) {
        return TransitionResult.noOp(state);
      }
      return TransitionResult.failure(
        state,
        issue: const TransitionIssue(
          code: 'secure_session_not_established',
          message: 'Encrypted data requires an established secure session.',
        ),
      );
    }

    switch ((state.linkStatus, event)) {
      case (PeerLinkStatus.discovered, PeerLinkEvent.linkRequested):
        return TransitionResult.transitioned(
          state.copyWith(linkStatus: PeerLinkStatus.linkRequested),
          effects: const [TransitionEffect('sendLinkRequest')],
        );
      case (PeerLinkStatus.linkRequested, PeerLinkEvent.challengeReceived):
        return TransitionResult.transitioned(
          state.copyWith(linkStatus: PeerLinkStatus.challengeReceived),
          effects: const [TransitionEffect('createLinkResponseToken')],
        );
      case (PeerLinkStatus.discovered, PeerLinkEvent.challengeIssued):
        return TransitionResult.transitioned(
          state.copyWith(linkStatus: PeerLinkStatus.challengeSent),
          effects: const [TransitionEffect('sendLinkChallenge')],
        );
      case (PeerLinkStatus.challengeReceived, PeerLinkEvent.tokenCreated):
      case (PeerLinkStatus.challengeSent, PeerLinkEvent.tokenReceived):
        return TransitionResult.transitioned(
          state.copyWith(linkStatus: PeerLinkStatus.authenticating),
        );
      case (PeerLinkStatus.authenticating, PeerLinkEvent.tokenVerified):
        return TransitionResult.transitioned(
          state.copyWith(linkStatus: PeerLinkStatus.authenticated),
          effects: const [TransitionEffect('startSecureSessionNegotiation')],
        );
      case (
        PeerLinkStatus.authenticated,
        PeerLinkEvent.secureSessionNegotiationStarted,
      ):
        return TransitionResult.transitioned(
          state.copyWith(secureSessionStatus: SecureSessionStatus.negotiating),
        );
      case (
        PeerLinkStatus.authenticated,
        PeerLinkEvent.secureSessionEstablished,
      ):
        return TransitionResult.transitioned(
          state.copyWith(secureSessionStatus: SecureSessionStatus.established),
        );
      case (PeerLinkStatus.authenticated, PeerLinkEvent.secureSessionFailed):
        return TransitionResult.failure(
          state.copyWith(secureSessionStatus: SecureSessionStatus.failed),
          issue: const TransitionIssue(
            code: 'secure_session_failed',
            message: 'Secure session negotiation failed.',
          ),
        );
      case (_, PeerLinkEvent.tokenRejected):
      case (_, PeerLinkEvent.linkRejected):
        return TransitionResult.transitioned(
          state.copyWith(linkStatus: PeerLinkStatus.rejected),
        );
      case (_, PeerLinkEvent.sessionExpired):
        return TransitionResult.transitioned(
          state.copyWith(
            linkStatus: PeerLinkStatus.expired,
            secureSessionStatus: SecureSessionStatus.expired,
          ),
        );
      case (_, PeerLinkEvent.controlTimeout):
        return TransitionResult.failure(
          state.copyWith(linkStatus: PeerLinkStatus.failed),
          issue: const TransitionIssue(
            code: 'peer_link_timeout',
            message: 'Peer link control flow timed out.',
          ),
        );
      case (_, PeerLinkEvent.disconnectRequested):
        return TransitionResult.transitioned(
          state.copyWith(
            linkStatus: PeerLinkStatus.disconnected,
            secureSessionStatus: SecureSessionStatus.destroyed,
          ),
          effects: const [TransitionEffect('destroySecureSession')],
        );
      case (_, PeerLinkEvent.secureSessionDestroyed):
        return TransitionResult.transitioned(
          state.copyWith(secureSessionStatus: SecureSessionStatus.destroyed),
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_peer_link_transition',
            message:
                'Cannot apply $event while peer link is ${state.linkStatus}.',
          ),
        );
    }
  }
}
