import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

enum PeerPathStatus {
  discovered,
  probing,
  probeSucceeded,
  probeFailed,
  authenticating,
  active,
  degraded,
  failoverRequested,
  failed,
}

enum PeerPathSelectionReason {
  sameSubnet,
  previousSuccess,
  lowestRtt,
  lowestFailureCount,
  deterministicTieBreaker,
}

enum PeerPathEvent {
  probeStarted,
  probeSucceeded,
  probeFailed,
  authStarted,
  authSucceeded,
  authFailed,
  degraded,
  failoverRequested,
}

class PeerConnectionPath {
  const PeerConnectionPath({
    required this.pathId,
    required this.peerId,
    required this.candidate,
    required this.controlEndpoint,
    this.dataEndpoint,
    required this.status,
    required this.selectedAt,
    required this.selectionReason,
    this.rttMs,
    this.failureReasonCode,
  });

  factory PeerConnectionPath.fromCandidate({
    required PeerRouteCandidate candidate,
    required DateTime selectedAt,
    required PeerPathSelectionReason selectionReason,
    int? dataPort,
  }) {
    return PeerConnectionPath(
      pathId: 'path:${candidate.candidateId}',
      peerId: candidate.peerId,
      candidate: candidate,
      controlEndpoint: UdpInterfaceEndpoint(
        role: UdpPortRole.control,
        interfaceId: candidate.localInterfaceId,
        localAddress: candidate.localAddress,
        port: candidate.remotePort,
        bindMode: candidate.bindMode,
      ),
      dataEndpoint: dataPort == null
          ? null
          : UdpInterfaceEndpoint(
              role: UdpPortRole.data,
              interfaceId: candidate.localInterfaceId,
              localAddress: candidate.localAddress,
              port: dataPort,
              bindMode: candidate.bindMode,
            ),
      status: PeerPathStatus.discovered,
      selectedAt: selectedAt,
      selectionReason: selectionReason,
      rttMs: candidate.rttMs,
    );
  }

  final String pathId;
  final String peerId;
  final PeerRouteCandidate candidate;
  final UdpInterfaceEndpoint controlEndpoint;
  final UdpInterfaceEndpoint? dataEndpoint;
  final PeerPathStatus status;
  final DateTime selectedAt;
  final PeerPathSelectionReason selectionReason;
  final int? rttMs;
  final String? failureReasonCode;

  PeerConnectionPath copyWith({
    PeerPathStatus? status,
    int? rttMs,
    String? failureReasonCode,
    bool clearFailureReasonCode = false,
  }) {
    return PeerConnectionPath(
      pathId: pathId,
      peerId: peerId,
      candidate: candidate,
      controlEndpoint: controlEndpoint,
      dataEndpoint: dataEndpoint,
      status: status ?? this.status,
      selectedAt: selectedAt,
      selectionReason: selectionReason,
      rttMs: rttMs ?? this.rttMs,
      failureReasonCode: clearFailureReasonCode
          ? null
          : failureReasonCode ?? this.failureReasonCode,
    );
  }
}

class PeerPathSelection {
  const PeerPathSelection({
    required this.path,
    required this.reason,
    required this.score,
  });

  final PeerConnectionPath path;
  final PeerPathSelectionReason reason;
  final int score;
}

class PeerPathSelectionPolicy {
  const PeerPathSelectionPolicy({this.previousSuccessCandidateIds = const {}});

  final Set<String> previousSuccessCandidateIds;

