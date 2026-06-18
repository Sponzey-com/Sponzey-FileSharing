import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_promotion_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataSessionRegistryPromotionResult {
  const TcpDataSessionRegistryPromotionResult({
    required this.registered,
    this.session,
    this.issueCode,
  });

  final bool registered;
  final TcpDataPeerSessionSnapshot? session;
  final String? issueCode;
}

class TcpDataSessionRegistryPromotionCommand {
  const TcpDataSessionRegistryPromotionCommand({
    required this.registry,
    required this.promotionCommand,
  });

  final DataChannelSessionRegistry registry;
  final TcpDataSessionPromotionCommand promotionCommand;

  TcpDataSessionRegistryPromotionResult promoteAndRegister({
    required TcpDataPeerSessionSnapshot session,
    required TcpDataSessionHello hello,
    required TcpDataSessionHandshakeExpectation expectation,
  }) {
    final promotion = promotionCommand.promoteIncomingHello(
      session: session,
      hello: hello,
      expectation: expectation,
    );
    if (!promotion.didTransition ||
        promotion.state.status != TcpDataPeerSessionStatus.connected) {
      return TcpDataSessionRegistryPromotionResult(
        registered: false,
        session: promotion.state,
        issueCode: promotion.issue?.code,
      );
    }

    final key = DataChannelSessionKey(
      peerId: promotion.state.peerId,
      authSessionId: expectation.authSessionId,
      direction: promotion.state.direction,
    );
    final registration = registry.register(key, promotion.state);
    return TcpDataSessionRegistryPromotionResult(
      registered: registration.registered,
      session: promotion.state,
      issueCode: registration.issueCode,
    );
  }
}
