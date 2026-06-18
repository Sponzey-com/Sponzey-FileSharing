import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataAcceptedSessionFactory {
  const TcpDataAcceptedSessionFactory();

  TcpDataPeerSessionSnapshot create({
    required TcpDataAcceptedConnection accepted,
    required TcpDataSessionId sessionId,
    required TcpDataSessionHello hello,
  }) {
    return TcpDataPeerSessionSnapshot(
      peerId: hello.peerId,
      sessionId: sessionId,
      channelId: accepted.channelId,
      direction: TcpDataChannelDirection.inbound,
      status: TcpDataPeerSessionStatus.authenticating,
      localEndpointLabel: _label(accepted.localEndpoint),
      remoteEndpointLabel: _label(accepted.remoteEndpoint),
    );
  }

  String _label(TcpDataEndpoint endpoint) {
    return '${endpoint.host}:${endpoint.port}';
  }
}
