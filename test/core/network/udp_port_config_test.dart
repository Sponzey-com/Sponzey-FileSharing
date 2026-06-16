import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';

void main() {
  test('production config exposes discovery, control, and data ports', () {
    final config = AppConfig.production();

    expect(config.discoveryPort, 38400);
    expect(config.controlPort, 38401);
    expect(config.authPort, 38401);
    expect(config.dataPort, 38410);
    expect(config.dataPortRange.contains(38430), isTrue);
    expect(config.appVersion, isNotEmpty);
  });

  test('production config uses short LAN connection retry timings', () {
    final config = AppConfig.production();

    expect(config.discoveryBroadcastInterval, const Duration(seconds: 1));
    expect(config.authHandshakeTimeout, const Duration(seconds: 2));
    expect(
      config.discoveryStaleAfter,
      greaterThan(config.authHandshakeTimeout),
    );
  });

  test('authPort remains a migration alias for controlPort', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      appName: 'Test',
      protocolVersion: '1.0',
      discoveryPort: 40000,
      authPort: 40001,
      dataPort: 40010,
      dataPortRange: UdpPortRange(start: 40010, end: 40012),
      authTokenLifetime: Duration(seconds: 20),
      authAllowedClockSkew: Duration(seconds: 5),
      authHandshakeTimeout: Duration(seconds: 15),
      discoveryBroadcastInterval: Duration(seconds: 3),
      discoveryStaleAfter: Duration(seconds: 10),
      discoveryOfflineAfter: Duration(seconds: 30),
      defaultLogLevel: AppLogLevel.info,
    );

    expect(config.controlPort, 40001);
    expect(config.authPort, 40001);
  });

  test('data port allocator only leases configured range ports', () {
    final allocator = DataPortAllocator(
      range: const UdpPortRange(start: 50000, end: 50001),
    );

    expect(allocator.allocate(), 50000);
    expect(allocator.allocate(), 50001);
    expect(() => allocator.allocate(), throwsStateError);

    allocator.release(50000);
    expect(allocator.allocate(), 50000);
    expect(() => allocator.release(49999), throwsArgumentError);
  });
}
