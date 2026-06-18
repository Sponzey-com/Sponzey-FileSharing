import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_bundle.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_transfer_pipeline_providers.dart';

final diagnosticsExportBundleProvider = Provider<DiagnosticsExportBundle>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(appLoggerProvider);
  ref.watch(peerPathRegistryRevisionProvider);

  return const DiagnosticsExportBundleBuilder().build(
    DiagnosticsExportInput(
      generatedAt: DateTime.now().toUtc(),
      appName: config.appName,
      protocolVersion: config.protocolVersion,
      operatingSystem: Platform.operatingSystem,
      logLevel: logger.minimumLevel,
      logFilePath: logger is AppLogFileLocator
          ? (logger as AppLogFileLocator).logFilePath
          : null,
      authState: ref.watch(authControllerProvider),
      peerAuthState: ref.watch(peerAuthControllerProvider),
      discoveryState: ref.watch(discoveryControllerProvider),
      transferState: ref.watch(transferControllerProvider),
      settingsState: ref.watch(settingsControllerProvider),
      routeCandidates: ref.watch(peerRouteCandidateStoreProvider),
      activePaths: ref.watch(peerPathRegistryProvider).snapshot(),
      tcpDataSessions: ref
          .watch(tcpDataChannelSessionRegistryProvider)
          .snapshot(),
    ),
  );
});
