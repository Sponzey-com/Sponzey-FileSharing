import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/peer_link/peer_link_state_machine.dart';

void main() {
  const machine = PeerLinkStateMachine();

  test('rejects link requests before discovery', () {
    final result = machine.transition(
      const PeerLinkSnapshot(linkStatus: PeerLinkStatus.rejected),
      PeerLinkEvent.linkRequested,
    );

    expect(result.issue?.code, 'invalid_peer_link_transition');
  });

  test('rejects transfer offers before authentication', () {
    final result = machine.transition(
      const PeerLinkSnapshot(linkStatus: PeerLinkStatus.discovered),
      PeerLinkEvent.transferOfferRequested,
    );

    expect(result.isFailure, isTrue);
    expect(result.issue?.code, 'transfer_offer_not_allowed');
  });

  test('rejects encrypted data before secure session establishment', () {
    final result = machine.transition(
      const PeerLinkSnapshot(linkStatus: PeerLinkStatus.authenticated),
      PeerLinkEvent.encryptedDataRequested,
    );

    expect(result.isFailure, isTrue);
    expect(result.issue?.code, 'secure_session_not_established');
  });

  test('allows encrypted data after secure session establishment', () {
    final result = machine.transition(
      const PeerLinkSnapshot(
        linkStatus: PeerLinkStatus.authenticated,
        secureSessionStatus: SecureSessionStatus.established,
      ),
      PeerLinkEvent.encryptedDataRequested,
    );

    expect(result.didTransition, isFalse);
    expect(result.isFailure, isFalse);
  });

  test('expires authenticated sessions', () {
    final result = machine.transition(
      const PeerLinkSnapshot(
        linkStatus: PeerLinkStatus.authenticated,
        secureSessionStatus: SecureSessionStatus.established,
      ),
      PeerLinkEvent.sessionExpired,
    );

    expect(result.state.linkStatus, PeerLinkStatus.expired);
    expect(result.state.secureSessionStatus, SecureSessionStatus.expired);
  });
}
