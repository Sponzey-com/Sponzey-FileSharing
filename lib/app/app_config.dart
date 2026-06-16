import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';

enum AppEnvironment { development, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.appName,
    this.appVersion = const String.fromEnvironment(
      'SPONZEY_APP_VERSION',
      defaultValue: 'development',
    ),
    required this.protocolVersion,
    required this.discoveryPort,
    int? controlPort,
    int? authPort,
    this.dataPort = 38410,
    this.dataPortRange = const UdpPortRange(start: 38410, end: 38430),
    required this.authTokenLifetime,
    required this.authAllowedClockSkew,
    required this.authHandshakeTimeout,
    required this.discoveryBroadcastInterval,
    required this.discoveryStaleAfter,
    required this.discoveryOfflineAfter,
    required this.defaultLogLevel,
  }) : controlPort = controlPort ?? authPort ?? 38401;

  factory AppConfig.production() {
    return const AppConfig(
      environment: AppEnvironment.production,
      appName: 'Sponzey FileSharing',
      protocolVersion: '1.0',
      discoveryPort: 38400,
      controlPort: 38401,
      dataPort: 38410,
      dataPortRange: UdpPortRange(start: 38410, end: 38430),
      authTokenLifetime: Duration(seconds: 20),
      authAllowedClockSkew: Duration(seconds: 5),
      authHandshakeTimeout: Duration(seconds: 5),
      discoveryBroadcastInterval: Duration(seconds: 1),
      discoveryStaleAfter: Duration(seconds: 10),
      discoveryOfflineAfter: Duration(seconds: 30),
      defaultLogLevel: AppLogLevel.info,
    );
  }

  final AppEnvironment environment;
  final String appName;
  final String appVersion;
  final String protocolVersion;
  final int discoveryPort;
  final int controlPort;
  final int dataPort;
  final UdpPortRange dataPortRange;
  final Duration authTokenLifetime;
  final Duration authAllowedClockSkew;
  final Duration authHandshakeTimeout;
  final Duration discoveryBroadcastInterval;
  final Duration discoveryStaleAfter;
  final Duration discoveryOfflineAfter;
  final AppLogLevel defaultLogLevel;

  bool get isDevelopment => environment == AppEnvironment.development;

  @Deprecated('Use controlPort. authPort is kept as a migration alias.')
  int get authPort => controlPort;

  UdpEndpointConfig endpointFor(UdpPortRole role) {
    switch (role) {
      case UdpPortRole.discovery:
        return UdpEndpointConfig(role: role, port: discoveryPort);
      case UdpPortRole.control:
        return UdpEndpointConfig(role: role, port: controlPort);
      case UdpPortRole.data:
        return UdpEndpointConfig(role: role, port: dataPort);
    }
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be overridden during bootstrap.');
});
