import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

void main() {
  group('PeerPathSelectionPolicy', () {
    test('selects the lower RTT candidate', () {
      final selection = const PeerPathSelectionPolicy().select(
        candidates: [
          _candidate(id: 'a', rttMs: 40, localAddress: '10.0.1.10'),
          _candidate(id: 'b', rttMs: 10, localAddress: '10.0.2.10'),
        ],
        selectedAt: DateTime.utc(2026),
      );

      expect(selection!.path.candidate.remoteAddress, '10.0.2.20');
    });

    test('prioritizes same subnet candidate', () {
      final selection = const PeerPathSelectionPolicy().select(
        candidates: [
          _candidate(
            id: 'a',
            rttMs: 5,
            localAddress: '10.0.2.10',
            remoteAddress: '10.0.1.20',
          ),
          _candidate(
            id: 'b',
            rttMs: 80,
            localAddress: '10.0.1.10',
            remoteAddress: '10.0.1.20',
          ),
        ],
        selectedAt: DateTime.utc(2026),
      );

      expect(selection!.reason, PeerPathSelectionReason.sameSubnet);
      expect(selection.path.candidate.localAddress, '10.0.1.10');
    });

    test('prioritizes previous successful candidate', () {
      final previous = _candidate(id: 'previous', rttMs: 100);
      final selection =
          PeerPathSelectionPolicy(
            previousSuccessCandidateIds: {previous.candidateId},
          ).select(
            candidates: [
              previous,
              _candidate(id: 'new', rttMs: 1),
            ],
            selectedAt: DateTime.utc(2026),
          );

      expect(selection!.reason, PeerPathSelectionReason.previousSuccess);
      expect(selection.path.candidate.candidateId, previous.candidateId);
    });

    test('penalizes failure count and virtual interfaces', () {
      final selection = const PeerPathSelectionPolicy().select(
        candidates: [
          _candidate(id: 'failed', failureCount: 3, rttMs: 5),
          _candidate(
            id: 'virtual',
            rttMs: 5,
            typeHint: InterfaceTypeHint.virtual,
          ),
          _candidate(id: 'healthy', rttMs: 20),
        ],
        selectedAt: DateTime.utc(2026),
      );

      expect(selection!.path.candidate.localInterfaceId.name, 'healthy');
    });

    test('prioritizes bridge over host-only virtual candidate', () {
      final selection = const PeerPathSelectionPolicy().select(
        candidates: [
          _candidate(
            id: 'vmnet8',
            rttMs: 5,
            typeHint: InterfaceTypeHint.virtual,
          ),
          _candidate(
            id: 'bridge100',
            rttMs: 5,
            typeHint: InterfaceTypeHint.bridge,
          ),
        ],
        selectedAt: DateTime.utc(2026),
      );

      expect(selection!.path.candidate.localInterfaceId.name, 'bridge100');
    });

    test('prioritizes fresh candidate over degraded candidate', () {
      final selection = const PeerPathSelectionPolicy().select(
        candidates: [
          _candidate(
            id: 'degraded',
            rttMs: 5,
            status: RouteCandidateStatus.degraded,
          ),
          _candidate(id: 'fresh', rttMs: 20),
        ],
        selectedAt: DateTime.utc(2026),
      );

      expect(selection!.path.candidate.localInterfaceId.name, 'fresh');
    });

    test('uses deterministic tie breaker', () {
      final selection = const PeerPathSelectionPolicy().select(
        candidates: [
          _candidate(id: 'b'),
          _candidate(id: 'a'),
        ],
        selectedAt: DateTime.utc(2026),
      );

      expect(selection!.path.candidate.localInterfaceId.name, 'a');
    });
  });

  group('PeerConnectionPathStateMachine', () {
    test('transitions through probe and auth success', () {
      const machine = PeerConnectionPathStateMachine();
      var path = PeerConnectionPath.fromCandidate(
        candidate: _candidate(id: 'a'),
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.deterministicTieBreaker,
      );

      var result = machine.transition(path, PeerPathEvent.probeStarted);
      expect(result.state.status, PeerPathStatus.probing);
      expect(result.effects.single.name, 'sendControlProbe');

      result = machine.transition(result.state, PeerPathEvent.probeSucceeded);
      expect(result.state.status, PeerPathStatus.probeSucceeded);

      result = machine.transition(result.state, PeerPathEvent.authStarted);
      result = machine.transition(result.state, PeerPathEvent.authSucceeded);
      expect(result.state.status, PeerPathStatus.active);
    });

    test('can authenticate directly without a separate probe packet', () {
      const machine = PeerConnectionPathStateMachine();
      final path = PeerConnectionPath.fromCandidate(
        candidate: _candidate(id: 'a'),
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.deterministicTieBreaker,
      );

      final authenticating = machine.transition(
        path,
        PeerPathEvent.authStarted,
      );
      final active = machine.transition(
        authenticating.state,
        PeerPathEvent.authSucceeded,
      );

      expect(authenticating.state.status, PeerPathStatus.authenticating);
      expect(active.state.status, PeerPathStatus.active);
    });

    test('separates probe failure from authentication failure', () {
      const machine = PeerConnectionPathStateMachine();
      final path = PeerConnectionPath.fromCandidate(
        candidate: _candidate(id: 'a'),
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.deterministicTieBreaker,
      );

      final probing = machine.transition(path, PeerPathEvent.probeStarted);
      final failed = machine.transition(
        probing.state,
        PeerPathEvent.probeFailed,
      );

      expect(failed.disposition, TransitionDisposition.failure);
      expect(failed.state.status, PeerPathStatus.probeFailed);
      expect(failed.issue!.code, 'peer_path_probe_failed');
    });

    test('moves active path into failover requested', () {
      const machine = PeerConnectionPathStateMachine();
      final path = PeerConnectionPath.fromCandidate(
        candidate: _candidate(id: 'a'),
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.deterministicTieBreaker,
      ).copyWith(status: PeerPathStatus.active);

      final result = machine.transition(path, PeerPathEvent.failoverRequested);

      expect(result.state.status, PeerPathStatus.failoverRequested);
      expect(result.effects.single.name, 'selectFailoverPath');
    });
  });
}

PeerRouteCandidate _candidate({
  required String id,
  int? rttMs,
  int failureCount = 0,
  String localAddress = '10.0.1.10',
  String? remoteAddress,
  InterfaceTypeHint typeHint = InterfaceTypeHint.ethernet,
  RouteCandidateStatus status = RouteCandidateStatus.fresh,
}) {
  return PeerRouteCandidate.create(
    peerId: 'user@device',
    remoteAddress:
        remoteAddress ??
        (localAddress.startsWith('10.0.1.') ? '10.0.1.20' : '10.0.2.20'),
    remotePort: 38401,
    localInterfaceId: NetworkInterfaceId(name: id, index: id.codeUnitAt(0)),
    localAddress: localAddress,
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    rttMs: rttMs,
    failureCount: failureCount,
    localInterfaceTypeHint: typeHint,
    status: status,
  );
}
