import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/outgoing_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

void main() {
  group('OutgoingTransferSessionStateMachine', () {
    const machine = OutgoingTransferSessionStateMachine();

    test('transitions through the happy path', () {
      var result = machine.transition(
        OutgoingTransferSessionState.created,
        OutgoingTransferSessionEvent.startRequested,
      );
      expect(
        result.state,
        OutgoingTransferSessionState.waitingForReceiverPrepare,
      );
      expect(result.disposition, TransitionDisposition.transitioned);
      expect(result.effects.map((effect) => effect.name), ['sendTransferInit']);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.receiverAccepted,
      );
      expect(result.state, OutgoingTransferSessionState.bindingDataEndpoint);
      expect(result.effects.map((effect) => effect.name), ['bindDataEndpoint']);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.dataEndpointBound,
      );
      expect(result.state, OutgoingTransferSessionState.sendingStartFrame);
      expect(result.effects.map((effect) => effect.name), [
        'sendDataStartFrame',
      ]);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.startFrameSent,
      );
      expect(result.state, OutgoingTransferSessionState.sendingChunks);
      expect(result.effects.map((effect) => effect.name), ['pumpChunkWindow']);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.windowSaturated,
      );
      expect(result.state, OutgoingTransferSessionState.waitingForChunkAcks);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.ackOpenedWindow,
      );
      expect(result.state, OutgoingTransferSessionState.sendingChunks);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.allChunksAcked,
      );
      expect(result.state, OutgoingTransferSessionState.sendingFinish);
      expect(result.effects.map((effect) => effect.name), [
        'sendDataFinishFrame',
      ]);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.finishFrameSent,
      );
      expect(result.state, OutgoingTransferSessionState.waitingForFinishAck);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.finishAccepted,
      );
      expect(result.state, OutgoingTransferSessionState.completed);
      expect(result.effects.map((effect) => effect.name), ['completeTransfer']);
    });

    test('marks failed when receiver rejects prepare or a failure occurs', () {
      final rejected = machine.transition(
        OutgoingTransferSessionState.waitingForReceiverPrepare,
        OutgoingTransferSessionEvent.receiverRejected,
      );
      expect(rejected.state, OutgoingTransferSessionState.failed);
      expect(rejected.effects.map((effect) => effect.name), ['failTransfer']);

      final failed = machine.transition(
        OutgoingTransferSessionState.sendingChunks,
        OutgoingTransferSessionEvent.failureOccurred,
      );
      expect(failed.state, OutgoingTransferSessionState.failed);
      expect(failed.effects.map((effect) => effect.name), ['failTransfer']);
    });

    test('cancels non-terminal states and completes cancellation', () {
      var result = machine.transition(
        OutgoingTransferSessionState.sendingChunks,
        OutgoingTransferSessionEvent.cancelRequested,
      );
      expect(result.state, OutgoingTransferSessionState.canceling);
      expect(result.effects.map((effect) => effect.name), ['cancelTransfer']);

      result = machine.transition(
        result.state,
        OutgoingTransferSessionEvent.cancelCompleted,
      );
      expect(result.state, OutgoingTransferSessionState.canceled);
      expect(result.effects.map((effect) => effect.name), ['cleanupTransfer']);
    });

    test('terminal states reject later events with warning no-op', () {
      final result = machine.transition(
        OutgoingTransferSessionState.completed,
        OutgoingTransferSessionEvent.failureOccurred,
      );

      expect(result.state, OutgoingTransferSessionState.completed);
      expect(result.disposition, TransitionDisposition.warning);
      expect(result.issue?.code, 'outgoing_transfer_already_terminal');
    });

    test('invalid non-terminal transition returns failure', () {
      final result = machine.transition(
        OutgoingTransferSessionState.created,
        OutgoingTransferSessionEvent.finishAccepted,
      );

      expect(result.state, OutgoingTransferSessionState.created);
      expect(result.disposition, TransitionDisposition.failure);
      expect(result.issue?.code, 'outgoing_transfer_invalid_transition');
    });
  });
}
