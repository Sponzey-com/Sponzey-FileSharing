import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_promotion_command.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const snapshot = TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: TcpDataSessionId('session-1'),
    channelId: TcpDataChannelId('channel-1'),
    direction: TcpDataChannelDirection.inbound,
    status: TcpDataPeerSessionStatus.authenticating,
    localEndpointLabel: '10.0.0.1:50001',
    remoteEndpointLabel: '10.0.0.2:50000',
  );
  const hello = TcpDataSessionHello(
    sessionId: TcpDataSessionId('session-1'),
    peerId: 'peer-1',
    instanceId: 'instance-1',
    authSessionId: 'auth-1',
    protocolVersion: 1,
    dataProtocolVersion: 1,
    proof: 'proof-1',
  );
  const expectation = TcpDataSessionHandshakeExpectation(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    protocolVersion: 1,
    dataProtocolVersion: 1,
  );

  test('promotes valid authenticating session to connected', () {
    final command = TcpDataSessionPromotionCommand(
      handshakeCommand: TcpDataSessionHandshakeCommand(
        proofVerifier: _FakeProofVerifier(allowed: true),
      ),
    );

    final result = command.promoteIncomingHello(
      session: snapshot,
      hello: hello,
      expectation: expectation,
    );

    expect(result.state.status, TcpDataPeerSessionStatus.connected);
    expect(result.didTransition, isTrue);
  });

  test('fails session when hello proof is invalid', () {
    final command = TcpDataSessionPromotionCommand(
      handshakeCommand: TcpDataSessionHandshakeCommand(
        proofVerifier: _FakeProofVerifier(allowed: false),
      ),
    );

    final result = command.promoteIncomingHello(
      session: snapshot,
      hello: hello,
      expectation: expectation,
    );

    expect(result.state.status, TcpDataPeerSessionStatus.failed);
    expect(result.isFailure, isTrue);
    expect(result.issue?.code, 'tcp_data_hello_invalid_proof');
  });

  test('does not promote session from invalid source state', () {
    final command = TcpDataSessionPromotionCommand(
      handshakeCommand: TcpDataSessionHandshakeCommand(
        proofVerifier: _FakeProofVerifier(allowed: true),
      ),
    );

    final result = command.promoteIncomingHello(
      session: snapshot.copyWith(status: TcpDataPeerSessionStatus.connected),
      hello: hello,
      expectation: expectation,
    );

    expect(result.disposition, TransitionDisposition.warning);
    expect(result.issue?.code, 'tcp_data_session_not_authenticating');
  });
}

class _FakeProofVerifier implements TcpDataSessionProofVerifier {
  const _FakeProofVerifier({required this.allowed});

  final bool allowed;

  @override
  bool verify(TcpDataSessionHello hello) => allowed;
}
