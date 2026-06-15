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
      receivePolicyValue: ReceivePolicy.autoReceiveAll.name,
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
    final normalizedSettings = _normalizeReceivePolicy(settings);
    await _database.saveSettings(
      SettingsCompanion(
        id: const Value(1),
        defaultSavePath: Value(normalizedSettings.defaultSavePath),
        autoReceiveEnabled: Value(normalizedSettings.autoReceiveEnabled),
        receivePolicy: Value(normalizedSettings.receivePolicy.name),
        logLevel: Value(normalizedSettings.logLevel.name),
        createdAt: Value(current?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );

    final savedRow = await _database.getSettings();
    return savedRow != null ? _map(savedRow) : normalizedSettings;
  }

  AppSettings _map(Setting row) {
    return _normalizeReceivePolicy(
      AppSettings(
        defaultSavePath: row.defaultSavePath,
        autoReceiveEnabled: row.autoReceiveEnabled,
        receivePolicy: ReceivePolicy.values.firstWhere(
          (value) => value.name == row.receivePolicy,
          orElse: () => ReceivePolicy.autoReceiveAll,
        ),
        logLevel: AppLogLevel.values.firstWhere(
          (value) => value.name == row.logLevel,
          orElse: () => AppLogLevel.info,
        ),
      ),
    );
  }

  AppSettings _normalizeReceivePolicy(AppSettings settings) {
    return settings.copyWith(
      autoReceiveEnabled: true,
      receivePolicy: ReceivePolicy.autoReceiveAll,
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});
