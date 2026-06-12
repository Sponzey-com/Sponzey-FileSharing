import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';

class SettingsRepository {
  const SettingsRepository(this._database);

  final AppDatabase _database;

  Future<AppSettings> ensureDefaults({required String defaultSavePath}) async {
    final row = await _database.ensureSettings(
      defaultSavePathValue: defaultSavePath,
      receivePolicyValue: ReceivePolicy.manualApproval.name,
      logLevelValue: AppLogLevel.info.name,
    );
    return _map(row);
  }

  Future<AppSettings> loadOrCreate({required String defaultSavePath}) async {
    final row = await _database.getSettings();
    if (row != null) {
      return _map(row);
    }

    return ensureDefaults(defaultSavePath: defaultSavePath);
  }

  Future<AppSettings> save(AppSettings settings) async {
    final now = DateTime.now();
    final current = await _database.getSettings();
    await _database.saveSettings(
      SettingsCompanion(
        id: const Value(1),
        defaultSavePath: Value(settings.defaultSavePath),
        autoReceiveEnabled: Value(settings.autoReceiveEnabled),
        receivePolicy: Value(settings.receivePolicy.name),
        logLevel: Value(settings.logLevel.name),
        createdAt: Value(current?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );

    final savedRow = await _database.getSettings();
    return savedRow != null ? _map(savedRow) : settings;
  }

  AppSettings _map(Setting row) {
    return AppSettings(
      defaultSavePath: row.defaultSavePath,
      autoReceiveEnabled: row.autoReceiveEnabled,
      receivePolicy: ReceivePolicy.values.firstWhere(
        (value) => value.name == row.receivePolicy,
        orElse: () => ReceivePolicy.manualApproval,
      ),
      logLevel: AppLogLevel.values.firstWhere(
        (value) => value.name == row.logLevel,
        orElse: () => AppLogLevel.info,
      ),
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});
