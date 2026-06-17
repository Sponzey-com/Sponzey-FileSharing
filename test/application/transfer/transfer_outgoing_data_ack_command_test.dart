import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_data_ack_command.dart';

void main() {
  test('filters invalid ACK indexes and sorts valid indexes', () {
    final decision = TransferOutgoingDataAckCommand.decide(
      rawAckIndexes: const [5, -1, 2, 99, 1],
      chunkCount: 6,
      acknowledgedChunks: const {},
    );

    expect(decision.validAckIndexes, [1, 2, 5]);
    expect(decision.newlyAckedIndexes, [1, 2, 5]);
    expect(decision.duplicateAckCount, 0);
  });

  test('counts indexes already acknowledged as duplicate ACKs', () {
    final decision = TransferOutgoingDataAckCommand.decide(
      rawAckIndexes: const [1, 2, 3],
      chunkCount: 5,
      acknowledgedChunks: const {1, 3},
    );

    expect(decision.validAckIndexes, [1, 2, 3]);
    expect(decision.newlyAckedIndexes, [2]);
    expect(decision.duplicateAckCount, 2);
  });

  test('counts same-frame duplicate ACK indexes', () {
    final decision = TransferOutgoingDataAckCommand.decide(
      rawAckIndexes: const [4, 2, 4, 2],
      chunkCount: 5,
      acknowledgedChunks: const {},
    );

    expect(decision.validAckIndexes, [2, 2, 4, 4]);
    expect(decision.newlyAckedIndexes, [2, 4]);
    expect(decision.duplicateAckCount, 2);
  });

  test('does not mutate acknowledged chunk input', () {
    final acknowledged = {0, 1};

    TransferOutgoingDataAckCommand.decide(
      rawAckIndexes: const [1, 2],
      chunkCount: 4,
      acknowledgedChunks: acknowledged,
    );

    expect(acknowledged, {0, 1});
  });

  test('command stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_outgoing_data_ack_command.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });
}
