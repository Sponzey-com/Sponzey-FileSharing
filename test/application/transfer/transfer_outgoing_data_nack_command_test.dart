import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_data_nack_command.dart';

void main() {
  test('includes the primary NACK chunk index', () {
    final decision = TransferOutgoingDataNackCommand.decide(
      primaryChunkIndex: 7,
      ackBase: 20,
      ackBitmapWords: const [],
      acknowledgedChunks: const {},
    );

    expect(decision.retransmissionIndexes, [7]);
  });

  test('expands bitmap words from ack base into retransmission indexes', () {
    final decision = TransferOutgoingDataNackCommand.decide(
      primaryChunkIndex: 7,
      ackBase: 20,
      ackBitmapWords: const [5, 2],
      acknowledgedChunks: const {},
    );

    expect(decision.retransmissionIndexes, [7, 20, 22, 53]);
  });

  test('excludes chunks already acknowledged by the sender', () {
    final decision = TransferOutgoingDataNackCommand.decide(
      primaryChunkIndex: 7,
      ackBase: 20,
      ackBitmapWords: const [5],
      acknowledgedChunks: const {7, 22},
    );

    expect(decision.retransmissionIndexes, [20]);
  });

  test('deduplicates and sorts retransmission indexes', () {
    final decision = TransferOutgoingDataNackCommand.decide(
      primaryChunkIndex: 20,
      ackBase: 20,
      ackBitmapWords: const [1],
      acknowledgedChunks: const {},
    );

    expect(decision.retransmissionIndexes, [20]);
  });

  test('does not mutate acknowledged chunk input', () {
    final acknowledged = {1, 2};

    TransferOutgoingDataNackCommand.decide(
      primaryChunkIndex: 3,
      ackBase: 4,
      ackBitmapWords: const [1],
      acknowledgedChunks: acknowledged,
    );

    expect(acknowledged, {1, 2});
  });

  test('command stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_outgoing_data_nack_command.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });
}
