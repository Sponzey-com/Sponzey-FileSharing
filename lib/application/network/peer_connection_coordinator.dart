import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

typedef PeerConnectionNow = DateTime Function();

enum PeerConnectionAttemptStatus {
  started,
  noSelectableCandidate,
  skippedOffline,
  skippedAuthenticated,
  skippedInProgress,
  failed,
}

class PeerConnectionAttemptResult {
  const PeerConnectionAttemptResult({
    required this.status,
    this.path,
    this.reasonCode,
  });

  final PeerConnectionAttemptStatus status;
  final PeerConnectionPath? path;
  final String? reasonCode;
}

class PeerConnectionCoordinatorState {
  const PeerConnectionCoordinatorState({
    this.selectedPathIdsByPeerId = const {},
    this.reasonCodesByPeerId = const {},
  });

  final Map<String, String> selectedPathIdsByPeerId;
  final Map<String, String> reasonCodesByPeerId;

  String? selectedPathIdForPeer(String peerId) {
    return selectedPathIdsByPeerId[peerId];
  }

  String? reasonCodeForPeer(String peerId) {
    return reasonCodesByPeerId[peerId];
  }

  PeerConnectionCoordinatorState withSelectedPath(PeerConnectionPath path) {
    final nextReasons = {...reasonCodesByPeerId}..remove(path.peerId);
    return PeerConnectionCoordinatorState(
      selectedPathIdsByPeerId: {
        ...selectedPathIdsByPeerId,
        path.peerId: path.pathId,
      },
      reasonCodesByPeerId: nextReasons,
    );
  }

  PeerConnectionCoordinatorState withReason({
    required String peerId,
    required String reasonCode,
  }) {
    return PeerConnectionCoordinatorState(
      selectedPathIdsByPeerId: selectedPathIdsByPeerId,
      reasonCodesByPeerId: {...reasonCodesByPeerId, peerId: reasonCode},
    );
  }
}

