import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_bundle.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';

final diagnosticsExportRepositoryProvider =
    Provider<DiagnosticsExportRepository>((ref) {
      return FileDiagnosticsExportRepository(
        supportDirectoryLoader:
            AppPlatformDirectories.getApplicationSupportDirectory,
      );
    });

class FileDiagnosticsExportRepository implements DiagnosticsExportRepository {
  const FileDiagnosticsExportRepository({
    required Future<Directory> Function() supportDirectoryLoader,
  }) : _supportDirectoryLoader = supportDirectoryLoader;

  final Future<Directory> Function() _supportDirectoryLoader;

  @override
  Future<DiagnosticsExportSaveResult> save(
    DiagnosticsExportBundle bundle,
  ) async {
    final supportDirectory = await _supportDirectoryLoader();
    final diagnosticsDirectory = Directory(
      p.join(supportDirectory.path, 'diagnostics'),
    );
    await diagnosticsDirectory.create(recursive: true);

    final fileName = _fileNameFor(bundle.generatedAt);
    final file = File(p.join(diagnosticsDirectory.path, fileName));
    await file.writeAsString(bundle.toPrettyJson(), flush: true);
    return DiagnosticsExportSaveResult(
      filePath: file.path,
      fileName: fileName,
      createdAt: bundle.generatedAt,
    );
  }

  static String _fileNameFor(DateTime generatedAt) {
    final utc = generatedAt.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp =
        '${utc.year}${two(utc.month)}${two(utc.day)}T'
        '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
    return 'diagnostics-export-$stamp.json';
  }
}
