import 'dart:convert';

enum AuthPacketType {
  connectRequest('CONNECT_REQUEST'),
  authChallenge('AUTH_CHALLENGE'),
  authToken('AUTH_TOKEN'),
  authTokenAck('AUTH_TOKEN_ACK'),
  authAccept('AUTH_ACCEPT'),
  authReject('AUTH_REJECT'),
  transferInit('TRANSFER_INIT'),
  transferInitAck('TRANSFER_INIT_ACK'),
  transferChunk('TRANSFER_CHUNK'),
  transferChunkAck('TRANSFER_CHUNK_ACK'),
  transferChunkNack('TRANSFER_CHUNK_NACK'),
  transferWindowUpdate('TRANSFER_WINDOW_UPDATE'),
  transferComplete('TRANSFER_COMPLETE'),
  transferCompleteAck('TRANSFER_COMPLETE_ACK');

  const AuthPacketType(this.wireName);

  final String wireName;

  static AuthPacketType fromWireName(String value) {
    return AuthPacketType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw FormatException('Unsupported auth packet $value'),
    );
  }
}

class AuthPacket {
  const AuthPacket({
    required this.type,
    required this.protocolVersion,
    required this.sessionId,
    required this.fromUserId,
    required this.fromDeviceId,
    required this.sentAtEpochMs,
    this.fromDisplayName,
    this.nonce,
    this.token,
    this.rejectCode,
    this.rejectMessage,
    this.transferId,
    this.transferFileName,
    this.transferFileSize,
    this.transferSha256,
    this.transferChunkCount,
    this.transferChunkIndex,
    this.transferChunkIndexes,
    this.transferChunkDataBase64,
    this.transferAccepted,
    this.transferSavePath,
    this.transferWindowStart,
    this.transferWindowSize,
  });

  final AuthPacketType type;
  final String protocolVersion;
  final String sessionId;
  final String fromUserId;
  final String fromDeviceId;
  final int sentAtEpochMs;
  final String? fromDisplayName;
  final String? nonce;
  final String? token;
  final String? rejectCode;
  final String? rejectMessage;
  final String? transferId;
  final String? transferFileName;
  final int? transferFileSize;
  final String? transferSha256;
  final int? transferChunkCount;
  final int? transferChunkIndex;
  final List<int>? transferChunkIndexes;
  final String? transferChunkDataBase64;
  final bool? transferAccepted;
  final String? transferSavePath;
  final int? transferWindowStart;
  final int? transferWindowSize;

  List<int> encode() {
    return utf8.encode(
      jsonEncode({
        'type': type.wireName,
        'protocolVersion': protocolVersion,
        'sessionId': sessionId,
        'fromUserId': fromUserId,
        'fromDeviceId': fromDeviceId,
        'fromDisplayName': fromDisplayName,
        'nonce': nonce,
        'token': token,
        'rejectCode': rejectCode,
        'rejectMessage': rejectMessage,
        'transferId': transferId,
        'transferFileName': transferFileName,
        'transferFileSize': transferFileSize,
        'transferSha256': transferSha256,
        'transferChunkCount': transferChunkCount,
        'transferChunkIndex': transferChunkIndex,
        'transferChunkIndexes': transferChunkIndexes,
        'transferChunkDataBase64': transferChunkDataBase64,
        'transferAccepted': transferAccepted,
        'transferSavePath': transferSavePath,
        'transferWindowStart': transferWindowStart,
        'transferWindowSize': transferWindowSize,
        'sentAtEpochMs': sentAtEpochMs,
      }),
    );
  }

  factory AuthPacket.decode(List<int> bytes) {
    final payload = jsonDecode(utf8.decode(bytes));
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Auth packet must be a JSON object.');
    }

    return AuthPacket(
      type: AuthPacketType.fromWireName(_readString(payload, 'type')),
      protocolVersion: _readString(payload, 'protocolVersion'),
      sessionId: _readString(payload, 'sessionId'),
      fromUserId: _readString(payload, 'fromUserId'),
      fromDeviceId: _readString(payload, 'fromDeviceId'),
      sentAtEpochMs: _readInt(payload, 'sentAtEpochMs'),
      fromDisplayName: _readOptionalString(payload, 'fromDisplayName'),
      nonce: _readOptionalString(payload, 'nonce'),
      token: _readOptionalString(payload, 'token'),
      rejectCode: _readOptionalString(payload, 'rejectCode'),
      rejectMessage: _readOptionalString(payload, 'rejectMessage'),
      transferId: _readOptionalString(payload, 'transferId'),
      transferFileName: _readOptionalString(payload, 'transferFileName'),
      transferFileSize: _readOptionalInt(payload, 'transferFileSize'),
      transferSha256: _readOptionalString(payload, 'transferSha256'),
      transferChunkCount: _readOptionalInt(payload, 'transferChunkCount'),
      transferChunkIndex: _readOptionalInt(payload, 'transferChunkIndex'),
      transferChunkIndexes: _readOptionalIntList(
        payload,
        'transferChunkIndexes',
      ),
      transferChunkDataBase64: _readOptionalString(
        payload,
        'transferChunkDataBase64',
      ),
      transferAccepted: _readOptionalBool(payload, 'transferAccepted'),
      transferSavePath: _readOptionalString(payload, 'transferSavePath'),
      transferWindowStart: _readOptionalInt(payload, 'transferWindowStart'),
      transferWindowSize: _readOptionalInt(payload, 'transferWindowSize'),
    );
  }

  static String _readString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Auth packet field $key is missing.');
    }
    return value;
  }

  static String? _readOptionalString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Auth packet field $key is invalid.');
    }
    return value;
  }

  static int _readInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('Auth packet field $key is missing.');
    }
    return value;
  }

  static int? _readOptionalInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw FormatException('Auth packet field $key is invalid.');
    }
    return value;
  }

  static bool? _readOptionalBool(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! bool) {
      throw FormatException('Auth packet field $key is invalid.');
    }
    return value;
  }

  static List<int>? _readOptionalIntList(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! List) {
      throw FormatException('Auth packet field $key is invalid.');
    }
    return value
        .map((item) {
          if (item is! int) {
            throw FormatException('Auth packet field $key is invalid.');
          }
          return item;
        })
        .toList(growable: false);
  }
}
