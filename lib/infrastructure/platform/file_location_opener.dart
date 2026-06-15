import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileLocationOpener {
  const FileLocationOpener();

  Future<void> openPath(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
      return;
    }
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
      return;
    }
    await Process.run('xdg-open', [path]);
  }

  Future<void> openFolderForPath(String path) async {
    final folderPath = await _folderPath(path);
    if (Platform.isMacOS) {
      await Process.run('open', [folderPath]);
      return;
    }
    if (Platform.isWindows) {
      await Process.run('explorer', [folderPath]);
      return;
    }
    await Process.run('xdg-open', [folderPath]);
  }

  Future<String> _folderPath(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      return Directory(path).absolute.path;
    }
    return File(path).absolute.parent.path;
  }
}

final fileLocationOpenerProvider = Provider<FileLocationOpener>((ref) {
  return const FileLocationOpener();
});
