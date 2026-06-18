import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_accepted_session_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_listener_event_coordinator.dart';
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

  test('registers inbound session when accepted connection precedes hello', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final coordinator = _coordinator(registry);

    coordinator.handleAccepted(accepted);
    final result = coordinator.handleHello(
      received: const TcpDataReceivedHello(
        channelId: TcpDataChannelId('channel-1'),
        hello: hello,
      ),
      expectation: expectation,
    );

    expect(result.registered, isTrue);
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

  test('rejects hello that has no accepted connection', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final coordinator = _coordinator(registry);

    final result = coordinator.handleHello(
      received: const TcpDataReceivedHello(
        channelId: TcpDataChannelId('missing-channel'),
        hello: hello,
      ),
      expectation: expectation,
    );

    expect(result.registered, isFalse);
    expect(result.issueCode, 'missing_tcp_data_accepted_connection');
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

  test('malformed hello error removes pending accepted connection', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final coordinator = _coordinator(registry);

    coordinator.handleAccepted(accepted);
    final errorResult = coordinator.handleHelloError(
      const TcpDataReceivedHelloError(
        channelId: TcpDataChannelId('channel-1'),
        issueCode: 'malformed_tcp_data_hello',
        error: 'bad frame',
      ),
    );
    final lateHelloResult = coordinator.handleHello(
      received: const TcpDataReceivedHello(
        channelId: TcpDataChannelId('channel-1'),
        hello: hello,
      ),
      expectation: expectation,
    );

    expect(errorResult.registered, isFalse);
    expect(errorResult.issueCode, 'malformed_tcp_data_hello');
    expect(lateHelloResult.registered, isFalse);
    expect(lateHelloResult.issueCode, 'missing_tcp_data_accepted_connection');
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

TcpDataInboundListenerEventCoordinator _coordinator(
  DataChannelSessionRegistry registry,
) {
  return TcpDataInboundListenerEventCoordinator(
    command: TcpDataInboundHandshakeCommand(
      acceptedSessionFactory: const TcpDataAcceptedSessionFactory(),
      registryPromotionCommand: TcpDataSessionRegistryPromotionCommand(
        registry: registry,
        promotionCommand: TcpDataSessionPromotionCommand(
          handshakeCommand: TcpDataSessionHandshakeCommand(
            proofVerifier: const _AllowProofVerifier(),
          ),
        ),
      ),
    ),
  );
}

class _AllowProofVerifier implements TcpDataSessionProofVerifier {
  const _AllowProofVerifier();

  @override
  bool verify(TcpDataSessionHello hello) => true;
}