class PeerConnectionCoordinator
    extends Notifier<PeerConnectionCoordinatorState> {
  final Set<String> _previousSuccessCandidateIds = {};

  @override
  PeerConnectionCoordinatorState build() {
    return const PeerConnectionCoordinatorState();
  }

  Future<PeerConnectionAttemptResult> connect(
    PeerNode peer, {
    bool ignoreInProgress = false,
  }) async {
    if (!peer.isCompatible || peer.presence != PeerPresence.online) {
      return _skip(
        peerId: peer.id,
        status: PeerConnectionAttemptStatus.skippedOffline,
        reasonCode: 'peerNotOnline',
      );
    }

    final session = ref.read(peerAuthSessionByPeerIdProvider(peer.id));
    final activePath = ref.read(activePeerPathProvider(peer.id));
    final authenticatedWithActivePath =
        session?.isAuthenticated == true &&
        activePath?.status == PeerPathStatus.active;
    final shouldRefreshAuthenticatedPath =
        session?.isAuthenticated == true && !authenticatedWithActivePath;
    if (authenticatedWithActivePath) {
      return _skip(
        peerId: peer.id,
        status: PeerConnectionAttemptStatus.skippedAuthenticated,
        reasonCode: 'alreadyAuthenticated',
      );
    }
    if (!ignoreInProgress && _isInProgress(session?.status)) {
      return _skip(
        peerId: peer.id,
        status: PeerConnectionAttemptStatus.skippedInProgress,
        reasonCode: 'handshakeInProgress',
      );
    }

    final candidates = ref.read(peerRouteCandidatesProvider(peer.id));
    final selection = PeerPathSelectionPolicy(
      previousSuccessCandidateIds: _previousSuccessCandidateIds,
    ).select(candidates: candidates, selectedAt: _now());
    if (selection == null) {
      final reasonCode = candidates.isEmpty
          ? 'noSelectableRouteCandidate'
          : 'allRouteCandidatesFailed';
      _publishPathEvent(
        eventType: 'PeerPathSelectionSkipped',
        peerId: peer.id,
        reasonCode: reasonCode,
      );
      return _skip(
        peerId: peer.id,
        status: candidates.isEmpty
            ? PeerConnectionAttemptStatus.noSelectableCandidate
            : PeerConnectionAttemptStatus.failed,
        reasonCode: reasonCode,
      );
    }

    final path = selection.path;
    ref.read(peerPathRegistryMutationsProvider).select(path);
    state = state.withSelectedPath(path);
    _publishPathEvent(
      eventType: 'PeerPathSelected',
      peerId: peer.id,
      pathId: path.pathId,
      reasonCode: selection.reason.name,
    );

    await ref
        .read(peerAuthControllerProvider.notifier)
        .startHandshake(
          peer,
          selectedPath: path,
          restartAuthenticatedSession: shouldRefreshAuthenticatedPath,
        );
    return PeerConnectionAttemptResult(
      status: PeerConnectionAttemptStatus.started,
      path: path,
      reasonCode: selection.reason.name,
    );
  }

  Future<PeerConnectionAttemptResult> failCandidateAndRetry({
    required PeerNode peer,
    required String candidateId,
    required String reasonCode,
  }) async {
    ref
        .read(peerAuthControllerProvider.notifier)
        .failInProgressHandshakeForPeer(
          peerId: peer.id,
          reasonCode: reasonCode,
          markCandidateFailed: false,
        );
    final failed = ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .markCandidateFailed(candidateId: candidateId, now: _now());
    if (failed != null) {
      _publishCandidateEvent(
        eventType: 'PeerRouteCandidateUpdated',
        candidate: failed,
        reasonCode: reasonCode,
      );
    }
    return connect(peer, ignoreInProgress: true);
  }

  void recordSuccessfulPath(PeerConnectionPath path) {
    _previousSuccessCandidateIds.add(path.candidate.candidateId);
  }

  PeerConnectionAttemptResult _skip({
    required String peerId,
    required PeerConnectionAttemptStatus status,
    required String reasonCode,
  }) {
    state = state.withReason(peerId: peerId, reasonCode: reasonCode);
    return PeerConnectionAttemptResult(status: status, reasonCode: reasonCode);
  }

  bool _isInProgress(PeerAuthStatus? status) {
    switch (status) {
      case PeerAuthStatus.connecting:
      case PeerAuthStatus.challengeIssued:
      case PeerAuthStatus.tokenSent:
      case PeerAuthStatus.verifying:
        return true;
      case null:
      case PeerAuthStatus.idle:
      case PeerAuthStatus.authenticated:
      case PeerAuthStatus.rejected:
      case PeerAuthStatus.failed:
        return false;
    }
  }

  void _publishPathEvent({
    required String eventType,
    required String peerId,
    String? pathId,
    String? reasonCode,
  }) {
    ref
        .read(messageBusProvider)
        .publish(
          PeerPathAppEvent(
            eventId: _eventId(eventType),
            occurredAt: _now(),
            correlationId: pathId ?? peerId,
            source: 'PeerConnectionCoordinator',
            severity: AppEventSeverity.debug,
            eventType: eventType,
            peerId: peerId,
            pathId: pathId,
            reasonCode: reasonCode,
          ),
        );
  }

  void _publishCandidateEvent({
    required String eventType,
    required PeerRouteCandidate candidate,
    String? reasonCode,
  }) {
    ref
        .read(messageBusProvider)
        .publish(
          PeerRouteCandidateAppEvent(
            eventId: _eventId(eventType),
            occurredAt: _now(),
            correlationId: candidate.candidateId,
            source: 'PeerConnectionCoordinator',
            severity: AppEventSeverity.debug,
            eventType: eventType,
            peerId: candidate.peerId,
            candidateId: candidate.candidateId,
            reasonCode: reasonCode,
          ),
        );
  }

  DateTime _now() => ref.read(peerConnectionNowProvider)();

  String _eventId(String prefix) => '$prefix-${_now().microsecondsSinceEpoch}';
}

final peerConnectionNowProvider = Provider<PeerConnectionNow>(
  (ref) => DateTime.now,
);

final peerConnectionCoordinatorProvider =
    NotifierProvider<PeerConnectionCoordinator, PeerConnectionCoordinatorState>(
      PeerConnectionCoordinator.new,
    );
