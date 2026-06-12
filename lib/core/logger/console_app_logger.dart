import 'dart:developer' as developer;

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';

class ConsoleAppLogger implements AppLogger {
  const ConsoleAppLogger({required this.minimumLevel});

  @override
  final AppLogLevel minimumLevel;

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level: AppLogLevel.debug,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level: AppLogLevel.info,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level: AppLogLevel.warning,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      level: AppLogLevel.error,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _log({
    required AppLogLevel level,
    required AppLogCategory category,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) {
      return;
    }

    developer.log(
      '[${category.name}] $message',
      name: 'sponzey_file_sharing',
      level: _toDeveloperLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _toDeveloperLevel(AppLogLevel level) {
    switch (level) {
      case AppLogLevel.debug:
        return 500;
      case AppLogLevel.info:
        return 800;
      case AppLogLevel.warning:
        return 900;
      case AppLogLevel.error:
        return 1000;
    }
  }
}
