import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/application/network/data_path_failover_projection.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/domain/network/data_path_failover_state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

final peerRouteCandidateStoreProvider = Provider<List<PeerRouteCandidate>>(
  (ref) => ref.watch(peerRouteCandidateProjectionProvider),
);

final peerRouteCandidatesProvider =
    Provider.family<List<PeerRouteCandidate>, String>((ref, peerId) {
      return ref
          .watch(peerRouteCandidateStoreProvider)
          .where((candidate) => candidate.peerId == peerId)
          .toList(growable: false);
    });

final activePeerPathProvider = Provider.family<PeerConnectionPath?, String>((
  ref,
  peerId,
) {
  ref.watch(peerPathRegistryRevisionProvider);
  return ref.watch(peerPathRegistryProvider).selectedForPeer(peerId);
});

final dataPathFailoverProjectionProvider = Provider<DataPathFailoverProjection>(
  (ref) => DataPathFailoverProjection(),
);

final degradedDataPathProvider =
    Provider.family<List<DataPathFailoverSnapshot>, String>((ref, peerId) {
      return ref
          .watch(dataPathFailoverProjectionProvider)
          .byPeerId(peerId)
          .where(
            (snapshot) =>
                snapshot.status == DataPathStatus.degraded ||
                snapshot.status == DataPathStatus.retryingSameInterface ||
                snapshot.status == DataPathStatus.failingOverInterface,
          )
          .toList(growable: false);
    });

final peerPathDiagnosticsProvider =
    Provider.family<PeerPathDiagnostics, String>((ref, peerId) {
      final candidates = ref.watch(peerRouteCandidatesProvider(peerId));
      final activePath = ref.watch(activePeerPathProvider(peerId));
      final degraded = ref.watch(degradedDataPathProvider(peerId));
      return PeerPathDiagnostics(
        peerId: peerId,
        activePath: activePath,
        candidates: candidates,
        degradedTransfers: degraded,
      );
    });

class PeerPathDiagnostics {
  const PeerPathDiagnostics({
    required this.peerId,
    required this.activePath,
    required this.candidates,
    required this.degradedTransfers,
  });

  final String peerId;
  final PeerConnectionPath? activePath;
  final List<PeerRouteCandidate> candidates;
  final List<DataPathFailoverSnapshot> degradedTransfers;

  bool get hasDegradedPath => degradedTransfers.isNotEmpty;
  int get candidateCount => candidates.length;

  bool get allCandidatesFailed {
    return candidates.isNotEmpty &&
        candidates.every(
          (candidate) => candidate.status == RouteCandidateStatus.failed,
        );
  }

  String get activeInterface {
    return activePath?.candidate.localInterfaceId.stableId ?? '-';
  }

  String get activeEndpoint {
    final active = activePath;
    if (active == null) {
      return '-';
    }
    return '${active.candidate.localAddress}->'
        '${active.candidate.remoteAddress}:${active.candidate.remotePort}';
  }

  String get pathSelectionReason {
    return activePath?.selectionReason.name ?? '-';
  }

  String get lastFailureReason {
    final active = activePath;
    if (active != null &&
        (active.status == PeerPathStatus.failed ||
            active.status == PeerPathStatus.probeFailed ||
            active.status == PeerPathStatus.degraded ||
            active.status == PeerPathStatus.failoverRequested)) {
      return 'path:${active.status.name}';
    }
    final failedCandidates =
        candidates
            .where(
              (candidate) => candidate.status == RouteCandidateStatus.failed,
            )
            .toList(growable: false)
          ..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt));
    if (failedCandidates.isEmpty) {
      return '-';
    }
    return 'candidate:${failedCandidates.first.status.name}';
  }

  String get productSummary {
    if (hasDegradedPath) {
      return '다른 네트워크 경로로 재시도 중';
    }
    if (activePath != null) {
      return '연결 경로 정상';
    }
    if (candidates.isNotEmpty) {
      return '연결 경로 확인 중';
    }
    return '연결 경로 정보 없음';
  }

  String get debugSummary {
    final active = activePath;
    final activeText = active == null
        ? 'active=-'
        : 'active=${active.candidate.localInterfaceId.stableId} '
              'status=${active.status.name} '
              'reason=${active.selectionReason.name} '
              '${active.candidate.localAddress}->'
              '${active.candidate.remoteAddress}:${active.candidate.remotePort}';
    return '$activeText candidates=$candidateCount '
        'degraded=${degradedTransfers.length} '
        'lastFailure=$lastFailureReason';
  }

  List<String> get candidateDebugRows {
    return candidates
        .map(
          (candidate) =>
              '${candidate.localInterfaceId.stableId} '
              '${candidate.localAddress}->'
              '${candidate.remoteAddress}:${candidate.remotePort} '
              'type=${candidate.localInterfaceTypeHint.name} '
              'bind=${candidate.bindMode.name} '
              'status=${candidate.status.name} '
              'score=${candidate.score} '
              'rtt=${candidate.rttMs ?? '-'} '
              'failures=${candidate.failureCount}',
        )
        .toList(growable: false);
  }
}
