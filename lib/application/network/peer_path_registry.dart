import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

class PeerPathRegistry {
  final Map<String, PeerConnectionPath> _pathsByPeerId = {};
  final PeerConnectionPathStateMachine _stateMachine =
      const PeerConnectionPathStateMachine();

  void select(PeerConnectionPath path) {
    _pathsByPeerId[path.peerId] = path;
  }

  PeerConnectionPath? selectedForPeer(String peerId) => _pathsByPeerId[peerId];

  List<PeerConnectionPath> snapshot() {
    return _pathsByPeerId.values.toList(growable: false)
      ..sort((a, b) => a.peerId.compareTo(b.peerId));
  }

  TransitionResult<PeerConnectionPath>? applyEvent({
    required String peerId,
    required PeerPathEvent event,
    String? reasonCode,
  }) {
    final current = _pathsByPeerId[peerId];
    if (current == null) {
      return null;
    }
    final result = _stateMachine.transition(current, event);
    var nextPath = result.state;
    if (event == PeerPathEvent.authFailed ||
        result.disposition == TransitionDisposition.failure) {
      nextPath = nextPath.copyWith(failureReasonCode: reasonCode);
    }
    _pathsByPeerId[peerId] = nextPath;
    return result;
  }

  void markFailed({required String peerId, required String reasonCode}) {
    final current = _pathsByPeerId[peerId];
    if (current == null) {
      return;
    }
    _pathsByPeerId[peerId] = current.copyWith(
      status: PeerPathStatus.failed,
      failureReasonCode: reasonCode,
    );
  }

  bool expireLeaseForCandidate({
    required PeerRouteCandidate candidate,
    required String reasonCode,
  }) {
    final current = _pathsByPeerId[candidate.peerId];
    if (current == null ||
        current.candidate.candidateId != candidate.candidateId) {
      return false;
    }
    if (current.status == PeerPathStatus.failed ||
        current.status == PeerPathStatus.failoverRequested) {
      return false;
    }
    _pathsByPeerId[candidate.peerId] = current.copyWith(
      status: PeerPathStatus.failoverRequested,
      failureReasonCode: reasonCode,
    );
    return true;
  }

  void clear(String peerId) {
    _pathsByPeerId.remove(peerId);
  }
}

final peerPathRegistryProvider = Provider<PeerPathRegistry>((ref) {
  return PeerPathRegistry();
});

class PeerPathRegistryRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state += 1;
  }
}

final peerPathRegistryRevisionProvider =
    NotifierProvider<PeerPathRegistryRevision, int>(
      PeerPathRegistryRevision.new,
    );

class PeerPathRegistryMutations {
  const PeerPathRegistryMutations(this._ref);

  final Ref _ref;

  void select(PeerConnectionPath path) {
    _ref.read(peerPathRegistryProvider).select(path);
    _bump();
  }

  TransitionResult<PeerConnectionPath>? applyEvent({
    required String peerId,
    required PeerPathEvent event,
    String? reasonCode,
  }) {
    final result = _ref
        .read(peerPathRegistryProvider)
        .applyEvent(peerId: peerId, event: event, reasonCode: reasonCode);
    if (result != null) {
      _bump();
    }
    return result;
  }

  void markFailed({required String peerId, required String reasonCode}) {
    _ref
        .read(peerPathRegistryProvider)
        .markFailed(peerId: peerId, reasonCode: reasonCode);
    _bump();
  }

  bool expireLeaseForCandidate({
    required PeerRouteCandidate candidate,
    required String reasonCode,
  }) {
    final changed = _ref
        .read(peerPathRegistryProvider)
        .expireLeaseForCandidate(candidate: candidate, reasonCode: reasonCode);
    if (changed) {
      _bump();
    }
    return changed;
  }

  void clear(String peerId) {
    _ref.read(peerPathRegistryProvider).clear(peerId);
    _bump();
  }

  void _bump() {
    _ref.read(peerPathRegistryRevisionProvider.notifier).bump();
  }
}

final peerPathRegistryMutationsProvider = Provider<PeerPathRegistryMutations>(
  PeerPathRegistryMutations.new,
);