  PeerPathSelection? select({
    required Iterable<PeerRouteCandidate> candidates,
    required DateTime selectedAt,
  }) {
    final scored = candidates
        .where((candidate) => candidate.isSelectable)
        .map((candidate) {
          final score = _score(candidate);
          return (candidate: candidate, score: score);
        })
        .toList(growable: false);
    if (scored.isEmpty) {
      return null;
    }

    scored.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final rttCompare = (a.candidate.rttMs ?? 1 << 30).compareTo(
        b.candidate.rttMs ?? 1 << 30,
      );
      if (rttCompare != 0) {
        return rttCompare;
      }
      return a.candidate.candidateId.compareTo(b.candidate.candidateId);
    });

    final selected = scored.first;
    final reason = _reasonFor(selected.candidate);
    return PeerPathSelection(
      path: PeerConnectionPath.fromCandidate(
        candidate: selected.candidate,
        selectedAt: selectedAt,
        selectionReason: reason,
      ),
      reason: reason,
      score: selected.score,
    );
  }

  int _score(PeerRouteCandidate candidate) {
    var score = 1000;
    if (_sameSubnet24(candidate.localAddress, candidate.remoteAddress)) {
      score += 300;
    }
    if (previousSuccessCandidateIds.contains(candidate.candidateId)) {
      score += 500;
    }
    score -= candidate.rttMs ?? 100;
    score -= candidate.failureCount * 160;
    if (candidate.status == RouteCandidateStatus.degraded) {
      score -= 240;
    }
    switch (candidate.localInterfaceTypeHint) {
      case InterfaceTypeHint.virtual:
      case InterfaceTypeHint.vpn:
        score -= 260;
      case InterfaceTypeHint.bridge:
        score += 20;
      case InterfaceTypeHint.ethernet:
        score += 40;
      case InterfaceTypeHint.wifi:
        score += 10;
      case InterfaceTypeHint.loopback:
      case InterfaceTypeHint.unknown:
        break;
    }
    return score;
  }

  PeerPathSelectionReason _reasonFor(PeerRouteCandidate candidate) {
    if (previousSuccessCandidateIds.contains(candidate.candidateId)) {
      return PeerPathSelectionReason.previousSuccess;
    }
    if (_sameSubnet24(candidate.localAddress, candidate.remoteAddress)) {
      return PeerPathSelectionReason.sameSubnet;
    }
    if (candidate.rttMs != null) {
      return PeerPathSelectionReason.lowestRtt;
    }
    if (candidate.failureCount == 0) {
      return PeerPathSelectionReason.lowestFailureCount;
    }
    return PeerPathSelectionReason.deterministicTieBreaker;
  }

  static bool _sameSubnet24(String left, String right) {
    final leftParts = left.split('.');
    final rightParts = right.split('.');
    if (leftParts.length != 4 || rightParts.length != 4) {
      return false;
    }
    return leftParts[0] == rightParts[0] &&
        leftParts[1] == rightParts[1] &&
        leftParts[2] == rightParts[2];
  }
}

class PeerConnectionPathStateMachine
    implements StateMachine<PeerConnectionPath, PeerPathEvent> {
  const PeerConnectionPathStateMachine();

  @override
  TransitionResult<PeerConnectionPath> transition(
    PeerConnectionPath state,
    PeerPathEvent event,
  ) {
    switch ((state.status, event)) {
      case (PeerPathStatus.discovered, PeerPathEvent.probeStarted):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerPathStatus.probing),
          effects: const [TransitionEffect('sendControlProbe')],
        );
      case (PeerPathStatus.probing, PeerPathEvent.probeSucceeded):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerPathStatus.probeSucceeded),
          effects: const [TransitionEffect('recordProbeRtt')],
        );
      case (PeerPathStatus.probing, PeerPathEvent.probeFailed):
        return TransitionResult.failure(
          state.copyWith(status: PeerPathStatus.probeFailed),
          issue: const TransitionIssue(
            code: 'peer_path_probe_failed',
            message: 'The selected peer path did not respond to probe.',
          ),
        );
      case (PeerPathStatus.probeSucceeded, PeerPathEvent.authStarted):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerPathStatus.authenticating),
        );
      case (PeerPathStatus.discovered, PeerPathEvent.authStarted):
        return TransitionResult.transitioned(
          state.copyWith(
            status: PeerPathStatus.authenticating,
            clearFailureReasonCode: true,
          ),
        );
      case (PeerPathStatus.authenticating, PeerPathEvent.authSucceeded):
        return TransitionResult.transitioned(
          state.copyWith(
            status: PeerPathStatus.active,
            clearFailureReasonCode: true,
          ),
        );
      case (PeerPathStatus.authenticating, PeerPathEvent.authFailed):
        return TransitionResult.failure(
          state.copyWith(status: PeerPathStatus.failed),
          issue: const TransitionIssue(
            code: 'peer_path_auth_failed',
            message: 'Authentication failed on the selected peer path.',
          ),
        );
      case (PeerPathStatus.active, PeerPathEvent.degraded):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerPathStatus.degraded),
        );
      case (_, PeerPathEvent.failoverRequested):
        return TransitionResult.transitioned(
          state.copyWith(status: PeerPathStatus.failoverRequested),
          effects: const [TransitionEffect('selectFailoverPath')],
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_peer_path_transition',
            message: 'Cannot apply $event while path is ${state.status}.',
          ),
        );
    }
  }
}
