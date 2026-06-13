import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';

enum AppLogLevel { debug, info, warning, error }

abstract interface class AppLogger {
  AppLogLevel get minimumLevel;

  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}

abstract interface class AppLogFileLocator {
  String? get logFilePath;
}

final appLoggerProvider = Provider<AppLogger>((ref) {
  throw UnimplementedError('AppLogger must be overridden during bootstrap.');
});
