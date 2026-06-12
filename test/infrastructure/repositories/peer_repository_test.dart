import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/peer_repository.dart';

void main() {
  late AppDatabase database;
  late PeerRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PeerRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('stores and restores peer cache entries', () async {
    final lastSeenAt = DateTime(2026, 4, 9, 12, 0, 0);
    await repository.upsert(
      PeerNode(
        deviceId: 'device-1',
        userId: 'admin',
        displayName: 'Alpha Lab',
        deviceName: 'Research Mac',
        osType: 'macos',
        protocolVersion: '1.0',
        lastSeenAt: lastSeenAt,
        address: '192.168.0.10',
        port: 38401,
        receiveAvailable: true,
        presence: PeerPresence.online,
      ),
    );

    final loaded = await repository.loadCachedPeers();

    expect(loaded, hasLength(1));
    expect(loaded.first.deviceId, 'device-1');
    expect(loaded.first.address, '192.168.0.10');
    expect(loaded.first.lastSeenAt, lastSeenAt);
    expect(loaded.first.presence, PeerPresence.offline);
  });

  test('updates existing peer rows instead of duplicating them', () async {
    await repository.upsert(
      PeerNode(
        deviceId: 'device-1',
        userId: 'admin',
        displayName: 'Alpha Lab',
        deviceName: 'Research Mac',
        osType: 'macos',
        protocolVersion: '1.0',
        lastSeenAt: DateTime(2026, 4, 9, 12, 0, 0),
        address: '192.168.0.10',
        port: 38401,
        receiveAvailable: true,
        presence: PeerPresence.online,
      ),
    );

    await repository.upsert(
      PeerNode(
        deviceId: 'device-1',
        userId: 'admin',
        displayName: 'Alpha Lab Updated',
        deviceName: 'Research Mac',
        osType: 'macos',
        protocolVersion: '1.0',
        lastSeenAt: DateTime(2026, 4, 9, 12, 1, 0),
        address: '192.168.0.20',
        port: 38402,
        receiveAvailable: false,
        presence: PeerPresence.online,
      ),
    );

    final loaded = await repository.loadCachedPeers();

    expect(loaded, hasLength(1));
    expect(loaded.first.displayName, 'Alpha Lab Updated');
    expect(loaded.first.address, '192.168.0.20');
    expect(loaded.first.port, 38402);
    expect(loaded.first.receiveAvailable, isFalse);
  });
}
