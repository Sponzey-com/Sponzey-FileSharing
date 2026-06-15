import 'dart:typed_data';

enum DataFrameType {
  dataStart(1),
  dataChunk(2),
  dataAck(3),
  dataNack(4),
  dataWindowUpdate(5),
  dataFinish(6),
  dataAbort(7);

  const DataFrameType(this.code);

  final int code;

  static DataFrameType fromCode(int code) {
    return DataFrameType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => throw FormatException('Unsupported data frame type $code'),
    );
  }
}

class DataFrame {
  DataFrame({
    required this.version,
    required this.type,
    required this.flags,
    required this.sessionHash,
    required this.transferIdBytes,
    required this.sequence,
    required this.chunkIndex,
    required this.windowStart,
    required this.windowSize,
    required this.ackBase,
    this.ackBitmapWords = const [],
    Uint8List? payload,
    Uint8List? authTag,
  }) : payload = payload ?? Uint8List(0),
       authTag = authTag ?? Uint8List(0);

  final int version;
  final DataFrameType type;
  final int flags;
  final int sessionHash;
  final Uint8List transferIdBytes;
  final int sequence;
  final int chunkIndex;
  final int windowStart;
  final int windowSize;
  final int ackBase;
  final List<int> ackBitmapWords;
  final Uint8List payload;
  final Uint8List authTag;

  DataFrame copyWith({
    int? version,
    DataFrameType? type,
    int? flags,
    int? sessionHash,
    Uint8List? transferIdBytes,
    int? sequence,
    int? chunkIndex,
    int? windowStart,
    int? windowSize,
    int? ackBase,
    List<int>? ackBitmapWords,
    Uint8List? payload,
    Uint8List? authTag,
  }) {
    return DataFrame(
      version: version ?? this.version,
      type: type ?? this.type,
      flags: flags ?? this.flags,
      sessionHash: sessionHash ?? this.sessionHash,
      transferIdBytes: transferIdBytes ?? this.transferIdBytes,
      sequence: sequence ?? this.sequence,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      windowStart: windowStart ?? this.windowStart,
      windowSize: windowSize ?? this.windowSize,
      ackBase: ackBase ?? this.ackBase,
      ackBitmapWords: ackBitmapWords ?? this.ackBitmapWords,
      payload: payload ?? this.payload,
      authTag: authTag ?? this.authTag,
    );
  }
}
