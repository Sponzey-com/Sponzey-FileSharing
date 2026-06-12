import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/discovery/udp_port_state_machine.dart';

void main() {
  const machine = UdpPortStateMachine();

  test('binds and starts listening', () {
    var result = machine.transition(
      UdpPortStatus.unbound,
      UdpPortEvent.bindRequested,
    );
    expect(result.state, UdpPortStatus.binding);

    result = machine.transition(result.state, UdpPortEvent.bindSucceeded);
    expect(result.state, UdpPortStatus.bound);

    result = machine.transition(result.state, UdpPortEvent.listenStarted);
    expect(result.state, UdpPortStatus.listening);
  });

  test('binding failure becomes a failed transition', () {
    final result = machine.transition(
      UdpPortStatus.binding,
      UdpPortEvent.bindFailed,
    );

    expect(result.state, UdpPortStatus.failed);
    expect(result.disposition, TransitionDisposition.failure);
    expect(result.issue?.code, 'udp_port_bind_failed');
  });

  test('closed port state machines are not reused', () {
    final result = machine.transition(
      UdpPortStatus.closed,
      UdpPortEvent.bindRequested,
    );

    expect(result.isFailure, isTrue);
    expect(result.issue?.code, 'udp_port_reuse_forbidden');
  });
}
