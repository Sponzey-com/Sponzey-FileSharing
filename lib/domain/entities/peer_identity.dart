class PeerIdentity {
  const PeerIdentity._({
    required this.userId,
    required this.nodeId,
    required this.usesLegacyDeviceFallback,
  });

  final String userId;
  final String nodeId;
  final bool usesLegacyDeviceFallback;

  String get id => '$userId@$nodeId';

  static PeerIdentity resolve({
    required String userId,
    required String? instanceId,
    required String deviceId,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
    }

    final normalizedInstanceId = instanceId?.trim();
    if (normalizedInstanceId != null && normalizedInstanceId.isNotEmpty) {
      return PeerIdentity._(
        userId: normalizedUserId,
        nodeId: normalizedInstanceId,
        usesLegacyDeviceFallback: false,
      );
    }

    final normalizedDeviceId = deviceId.trim();
    if (normalizedDeviceId.isEmpty) {
      throw ArgumentError.value(
        deviceId,
        'deviceId',
        'Legacy device id must not be empty when instance id is unavailable.',
      );
    }

    return PeerIdentity._(
      userId: normalizedUserId,
      nodeId: normalizedDeviceId,
      usesLegacyDeviceFallback: true,
    );
  }
}
