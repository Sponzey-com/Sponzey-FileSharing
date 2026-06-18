import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataSessionHello {
  const TcpDataSessionHello({
    required this.sessionId,
    required this.peerId,
    required this.instanceId,
    required this.authSessionId,
    required this.protocolVersion,
    required this.dataProtocolVersion,
    required this.proof,
  });

  final TcpDataSessionId sessionId;
  final String peerId;
  final String instanceId;
  final String authSessionId;
  final int protocolVersion;
  final int dataProtocolVersion;
  final String proof;

  TcpDataSessionHello copyWith({
    TcpDataSessionId? sessionId,
    String? peerId,
    String? instanceId,
    String? authSessionId,
    int? protocolVersion,
    int? dataProtocolVersion,
    String? proof,
  }) {
    return TcpDataSessionHello(
      sessionId: sessionId ?? this.sessionId,
      peerId: peerId ?? this.peerId,
      instanceId: instanceId ?? this.instanceId,
      authSessionId: authSessionId ?? this.authSessionId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      dataProtocolVersion: dataProtocolVersion ?? this.dataProtocolVersion,
      proof: proof ?? this.proof,
    );
  }
}

class TcpDataSessionHandshakeExpectation {
  const TcpDataSessionHandshakeExpectation({
    required this.peerId,
    required this.authSessionId,
    required this.protocolVersion,
    required this.dataProtocolVersion,
  });

  final String peerId;
  final String authSessionId;
  final int protocolVersion;
  final int dataProtocolVersion;
}

abstract interface class TcpDataSessionProofVerifier {
  bool verify(TcpDataSessionHello hello);
}

class TcpDataSessionHandshakeResult {
  const TcpDataSessionHandshakeResult({required this.accepted, this.issueCode});

  final bool accepted;
  final String? issueCode;

  const TcpDataSessionHandshakeResult.accepted()
    : accepted = true,
      issueCode = null;

  const TcpDataSessionHandshakeResult.rejected({required this.issueCode})
    : accepted = false;
}

class TcpDataSessionHandshakeCommand {
  const TcpDataSessionHandshakeCommand({required this.proofVerifier});

  final TcpDataSessionProofVerifier proofVerifier;

  TcpDataSessionHandshakeResult validateIncomingHello({
    required TcpDataSessionHello hello,
    required TcpDataSessionHandshakeExpectation expectation,
  }) {
    if (hello.peerId != expectation.peerId) {
      return const TcpDataSessionHandshakeResult.rejected(
        issueCode: 'tcp_data_hello_peer_mismatch',
      );
    }
    if (hello.authSessionId != expectation.authSessionId) {
      return const TcpDataSessionHandshakeResult.rejected(
        issueCode: 'tcp_data_hello_auth_session_mismatch',
      );
    }
    if (hello.protocolVersion != expectation.protocolVersion ||
        hello.dataProtocolVersion != expectation.dataProtocolVersion) {
      return const TcpDataSessionHandshakeResult.rejected(
        issueCode: 'tcp_data_hello_protocol_mismatch',
      );
    }
    if (!proofVerifier.verify(hello)) {
      return const TcpDataSessionHandshakeResult.rejected(
        issueCode: 'tcp_data_hello_invalid_proof',
      );
    }
    return const TcpDataSessionHandshakeResult.accepted();
  }
}
