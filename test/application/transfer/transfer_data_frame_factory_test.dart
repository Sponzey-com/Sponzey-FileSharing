import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_factory.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';

void main() {
  group('TransferDataFrameFactory', () {
    test('creates outgoing frame with remote window defaults', () {
      final transferIdBytes = Uint8List.fromList([1, 2, 3, 4]);
      final frame = TransferDataFrameFactory.outgoing(
        sessionHash: 123,
        transferIdBytes: transferIdBytes,
        type: DataFrameType.dataStart,
        sequence: 9,
        remoteWindowStart: 4,
        windowSize: 32,
      );

      expect(frame.version, DataFrameCodec.version);
      expect(frame.type, DataFrameType.dataStart);
      expect(frame.flags, 0);
      expect(frame.sessionHash, 123);
      expect(frame.transferIdBytes, transferIdBytes);
      expect(frame.sequence, 9);
      expect(frame.chunkIndex, 0);
      expect(frame.windowStart, 4);
      expect(frame.windowSize, 32);
      expect(frame.ackBase, 0);
      expect(frame.ackBitmapWords, isEmpty);
      expect(frame.payload, isEmpty);
    });

    test('creates outgoing frame with explicit data fields', () {
      final payload = Uint8List.fromList([10, 11, 12]);
      final frame = TransferDataFrameFactory.outgoing(
        sessionHash: 321,
        transferIdBytes: Uint8List.fromList([4, 3, 2, 1]),
        type: DataFrameType.dataChunk,
        sequence: 10,
        remoteWindowStart: 4,
        windowSize: 32,
        chunkIndex: 7,
        windowStart: 8,
        ackBase: 6,
        ackBitmapWords: const [1, 2],
        payload: payload,
      );

      expect(frame.chunkIndex, 7);
      expect(frame.windowStart, 8);
      expect(frame.windowSize, 32);
      expect(frame.ackBase, 6);
      expect(frame.ackBitmapWords, [1, 2]);
      expect(frame.payload, payload);
    });

    test('creates incoming frame with receiver window defaults', () {
      final frame = TransferDataFrameFactory.incoming(
        sessionHash: 456,
        transferIdBytes: Uint8List.fromList([9, 8, 7]),
        type: DataFrameType.dataAck,
        sequence: 3,
        nextExpectedChunk: 11,
        receiverWindowSize: 24,
      );

      expect(frame.version, DataFrameCodec.version);
      expect(frame.type, DataFrameType.dataAck);
      expect(frame.sessionHash, 456);
      expect(frame.sequence, 3);
      expect(frame.windowStart, 11);
      expect(frame.windowSize, 24);
    });

    test('creates incoming frame with explicit ack fields', () {
      final frame = TransferDataFrameFactory.incoming(
        sessionHash: 456,
        transferIdBytes: Uint8List.fromList([9, 8, 7]),
        type: DataFrameType.dataNack,
        sequence: 4,
        nextExpectedChunk: 11,
        receiverWindowSize: 24,
        chunkIndex: 12,
        windowStart: 13,
        windowSize: 14,
        ackBase: 10,
        ackBitmapWords: const [3],
      );

      expect(frame.chunkIndex, 12);
      expect(frame.windowStart, 13);
      expect(frame.windowSize, 14);
      expect(frame.ackBase, 10);
      expect(frame.ackBitmapWords, [3]);
    });

    test('controller delegates data frame creation to factory', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferDataFrameFactory.outgoing'));
      expect(source, contains('TransferDataFrameFactory.incoming'));
    });
  });
}
