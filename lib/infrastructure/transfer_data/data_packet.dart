import 'dart:convert';

enum DataPacketType {
  dataStart('DATA_START'),
  dataChunk('DATA_CHUNK'),
  dataAck('DATA_ACK'),
  dataNack('DATA_NACK'),
  dataWindowUpdate('DATA_WINDOW_UPDATE'),
  dataFinish('DATA_FINISH'),
  dataAbort('DATA_ABORT');

  const DataPacketType(this.wireName);

  final String wireName;

  static DataPacketType fromWireName(String value) {
    return DataPacketType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw FormatException('Unsupported data packet $value'),
    );
  }
}

class DataPacket {
  const DataPacket({
    required this.type,
    required this.protocolVersion,
    required this.messageId,
    required this.correlationId,
    required this.sourcePeerId,
    required this.targetPeerId,
    required this.sessionId,
    required this.transferId,
    required this.sentAtEpochMs,
    this.fileId,
    this.chunkIndex,
    this.chunkIndexes = const [],
    this.windowStart,
    this.windowSize,
    this.payloadBase64,
    this.payloadChecksum,
    this.aeadNonce,
    this.aeadTag,
    this.reasonCode,
  });

  final DataPacketType type;
  final String protocolVersion;
  final String messageId;
  final String correlationId;
  final String sourcePeerId;
  final String targetPeerId;
  final String sessionId;
  final String transferId;
  final int sentAtEpochMs;
  final String? fileId;
  final int? chunkIndex;
  final List<int> chunkIndexes;
  final int? windowStart;
  final int? windowSize;
  final String? payloadBase64;
  final String? payloadChecksum;
  final String? aeadNonce;
  final String? aeadTag;
  final String? reasonCode;

  List<int> encode() {
    return utf8.encode(
      jsonEncode({
        'type': type.wireName,
        'protocolVersion': protocolVersion,
        'messageId': messageId,
        'correlationId': correlationId,
        'sourcePeerId': sourcePeerId,
        'targetPeerId': targetPeerId,
        'sessionId': sessionId,
        'transferId': transferId,
        'fileId': fileId,
        'chunkIndex': chunkIndex,
        'chunkIndexes': chunkIndexes,
        'windowStart': windowStart,
        'windowSize': windowSize,
        'payloadBase64': payloadBase64,
        'payloadChecksum': payloadChecksum,
        'aeadNonce': aeadNonce,
        'aeadTag': aeadTag,
        'reasonCode': reasonCode,
        'sentAtEpochMs': sentAtEpochMs,
      }),
    );
  }

  factory DataPacket.decode(List<int> bytes) {
    final payload = jsonDecode(utf8.decode(bytes));
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Data packet must be a JSON object.');
    }
    return DataPacket(
      type: DataPacketType.fromWireName(_readString(payload, 'type')),
      protocolVersion: _readString(payload, 'protocolVersion'),
      messageId: _readString(payload, 'messageId'),
      correlationId: _readString(payload, 'correlationId'),
      sourcePeerId: _readString(payload, 'sourcePeerId'),
      targetPeerId: _readString(payload, 'targetPeerId'),
      sessionId: _readString(payload, 'sessionId'),
      transferId: _readString(payload, 'transferId'),
      sentAtEpochMs: _readInt(payload, 'sentAtEpochMs'),
      fileId: _readOptionalString(payload, 'fileId'),
      chunkIndex: _readOptionalInt(payload, 'chunkIndex'),
      chunkIndexes: _readIntList(payload, 'chunkIndexes'),
      windowStart: _readOptionalInt(payload, 'windowStart'),
      windowSize: _readOptionalInt(payload, 'windowSize'),
      payloadBase64: _readOptionalString(payload, 'payloadBase64'),
      payloadChecksum: _readOptionalString(payload, 'payloadChecksum'),
      aeadNonce: _readOptionalString(payload, 'aeadNonce'),
      aeadTag: _readOptionalString(payload, 'aeadTag'),
      reasonCode: _readOptionalString(payload, 'reasonCode'),
    );
  }

  static String _readString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Data packet field $key is missing.');
    }
    return value;
  }

  static String? _readOptionalString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Data packet field $key is invalid.');
    }
    return value;
  }

  static int _readInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('Data packet field $key is missing.');
    }
    return value;
  }

  static int? _readOptionalInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw FormatException('Data packet field $key is invalid.');
    }
    return value;
  }

  static List<int> _readIntList(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw FormatException('Data packet field $key is invalid.');
    }
    return value
        .map((item) {
          if (item is! int) {
            throw FormatException('Data packet field $key is invalid.');
          }
          return item;
        })
        .toList(growable: false);
  }
}
