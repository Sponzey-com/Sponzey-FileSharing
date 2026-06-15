import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_protocol.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_session.dart';

void main() {
  group('DataTransferSessionStateMachine', () {
    const machine = DataTransferSessionStateMachine();

    test('rejects chunks before incoming DATA_START', () {
      final decision = machine.transition(
        direction: DataTransferDirection.incoming,
        status: DataTransferStatus.waitingDataStart,
        event: DataTransferEvent.chunkReceived,
      );

      expect(decision.changed, isFalse);
      expect(decision.status, DataTransferStatus.waitingDataStart);
      expect(decision.issueCode, 'invalid_incoming_data_transfer_transition');
    });

    test('does not revive terminal failed transfer with late ACK', () {
      final decision = machine.transition(
        direction: DataTransferDirection.outgoing,
        status: DataTransferStatus.failed,
        event: DataTransferEvent.ackReceived,
      );

      expect(decision.changed, isFalse);
      expect(decision.status, DataTransferStatus.failed);
      expect(decision.issueCode, 'terminal_data_transfer_state');
    });

    test('outgoing path reaches verifying after all chunks are acked', () {
      var decision = machine.transition(
        direction: DataTransferDirection.outgoing,
        status: DataTransferStatus.sending,
        event: DataTransferEvent.allChunksAcked,
      );
      expect(decision.status, DataTransferStatus.draining);
      expect(decision.effect, 'sendDataFinish');

      decision = machine.transition(
        direction: DataTransferDirection.outgoing,
        status: decision.status,
        event: DataTransferEvent.dataFinishSent,
      );
      expect(decision.status, DataTransferStatus.verifying);
    });
  });

  group('DataWindow', () {
    test('uses minimum of congestion and advertised window', () {
      const window = DataWindow(
        congestionWindow: 128,
        advertisedWindow: 32,
        inFlightCount: 10,
      );

      expect(window.effectiveWindow, 32);
      expect(window.sendBudget, 22);
    });

    test('shrinks and grows inside boundaries', () {
      const window = DataWindow(
        congestionWindow: 3,
        advertisedWindow: 100,
        inFlightCount: 0,
        minimumWindow: 2,
        maximumWindow: 4,
      );

      expect(window.shrink().congestionWindow, 2);
      expect(window.grow().congestionWindow, 4);
      expect(window.grow().grow().congestionWindow, 4);
    });
  });

  test('selective ACK resolves cumulative and bitmap acknowledgements', () {
    const bitmap = SelectiveAckBitmap(ackBase: 5, receivedOffsets: {0, 2});

    expect(bitmap.acknowledges(4), isTrue);
    expect(bitmap.acknowledges(5), isTrue);
    expect(bitmap.acknowledges(6), isFalse);
    expect(bitmap.acknowledges(7), isTrue);
  });

  test('retransmission planner returns missing indexes with limit', () {
    final plan = const RetransmissionPlanner().missing(
      totalChunks: 10,
      nextExpectedChunk: 3,
      receivedChunks: {3, 5, 8},
      limit: 3,
    );

    expect(plan.chunkIndexes, [4, 6, 7]);
  });

  test('receiver buffer budget reduces advertised window', () {
    const budget = ReceiverBufferBudget(
      sessionBytes: 4096,
      processBytes: 8192,
      usedSessionBytes: 3072,
      usedProcessBytes: 4096,
    );

    expect(budget.advertisedWindow(baseWindow: 8, payloadBytes: 512), 2);
  });

  test('data protocol capability is typed and round-trips from wire names', () {
    final capabilities = DataTransferCapabilitySet.fromWireList(const [
      'udpDataBinaryV1',
      'unknown',
    ]);

    expect(
      capabilities.supports(DataTransferCapability.udpDataBinaryV1),
      isTrue,
    );
    expect(capabilities.toWireList(), ['udpDataBinaryV1']);
    expect(DataTransferProtocolVersion.v1.isSupported, isTrue);
  });
}
