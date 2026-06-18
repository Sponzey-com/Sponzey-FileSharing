import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

export 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';

enum TcpDataEndpointDecisionType { connect, reject, noOp }

class TcpDataEndpointOfferContext {
  const TcpDataEndpointOfferContext({
    required this.offer,
    required this.isAuthenticated,
    required this.existingSessionStatus,
  });

  final TcpDataEndpointOffer offer;
  final bool isAuthenticated;
  final TcpDataPeerSessionStatus? existingSessionStatus;
}

class TcpDataEndpointDecision {
  const TcpDataEndpointDecision({
    required this.type,
    this.connectRequest,
    this.issueCode,
  });

  final TcpDataEndpointDecisionType type;
  final TcpDataConnectRequest? connectRequest;
  final String? issueCode;

  const TcpDataEndpointDecision.connect(this.connectRequest)
    : type = TcpDataEndpointDecisionType.connect,
      issueCode = null;

  const TcpDataEndpointDecision.reject({required this.issueCode})
    : type = TcpDataEndpointDecisionType.reject,
      connectRequest = null;

  const TcpDataEndpointDecision.noOp({required this.issueCode})
    : type = TcpDataEndpointDecisionType.noOp,
      connectRequest = null;
}

class TcpDataEndpointNegotiationCommand {
  const TcpDataEndpointNegotiationCommand();

  TcpDataEndpointDecision decideOffer(TcpDataEndpointOfferContext context) {
    if (context.existingSessionStatus == TcpDataPeerSessionStatus.connected) {
      return const TcpDataEndpointDecision.noOp(
        issueCode: 'tcp_data_session_already_connected',
      );
    }
    if (!context.isAuthenticated) {
      return const TcpDataEndpointDecision.reject(
        issueCode: 'unauthenticated_tcp_data_offer',
      );
    }
    if (!context.offer.endpoint.hasValidPort) {
      return const TcpDataEndpointDecision.reject(
        issueCode: 'invalid_tcp_data_endpoint_port',
      );
    }

    return TcpDataEndpointDecision.connect(
      TcpDataConnectRequest(
        peerId: context.offer.peerId,
        authSessionId: context.offer.authSessionId,
        sessionId: context.offer.sessionId,
        host: context.offer.host,
        port: context.offer.port,
      ),
    );
  }
}
