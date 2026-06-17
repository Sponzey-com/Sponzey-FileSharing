import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_data_chunk_command.dart';

void main() {
  test('rejects chunk indexes outside the expected range', () {
    final decision = TransferIncomingDataChunkCommand.decide(
      chunkIndex: 4,
      expectedChunkCount: 4,
      nextExpectedChunk: 2,
      acknowledgedChunks: const {0, 1},
    );

    expect(decision.action, TransferIncomingDataChunkAction.rejectOutOfRange);
    expect(decision.nackChunkIndex, 2);
  });

  test('acknowledges duplicate chunks without mutating acknowledged set', () {
    final acknowledged = {0, 1, 3};

    final decision = TransferIncomingDataChunkCommand.decide(
      chunkIndex: 1,
      expectedChunkCount: 5,
      nextExpectedChunk: 2,
      acknowledgedChunks: acknowledged,
    );

    expect(decision.action, TransferIncomingDataChunkAction.ackDuplicate);
    expect(acknowledged, {0, 1, 3});
  });

  test('appends in-order chunk when it matches next expected chunk', () {
    final decision = TransferIncomingDataChunkCommand.decide(
      chunkIndex: 2,
      expectedChunkCount: 5,
      nextExpectedChunk: 2,
      acknowledgedChunks: const {0, 1},
    );

    expect(decision.action, TransferIncomingDataChunkAction.appendInOrder);
  });

  test('buffers out-of-order chunk when it is valid but not next expected', () {
    final decision = TransferIncomingDataChunkCommand.decide(
      chunkIndex: 4,
      expectedChunkCount: 6,
      nextExpectedChunk: 2,
      acknowledgedChunks: const {0, 1},
    );

    expect(decision.action, TransferIncomingDataChunkAction.bufferOutOfOrder);
  });

  test('command stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_incoming_data_chunk_command.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });
}
