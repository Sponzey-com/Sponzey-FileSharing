import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/presentation/transfers/drop_transfer_intent.dart';

void main() {
  test(
    'creates immediate transfer intent for selected peer and dropped files',
    () {
      final peer = _peer('peer-a');
      final resolution = resolveDroppedTransfer(
        droppedPaths: const ['/tmp/a.txt', '/tmp/b.txt'],
        peers: [peer, _peer('peer-b')],
        selectedPeerId: peer.id,
        isFile: (_) => true,
      );

      expect(resolution.message, isNull);
      expect(resolution.intent?.peerId, peer.id);
      expect(resolution.intent?.filePaths, ['/tmp/a.txt', '/tmp/b.txt']);
    },
  );

  test(
    'falls back to first connected peer when selected peer is unavailable',
    () {
      final peer = _peer('peer-a');
      final resolution = resolveDroppedTransfer(
        droppedPaths: const ['/tmp/a.txt'],
        peers: [peer],
        selectedPeerId: 'admin@missing-peer',
        isFile: (_) => true,
      );

      expect(resolution.intent?.peerId, peer.id);
    },
  );

  test('rejects drop when no peer is connected', () {
    final resolution = resolveDroppedTransfer(
      droppedPaths: const ['/tmp/a.txt'],
      peers: const [],
      selectedPeerId: null,
      isFile: (_) => true,
    );

    expect(resolution.intent, isNull);
    expect(resolution.message, '연결된 피어가 없어 전송할 수 없습니다.');
  });

  test('rejects dropped directories before transfer starts', () {
    final resolution = resolveDroppedTransfer(
      droppedPaths: const ['/tmp/folder'],
      peers: [_peer('peer-a')],
      selectedPeerId: null,
      isFile: (_) => false,
    );

    expect(resolution.intent, isNull);
    expect(resolution.message, '디렉터리가 아니라 파일만 드롭해 주세요.');
  });
}

PeerNode _peer(String instanceId) {
  return PeerNode(
    deviceId: 'device-$instanceId',
    instanceId: instanceId,
    userId: 'admin',
    displayName: 'admin',
    deviceName: 'Node $instanceId',
    osType: 'windows',
    protocolVersion: '1.0',
    lastSeenAt: DateTime.utc(2026, 1, 1, 12),
    address: '10.211.55.3',
    port: 38401,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}
