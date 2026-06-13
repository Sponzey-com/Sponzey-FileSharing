enum PeerPresence { online, stale, offline, incompatible }

class PeerNode {
  const PeerNode({
    required this.deviceId,
    this.instanceId,
    required this.userId,
    required this.displayName,
    required this.deviceName,
    required this.osType,
    required this.protocolVersion,
    required this.lastSeenAt,
    required this.address,
    required this.port,
    required this.receiveAvailable,
    required this.presence,
  });

  final String deviceId;
  final String? instanceId;
  final String userId;
  final String displayName;
  final String deviceName;
  final String osType;
  final String protocolVersion;
  final DateTime lastSeenAt;
  final String address;
  final int port;
  final bool receiveAvailable;
  final PeerPresence presence;

  String get id => '$userId@${instanceId ?? deviceId}';

  String get statusLabel {
    switch (presence) {
      case PeerPresence.online:
        return '온라인';
      case PeerPresence.stale:
        return '비활성';
      case PeerPresence.offline:
        return '오프라인';
      case PeerPresence.incompatible:
        return '버전 다름';
    }
  }

  bool get isCompatible => presence != PeerPresence.incompatible;

  PeerNode copyWith({
    String? deviceId,
    String? instanceId,
    String? userId,
    String? displayName,
    String? deviceName,
    String? osType,
    String? protocolVersion,
    DateTime? lastSeenAt,
    String? address,
    int? port,
    bool? receiveAvailable,
    PeerPresence? presence,
  }) {
    return PeerNode(
      deviceId: deviceId ?? this.deviceId,
      instanceId: instanceId ?? this.instanceId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      deviceName: deviceName ?? this.deviceName,
      osType: osType ?? this.osType,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      address: address ?? this.address,
      port: port ?? this.port,
      receiveAvailable: receiveAvailable ?? this.receiveAvailable,
      presence: presence ?? this.presence,
    );
  }
}
