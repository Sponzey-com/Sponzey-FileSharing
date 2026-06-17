import 'dart:typed_data';

import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';

class TransferDataFrameFactory {
  const TransferDataFrameFactory._();

  static DataFrame outgoing({
    required int sessionHash,
    required Uint8List transferIdBytes,
    required DataFrameType type,
    required int sequence,
    required int remoteWindowStart,
    required int windowSize,
    int chunkIndex = 0,
    int? windowStart,
    int ackBase = 0,
    List<int> ackBitmapWords = const [],
    Uint8List? payload,
  }) {
    return DataFrame(
      version: DataFrameCodec.version,
      type: type,
      flags: 0,
      sessionHash: sessionHash,
      transferIdBytes: transferIdBytes,
      sequence: sequence,
      chunkIndex: chunkIndex,
      windowStart: windowStart ?? remoteWindowStart,
      windowSize: windowSize,
      ackBase: ackBase,
      ackBitmapWords: ackBitmapWords,
      payload: payload,
    );
  }

  static DataFrame incoming({
    required int sessionHash,
    required Uint8List transferIdBytes,
    required DataFrameType type,
    required int sequence,
    required int nextExpectedChunk,
    required int receiverWindowSize,
    int chunkIndex = 0,
    int? windowStart,
    int? windowSize,
    int ackBase = 0,
    List<int> ackBitmapWords = const [],
    Uint8List? payload,
  }) {
    return DataFrame(
      version: DataFrameCodec.version,
      type: type,
      flags: 0,
      sessionHash: sessionHash,
      transferIdBytes: transferIdBytes,
      sequence: sequence,
      chunkIndex: chunkIndex,
      windowStart: windowStart ?? nextExpectedChunk,
      windowSize: windowSize ?? receiverWindowSize,
      ackBase: ackBase,
      ackBitmapWords: ackBitmapWords,
      payload: payload,
    );
  }
}
