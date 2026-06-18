import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

void main() {
  test('expired route candidate downgrades the active route lease', () {
    final candidate = _candidate(peerId: 'team@peer-a', id: 'en0');
    final path = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.active);
    final registry = PeerPathRegistry()..select(path);

    final changed = registry.expireLeaseForCandidate(
      candidate: candidate.copyWith(status: RouteCandidateStatus.expired),
      reasonCode: 'ttlExceeded',
    );

    expect(changed, isTrue);
    final selected = registry.selectedForPeer('team@peer-a');
    expect(selected?.status, PeerPathStatus.failoverRequested);
    expect(selected?.failureReasonCode, 'ttlExceeded');
  });

  test('expired non-selected candidate does not change active route lease', () {
    final active = _candidate(peerId: 'team@peer-a', id: 'en0');
    final other = _candidate(peerId: 'team@peer-a', id: 'en1');
    final path = PeerConnectionPath.fromCandidate(
      candidate: active,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.active);
    final registry = PeerPathRegistry()..select(path);

    final changed = registry.expireLeaseForCandidate(
      candidate: other.copyWith(status: RouteCandidateStatus.expired),
      reasonCode: 'ttlExceeded',
    );

    expect(changed, isFalse);
    expect(
      registry.selectedForPeer('team@peer-a')?.status,
      PeerPathStatus.active,
    );
  });

  test('selectIfAbsent keeps existing active route for same peer', () {
    final active = _candidate(peerId: 'team@peer-a', id: 'en0');
    final refreshed = _candidate(peerId: 'team@peer-a', id: 'en1');
    final activePath = PeerConnectionPath.fromCandidate(
      candidate: active,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.active);
    final refreshedPath = PeerConnectionPath.fromCandidate(
      candidate: refreshed,
      selectedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.probing);
    final registry = PeerPathRegistry()..select(activePath);

    final selected = registry.selectIfAbsent(refreshedPath);

    expect(selected, isFalse);
    expect(registry.selectedForPeer('team@peer-a')?.pathId, activePath.pathId);
    expect(
      registry.selectedForPeer('team@peer-a')?.candidate.candidateId,
      active.candidateId,
    );
  });

  test('selectIfAbsent selects route when peer has no active lease', () {
    final candidate = _candidate(peerId: 'team@peer-a', id: 'en0');
    final path = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );
    final registry = PeerPathRegistry();

    final selected = registry.selectIfAbsent(path);

    expect(selected, isTrue);
    expect(registry.selectedForPeer('team@peer-a')?.pathId, path.pathId);
  });

  test('selectForHandshake explicitly replaces the selected route', () {
    final current = _candidate(peerId: 'team@peer-a', id: 'en0');
    final next = _candidate(peerId: 'team@peer-a', id: 'en1');
    final currentPath = PeerConnectionPath.fromCandidate(
      candidate: current,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.failoverRequested);
    final nextPath = PeerConnectionPath.fromCandidate(
      candidate: next,
      selectedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );
    final registry = PeerPathRegistry()..select(currentPath);

    registry.selectForHandshake(nextPath);

    expect(registry.selectedForPeer('team@peer-a')?.pathId, nextPath.pathId);
  });

  test('selectForTransferRecovery explicitly replaces the selected route', () {
    final current = _candidate(peerId: 'team@peer-a', id: 'en0');
    final recovered = _candidate(peerId: 'team@peer-a', id: 'en1');
    final currentPath = PeerConnectionPath.fromCandidate(
      candidate: current,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.failoverRequested);
    final recoveredPath = PeerConnectionPath.fromCandidate(
      candidate: recovered,
      selectedAt: DateTime.utc(2026, 1, 1, 0, 0, 1),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    );
    final registry = PeerPathRegistry()..select(currentPath);

    registry.selectForTransferRecovery(recoveredPath);

    expect(
      registry.selectedForPeer('team@peer-a')?.pathId,
      recoveredPath.pathId,
    );
  });
}

PeerRouteCandidate _candidate({required String peerId, required String id}) {
  return PeerRouteCandidate.create(
    peerId: peerId,
    remoteAddress: '10.20.30.40',
    remotePort: 46000,
    localInterfaceId: NetworkInterfaceId(name: id, index: id.codeUnitAt(0)),
    localAddress: '10.20.30.5',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    localInterfaceTypeHint: InterfaceTypeHint.ethernet,
  );
}
