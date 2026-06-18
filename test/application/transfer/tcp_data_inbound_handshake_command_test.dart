import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_accepted_session_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_promotion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_registry_promotion_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const accepted = TcpDataAcceptedConnection(
    channelId: TcpDataChannelId('channel-1'),
    localEndpoint: TcpDataEndpoint(host: '10.0.0.1', port: 50001),
    remoteEndpoint: TcpDataEndpoint(host: '10.0.0.2', port: 50000),
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

  test('registers connected inbound session for valid handshake', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final command = _command(registry, proofAllowed: true);

    final result = command.handle(
      accepted: accepted,
      sessionId: const TcpDataSessionId('session-1'),
      hello: hello,
      expectation: expectation,
    );

    expect(result.registered, isTrue);
    expect(result.session?.status, TcpDataPeerSessionStatus.connected);
    expect(
      registry.lookup(
        const DataChannelSessionKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          direction: TcpDataChannelDirection.inbound,
        ),
      ),
      isNotNull,
    );
  });

  test('does not register invalid proof handshake', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final command = _command(registry, proofAllowed: false);

    final result = command.handle(
      accepted: accepted,
      sessionId: const TcpDataSessionId('session-1'),
      hello: hello,
      expectation: expectation,
    );

    expect(result.registered, isFalse);
    expect(result.issueCode, 'tcp_data_hello_invalid_proof');
    expect(
      registry.lookup(
        const DataChannelSessionKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          direction: TcpDataChannelDirection.inbound,
        ),
      ),
      isNull,
    );
  });
}

TcpDataInboundHandshakeCommand _command(
  DataChannelSessionRegistry registry, {
  required bool proofAllowed,
}) {
  return TcpDataInboundHandshakeCommand(
    acceptedSessionFactory: const TcpDataAcceptedSessionFactory(),
    registryPromotionCommand: TcpDataSessionRegistryPromotionCommand(
      registry: registry,
      promotionCommand: TcpDataSessionPromotionCommand(
        handshakeCommand: TcpDataSessionHandshakeCommand(
          proofVerifier: _FakeProofVerifier(allowed: proofAllowed),
        ),
      ),
    ),
  );
}

class _FakeProofVerifier implements TcpDataSessionProofVerifier {
  const _FakeProofVerifier({required this.allowed});

  final bool allowed;

  @override
  bool verify(TcpDataSessionHello hello) => allowed;
}
