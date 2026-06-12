import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';

class SettingsState {
  const SettingsState({
    required this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  factory SettingsState.initial() {
    return SettingsState(settings: AppSettings.initial(), isLoading: true);
  }

  final AppSettings settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SettingsController extends Notifier<SettingsState> {
  bool _didInitialize = false;

  @override
  SettingsState build() {
    if (!_didInitialize) {
      _didInitialize = true;
      unawaited(load());
    }

    return SettingsState.initial();
  }

  Future<void> load() async {
    try {
      final defaultSavePath = await ref
          .read(appStoragePathProvider)
          .getDefaultReceivePath();
      final settings = await ref
          .read(settingsRepositoryProvider)
          .loadOrCreate(defaultSavePath: defaultSavePath);
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        isSaving: false,
        clearError: true,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.storage,
            'Failed to load settings',
            error: error,
            stackTrace: stackTrace,
          );
      state = state.copyWith(isLoading: false, errorMessage: '설정을 불러오지 못했습니다.');
    }
  }

  Future<void> save(AppSettings nextSettings) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final normalizedSettings = await _normalizeSettings(nextSettings);
      final saved = await ref
          .read(settingsRepositoryProvider)
          .save(normalizedSettings);
      state = state.copyWith(settings: saved, isSaving: false);
    } on AppException catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.storage,
            'Rejected invalid settings',
            error: error,
            stackTrace: stackTrace,
          );
      state = state.copyWith(isSaving: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.storage,
            'Failed to save settings',
            error: error,
            stackTrace: stackTrace,
          );
      state = state.copyWith(isSaving: false, errorMessage: '설정을 저장하지 못했습니다.');
    }
  }

  Future<AppSettings> _normalizeSettings(AppSettings nextSettings) async {
    var candidatePath = nextSettings.defaultSavePath.trim();
    if (candidatePath.isEmpty) {
      candidatePath = await ref
          .read(appStoragePathProvider)
          .getDefaultReceivePath();
    }

    final directory = Directory(candidatePath);
    final existingType = await FileSystemEntity.type(candidatePath);
    if (existingType == FileSystemEntityType.file) {
      throw const AppException(
        code: 'settings_invalid_save_path',
        message: '기본 저장 경로는 폴더여야 합니다.',
      );
    }

    await directory.create(recursive: true);

    return nextSettings.copyWith(
      defaultSavePath: p.normalize(directory.absolute.path),
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
