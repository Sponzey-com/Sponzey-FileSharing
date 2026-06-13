import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';

void main() {
  test('uses runtime instance id as live peer identity when available', () {
    final peer = _peer(instanceId: 'instance-a', deviceId: 'device-a');

    expect(peer.id, 'admin@instance-a');
  });

  test('falls back to device id for legacy cached peers', () {
    final peer = _peer(deviceId: 'device-a');

    expect(peer.id, 'admin@device-a');
  });
}

PeerNode _peer({String? instanceId, required String deviceId}) {
  return PeerNode(
    deviceId: deviceId,
    instanceId: instanceId,
    userId: 'admin',
    displayName: 'Admin',
    deviceName: 'DONGWOOSHINC28B',
    osType: 'windows',
    protocolVersion: '1.0',
    lastSeenAt: DateTime.utc(2026),
    address: '10.211.55.3',
    port: 38401,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}
