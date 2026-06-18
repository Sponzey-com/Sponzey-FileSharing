import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_outbound_channel_open_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  const connectRequest = TcpDataConnectRequest(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    sessionId: TcpDataSessionId('session-1'),
    host: '10.0.0.2',
    port: 50100,
  );
  const hello = TcpDataSessionHello(
    sessionId: TcpDataSessionId('session-1'),
    peerId: 'local-peer-1',
    instanceId: 'local-instance-1',
    authSessionId: 'auth-1',
    protocolVersion: 1,
    dataProtocolVersion: 1,
    proof: 'auth-1',
  );

  test(
    'connects, sends hello, and registers outbound connected session',
    () async {
      final registry = InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      );
      final connector = _RecordingTcpConnector();
      final command = TcpDataOutboundChannelOpenCommand(
        connector: connector,
        registry: registry,
      );

      final result = await command.open(
        connectRequest: connectRequest,
        hello: hello,
      );

      expect(result.opened, isTrue);
      expect(result.issueCode, isNull);
      expect(connector.calls, ['connect:10.0.0.2:50100', 'hello:channel-1']);
      final session = registry.lookup(
        const DataChannelSessionKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          direction: TcpDataChannelDirection.outbound,
        ),
      );
      expect(session?.status, TcpDataPeerSessionStatus.connected);
      expect(session?.channelId, const TcpDataChannelId('channel-1'));
    },
  );

  test('allows hello peer id to identify the local connector peer', () async {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final connector = _RecordingTcpConnector();
    final command = TcpDataOutboundChannelOpenCommand(
      connector: connector,
      registry: registry,
    );

    final result = await command.open(
      connectRequest: connectRequest,
      hello: hello,
    );

    expect(result.opened, isTrue);
    expect(connector.sentHellos.single.peerId, 'local-peer-1');
    expect(
      registry.lookup(
        const DataChannelSessionKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          direction: TcpDataChannelDirection.outbound,
        ),
      ),
      isNotNull,
    );
  });

  test('rejects hello session mismatch', () async {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final connector = _RecordingTcpConnector();
    final command = TcpDataOutboundChannelOpenCommand(
      connector: connector,
      registry: registry,
    );

    final result = await command.open(
      connectRequest: connectRequest,
      hello: const TcpDataSessionHello(
        sessionId: TcpDataSessionId('different-session'),
        peerId: 'local-peer-1',
        instanceId: 'local-instance-1',
        authSessionId: 'auth-1',
        protocolVersion: 1,
        dataProtocolVersion: 1,
        proof: 'auth-1',
      ),
    );

    expect(result.opened, isFalse);
    expect(result.issueCode, 'tcp_data_outbound_hello_mismatch');
    expect(connector.calls, isEmpty);
  });

  test(
    'does not reconnect when outbound session is already connected',
    () async {
      final registry = InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      );
      registry.register(
        const DataChannelSessionKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          direction: TcpDataChannelDirection.outbound,
        ),
        const TcpDataPeerSessionSnapshot(
          peerId: 'peer-1',
          sessionId: TcpDataSessionId('session-existing'),
          channelId: TcpDataChannelId('channel-existing'),
          direction: TcpDataChannelDirection.outbound,
          status: TcpDataPeerSessionStatus.connected,
          localEndpointLabel: 'existing-local',
          remoteEndpointLabel: 'existing-remote',
        ),
      );
      final connector = _RecordingTcpConnector();
      final command = TcpDataOutboundChannelOpenCommand(
        connector: connector,
        registry: registry,
      );

      final result = await command.open(
        connectRequest: connectRequest,
        hello: hello,
      );

      expect(result.opened, isFalse);
      expect(result.issueCode, 'tcp_data_outbound_already_connected');
      expect(connector.calls, isEmpty);
    },
  );

  test('does not register session when connector fails', () async {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    final connector = _RecordingTcpConnector(failConnect: true);
    final command = TcpDataOutboundChannelOpenCommand(
      connector: connector,
      registry: registry,
    );

    final result = await command.open(
      connectRequest: connectRequest,
      hello: hello,
    );

    expect(result.opened, isFalse);
    expect(result.issueCode, 'tcp_data_outbound_connect_failed');
    expect(
      registry.lookup(
        const DataChannelSessionKey(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          direction: TcpDataChannelDirection.outbound,
        ),
      ),
      isNull,
    );
  });
}

class _RecordingTcpConnector implements TcpDataConnectorPort {
  _RecordingTcpConnector({this.failConnect = false});

  final bool failConnect;
  final List<String> calls = [];
  final List<TcpDataSessionHello> sentHellos = [];

  @override
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request) async {
    calls.add('connect:${request.host}:${request.port}');
    if (failConnect) {
      throw StateError('connect failed');
    }
    return const TcpDataChannelId('channel-1');
  }

  @override
  Future<void> sendHello(
    TcpDataChannelId channelId,
    TcpDataSessionHello hello,
  ) async {
    calls.add('hello:${channelId.value}');
    sentHellos.add(hello);
  }

  @override
  Future<void> sendFrame(
    TcpDataChannelId channelId,
    TcpDataStreamFrame frame,
  ) async {}

  @override
  Future<void> close() async {}
}
