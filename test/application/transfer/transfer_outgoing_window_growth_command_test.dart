import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_window_growth_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_tuning_policy.dart';

void main() {
  group('TransferOutgoingWindowGrowthCommand', () {
    const policy = DataTransferTuningPolicy(
      initialWindowSize: 4,
      maximumWindowSize: 16,
      receiverAdvertisedWindow: 16,
      windowUpdateChunkInterval: 4,
      ackBatchChunkThreshold: 4,
      maxWindowGrowthPerAck: 3,
      maxRetransmissions: 5,
      maxNackIndexesPerPacket: 8,
      ackBatchInterval: Duration(milliseconds: 4),
      metricLogInterval: Duration(milliseconds: 700),
    );

    test('does not grow window when no chunks were newly acknowledged', () {
      expect(
        TransferOutgoingWindowGrowthCommand.afterDataAck(
          tuningPolicy: policy,
          currentWindowSize: 8,
          maximumWindowSize: 16,
          newlyAckedChunks: 0,
        ),
        8,
      );
    });

    test('grows by ACK batches and caps at maximum window', () {
      expect(
        TransferOutgoingWindowGrowthCommand.afterDataAck(
          tuningPolicy: policy,
          currentWindowSize: 8,
          maximumWindowSize: 16,
          newlyAckedChunks: 9,
        ),
        11,
      );
      expect(
        TransferOutgoingWindowGrowthCommand.afterDataAck(
          tuningPolicy: policy,
          currentWindowSize: 15,
          maximumWindowSize: 16,
          newlyAckedChunks: 9,
        ),
        16,
      );
    });

    test('controller delegates ACK window growth to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingWindowGrowthCommand'));
      expect(source, isNot(contains('.windowAfterAck(')));
    });

    test('grows legacy ACK window by one until maximum', () {
      expect(
        TransferOutgoingWindowGrowthCommand.afterLegacyAck(
          currentWindowSize: 7,
          maximumWindowSize: 16,
        ),
        8,
      );
      expect(
        TransferOutgoingWindowGrowthCommand.afterLegacyAck(
          currentWindowSize: 16,
          maximumWindowSize: 16,
        ),
        16,
      );
      expect(
        TransferOutgoingWindowGrowthCommand.afterLegacyAck(
          currentWindowSize: 20,
          maximumWindowSize: 16,
        ),
        20,
      );
    });

    test('controller delegates legacy ACK window growth to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('context.windowSize += 1')));
    });
  });
}
