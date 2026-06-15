import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_provider.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_repository.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/diagnostics_export_repository.dart';

class DiagnosticsExportState {
  const DiagnosticsExportState({
    this.isSaving = false,
    this.lastSavedPath,
    this.errorMessage,
  });

  final bool isSaving;
  final String? lastSavedPath;
  final String? errorMessage;

  DiagnosticsExportState copyWith({
    bool? isSaving,
    String? lastSavedPath,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiagnosticsExportState(
      isSaving: isSaving ?? this.isSaving,
      lastSavedPath: lastSavedPath ?? this.lastSavedPath,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DiagnosticsExportController extends Notifier<DiagnosticsExportState> {
  @override
  DiagnosticsExportState build() {
    return const DiagnosticsExportState();
  }

  Future<DiagnosticsExportSaveResult?> saveCurrentBundle() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final result = await ref
          .read(diagnosticsExportRepositoryProvider)
          .save(ref.read(diagnosticsExportBundleProvider));
      state = DiagnosticsExportState(lastSavedPath: result.filePath);
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.system,
            'Saved redacted diagnostics export ${result.fileName}',
          );
      return result;
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.system,
            'Failed to save diagnostics export',
            error: error,
            stackTrace: stackTrace,
          );
      state = const DiagnosticsExportState(
        errorMessage: '진단 export 파일을 저장하지 못했습니다.',
      );
      return null;
    }
  }
}

final diagnosticsExportControllerProvider =
    NotifierProvider<DiagnosticsExportController, DiagnosticsExportState>(
      DiagnosticsExportController.new,
    );
