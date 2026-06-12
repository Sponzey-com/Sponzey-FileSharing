import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/discovery/discovery_state_machine.dart';

void main() {
  const machine = DiscoveryStateMachine();

  test('starts, announces, listens, and stops discovery', () {
    var result = machine.transition(
      DiscoveryStatus.idle,
      DiscoveryEvent.startRequested,
    );
    expect(result.state, DiscoveryStatus.starting);

    result = machine.transition(result.state, DiscoveryEvent.portReady);
    expect(result.state, DiscoveryStatus.announcing);

    result = machine.transition(result.state, DiscoveryEvent.announceSent);
    expect(result.state, DiscoveryStatus.listening);

    result = machine.transition(result.state, DiscoveryEvent.listenStarted);
    expect(result.state, DiscoveryStatus.active);

    result = machine.transition(result.state, DiscoveryEvent.stopRequested);
    expect(result.state, DiscoveryStatus.stopping);
    expect(
      result.effects.map((effect) => effect.name),
      containsAll([
        'sendDiscoveryGoodbye',
        'cancelDiscoveryTimers',
        'closeDiscoveryPort',
      ]),
    );
  });

  test('classifies protocol mismatch peers as incompatible', () {
    final status = machine.classifyPeer(
      localProtocolVersion: '1.0',
      peerProtocolVersion: '2.0',
      now: DateTime(2026),
      lastSeenAt: DateTime(2026),
      staleAfter: const Duration(seconds: 10),
      offlineAfter: const Duration(seconds: 30),
    );

    expect(status, DiscoveryPeerStatus.incompatible);
  });

  test('classifies peers as stale and offline by heartbeat age', () {
    final now = DateTime(2026, 1, 1, 12);

    expect(
      machine.classifyPeer(
        localProtocolVersion: '1.0',
        peerProtocolVersion: '1.0',
        now: now,
        lastSeenAt: now.subtract(const Duration(seconds: 10)),
        staleAfter: const Duration(seconds: 10),
        offlineAfter: const Duration(seconds: 30),
      ),
      DiscoveryPeerStatus.stale,
    );

    expect(
      machine.classifyPeer(
        localProtocolVersion: '1.0',
        peerProtocolVersion: '1.0',
        now: now,
        lastSeenAt: now.subtract(const Duration(seconds: 30)),
        staleAfter: const Duration(seconds: 10),
        offlineAfter: const Duration(seconds: 30),
      ),
      DiscoveryPeerStatus.offline,
    );
  });
}
