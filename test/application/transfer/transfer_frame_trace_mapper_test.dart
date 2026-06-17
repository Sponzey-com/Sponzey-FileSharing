import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_frame_trace_mapper.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';

void main() {
  group('TransferFrameTraceMapper', () {
    test('maps data frame fields into a diagnostics trace', () {
      final occurredAt = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final frame = DataFrame(
        version: 1,
        type: DataFrameType.dataAck,
        flags: 0,
        sessionHash: 123,
        transferIdBytes: Uint8List.fromList([1, 2, 3]),
        sequence: 42,
        chunkIndex: 7,
        windowStart: 3,
        windowSize: 16,
        ackBase: 5,
      );

      final trace = TransferFrameTraceMapper.fromFrame(
        frame,
        occurredAt: occurredAt,
        direction: 'out',
        endpoint: '10.0.0.2:23200',
        datagramBytes: 512,
        decisionCode: 'sent',
      );

      expect(trace.occurredAt, occurredAt);
      expect(trace.direction, 'out');
      expect(trace.frameType, 'dataAck');
      expect(trace.sequence, 42);
      expect(trace.chunkIndex, 7);
      expect(trace.ackBase, 5);
      expect(trace.datagramBytes, 512);
      expect(trace.endpoint, '10.0.0.2:23200');
      expect(trace.decisionCode, 'sent');
    });

    test('controller delegates frame trace creation to mapper', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferFrameTraceMapper.fromFrame'));
      expect(source, isNot(contains('TransferFrameTrace(')));
    });
  });
}
