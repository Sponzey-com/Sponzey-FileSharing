import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_session_state_machine.dart';

void main() {
  const outgoing = OutgoingTransferStateMachine();
  const incoming = IncomingTransferStateMachine();

  test('outgoing transfer waits for accept before data start', () {
    final early = outgoing.transition(
      OutgoingTransferStatus.created,
      OutgoingTransferEvent.dataStartSent,
    );
    expect(early.issue?.code, 'invalid_outgoing_transfer_transition');

    var result = outgoing.transition(
      OutgoingTransferStatus.created,
      OutgoingTransferEvent.offerRequested,
    );
    expect(result.state, OutgoingTransferStatus.offering);

    result = outgoing.transition(result.state, OutgoingTransferEvent.offerSent);
    expect(result.state, OutgoingTransferStatus.waitingForAccept);

    result = outgoing.transition(
      result.state,
      OutgoingTransferEvent.offerAccepted,
    );
    expect(result.state, OutgoingTransferStatus.preparingFile);
  });

  test('outgoing transfer fails on max retry exceeded', () {
    final result = outgoing.transition(
      OutgoingTransferStatus.waitingForAcks,
      OutgoingTransferEvent.maxRetryExceeded,
    );

    expect(result.state, OutgoingTransferStatus.failed);
    expect(result.isFailure, isTrue);
  });

  test('incoming transfer does not write chunks before destination prep', () {
    final result = incoming.transition(
      IncomingTransferStatus.accepted,
      IncomingTransferEvent.chunkReceived,
    );

    expect(result.issue?.code, 'invalid_incoming_transfer_transition');
  });

  test('incoming transfer never completes on checksum failure', () {
    final result = incoming.transition(
      IncomingTransferStatus.receivingChunks,
      IncomingTransferEvent.checksumFailed,
    );

    expect(result.state, IncomingTransferStatus.failed);
    expect(result.isFailure, isTrue);
  });
}
