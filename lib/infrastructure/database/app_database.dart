import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userId => text().named('user_id').unique()();

  TextColumn get displayName => text().named('display_name')();

  TextColumn get deviceName => text().named('device_name')();

  TextColumn get passwordHash => text().named('password_hash')();

  TextColumn get passwordSalt => text().named('password_salt')();

  TextColumn get hashAlgorithm => text().named('hash_algorithm')();

  TextColumn get hashParams => text().named('hash_params')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get defaultSavePath => text().named('default_save_path')();

  BoolColumn get autoReceiveEnabled => boolean()
      .named('auto_receive_enabled')
      .withDefault(const Constant(false))();

  TextColumn get receivePolicy => text().named('receive_policy')();

  TextColumn get logLevel => text().named('log_level')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Peers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get peerUserId => text().named('peer_user_id')();

  TextColumn get peerDeviceId => text().named('peer_device_id').unique()();

  TextColumn get peerDisplayName => text().named('peer_display_name')();

  TextColumn get peerDeviceName => text().named('peer_device_name')();

  TextColumn get osType => text().named('os_type')();

  TextColumn get lastIp => text().named('last_ip')();

  IntColumn get lastPort => integer().named('last_port')();

  TextColumn get protocolVersion => text().named('protocol_version')();

  BoolColumn get receiveAvailable =>
      boolean().named('receive_available').withDefault(const Constant(true))();

  DateTimeColumn get lastSeenAt => dateTime().named('last_seen_at')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

class AllowedPeers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get peerUserId => text().named('peer_user_id').unique()();

  TextColumn get label => text()();

  TextColumn get verifierBase64 => text().named('verifier_base64')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}

@DriftDatabase(tables: [Users, Settings, Peers, AllowedPeers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(peers);
      }
      if (from < 3) {
        await m.createTable(allowedPeers);
      }
    },
  );

  Future<User?> getUserByUserId(String userIdValue) {
    return (select(
      users,
    )..where((tbl) => tbl.userId.equals(userIdValue))).getSingleOrNull();
  }

  Future<int> createUser(UsersCompanion companion) {
    return into(users).insert(companion);
  }

  Future<Setting?> getSettings() {
    return select(settings).getSingleOrNull();
  }

  Future<Setting> ensureSettings({
    required String defaultSavePathValue,
    required String receivePolicyValue,
    required String logLevelValue,
  }) async {
    final current = await getSettings();
    if (current != null) {
      return current;
    }

    final now = DateTime.now();
    await into(settings).insert(
      SettingsCompanion.insert(
        defaultSavePath: defaultSavePathValue,
        receivePolicy: receivePolicyValue,
        logLevel: logLevelValue,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return (await getSettings())!;
  }

  Future<void> saveSettings(SettingsCompanion companion) async {
    await into(settings).insertOnConflictUpdate(companion);
  }

  Future<List<Peer>> getCachedPeers() {
    return (select(
      peers,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])).get();
  }

  Future<List<AllowedPeer>> getAllowedPeers() {
    return (select(
      allowedPeers,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.peerUserId)])).get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final supportDirectory =
        await AppPlatformDirectories.getApplicationSupportDirectory();
    await supportDirectory.create(recursive: true);
    final file = File(
      p.join(supportDirectory.path, 'sponzey_file_sharing.sqlite'),
    );
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
