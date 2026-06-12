import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.currentUser,
    this.errorMessage,
    this.sessionPassword,
    this.isBusy = false,
  });

  const AuthState.initializing()
    : status = AuthStatus.initializing,
      currentUser = null,
      errorMessage = null,
      sessionPassword = null,
      isBusy = true;

  final AuthStatus status;
  final UserAccount? currentUser;
  final String? errorMessage;
  final String? sessionPassword;
  final bool isBusy;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserAccount? currentUser,
    String? errorMessage,
    String? sessionPassword,
    bool? isBusy,
    bool clearCurrentUser = false,
    bool clearError = false,
    bool clearSessionPassword = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      sessionPassword: clearSessionPassword
          ? null
          : sessionPassword ?? this.sessionPassword,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  bool _didInitialize = false;

  @override
  AuthState build() {
    if (!_didInitialize) {
      _didInitialize = true;
      unawaited(_initialize());
    }

    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _initialize() async {
    final logger = ref.read(appLoggerProvider);
    try {
      await _warmSettings();

      logger.info(
        AppLogCategory.auth,
        'Auth initialized with runtime-only memory session',
      );
    } on AppException catch (error, stackTrace) {
      logger.error(
        AppLogCategory.auth,
        'Failed to initialize auth dependencies',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        status: state.isAuthenticated
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        errorMessage: error.message,
        isBusy: false,
      );
    } on FileSystemException catch (error, stackTrace) {
      logger.warning(
        AppLogCategory.auth,
        'Storage path initialization failed, continuing with runtime auth only',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> signIn({
    required String userId,
    required String password,
  }) async {
    final logger = ref.read(appLoggerProvider);
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final normalizedUserId = userId.trim();
      if (normalizedUserId.isEmpty) {
        throw const AppException(
          code: 'user_id_required',
          message: '아이디를 입력해 주세요.',
        );
      }
      if (password.isEmpty) {
        throw const AppException(
          code: 'password_required',
          message: '비밀번호를 입력해 주세요.',
        );
      }

      final deviceName = Platform.localHostname.trim().isEmpty
          ? 'Desktop Node'
          : Platform.localHostname.trim();

      state = AuthState(
        status: AuthStatus.authenticated,
        currentUser: UserAccount(
          userId: normalizedUserId,
          displayName: normalizedUserId,
          deviceName: deviceName,
        ),
        sessionPassword: password,
        isBusy: false,
      );
      logger.info(
        AppLogCategory.auth,
        'Started runtime-only auth session for $normalizedUserId',
      );
      unawaited(_warmSettings());
    } on AppException catch (error, stackTrace) {
      logger.warning(
        AppLogCategory.auth,
        'Sign-in failed',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: error.message,
        isBusy: false,
      );
    }
  }

  Future<void> _warmSettings() async {
    try {
      final defaultSavePath = await ref
          .read(appStoragePathProvider)
          .getDefaultReceivePath()
          .timeout(const Duration(seconds: 2));
      await ref
          .read(settingsRepositoryProvider)
          .loadOrCreate(defaultSavePath: defaultSavePath)
          .timeout(const Duration(seconds: 2));
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.storage,
            'Settings warmup skipped',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  Future<void> signOut() async {
    final logger = ref.read(appLoggerProvider);
    logger.info(AppLogCategory.auth, 'Cleared runtime-only auth session');
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isBusy: false,
      clearCurrentUser: true,
      clearError: true,
      clearSessionPassword: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
