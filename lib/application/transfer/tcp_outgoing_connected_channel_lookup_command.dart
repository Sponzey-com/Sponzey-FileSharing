import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpOutgoingConnectedChannelLookupResult {
  const TcpOutgoingConnectedChannelLookupResult({
    required this.found,
    this.channelId,
    this.session,
    this.issueCode,
  });

  final bool found;
  final TcpDataChannelId? channelId;
  final TcpDataPeerSessionSnapshot? session;
  final String? issueCode;
}

class TcpOutgoingConnectedChannelLookupCommand {
  const TcpOutgoingConnectedChannelLookupCommand();

  TcpOutgoingConnectedChannelLookupResult lookup({
    required DataChannelSessionRegistry registry,
    required String peerId,
    required String authSessionId,
  }) {
    final session = registry.lookup(
      DataChannelSessionKey(
        peerId: peerId,
        authSessionId: authSessionId,
        direction: TcpDataChannelDirection.outbound,
      ),
    );
    if (session == null) {
      return const TcpOutgoingConnectedChannelLookupResult(
        found: false,
        issueCode: 'missing_tcp_outgoing_data_channel',
      );
    }
    if (session.status != TcpDataPeerSessionStatus.connected) {
      return TcpOutgoingConnectedChannelLookupResult(
        found: false,
        session: session,
        issueCode: 'tcp_outgoing_data_channel_not_connected',
      );
    }
    return TcpOutgoingConnectedChannelLookupResult(
      found: true,
      channelId: session.channelId,
      session: session,
    );
  }
}
