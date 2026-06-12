import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_secure_storage.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates a runtime-only session and does not restore it', () async {
    final container = _createContainer(
      database: database,
      secureStorage: _FakeSecureStorage(),
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);

    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'admin', password: 'secret');
    expect(container.read(authControllerProvider).currentUser?.userId, 'admin');

    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);

    final restoredContainer = _createContainer(
      database: database,
      secureStorage: _FakeSecureStorage(),
    );
    addTearDown(restoredContainer.dispose);

    restoredContainer.read(authControllerProvider);
    await _flush();

    expect(
      restoredContainer.read(authControllerProvider).isAuthenticated,
      isFalse,
    );
  });

  test('rejects empty user id and password', () async {
    final container = _createContainer(
      database: database,
      secureStorage: _FakeSecureStorage(),
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();

    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: '', password: 'secret');
    expect(
      container.read(authControllerProvider).errorMessage,
      '아이디를 입력해 주세요.',
    );

    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'admin', password: '');
    expect(
      container.read(authControllerProvider).errorMessage,
      '비밀번호를 입력해 주세요.',
    );
  });

  test('sign-in completes even when settings warmup stalls', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        appSecureStorageProvider.overrideWithValue(_FakeSecureStorage()),
        appStoragePathProvider.overrideWithValue(
          const _NeverCompletingStoragePathProvider(),
        ),
        appLoggerProvider.overrideWithValue(
          const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await _flush();

    await container
        .read(authControllerProvider.notifier)
        .signIn(userId: 'admin', password: 'secret');

    final state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.isBusy, isFalse);
    expect(state.currentUser?.userId, 'admin');
  });
}

ProviderContainer _createContainer({
  required AppDatabase database,
  required AppSecureStorage secureStorage,
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      appSecureStorageProvider.overrideWithValue(secureStorage),
      appStoragePathProvider.overrideWithValue(
        _FakeStoragePathProvider('/tmp/sponzey-test'),
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

class _NeverCompletingStoragePathProvider implements AppStoragePathProvider {
  const _NeverCompletingStoragePathProvider();

  @override
  Future<String> getDefaultReceivePath() {
    return Completer<String>().future;
  }
}

class _FakeSecureStorage implements AppSecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> ensureReady() async {
    _values.putIfAbsent('__memory_ready__', () => 'ready');
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}
