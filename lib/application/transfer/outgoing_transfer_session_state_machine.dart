import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum OutgoingTransferSessionState {
  created,
  waitingForReceiverPrepare,
  bindingDataEndpoint,
  sendingStartFrame,
  sendingChunks,
  waitingForChunkAcks,
  sendingFinish,
  waitingForFinishAck,
  completed,
  canceling,
  canceled,
  failed,
}

enum OutgoingTransferSessionEvent {
  startRequested,
  receiverAccepted,
  receiverRejected,
  dataEndpointBound,
  startFrameSent,
  windowSaturated,
  ackOpenedWindow,
  allChunksAcked,
  finishFrameSent,
  finishAccepted,
  cancelRequested,
  cancelCompleted,
  failureOccurred,
}

class OutgoingTransferSessionStateMachine
    implements
        StateMachine<
          OutgoingTransferSessionState,
          OutgoingTransferSessionEvent
        > {
  const OutgoingTransferSessionStateMachine();

  static const _sendTransferInit = TransitionEffect('sendTransferInit');
  static const _bindDataEndpoint = TransitionEffect('bindDataEndpoint');
  static const _sendDataStartFrame = TransitionEffect('sendDataStartFrame');
  static const _pumpChunkWindow = TransitionEffect('pumpChunkWindow');
  static const _sendDataFinishFrame = TransitionEffect('sendDataFinishFrame');
  static const _completeTransfer = TransitionEffect('completeTransfer');
  static const _failTransfer = TransitionEffect('failTransfer');
  static const _cancelTransfer = TransitionEffect('cancelTransfer');
  static const _cleanupTransfer = TransitionEffect('cleanupTransfer');

  @override
  TransitionResult<OutgoingTransferSessionState> transition(
    OutgoingTransferSessionState state,
    OutgoingTransferSessionEvent event,
  ) {
    if (_isTerminal(state)) {
      return TransitionResult.warning(
        state,
        issue: const TransitionIssue(
          code: 'outgoing_transfer_already_terminal',
          message: 'Outgoing transfer session is already terminal.',
        ),
      );
    }

    if (event == OutgoingTransferSessionEvent.cancelRequested) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.canceling,
        effects: [_cancelTransfer],
      );
    }

    if (event == OutgoingTransferSessionEvent.failureOccurred ||
        event == OutgoingTransferSessionEvent.receiverRejected) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.failed,
        effects: [_failTransfer],
      );
    }

    return switch (state) {
      OutgoingTransferSessionState.created => _fromCreated(event),
      OutgoingTransferSessionState.waitingForReceiverPrepare =>
        _fromWaitingForReceiverPrepare(event),
      OutgoingTransferSessionState.bindingDataEndpoint =>
        _fromBindingDataEndpoint(event),
      OutgoingTransferSessionState.sendingStartFrame => _fromSendingStartFrame(
        event,
      ),
      OutgoingTransferSessionState.sendingChunks => _fromSendingChunks(event),
      OutgoingTransferSessionState.waitingForChunkAcks =>
        _fromWaitingForChunkAcks(event),
      OutgoingTransferSessionState.sendingFinish => _fromSendingFinish(event),
      OutgoingTransferSessionState.waitingForFinishAck =>
        _fromWaitingForFinishAck(event),
      OutgoingTransferSessionState.canceling => _fromCanceling(event),
      OutgoingTransferSessionState.completed ||
      OutgoingTransferSessionState.canceled ||
      OutgoingTransferSessionState.failed => _invalid(state, event),
    };
  }

  static TransitionResult<OutgoingTransferSessionState> _fromCreated(
    OutgoingTransferSessionEvent event,
  ) {
    if (event == OutgoingTransferSessionEvent.startRequested) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.waitingForReceiverPrepare,
        effects: [_sendTransferInit],
      );
    }
    return _invalid(OutgoingTransferSessionState.created, event);
  }

  static TransitionResult<OutgoingTransferSessionState>
  _fromWaitingForReceiverPrepare(OutgoingTransferSessionEvent event) {
    if (event == OutgoingTransferSessionEvent.receiverAccepted) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.bindingDataEndpoint,
        effects: [_bindDataEndpoint],
      );
    }
    return _invalid(
      OutgoingTransferSessionState.waitingForReceiverPrepare,
      event,
    );
  }

  static TransitionResult<OutgoingTransferSessionState>
  _fromBindingDataEndpoint(OutgoingTransferSessionEvent event) {
    if (event == OutgoingTransferSessionEvent.dataEndpointBound) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.sendingStartFrame,
        effects: [_sendDataStartFrame],
      );
    }
    return _invalid(OutgoingTransferSessionState.bindingDataEndpoint, event);
  }

  static TransitionResult<OutgoingTransferSessionState> _fromSendingStartFrame(
    OutgoingTransferSessionEvent event,
  ) {
    if (event == OutgoingTransferSessionEvent.startFrameSent) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.sendingChunks,
        effects: [_pumpChunkWindow],
      );
    }
    return _invalid(OutgoingTransferSessionState.sendingStartFrame, event);
  }

  static TransitionResult<OutgoingTransferSessionState> _fromSendingChunks(
    OutgoingTransferSessionEvent event,
  ) {
    return switch (event) {
      OutgoingTransferSessionEvent.windowSaturated =>
        TransitionResult.transitioned(
          OutgoingTransferSessionState.waitingForChunkAcks,
        ),
      OutgoingTransferSessionEvent.allChunksAcked =>
        TransitionResult.transitioned(
          OutgoingTransferSessionState.sendingFinish,
          effects: [_sendDataFinishFrame],
        ),
      _ => _invalid(OutgoingTransferSessionState.sendingChunks, event),
    };
  }

  static TransitionResult<OutgoingTransferSessionState>
  _fromWaitingForChunkAcks(OutgoingTransferSessionEvent event) {
    return switch (event) {
      OutgoingTransferSessionEvent.ackOpenedWindow =>
        TransitionResult.transitioned(
          OutgoingTransferSessionState.sendingChunks,
        ),
      OutgoingTransferSessionEvent.allChunksAcked =>
        TransitionResult.transitioned(
          OutgoingTransferSessionState.sendingFinish,
          effects: [_sendDataFinishFrame],
        ),
      _ => _invalid(OutgoingTransferSessionState.waitingForChunkAcks, event),
    };
  }

  static TransitionResult<OutgoingTransferSessionState> _fromSendingFinish(
    OutgoingTransferSessionEvent event,
  ) {
    if (event == OutgoingTransferSessionEvent.finishFrameSent) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.waitingForFinishAck,
      );
    }
    return _invalid(OutgoingTransferSessionState.sendingFinish, event);
  }

  static TransitionResult<OutgoingTransferSessionState>
  _fromWaitingForFinishAck(OutgoingTransferSessionEvent event) {
    if (event == OutgoingTransferSessionEvent.finishAccepted) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.completed,
        effects: [_completeTransfer],
      );
    }
    return _invalid(OutgoingTransferSessionState.waitingForFinishAck, event);
  }

  static TransitionResult<OutgoingTransferSessionState> _fromCanceling(
    OutgoingTransferSessionEvent event,
  ) {
    if (event == OutgoingTransferSessionEvent.cancelCompleted) {
      return TransitionResult.transitioned(
        OutgoingTransferSessionState.canceled,
        effects: [_cleanupTransfer],
      );
    }
    return _invalid(OutgoingTransferSessionState.canceling, event);
  }

  static bool _isTerminal(OutgoingTransferSessionState state) {
    return state == OutgoingTransferSessionState.completed ||
        state == OutgoingTransferSessionState.canceled ||
        state == OutgoingTransferSessionState.failed;
  }

  static TransitionResult<OutgoingTransferSessionState> _invalid(
    OutgoingTransferSessionState state,
    OutgoingTransferSessionEvent event,
  ) {
    return TransitionResult.failure(
      state,
      issue: TransitionIssue(
        code: 'outgoing_transfer_invalid_transition',
        message: 'Invalid outgoing transfer transition: $state + $event.',
      ),
    );
  }
}
