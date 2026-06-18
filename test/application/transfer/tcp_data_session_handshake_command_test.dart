import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const expectation = TcpDataSessionHandshakeExpectation(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    protocolVersion: 1,
    dataProtocolVersion: 1,
  );
  const validHello = TcpDataSessionHello(
    sessionId: TcpDataSessionId('session-1'),
    peerId: 'peer-1',
    instanceId: 'instance-1',
    authSessionId: 'auth-1',
    protocolVersion: 1,
    dataProtocolVersion: 1,
    proof: 'proof-1',
  );

  test('accepts valid hello with valid proof', () {
    final command = TcpDataSessionHandshakeCommand(
      proofVerifier: _FakeProofVerifier(allowed: true),
    );

    final result = command.validateIncomingHello(
      hello: validHello,
      expectation: expectation,
    );

    expect(result.accepted, isTrue);
    expect(result.issueCode, isNull);
  });

  test('rejects wrong peer id', () {
    final command = TcpDataSessionHandshakeCommand(
      proofVerifier: _FakeProofVerifier(allowed: true),
    );

    final result = command.validateIncomingHello(
      hello: validHello.copyWith(peerId: 'peer-2'),
      expectation: expectation,
    );

    expect(result.accepted, isFalse);
    expect(result.issueCode, 'tcp_data_hello_peer_mismatch');
  });

  test('rejects wrong auth session id', () {
    final command = TcpDataSessionHandshakeCommand(
      proofVerifier: _FakeProofVerifier(allowed: true),
    );

    final result = command.validateIncomingHello(
      hello: validHello.copyWith(authSessionId: 'auth-2'),
      expectation: expectation,
    );

    expect(result.accepted, isFalse);
    expect(result.issueCode, 'tcp_data_hello_auth_session_mismatch');
  });

  test('rejects protocol mismatch', () {
    final command = TcpDataSessionHandshakeCommand(
      proofVerifier: _FakeProofVerifier(allowed: true),
    );

    final result = command.validateIncomingHello(
      hello: validHello.copyWith(dataProtocolVersion: 2),
      expectation: expectation,
    );

    expect(result.accepted, isFalse);
    expect(result.issueCode, 'tcp_data_hello_protocol_mismatch');
  });

  test('rejects invalid proof', () {
    final command = TcpDataSessionHandshakeCommand(
      proofVerifier: _FakeProofVerifier(allowed: false),
    );

    final result = command.validateIncomingHello(
      hello: validHello,
      expectation: expectation,
    );

    expect(result.accepted, isFalse);
    expect(result.issueCode, 'tcp_data_hello_invalid_proof');
  });
}

class _FakeProofVerifier implements TcpDataSessionProofVerifier {
  const _FakeProofVerifier({required this.allowed});

  final bool allowed;

  @override
  bool verify(TcpDataSessionHello hello) => allowed;
}
