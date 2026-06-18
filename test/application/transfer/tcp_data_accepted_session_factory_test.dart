import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_accepted_session_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const factory = TcpDataAcceptedSessionFactory();

  test('creates authenticating inbound snapshot from accepted connection', () {
    final snapshot = factory.create(
      accepted: const TcpDataAcceptedConnection(
        channelId: TcpDataChannelId('channel-1'),
        localEndpoint: TcpDataEndpoint(host: '10.0.0.1', port: 50001),
        remoteEndpoint: TcpDataEndpoint(host: '10.0.0.2', port: 50000),
      ),
      sessionId: const TcpDataSessionId('session-1'),
      hello: const TcpDataSessionHello(
        sessionId: TcpDataSessionId('session-1'),
        peerId: 'peer-1',
        instanceId: 'instance-1',
        authSessionId: 'auth-1',
        protocolVersion: 1,
        dataProtocolVersion: 1,
        proof: 'proof-1',
      ),
    );

    expect(snapshot.peerId, 'peer-1');
    expect(snapshot.sessionId, const TcpDataSessionId('session-1'));
    expect(snapshot.channelId, const TcpDataChannelId('channel-1'));
    expect(snapshot.direction, TcpDataChannelDirection.inbound);
    expect(snapshot.status, TcpDataPeerSessionStatus.authenticating);
    expect(snapshot.localEndpointLabel, '10.0.0.1:50001');
    expect(snapshot.remoteEndpointLabel, '10.0.0.2:50000');
  });
}
