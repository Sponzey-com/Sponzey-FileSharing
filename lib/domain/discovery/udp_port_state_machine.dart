import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum UdpPortStatus {
  unbound,
  binding,
  bound,
  listening,
  degraded,
  closing,
  closed,
  failed,
}

enum UdpPortEvent {
  bindRequested,
  bindSucceeded,
  bindFailed,
  listenStarted,
  receiveError,
  recoverRequested,
  closeRequested,
  closeCompleted,
}

class UdpPortStateMachine implements StateMachine<UdpPortStatus, UdpPortEvent> {
  const UdpPortStateMachine();

  @override
  TransitionResult<UdpPortStatus> transition(
    UdpPortStatus state,
    UdpPortEvent event,
  ) {
    switch ((state, event)) {
      case (UdpPortStatus.unbound, UdpPortEvent.bindRequested):
        return TransitionResult.transitioned(
          UdpPortStatus.binding,
          effects: const [TransitionEffect('bindUdpPort')],
        );
      case (UdpPortStatus.binding, UdpPortEvent.bindSucceeded):
        return TransitionResult.transitioned(UdpPortStatus.bound);
      case (UdpPortStatus.binding, UdpPortEvent.bindFailed):
        return TransitionResult.failure(
          UdpPortStatus.failed,
          issue: const TransitionIssue(
            code: 'udp_port_bind_failed',
            message: 'UDP port binding failed.',
          ),
        );
      case (UdpPortStatus.bound, UdpPortEvent.listenStarted):
        return TransitionResult.transitioned(UdpPortStatus.listening);
      case (UdpPortStatus.listening, UdpPortEvent.receiveError):
        return TransitionResult.transitioned(
          UdpPortStatus.degraded,
          effects: const [TransitionEffect('scheduleUdpPortRecovery')],
        );
      case (UdpPortStatus.degraded, UdpPortEvent.recoverRequested):
        return TransitionResult.transitioned(
          UdpPortStatus.listening,
          effects: const [TransitionEffect('resumeUdpReceiveLoop')],
        );
      case (UdpPortStatus.bound, UdpPortEvent.closeRequested):
      case (UdpPortStatus.listening, UdpPortEvent.closeRequested):
      case (UdpPortStatus.degraded, UdpPortEvent.closeRequested):
        return TransitionResult.transitioned(
          UdpPortStatus.closing,
          effects: const [TransitionEffect('closeUdpPort')],
        );
      case (UdpPortStatus.closing, UdpPortEvent.closeCompleted):
        return TransitionResult.transitioned(UdpPortStatus.closed);
      case (UdpPortStatus.closed, UdpPortEvent.bindRequested):
        return TransitionResult.failure(
          state,
          issue: const TransitionIssue(
            code: 'udp_port_reuse_forbidden',
            message: 'Closed UDP port state machines are not reused.',
          ),
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_udp_port_transition',
            message: 'Cannot apply $event while UDP port is $state.',
          ),
        );
    }
  }
}
