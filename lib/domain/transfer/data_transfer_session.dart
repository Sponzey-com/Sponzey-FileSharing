enum DataTransferDirection { outgoing, incoming }

enum DataTransferStatus {
  idle,
  preparingFile,
  controlNegotiating,
  bindingDataPort,
  dataStarting,
  sending,
  draining,
  controlAccepted,
  waitingDataStart,
  receiving,
  verifying,
  finalizing,
  completed,
  failed,
  cancelled,
}

enum DataTransferEvent {
  prepareRequested,
  filePrepared,
  controlAccepted,
  controlRejected,
  dataPortBound,
  dataStartSent,
  dataStartReceived,
  chunkSent,
  chunkReceived,
  ackReceived,
  nackReceived,
  allChunksAcked,
  dataFinishSent,
  dataFinishReceived,
  digestVerified,
  digestFailed,
  timeout,
  maxRetryExceeded,
  cancelRequested,
}

class DataTransferDecision {
  const DataTransferDecision({
    required this.status,
    required this.changed,
    this.effect,
    this.issueCode,
  });

  final DataTransferStatus status;
  final bool changed;
  final String? effect;
  final String? issueCode;

  bool get isFailure => status == DataTransferStatus.failed;

  static DataTransferDecision transitioned(
    DataTransferStatus status, {
    String? effect,
  }) {
    return DataTransferDecision(status: status, changed: true, effect: effect);
  }

  static DataTransferDecision noOp(
    DataTransferStatus status, {
    String? issueCode,
  }) {
    return DataTransferDecision(
      status: status,
      changed: false,
      issueCode: issueCode,
    );
  }

  static DataTransferDecision failed(String issueCode) {
    return DataTransferDecision(
      status: DataTransferStatus.failed,
      changed: true,
      issueCode: issueCode,
    );
  }
}

class DataTransferSessionStateMachine {
  const DataTransferSessionStateMachine();

  DataTransferDecision transition({
    required DataTransferDirection direction,
    required DataTransferStatus status,
    required DataTransferEvent event,
  }) {
    if (status == DataTransferStatus.completed ||
        status == DataTransferStatus.failed ||
        status == DataTransferStatus.cancelled) {
      return DataTransferDecision.noOp(
        status,
        issueCode: 'terminal_data_transfer_state',
      );
    }

    if (event == DataTransferEvent.cancelRequested) {
      return DataTransferDecision.transitioned(
        DataTransferStatus.cancelled,
        effect: 'sendDataAbort',
      );
    }
    if (event == DataTransferEvent.maxRetryExceeded ||
        event == DataTransferEvent.digestFailed) {
      return DataTransferDecision.failed(event.name);
    }

    switch (direction) {
      case DataTransferDirection.outgoing:
        return _outgoing(status, event);
      case DataTransferDirection.incoming:
        return _incoming(status, event);
    }
  }

  DataTransferDecision _outgoing(
    DataTransferStatus status,
    DataTransferEvent event,
  ) {
    switch ((status, event)) {
      case (DataTransferStatus.idle, DataTransferEvent.prepareRequested):
        return DataTransferDecision.transitioned(
          DataTransferStatus.preparingFile,
          effect: 'prepareOutgoingFile',
        );
      case (DataTransferStatus.preparingFile, DataTransferEvent.filePrepared):
        return DataTransferDecision.transitioned(
          DataTransferStatus.controlNegotiating,
          effect: 'sendTransferInit',
        );
      case (
        DataTransferStatus.controlNegotiating,
        DataTransferEvent.controlAccepted,
      ):
        return DataTransferDecision.transitioned(
          DataTransferStatus.bindingDataPort,
          effect: 'bindSenderDataPort',
        );
      case (
        DataTransferStatus.controlNegotiating,
        DataTransferEvent.controlRejected,
      ):
        return DataTransferDecision.failed('control_rejected');
      case (
        DataTransferStatus.bindingDataPort,
        DataTransferEvent.dataPortBound,
      ):
        return DataTransferDecision.transitioned(
          DataTransferStatus.dataStarting,
          effect: 'sendDataStart',
        );
      case (DataTransferStatus.dataStarting, DataTransferEvent.dataStartSent):
        return DataTransferDecision.transitioned(DataTransferStatus.sending);
      case (DataTransferStatus.sending, DataTransferEvent.chunkSent):
      case (DataTransferStatus.sending, DataTransferEvent.ackReceived):
      case (DataTransferStatus.sending, DataTransferEvent.nackReceived):
        return DataTransferDecision.noOp(status);
      case (DataTransferStatus.sending, DataTransferEvent.allChunksAcked):
        return DataTransferDecision.transitioned(
          DataTransferStatus.draining,
          effect: 'sendDataFinish',
        );
      case (DataTransferStatus.draining, DataTransferEvent.dataFinishSent):
        return DataTransferDecision.transitioned(DataTransferStatus.verifying);
      case (DataTransferStatus.verifying, DataTransferEvent.digestVerified):
        return DataTransferDecision.transitioned(DataTransferStatus.completed);
      case (_, DataTransferEvent.timeout):
        return DataTransferDecision.failed('data_transfer_timeout');
      default:
        return DataTransferDecision.noOp(
          status,
          issueCode: 'invalid_outgoing_data_transfer_transition',
        );
    }
  }

