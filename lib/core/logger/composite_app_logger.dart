import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';

class CompositeAppLogger implements AppLogger, AppLogFileLocator {
  const CompositeAppLogger(this.loggers);

  final List<AppLogger> loggers;

  @override
  AppLogLevel get minimumLevel {
    if (loggers.isEmpty) {
      return AppLogLevel.error;
    }
    return loggers
        .map((logger) => logger.minimumLevel)
        .reduce((a, b) => a.index <= b.index ? a : b);
  }

  @override
  String? get logFilePath {
    for (final logger in loggers) {
      if (logger is AppLogFileLocator) {
        return (logger as AppLogFileLocator).logFilePath;
      }
    }
    return null;
  }

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    for (final logger in loggers) {
      logger.debug(category, message, error: error, stackTrace: stackTrace);
    }
  }

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    for (final logger in loggers) {
      logger.info(category, message, error: error, stackTrace: stackTrace);
    }
  }

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    for (final logger in loggers) {
      logger.warning(category, message, error: error, stackTrace: stackTrace);
    }
  }

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    for (final logger in loggers) {
      logger.error(category, message, error: error, stackTrace: stackTrace);
    }
  }
}
