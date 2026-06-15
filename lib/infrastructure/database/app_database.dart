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

class TransferHistoryJobs extends Table {
  @override
  String get tableName => 'transfer_jobs';

  TextColumn get id => text()();

  TextColumn get transferId => text().named('transfer_id')();

  TextColumn get direction => text()();

  TextColumn get peerId => text().named('peer_id')();

  TextColumn get peerDisplayName => text().named('peer_display_name')();

  TextColumn get status => text()();

  TextColumn get failureCategory =>
      text().named('failure_category').nullable()();

  TextColumn get failureCode => text().named('failure_code').nullable()();

  TextColumn get message => text().nullable()();

  IntColumn get fileCount =>
      integer().named('file_count').withDefault(const Constant(1))();

  IntColumn get totalBytes => integer().named('total_bytes')();

  IntColumn get bytesTransferred => integer().named('bytes_transferred')();

  IntColumn get totalChunks => integer().named('total_chunks')();

  IntColumn get completedChunks => integer().named('completed_chunks')();

  IntColumn get retryCount =>
      integer().named('retry_count').withDefault(const Constant(0))();

  RealColumn get lossRate =>
      real().named('loss_rate').withDefault(const Constant(0))();

  RealColumn get throughputBytesPerSec =>
      real().named('throughput_bytes_per_sec').withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class TransferHistoryFiles extends Table {
  @override
  String get tableName => 'transfer_files';

  TextColumn get id => text()();

  TextColumn get jobId => text().named('job_id')();

  TextColumn get transferId => text().named('transfer_id')();

  TextColumn get fileName => text().named('file_name')();

  IntColumn get fileSize => integer().named('file_size')();

  TextColumn get localPath => text().named('local_path').nullable()();

  TextColumn get destinationPath =>
      text().named('destination_path').nullable()();

  TextColumn get sha256 => text().nullable()();

  TextColumn get status => text()();

  TextColumn get message => text().nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Users,
    Settings,
    Peers,
    AllowedPeers,
    TransferHistoryJobs,
    TransferHistoryFiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

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
      if (from < 4) {
        await m.createTable(transferHistoryJobs);
        await m.createTable(transferHistoryFiles);
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

  Future<List<TransferHistoryJob>> getTransferHistoryJobs({int limit = 100}) {
    return (select(transferHistoryJobs)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<TransferHistoryFile>> getTransferHistoryFilesForJob(
    String jobId,
  ) {
    return (select(transferHistoryFiles)
          ..where((tbl) => tbl.jobId.equals(jobId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
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
