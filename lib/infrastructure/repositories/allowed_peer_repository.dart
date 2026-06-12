import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/domain/entities/allowed_peer.dart'
    as domain;
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';

class AllowedPeerRepository {
  const AllowedPeerRepository(this._database);

  final AppDatabase _database;

  Future<List<domain.AllowedPeer>> listAll() async {
    final rows = await _database.getAllowedPeers();
    return rows.map(_map).toList();
  }

  Future<domain.AllowedPeer?> findByUserId(String userId) async {
    final row = await (_database.select(
      _database.allowedPeers,
    )..where((tbl) => tbl.peerUserId.equals(userId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _map(row);
  }

  Future<domain.AllowedPeer> save({
    required String userId,
    required String label,
    required String verifierBase64,
  }) async {
    final existing = await (_database.select(
      _database.allowedPeers,
    )..where((tbl) => tbl.peerUserId.equals(userId))).getSingleOrNull();
    final now = DateTime.now();

    if (existing == null) {
      await _database
          .into(_database.allowedPeers)
          .insert(
            AllowedPeersCompanion.insert(
              peerUserId: userId,
              label: label,
              verifierBase64: verifierBase64,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_database.update(
        _database.allowedPeers,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
        AllowedPeersCompanion(
          label: Value(label),
          verifierBase64: Value(verifierBase64),
          updatedAt: Value(now),
        ),
      );
    }

    return (await findByUserId(userId))!;
  }

  Future<void> deleteByUserId(String userId) async {
    await (_database.delete(
      _database.allowedPeers,
    )..where((tbl) => tbl.peerUserId.equals(userId))).go();
  }

  domain.AllowedPeer _map(AllowedPeer row) {
    return domain.AllowedPeer(
      userId: row.peerUserId,
      label: row.label,
      verifierBase64: row.verifierBase64,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

final allowedPeerRepositoryProvider = Provider<AllowedPeerRepository>((ref) {
  return AllowedPeerRepository(ref.watch(appDatabaseProvider));
});
