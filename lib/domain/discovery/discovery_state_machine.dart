import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum DiscoveryStatus {
  idle,
  starting,
  announcing,
  listening,
  scanning,
  active,
  degraded,
  stopping,
  stopped,
  failed,
}

enum DiscoveryEvent {
  startRequested,
  portReady,
  announceSent,
  listenStarted,
  scanRequested,
  helloReceived,
  heartbeatReceived,
  stopRequested,
  stopCompleted,
  socketError,
}

enum DiscoveryPeerStatus {
  unknown,
  seen,
  online,
  stale,
  offline,
  blocked,
  incompatible,
}

class DiscoveryStateMachine
    implements StateMachine<DiscoveryStatus, DiscoveryEvent> {
  const DiscoveryStateMachine();

  @override
  TransitionResult<DiscoveryStatus> transition(
    DiscoveryStatus state,
    DiscoveryEvent event,
  ) {
    switch ((state, event)) {
      case (DiscoveryStatus.idle, DiscoveryEvent.startRequested):
      case (DiscoveryStatus.stopped, DiscoveryEvent.startRequested):
        return TransitionResult.transitioned(
          DiscoveryStatus.starting,
          effects: const [TransitionEffect('bindDiscoveryPort')],
        );
      case (DiscoveryStatus.starting, DiscoveryEvent.portReady):
        return TransitionResult.transitioned(
          DiscoveryStatus.announcing,
          effects: const [TransitionEffect('sendDiscoveryAnnounce')],
        );
      case (DiscoveryStatus.announcing, DiscoveryEvent.announceSent):
        return TransitionResult.transitioned(
          DiscoveryStatus.listening,
          effects: const [TransitionEffect('startDiscoveryListener')],
        );
      case (DiscoveryStatus.listening, DiscoveryEvent.listenStarted):
        return TransitionResult.transitioned(DiscoveryStatus.active);
      case (DiscoveryStatus.active, DiscoveryEvent.scanRequested):
        return TransitionResult.transitioned(
          DiscoveryStatus.scanning,
          effects: const [TransitionEffect('sendDiscoveryProbe')],
        );
      case (DiscoveryStatus.scanning, DiscoveryEvent.helloReceived):
      case (DiscoveryStatus.scanning, DiscoveryEvent.heartbeatReceived):
        return TransitionResult.transitioned(DiscoveryStatus.active);
      case (DiscoveryStatus.active, DiscoveryEvent.helloReceived):
      case (DiscoveryStatus.active, DiscoveryEvent.heartbeatReceived):
        return TransitionResult.noOp(state);
      case (DiscoveryStatus.active, DiscoveryEvent.stopRequested):
      case (DiscoveryStatus.degraded, DiscoveryEvent.stopRequested):
        return TransitionResult.transitioned(
          DiscoveryStatus.stopping,
          effects: const [
            TransitionEffect('sendDiscoveryGoodbye'),
            TransitionEffect('cancelDiscoveryTimers'),
            TransitionEffect('closeDiscoveryPort'),
          ],
        );
      case (DiscoveryStatus.stopping, DiscoveryEvent.stopCompleted):
        return TransitionResult.transitioned(DiscoveryStatus.stopped);
      case (_, DiscoveryEvent.socketError):
        return TransitionResult.transitioned(
          DiscoveryStatus.degraded,
          effects: const [TransitionEffect('logDiscoverySocketError')],
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_discovery_transition',
            message: 'Cannot apply $event while discovery is $state.',
          ),
        );
    }
  }

  DiscoveryPeerStatus classifyPeer({
    required String localProtocolVersion,
    required String peerProtocolVersion,
    required DateTime now,
    required DateTime lastSeenAt,
    required Duration staleAfter,
    required Duration offlineAfter,
    bool blocked = false,
  }) {
    if (blocked) {
      return DiscoveryPeerStatus.blocked;
    }
    if (peerProtocolVersion != localProtocolVersion) {
      return DiscoveryPeerStatus.incompatible;
    }
    final age = now.difference(lastSeenAt);
    if (age >= offlineAfter) {
      return DiscoveryPeerStatus.offline;
    }
    if (age >= staleAfter) {
      return DiscoveryPeerStatus.stale;
    }
    return DiscoveryPeerStatus.online;
  }
}
