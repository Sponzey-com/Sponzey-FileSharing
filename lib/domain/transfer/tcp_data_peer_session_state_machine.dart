import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum TcpDataPeerSessionStatus {
  idle,
  negotiating,
  connecting,
  accepting,
  authenticating,
  connected,
  reconnecting,
  closing,
  closed,
  failed,
}

enum TcpDataPeerSessionEvent {
  negotiationStarted,
  outboundConnectRequested,
  inboundSocketAccepted,
  socketConnected,
  authSucceeded,
  authFailed,
  discoveryStale,
  routeCandidateObserved,
  routeLeaseExpired,
  socketClosed,
  socketError,
  explicitDisconnectRequested,
  disconnectCompleted,
}

enum TcpDataChannelDirection { outbound, inbound }

class TcpDataSessionId {
  const TcpDataSessionId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TcpDataSessionId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class TcpDataChannelId {
  const TcpDataChannelId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TcpDataChannelId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class TcpDataPeerSessionSnapshot {
  const TcpDataPeerSessionSnapshot({
    required this.peerId,
    required this.sessionId,
    required this.channelId,
    required this.direction,
    required this.status,
    required this.localEndpointLabel,
    required this.remoteEndpointLabel,
    this.lastCloseReason,
  });

  final String peerId;
  final TcpDataSessionId sessionId;
  final TcpDataChannelId channelId;
  final TcpDataChannelDirection direction;
  final TcpDataPeerSessionStatus status;
  final String localEndpointLabel;
  final String remoteEndpointLabel;
  final String? lastCloseReason;

  TcpDataPeerSessionSnapshot copyWith({
    String? peerId,
    TcpDataSessionId? sessionId,
    TcpDataChannelId? channelId,
    TcpDataChannelDirection? direction,
    TcpDataPeerSessionStatus? status,
    String? localEndpointLabel,
    String? remoteEndpointLabel,
    String? lastCloseReason,
    bool clearLastCloseReason = false,
  }) {
    return TcpDataPeerSessionSnapshot(
      peerId: peerId ?? this.peerId,
      sessionId: sessionId ?? this.sessionId,
      channelId: channelId ?? this.channelId,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      localEndpointLabel: localEndpointLabel ?? this.localEndpointLabel,
      remoteEndpointLabel: remoteEndpointLabel ?? this.remoteEndpointLabel,
      lastCloseReason: clearLastCloseReason
          ? null
          : lastCloseReason ?? this.lastCloseReason,
    );
  }
}

class TcpDataPeerSessionStateMachine
    implements
        StateMachine<TcpDataPeerSessionSnapshot, TcpDataPeerSessionEvent> {
  const TcpDataPeerSessionStateMachine();

  @override
  TransitionResult<TcpDataPeerSessionSnapshot> transition(
    TcpDataPeerSessionSnapshot state,
    TcpDataPeerSessionEvent event,
  ) {
    switch ((state.status, event)) {
      case (
        TcpDataPeerSessionStatus.idle,
        TcpDataPeerSessionEvent.negotiationStarted,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: TcpDataPeerSessionStatus.negotiating),
          effects: const [TransitionEffect('negotiateTcpDataChannel')],
        );
      case (
        TcpDataPeerSessionStatus.negotiating,
        TcpDataPeerSessionEvent.outboundConnectRequested,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: TcpDataPeerSessionStatus.connecting),
          effects: const [TransitionEffect('openOutboundTcpDataChannel')],
        );
      case (
        TcpDataPeerSessionStatus.idle,
        TcpDataPeerSessionEvent.inboundSocketAccepted,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: TcpDataPeerSessionStatus.accepting),
          effects: const [TransitionEffect('acceptInboundTcpDataChannel')],
        );
      case (
        TcpDataPeerSessionStatus.connecting,
        TcpDataPeerSessionEvent.socketConnected,
      ):
      case (
        TcpDataPeerSessionStatus.accepting,
        TcpDataPeerSessionEvent.socketConnected,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: TcpDataPeerSessionStatus.authenticating),
          effects: const [TransitionEffect('sendTcpDataSessionHello')],
        );
      case (
        TcpDataPeerSessionStatus.authenticating,
        TcpDataPeerSessionEvent.authSucceeded,
      ):
        return TransitionResult.transitioned(
          state.copyWith(
            status: TcpDataPeerSessionStatus.connected,
            clearLastCloseReason: true,
          ),
        );
      case (
        TcpDataPeerSessionStatus.authenticating,
        TcpDataPeerSessionEvent.authFailed,
      ):
        return TransitionResult.failure(
          state.copyWith(
            status: TcpDataPeerSessionStatus.failed,
            lastCloseReason: 'tcp_data_auth_failed',
          ),
          issue: const TransitionIssue(
            code: 'tcp_data_auth_failed',
            message: 'TCP data session authentication failed.',
          ),
        );
      case (
        TcpDataPeerSessionStatus.connected,
        TcpDataPeerSessionEvent.discoveryStale,
      ):
      case (
        TcpDataPeerSessionStatus.connected,
        TcpDataPeerSessionEvent.routeCandidateObserved,
      ):
      case (
        TcpDataPeerSessionStatus.connected,
        TcpDataPeerSessionEvent.routeLeaseExpired,
      ):
        return TransitionResult.noOp(
          state,
          issue: const TransitionIssue(
            code: 'tcp_data_session_locked_to_channel',
            message:
                'Connected TCP data session ignores discovery and route churn.',
          ),
        );
      case (
        TcpDataPeerSessionStatus.connected,
        TcpDataPeerSessionEvent.socketClosed,
      ):
        return TransitionResult.transitioned(
          state.copyWith(
            status: TcpDataPeerSessionStatus.reconnecting,
            lastCloseReason: 'tcp_data_socket_closed',
          ),
          effects: const [TransitionEffect('scheduleTcpDataReconnect')],
        );
      case (_, TcpDataPeerSessionEvent.socketError):
        return TransitionResult.failure(
          state.copyWith(
            status: TcpDataPeerSessionStatus.failed,
            lastCloseReason: 'tcp_data_socket_error',
          ),
          issue: const TransitionIssue(
            code: 'tcp_data_socket_error',
            message: 'TCP data socket reported an error.',
          ),
        );
      case (
        TcpDataPeerSessionStatus.connected,
        TcpDataPeerSessionEvent.explicitDisconnectRequested,
      ):
      case (
        TcpDataPeerSessionStatus.reconnecting,
        TcpDataPeerSessionEvent.explicitDisconnectRequested,
      ):
        return TransitionResult.transitioned(
          state.copyWith(
            status: TcpDataPeerSessionStatus.closing,
            lastCloseReason: 'tcp_data_explicit_disconnect',
          ),
          effects: const [TransitionEffect('closeTcpDataChannel')],
        );
      case (
        TcpDataPeerSessionStatus.closing,
        TcpDataPeerSessionEvent.disconnectCompleted,
      ):
        return TransitionResult.transitioned(
          state.copyWith(status: TcpDataPeerSessionStatus.closed),
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_tcp_data_peer_session_transition',
            message:
                'Cannot apply $event while TCP data session is ${state.status}.',
          ),
        );
    }
  }
}
