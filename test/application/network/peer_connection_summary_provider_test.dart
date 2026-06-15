import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_connection_summary_provider.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

void main() {
  test(
    'shows connected only when auth session and active path are both ready',
    () {
      final peer = _peer();
      final candidate = _candidate(peer.id);
      final activePath = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.sameSubnet,
      ).copyWith(status: PeerPathStatus.active);

      final summary = PeerConnectionSummary.resolve(
        peer: peer,
        authSession: _session(peer, status: PeerAuthStatus.authenticated),
        diagnostics: PeerPathDiagnostics(
          peerId: peer.id,
          activePath: activePath,
          candidates: [candidate],
          degradedTransfers: const [],
        ),
      );

      expect(summary.status, PeerConnectionProductStatus.connected);
      expect(summary.label, '연결됨');
      expect(summary.canSendFiles, isTrue);
      expect(summary.description, isNot(contains('10.20.30.')));
      expect(summary.description, isNot(contains('token')));
    },
  );

  test(
    'shows connected when authenticated route exists but path is still synchronizing',
    () {
      final peer = _peer();
      final candidate = _candidate(peer.id);
      final authenticatingPath = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.sameSubnet,
      ).copyWith(status: PeerPathStatus.authenticating);

      final summary = PeerConnectionSummary.resolve(
        peer: peer,
        authSession: _session(peer, status: PeerAuthStatus.authenticated),
        diagnostics: PeerPathDiagnostics(
          peerId: peer.id,
          activePath: authenticatingPath,
          candidates: [candidate],
          degradedTransfers: const [],
        ),
      );

      expect(summary.status, PeerConnectionProductStatus.connected);
      expect(summary.label, '연결됨');
      expect(summary.canSendFiles, isTrue);
    },
  );

  test(
    'shows connected for incoming authenticated sessions without registry path',
    () {
      final peer = _peer();

      final summary = PeerConnectionSummary.resolve(
        peer: peer,
        authSession: _session(peer, status: PeerAuthStatus.authenticated),
        diagnostics: PeerPathDiagnostics(
          peerId: peer.id,
          activePath: null,
          candidates: const [],
          degradedTransfers: const [],
        ),
      );

      expect(summary.status, PeerConnectionProductStatus.connected);
      expect(summary.label, '연결됨');
      expect(summary.canSendFiles, isTrue);
    },
  );

  test('shows checking when candidates exist but active path is missing', () {
    final peer = _peer();
    final container = ProviderContainer(
      overrides: [
        peerAuthSessionByPeerIdProvider(peer.id).overrideWith((ref) => null),
        peerRouteCandidateStoreProvider.overrideWith(
          (ref) => [_candidate(peer.id)],
        ),
      ],
    );
    addTearDown(container.dispose);

    final summary = container.read(peerConnectionSummaryProvider(peer));

    expect(summary.status, PeerConnectionProductStatus.checking);
    expect(summary.label, '연결 확인 중');
    expect(summary.canSendFiles, isFalse);
  });

  test('shows failure when every route candidate failed', () {
    final peer = _peer();
    final failed = _candidate(
      peer.id,
      status: RouteCandidateStatus.failed,
      failureCount: 2,
    );

    final summary = PeerConnectionSummary.resolve(
      peer: peer,
      authSession: null,
      diagnostics: PeerPathDiagnostics(
        peerId: peer.id,
        activePath: null,
        candidates: [failed],
        degradedTransfers: const [],
      ),
    );

    expect(summary.status, PeerConnectionProductStatus.failed);
    expect(summary.label, '경로 실패');
    expect(summary.canSendFiles, isFalse);
  });

  test('does not show connected for stale or offline peers', () {
    final candidate = _candidate('team@device-b');
    final activePath = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.active);
    final diagnostics = PeerPathDiagnostics(
      peerId: 'team@device-b',
      activePath: activePath,
      candidates: [candidate],
      degradedTransfers: const [],
    );

    for (final presence in [PeerPresence.stale, PeerPresence.offline]) {
      final peer = _peer(presence: presence);
      final summary = PeerConnectionSummary.resolve(
        peer: peer,
        authSession: _session(peer, status: PeerAuthStatus.authenticated),
        diagnostics: diagnostics,
      );

      expect(summary.status, isNot(PeerConnectionProductStatus.connected));
      expect(summary.canSendFiles, isFalse);
    }
  });
}

PeerNode _peer({PeerPresence presence = PeerPresence.online}) {
  return PeerNode(
    deviceId: 'device-b',
    userId: 'team',
    displayName: 'Very Long Peer Name That Must Stay Product Safe',
    deviceName: 'Very-Long-Host-Name-That-Should-Ellipsize.local',
    osType: 'macos',
    protocolVersion: '1.0',
    lastSeenAt: DateTime.utc(2026),
    address: '10.20.30.40',
    port: 38401,
    receiveAvailable: true,
    presence: presence,
  );
}

PeerAuthSession _session(PeerNode peer, {required PeerAuthStatus status}) {
  return PeerAuthSession(
    sessionId: 'session-a',
    peerId: peer.id,
    peerUserId: peer.userId,
    peerDisplayName: peer.displayName,
    peerAddress: peer.address,
    peerPort: peer.port,
    status: status,
    updatedAt: DateTime.utc(2026),
  );
}

PeerRouteCandidate _candidate(
  String peerId, {
  RouteCandidateStatus status = RouteCandidateStatus.fresh,
  int failureCount = 0,
}) {
  return PeerRouteCandidate.create(
    peerId: peerId,
    remoteAddress: '10.20.30.40',
    remotePort: 38401,
    localInterfaceId: const NetworkInterfaceId(
      name: 'very-long-ethernet-interface-name',
      index: 7,
    ),
    localAddress: '10.20.30.5',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    status: status,
    failureCount: failureCount,
    localInterfaceTypeHint: InterfaceTypeHint.ethernet,
  );
}
