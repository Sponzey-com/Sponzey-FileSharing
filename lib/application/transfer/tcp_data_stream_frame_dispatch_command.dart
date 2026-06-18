import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

class TcpDataStreamFrameDispatchDecision {
  const TcpDataStreamFrameDispatchDecision({
    required this.allowed,
    this.route,
    this.peerId,
    this.authSessionId,
    this.session,
    this.transferId,
    this.frame,
    this.issueCode,
  });

  final bool allowed;
  final TcpDataStreamFrameRoute? route;
  final String? peerId;
  final String? authSessionId;
  final TcpDataPeerSessionSnapshot? session;
  final String? transferId;
  final TcpDataStreamFrame? frame;
  final String? issueCode;
}

class TcpDataStreamFrameDispatchCommand {
  const TcpDataStreamFrameDispatchCommand({
    required this.contextCommand,
    required this.dispatcher,
  });

  final TcpDataStreamFrameChannelContextCommand contextCommand;
  final TcpDataStreamFrameDispatcher dispatcher;

  TcpDataStreamFrameDispatchDecision decide({
    required DataChannelSessionRegistry registry,
    required TcpDataReceivedStreamFrame received,
  }) {
    final context = contextCommand.resolve(
      registry: registry,
      received: received,
    );
    if (!context.allowed) {
      return TcpDataStreamFrameDispatchDecision(
        allowed: false,
        issueCode: context.issueCode,
      );
    }

    return TcpDataStreamFrameDispatchDecision(
      allowed: true,
      route: dispatcher.routeFor(received.frame.type),
      peerId: context.peerId,
      authSessionId: context.authSessionId,
      session: context.session,
      transferId: received.frame.transferId,
      frame: received.frame,
    );
  }
}
