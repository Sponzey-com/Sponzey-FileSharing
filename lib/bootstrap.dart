import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/app/app.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/core/errors/error_presenter.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/composite_app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/file_app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

Future<void> bootstrap({required AppConfig config}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = await _createLogger(config);
  final presenter = ErrorPresenter();

  FlutterError.onError = (details) {
    logger.error(
      AppLogCategory.system,
      'Unhandled Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.error(
      AppLogCategory.system,
      'Unhandled platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            appLoggerProvider.overrideWithValue(logger),
            errorPresenterProvider.overrideWithValue(presenter),
          ],
          child: const SponzeyFileSharingApp(),
        ),
      );
    },
    (error, stackTrace) {
      logger.error(
        AppLogCategory.system,
        'Unhandled zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

Future<AppLogger> _createLogger(AppConfig config) async {
  final consoleLogger = ConsoleAppLogger(minimumLevel: config.defaultLogLevel);
  try {
    final supportDirectory =
        await AppPlatformDirectories.getApplicationSupportDirectory();
    return CompositeAppLogger([
      consoleLogger,
      FileAppLogger(
        file: File(p.join(supportDirectory.path, 'logs', 'sponzey.log')),
        minimumLevel: config.defaultLogLevel,
      ),
    ]);
  } catch (_) {
    return consoleLogger;
  }
}
