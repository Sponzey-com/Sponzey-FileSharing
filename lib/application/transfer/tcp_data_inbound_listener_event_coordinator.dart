import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_registry_promotion_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataInboundListenerEventCoordinator {
  TcpDataInboundListenerEventCoordinator({required this.command});

  final TcpDataInboundHandshakeCommand command;
  final Map<TcpDataChannelId, TcpDataAcceptedConnection> _pendingAccepted = {};

  void handleAccepted(TcpDataAcceptedConnection accepted) {
    _pendingAccepted[accepted.channelId] = accepted;
  }

  TcpDataSessionRegistryPromotionResult handleHello({
    required TcpDataReceivedHello received,
    required TcpDataSessionHandshakeExpectation expectation,
  }) {
    final accepted = _pendingAccepted.remove(received.channelId);
    if (accepted == null) {
      return const TcpDataSessionRegistryPromotionResult(
        registered: false,
        issueCode: 'missing_tcp_data_accepted_connection',
      );
    }

    return command.handle(
      accepted: accepted,
      sessionId: received.hello.sessionId,
      hello: received.hello,
      expectation: expectation,
    );
  }

  TcpDataSessionRegistryPromotionResult handleHelloError(
    TcpDataReceivedHelloError error,
  ) {
    _pendingAccepted.remove(error.channelId);
    return TcpDataSessionRegistryPromotionResult(
      registered: false,
      issueCode: error.issueCode,
    );
  }
}
