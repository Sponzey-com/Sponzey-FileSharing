import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

abstract interface class PeerPathProbe {
  Future<int?> probe(PeerConnectionPath path);
}

class PeerPathProbeResult {
  const PeerPathProbeResult({
    required this.path,
    required this.failedCandidateIds,
  });

  final PeerConnectionPath? path;
  final List<String> failedCandidateIds;
}

class PeerPathProbeCoordinator {
  const PeerPathProbeCoordinator({
    required this.probe,
    this.selectionPolicy = const PeerPathSelectionPolicy(),
  });

  final PeerPathProbe probe;
  final PeerPathSelectionPolicy selectionPolicy;

  Future<PeerPathProbeResult> selectReachablePath({
    required Iterable<PeerRouteCandidate> candidates,
    required DateTime now,
  }) async {
    final remaining = candidates.toList(growable: true);
    final failed = <String>[];
    while (remaining.isNotEmpty) {
      final selection = selectionPolicy.select(
        candidates: remaining,
        selectedAt: now,
      );
      if (selection == null) {
        break;
      }
      final path = selection.path.copyWith(status: PeerPathStatus.probing);
      final rtt = await probe.probe(path);
      if (rtt != null) {
        return PeerPathProbeResult(
          path: path.copyWith(
            status: PeerPathStatus.probeSucceeded,
            rttMs: rtt,
          ),
          failedCandidateIds: failed,
        );
      }
      failed.add(selection.path.candidate.candidateId);
      remaining.removeWhere(
        (candidate) =>
            candidate.candidateId == selection.path.candidate.candidateId,
      );
    }
    return PeerPathProbeResult(path: null, failedCandidateIds: failed);
  }
}
