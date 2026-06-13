import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';

class FileAppLogger implements AppLogger, AppLogFileLocator {
  FileAppLogger({required File file, required this.minimumLevel})
    : _file = file {
    _prepareFile();
  }

  final File _file;

  @override
  final AppLogLevel minimumLevel;

  @override
  String get logFilePath => _file.path;

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.debug, category, message, error, stackTrace);
  }

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.info, category, message, error, stackTrace);
  }

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.warning, category, message, error, stackTrace);
  }

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(AppLogLevel.error, category, message, error, stackTrace);
  }

  void _prepareFile() {
    try {
      _file.parent.createSync(recursive: true);
      if (!_file.existsSync()) {
        _file.createSync(recursive: true);
      }
    } on Object {
      // Logging must never break app startup.
    }
  }

  void _log(
    AppLogLevel level,
    AppLogCategory category,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    if (level.index < minimumLevel.index) {
      return;
    }
    final buffer = StringBuffer()
      ..write(DateTime.now().toIso8601String())
      ..write(' ')
      ..write(level.name.toUpperCase())
      ..write(' [')
      ..write(category.name)
      ..write('] ')
      ..write(_singleLine(message));
    if (error != null) {
      buffer
        ..write(' error=')
        ..write(_singleLine(error.toString()));
    }
    if (stackTrace != null && level == AppLogLevel.error) {
      buffer
        ..write(' stack=')
        ..write(_singleLine(stackTrace.toString()));
    }
    buffer.writeln();

    try {
      _file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
    } on Object {
      // Logging must never crash the product.
    }
  }

  String _singleLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
