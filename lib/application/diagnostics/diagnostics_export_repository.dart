import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_bundle.dart';

class DiagnosticsExportSaveResult {
  const DiagnosticsExportSaveResult({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
  });

  final String filePath;
  final String fileName;
  final DateTime createdAt;
}

abstract interface class DiagnosticsExportRepository {
  Future<DiagnosticsExportSaveResult> save(DiagnosticsExportBundle bundle);
}
