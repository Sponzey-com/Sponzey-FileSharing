import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum OutgoingTransferStatus {
  created,
  offering,
  waitingForAccept,
  preparingFile,
  sendingStart,
  sendingChunks,
  waitingForAcks,
  retrying,
  finishing,
  completed,
  cancelling,
  cancelled,
  failed,
}

enum OutgoingTransferEvent {
  offerRequested,
  offerSent,
  offerAccepted,
  offerRejected,
  filePrepared,
  dataStartSent,
  chunkSent,
  ackReceived,
  nackReceived,
  windowUpdated,
  retryTimeout,
  maxRetryExceeded,
  finishAckReceived,
  cancelRequested,
}

class OutgoingTransferStateMachine
    implements StateMachine<OutgoingTransferStatus, OutgoingTransferEvent> {
  const OutgoingTransferStateMachine();

  @override
  TransitionResult<OutgoingTransferStatus> transition(
    OutgoingTransferStatus state,
    OutgoingTransferEvent event,
  ) {
    switch ((state, event)) {
      case (
        OutgoingTransferStatus.created,
        OutgoingTransferEvent.offerRequested,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.offering,
          effects: const [TransitionEffect('sendTransferOffer')],
        );
      case (OutgoingTransferStatus.offering, OutgoingTransferEvent.offerSent):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.waitingForAccept,
        );
      case (
        OutgoingTransferStatus.waitingForAccept,
        OutgoingTransferEvent.offerAccepted,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.preparingFile,
          effects: const [TransitionEffect('prepareOutgoingFile')],
        );
      case (
        OutgoingTransferStatus.waitingForAccept,
        OutgoingTransferEvent.offerRejected,
      ):
        return TransitionResult.transitioned(OutgoingTransferStatus.failed);
      case (
        OutgoingTransferStatus.preparingFile,
        OutgoingTransferEvent.filePrepared,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.sendingStart,
          effects: const [TransitionEffect('sendDataStart')],
        );
      case (
        OutgoingTransferStatus.sendingStart,
        OutgoingTransferEvent.dataStartSent,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.sendingChunks,
        );
      case (
        OutgoingTransferStatus.sendingChunks,
        OutgoingTransferEvent.chunkSent,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.waitingForAcks,
        );
      case (
        OutgoingTransferStatus.waitingForAcks,
        OutgoingTransferEvent.ackReceived,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.sendingChunks,
        );
      case (
        OutgoingTransferStatus.waitingForAcks,
        OutgoingTransferEvent.nackReceived,
      ):
      case (
        OutgoingTransferStatus.waitingForAcks,
        OutgoingTransferEvent.retryTimeout,
      ):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.retrying,
          effects: const [TransitionEffect('retransmitMissingChunks')],
        );
      case (OutgoingTransferStatus.retrying, OutgoingTransferEvent.chunkSent):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.waitingForAcks,
        );
      case (_, OutgoingTransferEvent.maxRetryExceeded):
        return TransitionResult.failure(
          OutgoingTransferStatus.failed,
          issue: const TransitionIssue(
            code: 'max_retry_exceeded',
            message: 'Maximum transfer retry count exceeded.',
          ),
        );
      case (
        OutgoingTransferStatus.waitingForAcks,
        OutgoingTransferEvent.finishAckReceived,
      ):
      case (
        OutgoingTransferStatus.sendingChunks,
        OutgoingTransferEvent.finishAckReceived,
      ):
        return TransitionResult.transitioned(OutgoingTransferStatus.completed);
      case (_, OutgoingTransferEvent.cancelRequested):
        return TransitionResult.transitioned(
          OutgoingTransferStatus.cancelling,
          effects: const [TransitionEffect('sendTransferCancel')],
        );
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_outgoing_transfer_transition',
            message: 'Cannot apply $event while outgoing transfer is $state.',
          ),
        );
    }
  }
}

enum IncomingTransferStatus {
  offered,
  policyChecking,
  waitingForUserApproval,
  accepted,
  preparingDestination,
  receivingStart,
  receivingChunks,
  requestingRetransmit,
  verifying,
  completed,
  rejecting,
  rejected,
  cancelling,
  cancelled,
  failed,
}

enum IncomingTransferEvent {
  offerReceived,
  policyAllowed,
  policyRequiresApproval,
  policyDenied,
  userAccepted,
  userRejected,
  destinationPrepared,
  dataStartReceived,
  chunkReceived,
  chunkDuplicateReceived,
  chunkMissingDetected,
  checksumVerified,
  checksumFailed,
  senderCancelled,
  cancelRequested,
}

class IncomingTransferStateMachine
    implements StateMachine<IncomingTransferStatus, IncomingTransferEvent> {
  const IncomingTransferStateMachine();

  @override
  TransitionResult<IncomingTransferStatus> transition(
    IncomingTransferStatus state,
    IncomingTransferEvent event,
  ) {
    switch ((state, event)) {
      case (
        IncomingTransferStatus.offered,
        IncomingTransferEvent.offerReceived,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.policyChecking,
          effects: const [TransitionEffect('evaluateReceivePolicy')],
        );
      case (
        IncomingTransferStatus.policyChecking,
        IncomingTransferEvent.policyAllowed,
      ):
      case (
        IncomingTransferStatus.waitingForUserApproval,
        IncomingTransferEvent.userAccepted,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.accepted,
          effects: const [TransitionEffect('sendTransferAccept')],
        );
      case (
        IncomingTransferStatus.policyChecking,
        IncomingTransferEvent.policyRequiresApproval,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.waitingForUserApproval,
        );
      case (
        IncomingTransferStatus.policyChecking,
        IncomingTransferEvent.policyDenied,
      ):
      case (
        IncomingTransferStatus.waitingForUserApproval,
        IncomingTransferEvent.userRejected,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.rejecting,
          effects: const [TransitionEffect('sendTransferReject')],
        );
      case (
        IncomingTransferStatus.accepted,
        IncomingTransferEvent.destinationPrepared,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.preparingDestination,
        );
      case (
        IncomingTransferStatus.preparingDestination,
        IncomingTransferEvent.dataStartReceived,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.receivingChunks,
        );
      case (
        IncomingTransferStatus.receivingChunks,
        IncomingTransferEvent.chunkReceived,
      ):
      case (
        IncomingTransferStatus.receivingChunks,
        IncomingTransferEvent.chunkDuplicateReceived,
      ):
        return TransitionResult.noOp(state);
      case (
        IncomingTransferStatus.receivingChunks,
        IncomingTransferEvent.chunkMissingDetected,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.requestingRetransmit,
          effects: const [TransitionEffect('sendDataNack')],
        );
      case (
        IncomingTransferStatus.requestingRetransmit,
        IncomingTransferEvent.chunkReceived,
      ):
        return TransitionResult.transitioned(
          IncomingTransferStatus.receivingChunks,
        );
      case (
        IncomingTransferStatus.receivingChunks,
        IncomingTransferEvent.checksumVerified,
      ):
        return TransitionResult.transitioned(IncomingTransferStatus.completed);
      case (_, IncomingTransferEvent.checksumFailed):
        return TransitionResult.failure(
          IncomingTransferStatus.failed,
          issue: const TransitionIssue(
            code: 'checksum_failed',
            message: 'Transfer checksum verification failed.',
          ),
        );
      case (_, IncomingTransferEvent.senderCancelled):
      case (_, IncomingTransferEvent.cancelRequested):
        return TransitionResult.transitioned(IncomingTransferStatus.cancelled);
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_incoming_transfer_transition',
            message: 'Cannot apply $event while incoming transfer is $state.',
          ),
        );
    }
  }
}
