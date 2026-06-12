import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum ReceivePolicyMode {
  autoAcceptAll,
  askEveryTime,
  autoAcceptAllowedPeers,
  rejectUnknownPeers,
}

enum ReceivePolicyStatus {
  offered,
  checkingAuthSession,
  checkingAllowedPeer,
  checkingFileMetadata,
  checkingDestination,
  checkingFileConflict,
  accepted,
  waitingForApproval,
  rejected,
}

enum ReceivePolicyEvent {
  offerReceived,
  authSessionValid,
  authSessionInvalid,
  peerAllowed,
  peerUnknown,
  metadataValid,
  metadataInvalid,
  destinationAllowed,
  destinationDenied,
  noConflict,
  conflictRequiresApproval,
  userAccepted,
  userRejected,
}

class ReceivePolicyStateMachine
    implements StateMachine<ReceivePolicyStatus, ReceivePolicyEvent> {
  const ReceivePolicyStateMachine({required this.mode});

  final ReceivePolicyMode mode;

  @override
  TransitionResult<ReceivePolicyStatus> transition(
    ReceivePolicyStatus state,
    ReceivePolicyEvent event,
  ) {
    switch ((state, event)) {
      case (ReceivePolicyStatus.offered, ReceivePolicyEvent.offerReceived):
        return TransitionResult.transitioned(
          ReceivePolicyStatus.checkingAuthSession,
        );
      case (
        ReceivePolicyStatus.checkingAuthSession,
        ReceivePolicyEvent.authSessionValid,
      ):
        return TransitionResult.transitioned(
          ReceivePolicyStatus.checkingAllowedPeer,
        );
      case (
        ReceivePolicyStatus.checkingAuthSession,
        ReceivePolicyEvent.authSessionInvalid,
      ):
        return _reject('invalid_auth_session');
      case (
        ReceivePolicyStatus.checkingAllowedPeer,
        ReceivePolicyEvent.peerAllowed,
      ):
        return TransitionResult.transitioned(
          ReceivePolicyStatus.checkingFileMetadata,
        );
      case (
        ReceivePolicyStatus.checkingAllowedPeer,
        ReceivePolicyEvent.peerUnknown,
      ):
        if (mode == ReceivePolicyMode.autoAcceptAll ||
            mode == ReceivePolicyMode.askEveryTime) {
          return TransitionResult.transitioned(
            ReceivePolicyStatus.checkingFileMetadata,
          );
        }
        return _reject('unknown_peer_rejected');
      case (
        ReceivePolicyStatus.checkingFileMetadata,
        ReceivePolicyEvent.metadataValid,
      ):
        return TransitionResult.transitioned(
          ReceivePolicyStatus.checkingDestination,
        );
      case (
        ReceivePolicyStatus.checkingFileMetadata,
        ReceivePolicyEvent.metadataInvalid,
      ):
        return _reject('invalid_file_metadata');
      case (
        ReceivePolicyStatus.checkingDestination,
        ReceivePolicyEvent.destinationAllowed,
      ):
        return TransitionResult.transitioned(
          ReceivePolicyStatus.checkingFileConflict,
        );
      case (
        ReceivePolicyStatus.checkingDestination,
        ReceivePolicyEvent.destinationDenied,
      ):
        return _reject('destination_denied');
      case (
        ReceivePolicyStatus.checkingFileConflict,
        ReceivePolicyEvent.noConflict,
      ):
        if (mode == ReceivePolicyMode.askEveryTime) {
          return TransitionResult.transitioned(
            ReceivePolicyStatus.waitingForApproval,
          );
        }
        return TransitionResult.transitioned(ReceivePolicyStatus.accepted);
      case (
        ReceivePolicyStatus.checkingFileConflict,
        ReceivePolicyEvent.conflictRequiresApproval,
      ):
        return TransitionResult.transitioned(
          ReceivePolicyStatus.waitingForApproval,
        );
      case (
        ReceivePolicyStatus.waitingForApproval,
        ReceivePolicyEvent.userAccepted,
      ):
        return TransitionResult.transitioned(ReceivePolicyStatus.accepted);
      case (
        ReceivePolicyStatus.waitingForApproval,
        ReceivePolicyEvent.userRejected,
      ):
        return _reject('user_rejected');
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_receive_policy_transition',
            message: 'Cannot apply $event while receive policy is $state.',
          ),
        );
    }
  }

  TransitionResult<ReceivePolicyStatus> _reject(String reasonCode) {
    return TransitionResult.failure(
      ReceivePolicyStatus.rejected,
      issue: TransitionIssue(
        code: reasonCode,
        message: 'Receive policy rejected the transfer.',
      ),
    );
  }
}
