import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'save falls back to the default receive path when path is blank',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'settings-controller-save-blank',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final fallbackPath = '${tempDirectory.path}/downloads';
      final container = _createContainer(
        database: database,
        defaultReceivePath: fallbackPath,
      );
      addTearDown(container.dispose);

      container.read(settingsControllerProvider);
      await _flush();

      await container
          .read(settingsControllerProvider.notifier)
          .save(
            const AppSettings(
              defaultSavePath: '   ',
              autoReceiveEnabled: true,
              receivePolicy: ReceivePolicy.autoReceiveAll,
              logLevel: AppLogLevel.debug,
            ),
          );

      final state = container.read(settingsControllerProvider);
      expect(state.errorMessage, isNull);
      expect(state.settings.defaultSavePath, fallbackPath);
      expect(Directory(fallbackPath).existsSync(), isTrue);
    },
  );

  test(
    'load uses saved path when default receive path cannot be prepared',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'settings-controller-load-saved',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final savedPath = '${tempDirectory.path}/saved-downloads';
      await SettingsRepository(
        database,
      ).save(AppSettings.initial().copyWith(defaultSavePath: savedPath));

      final container = _createContainer(
        database: database,
        storagePathProvider: const _ThrowingStoragePathProvider(),
      );
      addTearDown(container.dispose);

      container.read(settingsControllerProvider);
      await _flush();

      final state = container.read(settingsControllerProvider);
      expect(state.errorMessage, isNull);
      expect(state.settings.defaultSavePath, savedPath);
    },
  );

  test(
    'load migrates legacy macOS sandbox receive path to default path',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'settings-controller-legacy-sandbox',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final defaultPath = '${tempDirectory.path}/normal-downloads';
      const legacySandboxPath =
          '/Users/alice/Library/Containers/com.sponzey.filesharing/Data/Downloads/Sponzey FileSharing';
      await SettingsRepository(database).save(
        AppSettings.initial().copyWith(defaultSavePath: legacySandboxPath),
      );

      final container = _createContainer(
        database: database,
        defaultReceivePath: defaultPath,
      );
      addTearDown(container.dispose);

      container.read(settingsControllerProvider);
      await _flush();

      final state = container.read(settingsControllerProvider);
      expect(state.errorMessage, isNull);
      expect(state.settings.defaultSavePath, defaultPath);
      expect(
        (await SettingsRepository(database).load())?.defaultSavePath,
        defaultPath,
      );
    },
  );

  test('save rejects a file path and keeps the app alive', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'settings-controller-save-file',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/not-a-directory.txt');
    await file.writeAsString('content');

    final container = _createContainer(
      database: database,
      defaultReceivePath: '${tempDirectory.path}/downloads',
    );
    addTearDown(container.dispose);

    container.read(settingsControllerProvider);
    await _flush();

    await container
        .read(settingsControllerProvider.notifier)
        .save(AppSettings.initial().copyWith(defaultSavePath: file.path));

    final state = container.read(settingsControllerProvider);
    expect(state.isSaving, isFalse);
    expect(state.errorMessage, '기본 저장 경로는 폴더여야 합니다.');
  });
}

ProviderContainer _createContainer({
  required AppDatabase database,
  String? defaultReceivePath,
  AppStoragePathProvider? storagePathProvider,
}) {
  assert(defaultReceivePath != null || storagePathProvider != null);
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      appStoragePathProvider.overrideWithValue(
        storagePathProvider ?? _FakeStoragePathProvider(defaultReceivePath!),
      ),
      appLoggerProvider.overrideWithValue(
        const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      ),
    ],
  );
}

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

class _FakeStoragePathProvider implements AppStoragePathProvider {
  const _FakeStoragePathProvider(this.path);

  final String path;

  @override
  Future<String> getDefaultReceivePath() async => path;
}

class _ThrowingStoragePathProvider implements AppStoragePathProvider {
  const _ThrowingStoragePathProvider();

  @override
  Future<String> getDefaultReceivePath() {
    throw StateError('default receive path is unavailable for test');
  }
}
