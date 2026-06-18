import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_endpoint_negotiation_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const command = TcpDataEndpointNegotiationCommand();
  const offer = TcpDataEndpointOffer(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    sessionId: TcpDataSessionId('session-1'),
    host: '10.0.0.2',
    port: 50100,
  );

  test('rejects endpoint offer from unauthenticated peer', () {
    final decision = command.decideOffer(
      TcpDataEndpointOfferContext(
        offer: offer,
        isAuthenticated: false,
        existingSessionStatus: null,
      ),
    );

    expect(decision.type, TcpDataEndpointDecisionType.reject);
    expect(decision.issueCode, 'unauthenticated_tcp_data_offer');
  });

  test('creates connect decision for authenticated endpoint offer', () {
    final decision = command.decideOffer(
      TcpDataEndpointOfferContext(
        offer: offer,
        isAuthenticated: true,
        existingSessionStatus: null,
      ),
    );

    expect(decision.type, TcpDataEndpointDecisionType.connect);
    expect(decision.connectRequest?.peerId, offer.peerId);
    expect(decision.connectRequest?.host, offer.host);
    expect(decision.connectRequest?.port, offer.port);
    expect(decision.issueCode, isNull);
  });

  test('keeps existing connected session instead of reconnecting', () {
    final decision = command.decideOffer(
      TcpDataEndpointOfferContext(
        offer: offer,
        isAuthenticated: true,
        existingSessionStatus: TcpDataPeerSessionStatus.connected,
      ),
    );

    expect(decision.type, TcpDataEndpointDecisionType.noOp);
    expect(decision.issueCode, 'tcp_data_session_already_connected');
    expect(decision.connectRequest, isNull);
  });

  test('rejects invalid offered port before connector boundary', () {
    final decision = command.decideOffer(
      const TcpDataEndpointOfferContext(
        offer: TcpDataEndpointOffer(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          sessionId: TcpDataSessionId('session-1'),
          host: '10.0.0.2',
          port: 0,
        ),
        isAuthenticated: true,
        existingSessionStatus: null,
      ),
    );

    expect(decision.type, TcpDataEndpointDecisionType.reject);
    expect(decision.issueCode, 'invalid_tcp_data_endpoint_port');
  });
}
