import 'dart:io';

import 'package:path/path.dart' as p;

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
    if (Platform.isWindows) {
      final base =
          Platform.environment['APPDATA'] ??
          Platform.environment['USERPROFILE'] ??
          Directory.current.path;
      return p.join(base, appFolderName);
    }

    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      return p.join(home, 'Library', 'Application Support', appFolderName);
    }

    final dataHome = Platform.environment['XDG_DATA_HOME'];
    if (dataHome != null && dataHome.isNotEmpty) {
      return p.join(dataHome, appFolderName);
    }

    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return p.join(home, '.local', 'share', appFolderName);
  }

  static String _defaultReceivePath() {
    if (Platform.isWindows) {
      final userProfile =
          Platform.environment['USERPROFILE'] ?? Directory.current.path;
      final downloads = p.join(userProfile, 'Downloads', appFolderName);
      if (Directory(p.join(userProfile, 'Downloads')).existsSync()) {
        return downloads;
      }
      return p.join(userProfile, 'Documents', appFolderName);
    }

    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final downloads = p.join(home, 'Downloads', appFolderName);
    if (Directory(p.join(home, 'Downloads')).existsSync()) {
      return downloads;
    }
    return p.join(home, 'Documents', appFolderName);
  }
}
