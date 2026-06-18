import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_outgoing_connected_channel_lookup_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart';

class TcpPeerFileSendResult {
  const TcpPeerFileSendResult({
    required this.sent,
    this.framesSent = 0,
    this.bytesSent = 0,
    this.issueCode,
  });

  final bool sent;
  final int framesSent;
  final int bytesSent;
  final String? issueCode;
}

abstract interface class TcpPeerFileSenderPort {
  Future<TcpPeerFileSendResult> send({
    required DataChannelSessionRegistry registry,
    required String peerId,
    required String authSessionId,
    required String transferId,
    required String filePath,
    required int chunkSize,
  });
}

class TcpPeerFileSendCommand implements TcpPeerFileSenderPort {
  const TcpPeerFileSendCommand({
    required this.channelLookupCommand,
    required this.sender,
  });

  final TcpOutgoingConnectedChannelLookupCommand channelLookupCommand;
  final TcpOutgoingTransferStreamSenderPort sender;

  @override
  Future<TcpPeerFileSendResult> send({
    required DataChannelSessionRegistry registry,
    required String peerId,
    required String authSessionId,
    required String transferId,
    required String filePath,
    required int chunkSize,
  }) async {
    final channel = channelLookupCommand.lookup(
      registry: registry,
      peerId: peerId,
      authSessionId: authSessionId,
    );
    if (!channel.found || channel.channelId == null) {
      return TcpPeerFileSendResult(sent: false, issueCode: channel.issueCode);
    }

    final result = await sender.send(
      channelId: channel.channelId!,
      transferId: transferId,
      filePath: filePath,
      chunkSize: chunkSize,
    );
    return TcpPeerFileSendResult(
      sent: result.sent,
      framesSent: result.framesSent,
      bytesSent: result.bytesSent,
      issueCode: result.issueCode,
    );
  }
}
