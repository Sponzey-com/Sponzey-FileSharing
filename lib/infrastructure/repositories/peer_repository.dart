import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';

class PeerRepository {
  const PeerRepository(this._database);

  final AppDatabase _database;

  Future<List<PeerNode>> loadCachedPeers() async {
    final rows = await _database.getCachedPeers();
    return rows.map(_map).toList();
  }

  Future<void> upsert(PeerNode peer) async {
    final now = DateTime.now();
    final existing =
        await (_database.select(_database.peers)
              ..where((tbl) => tbl.peerDeviceId.equals(peer.deviceId)))
            .getSingleOrNull();

    final companion = PeersCompanion(
      peerUserId: Value(peer.userId),
      peerDeviceId: Value(peer.deviceId),
      peerDisplayName: Value(peer.displayName),
      peerDeviceName: Value(peer.deviceName),
      osType: Value(peer.osType),
      lastIp: Value(peer.address),
      lastPort: Value(peer.port),
      protocolVersion: Value(peer.protocolVersion),
      receiveAvailable: Value(peer.receiveAvailable),
      lastSeenAt: Value(peer.lastSeenAt),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
    );

    if (existing == null) {
      await _database
          .into(_database.peers)
          .insert(
            PeersCompanion.insert(
              peerUserId: peer.userId,
              peerDeviceId: peer.deviceId,
              peerDisplayName: peer.displayName,
              peerDeviceName: peer.deviceName,
              osType: peer.osType,
              lastIp: peer.address,
              lastPort: peer.port,
              protocolVersion: peer.protocolVersion,
              receiveAvailable: Value(peer.receiveAvailable),
              lastSeenAt: peer.lastSeenAt,
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );
      return;
    }

    await (_database.update(
      _database.peers,
    )..where((tbl) => tbl.id.equals(existing.id))).write(companion);
  }

  PeerNode _map(Peer row) {
    return PeerNode(
      deviceId: row.peerDeviceId,
      userId: row.peerUserId,
      displayName: row.peerDisplayName,
      deviceName: row.peerDeviceName,
      osType: row.osType,
      protocolVersion: row.protocolVersion,
      lastSeenAt: row.lastSeenAt,
      address: row.lastIp,
      port: row.lastPort,
      receiveAvailable: row.receiveAvailable,
      presence: PeerPresence.offline,
    );
  }
}

final peerRepositoryProvider = Provider<PeerRepository>((ref) {
  return PeerRepository(ref.watch(appDatabaseProvider));
});
