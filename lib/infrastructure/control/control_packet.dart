import 'dart:convert';

enum ControlPacketType {
  linkRequest('LINK_REQUEST'),
  linkChallenge('LINK_CHALLENGE'),
  linkResponse('LINK_RESPONSE'),
  linkAccepted('LINK_ACCEPTED'),
  linkRejected('LINK_REJECTED'),
  sessionRefresh('SESSION_REFRESH'),
  transferOffer('TRANSFER_OFFER'),
  transferAccept('TRANSFER_ACCEPT'),
  transferReject('TRANSFER_REJECT'),
  transferCancel('TRANSFER_CANCEL'),
  transferComplete('TRANSFER_COMPLETE'),
  transferFailed('TRANSFER_FAILED');

  const ControlPacketType(this.wireName);

  final String wireName;

  static ControlPacketType fromWireName(String value) {
    return ControlPacketType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw FormatException('Unsupported control packet $value'),
    );
  }
}

class ControlPacket {
  const ControlPacket({
    required this.type,
    required this.protocolVersion,
    required this.messageId,
    required this.correlationId,
    required this.sourcePeerId,
    required this.targetPeerId,
    required this.sentAtEpochMs,
    this.sessionId,
    this.nonce,
    this.token,
    this.transferId,
    this.fileName,
    this.fileSize,
    this.fileSha256,
    this.fileCount,
    this.dataPort,
    this.dataPortLeaseId,
    this.rejectCode,
    this.rejectMessage,
  });

  final ControlPacketType type;
  final String protocolVersion;
  final String messageId;
  final String correlationId;
  final String sourcePeerId;
  final String targetPeerId;
  final int sentAtEpochMs;
  final String? sessionId;
  final String? nonce;
  final String? token;
  final String? transferId;
  final String? fileName;
  final int? fileSize;
  final String? fileSha256;
  final int? fileCount;
  final int? dataPort;
  final String? dataPortLeaseId;
  final String? rejectCode;
  final String? rejectMessage;

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
        'nonce': nonce,
        'token': token,
        'transferId': transferId,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileSha256': fileSha256,
        'fileCount': fileCount,
        'dataPort': dataPort,
        'dataPortLeaseId': dataPortLeaseId,
        'rejectCode': rejectCode,
        'rejectMessage': rejectMessage,
        'sentAtEpochMs': sentAtEpochMs,
      }),
    );
  }

  factory ControlPacket.decode(List<int> bytes) {
    final payload = jsonDecode(utf8.decode(bytes));
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Control packet must be a JSON object.');
    }
    return ControlPacket(
      type: ControlPacketType.fromWireName(_readString(payload, 'type')),
      protocolVersion: _readString(payload, 'protocolVersion'),
      messageId: _readString(payload, 'messageId'),
      correlationId: _readString(payload, 'correlationId'),
      sourcePeerId: _readString(payload, 'sourcePeerId'),
      targetPeerId: _readString(payload, 'targetPeerId'),
      sentAtEpochMs: _readInt(payload, 'sentAtEpochMs'),
      sessionId: _readOptionalString(payload, 'sessionId'),
      nonce: _readOptionalString(payload, 'nonce'),
      token: _readOptionalString(payload, 'token'),
      transferId: _readOptionalString(payload, 'transferId'),
      fileName: _readOptionalString(payload, 'fileName'),
      fileSize: _readOptionalInt(payload, 'fileSize'),
      fileSha256: _readOptionalString(payload, 'fileSha256'),
      fileCount: _readOptionalInt(payload, 'fileCount'),
      dataPort: _readOptionalInt(payload, 'dataPort'),
      dataPortLeaseId: _readOptionalString(payload, 'dataPortLeaseId'),
      rejectCode: _readOptionalString(payload, 'rejectCode'),
      rejectMessage: _readOptionalString(payload, 'rejectMessage'),
    );
  }

  static String _readString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Control packet field $key is missing.');
    }
    return value;
  }

  static String? _readOptionalString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Control packet field $key is invalid.');
    }
    return value;
  }

  static int _readInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('Control packet field $key is missing.');
    }
    return value;
  }

  static int? _readOptionalInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw FormatException('Control packet field $key is invalid.');
    }
    return value;
  }
}
