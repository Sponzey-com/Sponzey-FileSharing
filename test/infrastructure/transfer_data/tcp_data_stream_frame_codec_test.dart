import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_frame_codec.dart';

void main() {
  const codec = TcpDataStreamFrameCodec();

  test('encodes and decodes metadata frame', () {
    final frame = TcpDataStreamFrame(
      type: TcpDataStreamFrameType.metadata,
      transferId: 'transfer-1',
      sequence: 0,
      payload: Uint8List.fromList('file-name.pdf'.codeUnits),
    );

    final decoded = codec.decode(codec.encode(frame));

    expect(decoded.type, TcpDataStreamFrameType.metadata);
    expect(decoded.transferId, 'transfer-1');
    expect(decoded.sequence, 0);
    expect(String.fromCharCodes(decoded.payload), 'file-name.pdf');
  });

  test('encodes and decodes chunk frame with binary payload', () {
    final frame = TcpDataStreamFrame(
      type: TcpDataStreamFrameType.chunk,
      transferId: 'transfer-1',
      sequence: 42,
      payload: Uint8List.fromList([0, 1, 2, 255]),
    );

    final decoded = codec.decode(codec.encode(frame));

    expect(decoded.type, TcpDataStreamFrameType.chunk);
    expect(decoded.transferId, 'transfer-1');
    expect(decoded.sequence, 42);
    expect(decoded.payload, [0, 1, 2, 255]);
  });

  test('encodes and decodes complete frame without payload', () {
    final frame = TcpDataStreamFrame(
      type: TcpDataStreamFrameType.complete,
      transferId: 'transfer-1',
      sequence: 43,
      payload: Uint8List(0),
    );

    final decoded = codec.decode(codec.encode(frame));

    expect(decoded.type, TcpDataStreamFrameType.complete);
    expect(decoded.transferId, 'transfer-1');
    expect(decoded.sequence, 43);
    expect(decoded.payload, isEmpty);
  });

  test('rejects wrong magic', () {
    final bytes = codec.encode(
      TcpDataStreamFrame(
        type: TcpDataStreamFrameType.chunk,
        transferId: 'transfer-1',
        sequence: 1,
        payload: Uint8List(0),
      ),
    );
    bytes[4] = 0x58;

    expect(() => codec.decode(bytes), throwsFormatException);
  });

  test('rejects unsupported version', () {
    final bytes = codec.encode(
      TcpDataStreamFrame(
        type: TcpDataStreamFrameType.chunk,
        transferId: 'transfer-1',
        sequence: 1,
        payload: Uint8List(0),
      ),
    );
    bytes[8] = 99;

    expect(() => codec.decode(bytes), throwsFormatException);
  });

  test('rejects body length mismatch', () {
    final bytes = codec.encode(
      TcpDataStreamFrame(
        type: TcpDataStreamFrameType.chunk,
        transferId: 'transfer-1',
        sequence: 1,
        payload: Uint8List(0),
      ),
    );
    bytes[3] = bytes[3] + 1;

    expect(() => codec.decode(bytes), throwsFormatException);
  });
}
