import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/domain/network/data_path_failover_state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

void main() {
  test('route candidate provider returns candidates by peer', () {
    final container = ProviderContainer(
      overrides: [
        peerRouteCandidateStoreProvider.overrideWith(
          (ref) => [_candidate('peer-a', 'en0'), _candidate('peer-b', 'en1')],
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(peerRouteCandidatesProvider('peer-a')), hasLength(1));
    expect(container.read(peerRouteCandidatesProvider('peer-b')), hasLength(1));
  });

  test('active path provider returns selected path', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final candidate = _candidate('peer-a', 'en0');
    final path = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );

    container.read(peerPathRegistryProvider).select(path);

    expect(
      container.read(activePeerPathProvider('peer-a'))!.pathId,
      path.pathId,
    );
  });

  test('diagnostics separates product and debug summaries', () {
    final container = ProviderContainer(
      overrides: [
        peerRouteCandidateStoreProvider.overrideWith(
          (ref) => [_candidate('peer-a', 'en0', rttMs: 12)],
        ),
      ],
    );
    addTearDown(container.dispose);

    final diagnostics = container.read(peerPathDiagnosticsProvider('peer-a'));

    expect(diagnostics.productSummary, '연결 경로 확인 중');
    expect(diagnostics.debugSummary, contains('candidates=1'));
    expect(diagnostics.candidateDebugRows.single, contains('rtt=12'));
    expect(diagnostics.candidateDebugRows.single, isNot(contains('token')));
    expect(diagnostics.candidateDebugRows.single, isNot(contains('password')));
    expect(
      diagnostics.candidateDebugRows.single,
      isNot(contains('session key')),
    );
  });

  test('degraded provider reports failover states', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(dataPathFailoverProjectionProvider)
        .upsert(
          const DataPathFailoverSnapshot(
            transferId: 'transfer-a',
            peerId: 'peer-a',
            status: DataPathStatus.failingOverInterface,
          ),
        );

    expect(container.read(degradedDataPathProvider('peer-a')), hasLength(1));
    expect(
      container.read(peerPathDiagnosticsProvider('peer-a')).productSummary,
      '다른 네트워크 경로로 재시도 중',
    );
  });
}

PeerRouteCandidate _candidate(
  String peerId,
  String interfaceName, {
  int? rttMs,
}) {
  return PeerRouteCandidate.create(
    peerId: peerId,
    remoteAddress: '10.0.1.20',
    remotePort: 38401,
    localInterfaceId: NetworkInterfaceId(
      name: interfaceName,
      index: interfaceName.codeUnitAt(interfaceName.length - 1),
    ),
    localAddress: '10.0.1.10',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    rttMs: rttMs,
    score: 1188,
  );
}
