import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';

void main() {
  final transferIdBytes = transferIdBytesFromString('transfer-001');

  DataFrame chunkFrame({Uint8List? payload}) {
    return DataFrame(
      version: DataFrameCodec.version,
      type: DataFrameType.dataChunk,
      flags: 0,
      sessionHash: 0x0102030405060708,
      transferIdBytes: transferIdBytes,
      sequence: 7,
      chunkIndex: 3,
      windowStart: 0,
      windowSize: 128,
      ackBase: 0,
      payload: payload ?? Uint8List.fromList([1, 2, 3, 4]),
    );
  }

  test('encodes and decodes raw bytes without JSON or base64 payload path', () {
    const codec = DataFrameCodec();
    final frame = chunkFrame(payload: Uint8List.fromList([0, 255, 18, 42]));
    final encoded = codec.encode(frame);
    final decoded = codec.decode(encoded);

    expect(decoded.type, DataFrameType.dataChunk);
    expect(decoded.payload, [0, 255, 18, 42]);
    expect(utf8.decode(encoded, allowMalformed: true), isNot(contains('{')));
  });

  test('uses big-endian numeric fields', () {
    const codec = DataFrameCodec();
    final encoded = codec.encode(chunkFrame());

    expect(encoded.sublist(16, 24), [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('rejects truncated payload and unknown magic', () {
    const codec = DataFrameCodec();
    final encoded = codec.encode(chunkFrame());

    expect(
      () => codec.decode(Uint8List.fromList(encoded.sublist(0, 20))),
      throwsFormatException,
    );

    encoded[0] = 0;
    expect(() => codec.decode(encoded), throwsFormatException);
  });

  test('rejects auth tag mismatch', () {
    final codec = DataFrameCodec(
      authenticator: const DataFrameAuthenticator(key: [1, 2, 3]),
    );
    final encoded = codec.encode(chunkFrame());
    encoded[encoded.length - 1] ^= 0xff;

    expect(() => codec.decode(encoded), throwsFormatException);
  });

  test('calculates safe MTU payload budget', () {
    const codec = DataFrameCodec();

    expect(codec.maxPayloadBytes(), inInclusiveRange(1200, 1400));
    expect(
      codec
          .encode(chunkFrame(payload: Uint8List(codec.maxPayloadBytes())))
          .length,
      lessThanOrEqualTo(DataFrameCodec.safeUdpPayloadBytes),
    );
  });
}
