import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

abstract interface class AppStoragePathProvider {
  Future<String> getDefaultReceivePath();
}

class DesktopAppStoragePathProvider implements AppStoragePathProvider {
  @override
  Future<String> getDefaultReceivePath() async {
    final directory = await AppPlatformDirectories.getDefaultReceiveDirectory();
    return _ensureDirectory(directory.path);
  }

  Future<String> _ensureDirectory(String rawPath) async {
    final directory = Directory(rawPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory.path;
  }
}

final appStoragePathProvider = Provider<AppStoragePathProvider>((ref) {
  return DesktopAppStoragePathProvider();
});