  DataTransferDecision _incoming(
    DataTransferStatus status,
    DataTransferEvent event,
  ) {
    switch ((status, event)) {
      case (DataTransferStatus.idle, DataTransferEvent.controlAccepted):
        return DataTransferDecision.transitioned(
          DataTransferStatus.controlAccepted,
          effect: 'bindReceiverDataPort',
        );
      case (
        DataTransferStatus.controlAccepted,
        DataTransferEvent.dataPortBound,
      ):
        return DataTransferDecision.transitioned(
          DataTransferStatus.waitingDataStart,
        );
      case (
        DataTransferStatus.waitingDataStart,
        DataTransferEvent.dataStartReceived,
      ):
        return DataTransferDecision.transitioned(DataTransferStatus.receiving);
      case (DataTransferStatus.receiving, DataTransferEvent.chunkReceived):
      case (DataTransferStatus.receiving, DataTransferEvent.ackReceived):
      case (DataTransferStatus.receiving, DataTransferEvent.nackReceived):
        return DataTransferDecision.noOp(status);
      case (DataTransferStatus.receiving, DataTransferEvent.dataFinishReceived):
        return DataTransferDecision.transitioned(
          DataTransferStatus.verifying,
          effect: 'verifyStreamingDigest',
        );
      case (DataTransferStatus.verifying, DataTransferEvent.digestVerified):
        return DataTransferDecision.transitioned(
          DataTransferStatus.finalizing,
          effect: 'finalizeIncomingFile',
        );
      case (DataTransferStatus.finalizing, DataTransferEvent.digestVerified):
        return DataTransferDecision.transitioned(DataTransferStatus.completed);
      case (_, DataTransferEvent.timeout):
        return DataTransferDecision.failed('data_transfer_timeout');
      default:
        return DataTransferDecision.noOp(
          status,
          issueCode: 'invalid_incoming_data_transfer_transition',
        );
    }
  }
}

class DataWindow {
  const DataWindow({
    required this.congestionWindow,
    required this.advertisedWindow,
    required this.inFlightCount,
    this.minimumWindow = 1,
    this.maximumWindow = 2048,
  });

  final int congestionWindow;
  final int advertisedWindow;
  final int inFlightCount;
  final int minimumWindow;
  final int maximumWindow;

  int get sendBudget {
    final available = effectiveWindow - inFlightCount;
    return available < 0 ? 0 : available;
  }

  int get effectiveWindow {
    final boundedCongestion = congestionWindow.clamp(
      minimumWindow,
      maximumWindow,
    );
    final boundedAdvertised = advertisedWindow < minimumWindow
        ? minimumWindow
        : advertisedWindow;
    return boundedCongestion < boundedAdvertised
        ? boundedCongestion
        : boundedAdvertised;
  }

  DataWindow grow() {
    return DataWindow(
      congestionWindow: congestionWindow >= maximumWindow
          ? maximumWindow
          : congestionWindow + 1,
      advertisedWindow: advertisedWindow,
      inFlightCount: inFlightCount,
      minimumWindow: minimumWindow,
      maximumWindow: maximumWindow,
    );
  }

  DataWindow shrink() {
    final reduced = congestionWindow ~/ 2;
    return DataWindow(
      congestionWindow: reduced < minimumWindow ? minimumWindow : reduced,
      advertisedWindow: advertisedWindow,
      inFlightCount: inFlightCount,
      minimumWindow: minimumWindow,
      maximumWindow: maximumWindow,
    );
  }

  DataWindow withAdvertisedWindow(int nextAdvertisedWindow) {
    return DataWindow(
      congestionWindow: congestionWindow,
      advertisedWindow: nextAdvertisedWindow,
      inFlightCount: inFlightCount,
      minimumWindow: minimumWindow,
      maximumWindow: maximumWindow,
    );
  }
}

class SelectiveAckBitmap {
  const SelectiveAckBitmap({
    required this.ackBase,
    required this.receivedOffsets,
  });

  final int ackBase;
  final Set<int> receivedOffsets;

  bool acknowledges(int chunkIndex) {
    if (chunkIndex < ackBase) {
      return true;
    }
    return receivedOffsets.contains(chunkIndex - ackBase);
  }

  List<int> acknowledgedIndexes({required int limit}) {
    return [
      for (var index = 0; index < limit; index += 1)
        if (acknowledges(index)) index,
    ];
  }
}

class RetransmissionPlan {
  const RetransmissionPlan({required this.chunkIndexes});

  final List<int> chunkIndexes;

  bool get isEmpty => chunkIndexes.isEmpty;
}

class RetransmissionPlanner {
  const RetransmissionPlanner();

  RetransmissionPlan missing({
    required int totalChunks,
    required int nextExpectedChunk,
    required Set<int> receivedChunks,
    required int limit,
  }) {
    final missing = <int>[];
    for (
      var index = nextExpectedChunk;
      index < totalChunks && missing.length < limit;
      index += 1
    ) {
      if (!receivedChunks.contains(index)) {
        missing.add(index);
      }
    }
    return RetransmissionPlan(chunkIndexes: missing);
  }
}

class ReceiverBufferBudget {
  const ReceiverBufferBudget({
    required this.sessionBytes,
    required this.processBytes,
    required this.usedSessionBytes,
    required this.usedProcessBytes,
  });

  final int sessionBytes;
  final int processBytes;
  final int usedSessionBytes;
  final int usedProcessBytes;

  bool get isExceeded {
    return usedSessionBytes > sessionBytes || usedProcessBytes > processBytes;
  }

  int advertisedWindow({required int baseWindow, required int payloadBytes}) {
    if (payloadBytes <= 0 || baseWindow <= 1) {
      return 1;
    }
    final sessionRemaining = sessionBytes - usedSessionBytes;
    final processRemaining = processBytes - usedProcessBytes;
    final remaining = sessionRemaining < processRemaining
        ? sessionRemaining
        : processRemaining;
    final byBytes = remaining ~/ payloadBytes;
    if (byBytes < 1) {
      return 1;
    }
    return byBytes > baseWindow ? baseWindow : byBytes;
  }
}
