import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/file_app_logger.dart';

void main() {
  test('writes product logs to a local file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sponzey-file-logger-',
    );
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File('${directory.path}/logs/sponzey.log');
    final logger = FileAppLogger(file: file, minimumLevel: AppLogLevel.info);

    logger.info(AppLogCategory.discovery, 'Discovery engine started');

    final content = await file.readAsString();
    expect(content, contains('INFO [discovery] Discovery engine started'));
  });

  test('does not write messages below the configured minimum level', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sponzey-file-logger-',
    );
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File('${directory.path}/logs/sponzey.log');
    final logger = FileAppLogger(file: file, minimumLevel: AppLogLevel.warning);

    logger.debug(AppLogCategory.discovery, 'noisy packet');
    logger.info(AppLogCategory.discovery, 'routine heartbeat');
    logger.warning(AppLogCategory.discovery, 'receive fallback');

    final content = await file.readAsString();
    expect(content, isNot(contains('noisy packet')));
    expect(content, isNot(contains('routine heartbeat')));
    expect(content, contains('WARNING [discovery] receive fallback'));
  });
}
