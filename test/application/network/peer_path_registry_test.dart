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
