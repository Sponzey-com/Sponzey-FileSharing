import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';

void main() {
  test('transitions normal outbound authentication flow', () {
    const machine = PeerAuthSessionStateMachine();
    final idle = _session(PeerAuthStatus.idle);

    final connecting = machine.transition(idle, PeerAuthEvent.connectStarted);
    expect(connecting.state.status, PeerAuthStatus.connecting);

    final tokenSent = machine.transition(
      connecting.state,
      PeerAuthEvent.tokenSent,
    );
    expect(tokenSent.state.status, PeerAuthStatus.tokenSent);

    final authenticated = machine.transition(
      tokenSent.state,
      PeerAuthEvent.authSucceeded,
    );
    expect(authenticated.state.status, PeerAuthStatus.authenticated);
  });

  test('transitions normal inbound challenge and verification flow', () {
    const machine = PeerAuthSessionStateMachine();
    final idle = _session(PeerAuthStatus.idle);

    final challengeIssued = machine.transition(
      idle,
      PeerAuthEvent.challengeIssued,
    );
    expect(challengeIssued.state.status, PeerAuthStatus.challengeIssued);

    final verifying = machine.transition(
      challengeIssued.state,
      PeerAuthEvent.tokenVerificationStarted,
    );
    expect(verifying.state.status, PeerAuthStatus.verifying);

    final authenticated = machine.transition(
      verifying.state,
      PeerAuthEvent.authSucceeded,
    );
    expect(authenticated.state.status, PeerAuthStatus.authenticated);
  });

  test('late failure cannot downgrade an authenticated session', () {
    const machine = PeerAuthSessionStateMachine();
    final authenticated = _session(PeerAuthStatus.authenticated);

    final rejected = machine.transition(
      authenticated,
      PeerAuthEvent.authRejected,
    );
    final failed = machine.transition(authenticated, PeerAuthEvent.authFailed);

    expect(rejected.disposition, TransitionDisposition.warning);
    expect(rejected.state.status, PeerAuthStatus.authenticated);
    expect(failed.disposition, TransitionDisposition.warning);
    expect(failed.state.status, PeerAuthStatus.authenticated);
  });

  test(
    'stale peer downgrades authenticated session without deleting identity',
    () {
      const machine = PeerAuthSessionStateMachine();
      final authenticated = _session(PeerAuthStatus.authenticated);

      final stale = machine.transition(authenticated, PeerAuthEvent.stale);

      expect(stale.state.status, PeerAuthStatus.idle);
      expect(stale.effects.single.name, 'clearActivePeerPath');
    },
  );
}

PeerAuthSession _session(PeerAuthStatus status) {
  return PeerAuthSession(
    sessionId: 'session-a',
    peerId: 'team@device-b',
    peerUserId: 'team',
    peerDisplayName: 'team',
    peerAddress: '10.20.30.40',
    peerPort: 38401,
    status: status,
    updatedAt: DateTime.utc(2026),
  );
}
