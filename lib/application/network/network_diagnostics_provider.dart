import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/network/data_path_failover_projection.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/domain/network/data_path_failover_state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

final peerRouteCandidateStoreProvider = Provider<List<PeerRouteCandidate>>(
  (ref) => const [],
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
              '${active.candidate.localAddress}->'
              '${active.candidate.remoteAddress}:${active.candidate.remotePort}';
    return '$activeText candidates=${candidates.length} '
        'degraded=${degradedTransfers.length}';
  }

  List<String> get candidateDebugRows {
    return candidates
        .map(
          (candidate) =>
              '${candidate.localInterfaceId.stableId} '
              '${candidate.localAddress}->'
              '${candidate.remoteAddress}:${candidate.remotePort} '
              'status=${candidate.status.name} '
              'score=${candidate.score} '
              'rtt=${candidate.rttMs ?? '-'} '
              'failures=${candidate.failureCount}',
        )
        .toList(growable: false);
  }
}
