import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataStreamFrameChannelContextResult {
  const TcpDataStreamFrameChannelContextResult({
    required this.allowed,
    this.peerId,
    this.authSessionId,
    this.session,
    this.issueCode,
  });

  final bool allowed;
  final String? peerId;
  final String? authSessionId;
  final TcpDataPeerSessionSnapshot? session;
  final String? issueCode;
}

class TcpDataStreamFrameChannelContextCommand {
  const TcpDataStreamFrameChannelContextCommand();

  TcpDataStreamFrameChannelContextResult resolve({
    required DataChannelSessionRegistry registry,
    required TcpDataReceivedStreamFrame received,
  }) {
    final lookup = registry.lookupContextByChannelId(
      direction: TcpDataChannelDirection.inbound,
      channelId: received.channelId,
    );
    if (lookup == null) {
      return const TcpDataStreamFrameChannelContextResult(
        allowed: false,
        issueCode: 'missing_tcp_data_channel_context',
      );
    }

    return TcpDataStreamFrameChannelContextResult(
      allowed: true,
      peerId: lookup.key.peerId,
      authSessionId: lookup.key.authSessionId,
      session: lookup.session,
    );
  }
}
