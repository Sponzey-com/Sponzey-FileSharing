import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataOutboundChannelOpenResult {
  const TcpDataOutboundChannelOpenResult({
    required this.opened,
    this.session,
    this.issueCode,
  });

  final bool opened;
  final TcpDataPeerSessionSnapshot? session;
  final String? issueCode;

  const TcpDataOutboundChannelOpenResult.opened(this.session)
    : opened = true,
      issueCode = null;

  const TcpDataOutboundChannelOpenResult.rejected({required this.issueCode})
    : opened = false,
      session = null;
}

class TcpDataOutboundChannelOpenCommand {
  const TcpDataOutboundChannelOpenCommand({
    required this.connector,
    required this.registry,
  });

  final TcpDataConnectorPort connector;
  final DataChannelSessionRegistry registry;

  Future<TcpDataOutboundChannelOpenResult> open({
    required TcpDataConnectRequest connectRequest,
    required TcpDataSessionHello hello,
  }) async {
    final key = DataChannelSessionKey(
      peerId: connectRequest.peerId,
      authSessionId: connectRequest.authSessionId,
      direction: TcpDataChannelDirection.outbound,
    );
    final existing = registry.lookup(key);
    if (existing?.status == TcpDataPeerSessionStatus.connected) {
      return const TcpDataOutboundChannelOpenResult.rejected(
        issueCode: 'tcp_data_outbound_already_connected',
      );
    }
    if (hello.sessionId != connectRequest.sessionId ||
        hello.authSessionId != connectRequest.authSessionId) {
      return const TcpDataOutboundChannelOpenResult.rejected(
        issueCode: 'tcp_data_outbound_hello_mismatch',
      );
    }

    final TcpDataChannelId channelId;
    try {
      channelId = await connector.connect(connectRequest);
      await connector.sendHello(channelId, hello);
    } catch (_) {
      return const TcpDataOutboundChannelOpenResult.rejected(
        issueCode: 'tcp_data_outbound_connect_failed',
      );
    }

    final session = TcpDataPeerSessionSnapshot(
      peerId: connectRequest.peerId,
      sessionId: connectRequest.sessionId,
      channelId: channelId,
      direction: TcpDataChannelDirection.outbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: 'tcp-outbound',
      remoteEndpointLabel: '${connectRequest.host}:${connectRequest.port}',
    );
    final registration = registry.register(key, session);
    if (!registration.registered) {
      return TcpDataOutboundChannelOpenResult.rejected(
        issueCode:
            registration.issueCode ?? 'tcp_data_outbound_register_failed',
      );
    }

    return TcpDataOutboundChannelOpenResult.opened(session);
  }
}
