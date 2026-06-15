import 'package:sponzey_file_sharing/core/logger/app_logger.dart';

enum ReceivePolicy { manualApproval, autoReceiveAll, autoReceiveAllowedUsers }

class AppSettings {
  const AppSettings({
    required this.defaultSavePath,
    required this.autoReceiveEnabled,
    required this.receivePolicy,
    required this.logLevel,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      defaultSavePath: '',
      autoReceiveEnabled: true,
      receivePolicy: ReceivePolicy.autoReceiveAll,
      logLevel: AppLogLevel.info,
    );
  }

  final String defaultSavePath;
  final bool autoReceiveEnabled;
  final ReceivePolicy receivePolicy;
  final AppLogLevel logLevel;
  AppSettings copyWith({
    String? defaultSavePath,
    bool? autoReceiveEnabled,
    ReceivePolicy? receivePolicy,
    AppLogLevel? logLevel,
  }) {
    return AppSettings(
      defaultSavePath: defaultSavePath ?? this.defaultSavePath,
      autoReceiveEnabled: autoReceiveEnabled ?? this.autoReceiveEnabled,
      receivePolicy: receivePolicy ?? this.receivePolicy,
      logLevel: logLevel ?? this.logLevel,
    );
  }
}
