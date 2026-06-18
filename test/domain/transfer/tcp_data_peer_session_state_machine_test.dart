import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

void main() {
  const machine = TcpDataPeerSessionStateMachine();

  const outboundSnapshot = TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: TcpDataSessionId('session-1'),
    channelId: TcpDataChannelId('channel-1'),
    direction: TcpDataChannelDirection.outbound,
    status: TcpDataPeerSessionStatus.idle,
    localEndpointLabel: '10.0.0.1:0',
    remoteEndpointLabel: '10.0.0.2:38420',
  );

  const inboundSnapshot = TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: TcpDataSessionId('session-1'),
    channelId: TcpDataChannelId('channel-2'),
    direction: TcpDataChannelDirection.inbound,
    status: TcpDataPeerSessionStatus.idle,
    localEndpointLabel: '10.0.0.1:38420',
    remoteEndpointLabel: '10.0.0.2:0',
  );

  test('outbound session connects only through negotiation and auth', () {
    var result = machine.transition(
      outboundSnapshot,
      TcpDataPeerSessionEvent.negotiationStarted,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.negotiating);
    expect(result.effects.single.name, 'negotiateTcpDataChannel');

    result = machine.transition(
      result.state,
      TcpDataPeerSessionEvent.outboundConnectRequested,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.connecting);
    expect(result.effects.single.name, 'openOutboundTcpDataChannel');

    result = machine.transition(
      result.state,
      TcpDataPeerSessionEvent.socketConnected,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.authenticating);
    expect(result.effects.single.name, 'sendTcpDataSessionHello');

    result = machine.transition(
      result.state,
      TcpDataPeerSessionEvent.authSucceeded,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.connected);
  });

  test('inbound session authenticates accepted socket before connected', () {
    var result = machine.transition(
      inboundSnapshot,
      TcpDataPeerSessionEvent.inboundSocketAccepted,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.accepting);
    expect(result.effects.single.name, 'acceptInboundTcpDataChannel');

    result = machine.transition(
      result.state,
      TcpDataPeerSessionEvent.socketConnected,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.authenticating);
    expect(result.effects.single.name, 'sendTcpDataSessionHello');

    result = machine.transition(
      result.state,
      TcpDataPeerSessionEvent.authSucceeded,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.connected);
  });

  test('connected session ignores discovery and route churn', () {
    final connected = outboundSnapshot.copyWith(
      status: TcpDataPeerSessionStatus.connected,
    );

    for (final event in [
      TcpDataPeerSessionEvent.discoveryStale,
      TcpDataPeerSessionEvent.routeCandidateObserved,
      TcpDataPeerSessionEvent.routeLeaseExpired,
    ]) {
      final result = machine.transition(connected, event);

      expect(result.state, same(connected));
      expect(result.disposition, TransitionDisposition.noOp);
      expect(result.issue?.code, 'tcp_data_session_locked_to_channel');
    }
  });

  test('socket close reconnects and socket error fails the session', () {
    final connected = outboundSnapshot.copyWith(
      status: TcpDataPeerSessionStatus.connected,
    );

    final closed = machine.transition(
      connected,
      TcpDataPeerSessionEvent.socketClosed,
    );
    expect(closed.state.status, TcpDataPeerSessionStatus.reconnecting);
    expect(closed.state.lastCloseReason, 'tcp_data_socket_closed');
    expect(closed.effects.single.name, 'scheduleTcpDataReconnect');

    final errored = machine.transition(
      connected,
      TcpDataPeerSessionEvent.socketError,
    );
    expect(errored.state.status, TcpDataPeerSessionStatus.failed);
    expect(errored.state.lastCloseReason, 'tcp_data_socket_error');
    expect(errored.isFailure, isTrue);
    expect(errored.issue?.code, 'tcp_data_socket_error');
  });

  test('successful auth clears previous close reason', () {
    final reconnecting = outboundSnapshot.copyWith(
      status: TcpDataPeerSessionStatus.authenticating,
      lastCloseReason: 'tcp_data_socket_closed',
    );

    final result = machine.transition(
      reconnecting,
      TcpDataPeerSessionEvent.authSucceeded,
    );

    expect(result.state.status, TcpDataPeerSessionStatus.connected);
    expect(result.state.lastCloseReason, isNull);
  });

  test('explicit disconnect closes through a tracked transition', () {
    final connected = outboundSnapshot.copyWith(
      status: TcpDataPeerSessionStatus.connected,
    );

    var result = machine.transition(
      connected,
      TcpDataPeerSessionEvent.explicitDisconnectRequested,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.closing);
    expect(result.state.lastCloseReason, 'tcp_data_explicit_disconnect');
    expect(result.effects.single.name, 'closeTcpDataChannel');

    result = machine.transition(
      result.state,
      TcpDataPeerSessionEvent.disconnectCompleted,
    );
    expect(result.state.status, TcpDataPeerSessionStatus.closed);
  });

  test('invalid transition returns warning with issue code', () {
    final result = machine.transition(
      outboundSnapshot,
      TcpDataPeerSessionEvent.authSucceeded,
    );

    expect(result.state, same(outboundSnapshot));
    expect(result.disposition, TransitionDisposition.warning);
    expect(result.issue?.code, 'invalid_tcp_data_peer_session_transition');
  });
}
