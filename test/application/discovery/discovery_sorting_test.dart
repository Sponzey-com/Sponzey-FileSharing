import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_sorting.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';

void main() {
  test('filters peers by multiple searchable fields', () {
    final peers = [
      _peer(
        deviceId: 'alpha-device',
        userId: 'alpha',
        displayName: 'Alpha Lab',
        deviceName: 'Research Mac',
        osType: 'macos',
        presence: PeerPresence.online,
      ),
      _peer(
        deviceId: 'beta-device',
        userId: 'ops',
        displayName: 'Ops Room',
        deviceName: 'Windows Tower',
        osType: 'windows',
        presence: PeerPresence.offline,
      ),
    ];

    expect(filterPeers(peers, query: 'tower').map((peer) => peer.deviceId), [
      'beta-device',
    ]);
    expect(filterPeers(peers, query: 'alpha').map((peer) => peer.deviceId), [
      'alpha-device',
    ]);
  });

  test('sorts peers by status and recency', () {
    final peers = [
      _peer(
        deviceId: 'offline',
        userId: 'offline',
        displayName: 'Offline Peer',
        deviceName: 'Linux Desktop',
        osType: 'linux',
        presence: PeerPresence.offline,
        lastSeenAt: DateTime(2026, 4, 9, 10, 0, 0),
      ),
      _peer(
        deviceId: 'stale',
        userId: 'stale',
        displayName: 'Stale Peer',
        deviceName: 'Windows Desktop',
        osType: 'windows',
        presence: PeerPresence.stale,
        lastSeenAt: DateTime(2026, 4, 9, 10, 5, 0),
      ),
      _peer(
        deviceId: 'online-old',
        userId: 'online',
        displayName: 'Online Old',
        deviceName: 'Mac Mini',
        osType: 'macos',
        presence: PeerPresence.online,
        lastSeenAt: DateTime(2026, 4, 9, 10, 1, 0),
      ),
      _peer(
        deviceId: 'online-new',
        userId: 'online2',
        displayName: 'Online New',
        deviceName: 'Mac Studio',
        osType: 'macos',
        presence: PeerPresence.online,
        lastSeenAt: DateTime(2026, 4, 9, 10, 7, 0),
      ),
      _peer(
        deviceId: 'mismatch',
        userId: 'legacy',
        displayName: 'Legacy Peer',
        deviceName: 'Legacy Linux',
        osType: 'linux',
        presence: PeerPresence.incompatible,
        lastSeenAt: DateTime(2026, 4, 9, 10, 9, 0),
      ),
    ];

    final sorted = sortPeers(peers, sortMode: PeerSortMode.recent);

    expect(sorted.map((peer) => peer.deviceId), [
      'online-new',
      'online-old',
      'stale',
      'offline',
      'mismatch',
    ]);
  });
}

PeerNode _peer({
  required String deviceId,
  required String userId,
  required String displayName,
  required String deviceName,
  required String osType,
  required PeerPresence presence,
  DateTime? lastSeenAt,
}) {
  return PeerNode(
    deviceId: deviceId,
    userId: userId,
    displayName: displayName,
    deviceName: deviceName,
    osType: osType,
    protocolVersion: '1.0',
    lastSeenAt: lastSeenAt ?? DateTime(2026, 4, 9, 10, 0, 0),
    address: '192.168.0.2',
    port: 38401,
    receiveAvailable: true,
    presence: presence,
  );
}
