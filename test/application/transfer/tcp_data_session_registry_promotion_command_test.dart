import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_promotion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_registry_promotion_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const session = TcpDataPeerSessionSnapshot(
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

  test('registers connected session after valid hello promotion', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final command = _command(registry, proofAllowed: true);

    final result = command.promoteAndRegister(
      session: session,
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

  test('does not register failed hello promotion', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final command = _command(registry, proofAllowed: false);

    final result = command.promoteAndRegister(
      session: session,
      hello: hello,
      expectation: expectation,
    );

    expect(result.registered, isFalse);
    expect(result.issueCode, 'tcp_data_hello_invalid_proof');
    expect(result.session?.status, TcpDataPeerSessionStatus.failed);
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

  test('returns duplicate registration issue without replacing session', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final command = _command(registry, proofAllowed: true);
    command.promoteAndRegister(
      session: session,
      hello: hello,
      expectation: expectation,
    );

    final duplicate = command.promoteAndRegister(
      session: session.copyWith(channelId: const TcpDataChannelId('channel-2')),
      hello: hello,
      expectation: expectation,
    );

    expect(duplicate.registered, isFalse);
    expect(duplicate.issueCode, 'duplicate_data_channel_session');
    expect(
      registry
          .lookup(
            const DataChannelSessionKey(
              peerId: 'peer-1',
              authSessionId: 'auth-1',
              direction: TcpDataChannelDirection.inbound,
            ),
          )
          ?.channelId,
      const TcpDataChannelId('channel-1'),
    );
  });
}

TcpDataSessionRegistryPromotionCommand _command(
  DataChannelSessionRegistry registry, {
  required bool proofAllowed,
}) {
  return TcpDataSessionRegistryPromotionCommand(
    registry: registry,
    promotionCommand: TcpDataSessionPromotionCommand(
      handshakeCommand: TcpDataSessionHandshakeCommand(
        proofVerifier: _FakeProofVerifier(allowed: proofAllowed),
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
