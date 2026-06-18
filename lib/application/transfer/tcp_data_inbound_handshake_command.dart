import 'package:sponzey_file_sharing/application/transfer/tcp_data_accepted_session_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_registry_promotion_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataInboundHandshakeCommand {
  const TcpDataInboundHandshakeCommand({
    required this.acceptedSessionFactory,
    required this.registryPromotionCommand,
  });

  final TcpDataAcceptedSessionFactory acceptedSessionFactory;
  final TcpDataSessionRegistryPromotionCommand registryPromotionCommand;

  TcpDataSessionRegistryPromotionResult handle({
    required TcpDataAcceptedConnection accepted,
    required TcpDataSessionId sessionId,
    required TcpDataSessionHello hello,
    required TcpDataSessionHandshakeExpectation expectation,
  }) {
    final session = acceptedSessionFactory.create(
      accepted: accepted,
      sessionId: sessionId,
      hello: hello,
    );
    return registryPromotionCommand.promoteAndRegister(
      session: session,
      hello: hello,
      expectation: expectation,
    );
  }
}
