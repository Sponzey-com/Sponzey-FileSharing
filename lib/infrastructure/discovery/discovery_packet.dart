import 'dart:convert';

enum DiscoveryPacketType {
  discover('DISCOVER'),
  discoverAck('DISCOVER_ACK');

  const DiscoveryPacketType(this.wireName);

  final String wireName;

  static DiscoveryPacketType fromWireName(String value) {
    return DiscoveryPacketType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () =>
          throw FormatException('Unsupported discovery packet $value'),
    );
  }
}

class DiscoveryPacket {
  const DiscoveryPacket({
    required this.type,
    required this.protocolVersion,
    this.messageId = '',
    required this.userId,
    String? discoveryGroupTag,
    @Deprecated('Use discoveryGroupTag. This is kept for legacy decode tests.')
    String? pairingProof,
    required this.instanceId,
    required this.displayName,
    required this.deviceId,
    required this.deviceName,
    required this.osType,
    required this.port,
    this.controlPort,
    this.dataPort,
    this.dataPortRange = const [],
    this.capabilities = const [],
    this.sourceInterfaceId,
    this.sourceInterfaceHint,
    this.sourceAddress,
    required this.receiveAvailable,
    required this.sentAtEpochMs,
  }) : assert(
         (discoveryGroupTag != null && discoveryGroupTag != '') ||
             (pairingProof != null && pairingProof != ''),
         'Discovery packet requires a discovery group tag.',
       ),
       discoveryGroupTag = discoveryGroupTag ?? pairingProof ?? '';

  final DiscoveryPacketType type;
  final String protocolVersion;
  final String messageId;
  final String userId;
  final String discoveryGroupTag;

  @Deprecated('Use discoveryGroupTag. This is a legacy migration alias.')
  String get pairingProof => discoveryGroupTag;

  final String instanceId;
  final String displayName;
  final String deviceId;
  final String deviceName;
  final String osType;
  final int port;
  final int? controlPort;
  final int? dataPort;
  final List<int> dataPortRange;
  final List<String> capabilities;
  final String? sourceInterfaceId;
  final String? sourceInterfaceHint;
  final String? sourceAddress;
  final bool receiveAvailable;
  final int sentAtEpochMs;

  List<int> encode() {
    return utf8.encode(
      jsonEncode({
        'type': type.wireName,
        'protocolVersion': protocolVersion,
        'messageId': messageId,
        'userId': userId,
        'discoveryGroupTag': discoveryGroupTag,
        'instanceId': instanceId,
        'displayName': displayName,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'osType': osType,
        'port': port,
        'controlPort': controlPort ?? port,
        'dataPort': dataPort,
        'dataPortRange': dataPortRange,
        'capabilities': capabilities,
        'sourceInterfaceId': sourceInterfaceId,
        'sourceInterfaceHint': sourceInterfaceHint,
        'sourceAddress': sourceAddress,
        'receiveAvailable': receiveAvailable,
        'sentAtEpochMs': sentAtEpochMs,
      }),
    );
  }

  factory DiscoveryPacket.decode(List<int> bytes) {
    final payload = jsonDecode(utf8.decode(bytes));
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Discovery packet must be a JSON object.');
    }

    return DiscoveryPacket(
      type: DiscoveryPacketType.fromWireName(_readString(payload, 'type')),
      protocolVersion: _readString(payload, 'protocolVersion'),
      messageId: _readOptionalString(payload, 'messageId') ?? '',
      userId: _readString(payload, 'userId'),
      discoveryGroupTag:
          _readOptionalString(payload, 'discoveryGroupTag') ??
          _readString(payload, 'pairingProof'),
      instanceId: _readString(payload, 'instanceId'),
      displayName: _readString(payload, 'displayName'),
      deviceId: _readString(payload, 'deviceId'),
      deviceName: _readString(payload, 'deviceName'),
      osType: _readString(payload, 'osType'),
      port: _readInt(payload, 'port'),
      controlPort: _readOptionalInt(payload, 'controlPort'),
      dataPort: _readOptionalInt(payload, 'dataPort'),
      dataPortRange: _readIntList(payload, 'dataPortRange'),
      capabilities: _readStringList(payload, 'capabilities'),
      sourceInterfaceId: _readOptionalString(payload, 'sourceInterfaceId'),
      sourceInterfaceHint: _readOptionalString(payload, 'sourceInterfaceHint'),
      sourceAddress: _readOptionalString(payload, 'sourceAddress'),
      receiveAvailable: _readBool(payload, 'receiveAvailable'),
      sentAtEpochMs: _readInt(payload, 'sentAtEpochMs'),
    );
  }

  static String _readString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Discovery packet field $key is missing.');
    }
    return value;
  }

  static String? _readOptionalString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('Discovery packet field $key is invalid.');
    }
    if (value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  static int _readInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! int) {
      throw FormatException('Discovery packet field $key is missing.');
    }
    return value;
  }

  static int? _readOptionalInt(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw FormatException('Discovery packet field $key is invalid.');
    }
    return value;
  }

  static List<int> _readIntList(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw FormatException('Discovery packet field $key is invalid.');
    }
    return value
        .map((entry) {
          if (entry is! int) {
            throw FormatException('Discovery packet field $key is invalid.');
          }
          return entry;
        })
        .toList(growable: false);
  }

  static List<String> _readStringList(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw FormatException('Discovery packet field $key is invalid.');
    }
    return value
        .map((entry) {
          if (entry is! String || entry.trim().isEmpty) {
            throw FormatException('Discovery packet field $key is invalid.');
          }
          return entry;
        })
        .toList(growable: false);
  }

  static bool _readBool(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! bool) {
      throw FormatException('Discovery packet field $key is missing.');
    }
    return value;
  }
}
