import 'dart:io';

import 'package:path/path.dart' as p;

enum AppDesktopPlatform { macos, windows, linux, other }

final class AppPlatformDirectories {
  static const appFolderName = 'Sponzey FileSharing';

  static Future<Directory> getApplicationSupportDirectory() async {
    final directory = Directory(_applicationSupportPath());
    await directory.create(recursive: true);
    return directory;
  }

  static Future<Directory> getDefaultReceiveDirectory() async {
    final directory = Directory(_defaultReceivePath());
    await directory.create(recursive: true);
    return directory;
  }

  static String _applicationSupportPath() {
    return applicationSupportPathFor(
      platform: _currentPlatform,
      environment: Platform.environment,
      currentDirectory: Directory.current.path,
    );
  }

  static String _defaultReceivePath() {
    return defaultReceivePathFor(
      platform: _currentPlatform,
      environment: Platform.environment,
      currentDirectory: Directory.current.path,
    );
  }

  static String applicationSupportPathFor({
    required AppDesktopPlatform platform,
    required Map<String, String> environment,
    required String currentDirectory,
  }) {
    final context = _pathContextFor(platform);
    if (platform == AppDesktopPlatform.windows) {
      final base =
          environment['APPDATA'] ??
          environment['USERPROFILE'] ??
          currentDirectory;
      return context.join(base, appFolderName);
    }

    if (platform == AppDesktopPlatform.macos) {
      final home = environment['HOME'] ?? currentDirectory;
      return context.join(
        home,
        'Library',
        'Application Support',
        appFolderName,
      );
    }

    final dataHome = environment['XDG_DATA_HOME'];
    if (dataHome != null && dataHome.isNotEmpty) {
      return context.join(dataHome, appFolderName);
    }

    final home = environment['HOME'] ?? currentDirectory;
    return context.join(home, '.local', 'share', appFolderName);
  }

  static String defaultReceivePathFor({
    required AppDesktopPlatform platform,
    required Map<String, String> environment,
    required String currentDirectory,
  }) {
    final context = _pathContextFor(platform);
    if (platform == AppDesktopPlatform.windows) {
      final userProfile = environment['USERPROFILE'] ?? currentDirectory;
      return context.join(userProfile, 'Downloads', appFolderName);
    }

    final home = environment['HOME'] ?? currentDirectory;
    if (platform == AppDesktopPlatform.linux) {
      final xdgDownloads = environment['XDG_DOWNLOAD_DIR'];
      if (xdgDownloads != null && xdgDownloads.trim().isNotEmpty) {
        return context.join(
          _expandHome(xdgDownloads.trim(), home),
          appFolderName,
        );
      }
    }

    return context.join(home, 'Downloads', appFolderName);
  }

  static bool looksLikeLegacySandboxReceivePath(String rawPath) {
    final normalized = p.normalize(rawPath.trim());
    if (normalized.isEmpty) {
      return false;
    }

    final parts = p.split(normalized);
    final libraryIndex = parts.indexOf('Library');
    if (libraryIndex < 0 || libraryIndex + 4 >= parts.length) {
      return false;
    }

    return parts[libraryIndex + 1] == 'Containers' &&
        parts.contains('Data') &&
        parts.length >= 2 &&
        parts[parts.length - 2] == 'Downloads' &&
        parts.last == appFolderName;
  }

  static AppDesktopPlatform get _currentPlatform {
    if (Platform.isWindows) {
      return AppDesktopPlatform.windows;
    }
    if (Platform.isMacOS) {
      return AppDesktopPlatform.macos;
    }
    if (Platform.isLinux) {
      return AppDesktopPlatform.linux;
    }
    return AppDesktopPlatform.other;
  }

  static p.Context _pathContextFor(AppDesktopPlatform platform) {
    if (platform == AppDesktopPlatform.windows) {
      return p.Context(style: p.Style.windows);
    }
    return p.Context(style: p.Style.posix);
  }

  static String _expandHome(String rawPath, String home) {
    if (rawPath == r'$HOME') {
      return home;
    }
    if (rawPath.startsWith(r'$HOME/')) {
      return p.posix.join(home, rawPath.substring(r'$HOME/'.length));
    }
    if (rawPath == '~') {
      return home;
    }
    if (rawPath.startsWith('~/')) {
      return p.posix.join(home, rawPath.substring(2));
    }
    return rawPath;
  }
}
