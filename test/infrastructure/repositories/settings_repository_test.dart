import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;
  late SettingsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates default settings and restores them', () async {
    final defaults = await repository.ensureDefaults(
      defaultSavePath: '/tmp/sponzey-downloads',
    );

    expect(defaults.defaultSavePath, '/tmp/sponzey-downloads');
    expect(defaults.autoReceiveEnabled, isTrue);
    expect(defaults.receivePolicy, ReceivePolicy.autoReceiveAll);
    expect(defaults.logLevel, AppLogLevel.info);

    final loaded = await repository.loadOrCreate(
      defaultSavePath: '/another-path',
    );

    expect(loaded.defaultSavePath, '/tmp/sponzey-downloads');
  });

  test(
    'normalizes legacy manual approval settings to automatic receive',
    () async {
      final now = DateTime(2026);
      await database.saveSettings(
        SettingsCompanion(
          id: const Value(1),
          defaultSavePath: const Value('/tmp/legacy-downloads'),
          autoReceiveEnabled: const Value(false),
          receivePolicy: Value(ReceivePolicy.manualApproval.name),
          logLevel: Value(AppLogLevel.info.name),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final loaded = await repository.loadOrCreate(
        defaultSavePath: '/tmp/sponzey-downloads',
      );

      expect(loaded.defaultSavePath, '/tmp/legacy-downloads');
      expect(loaded.autoReceiveEnabled, isTrue);
      expect(loaded.receivePolicy, ReceivePolicy.autoReceiveAll);
    },
  );

  test('saves updated settings', () async {
    await repository.ensureDefaults(defaultSavePath: '/tmp/sponzey-downloads');

    final saved = await repository.save(
      const AppSettings(
        defaultSavePath: '/tmp/custom-path',
        autoReceiveEnabled: true,
        receivePolicy: ReceivePolicy.autoReceiveAllowedUsers,
        logLevel: AppLogLevel.warning,
      ),
    );

    expect(saved.defaultSavePath, '/tmp/custom-path');
    expect(saved.autoReceiveEnabled, isTrue);
    expect(saved.receivePolicy, ReceivePolicy.autoReceiveAll);
  });
}
