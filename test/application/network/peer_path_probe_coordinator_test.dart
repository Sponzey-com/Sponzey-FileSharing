import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_probe_coordinator.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

void main() {
  test('probes next candidate after the first candidate times out', () async {
    final probe = _FakeProbe({'a': null, 'b': 17});
    final coordinator = PeerPathProbeCoordinator(probe: probe);

    final result = await coordinator.selectReachablePath(
      candidates: [_candidate('a', rttMs: 1), _candidate('b', rttMs: 2)],
      now: DateTime.utc(2026),
    );

    expect(result.failedCandidateIds, hasLength(1));
    expect(result.path, isNotNull);
    expect(result.path!.status, PeerPathStatus.probeSucceeded);
    expect(result.path!.rttMs, 17);
  });

  test('returns failed result when all candidates fail', () async {
    final probe = _FakeProbe({'a': null, 'b': null});
    final coordinator = PeerPathProbeCoordinator(probe: probe);

    final result = await coordinator.selectReachablePath(
      candidates: [_candidate('a', rttMs: 1), _candidate('b', rttMs: 2)],
      now: DateTime.utc(2026),
    );

    expect(result.path, isNull);
    expect(result.failedCandidateIds, hasLength(2));
  });
}

class _FakeProbe implements PeerPathProbe {
  _FakeProbe(this.results);

  final Map<String, int?> results;

  @override
  Future<int?> probe(PeerConnectionPath path) async {
    return results[path.candidate.localInterfaceId.name];
  }
}

PeerRouteCandidate _candidate(String id, {required int rttMs}) {
  return PeerRouteCandidate.create(
    peerId: 'user@device',
    remoteAddress: id == 'a' ? '10.0.1.20' : '10.0.2.20',
    remotePort: 38401,
    localInterfaceId: NetworkInterfaceId(name: id, index: id.codeUnitAt(0)),
    localAddress: id == 'a' ? '10.0.1.10' : '10.0.2.10',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    rttMs: rttMs,
    localInterfaceTypeHint: InterfaceTypeHint.ethernet,
  );
}
