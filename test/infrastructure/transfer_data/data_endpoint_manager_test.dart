import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_endpoint_manager.dart';

void main() {
  test('dispatcher drops unknown transfer id by returning null', () {
    final dispatcher = DataSessionDispatcher<String>();
    dispatcher.register(transferId: 'known', session: 'session');

    expect(dispatcher.lookup('known'), 'session');
    expect(dispatcher.lookup('unknown'), isNull);
    expect(dispatcher.unregister('known'), 'session');
    expect(dispatcher.contains('known'), isFalse);
  });

  test('windows bind options never enable reusePort', () {
    const options = DataSocketBindOptions(reuseAddress: true, reusePort: false);

    expect(options.reuseAddress, isTrue);
    expect(options.reusePort, isFalse);
  });

  test('binds next port when first data port is occupied', () async {
    final occupied = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final range = UdpPortRange(start: occupied.port, end: occupied.port + 2);
    final manager = DataEndpointManager(
      logger: _NoopLogger(),
      bindOptions: const DataSocketBindOptions(
        reuseAddress: false,
        reusePort: false,
      ),
    );

    try {
      final lease = await manager.bind(
        localEndpoint: UdpInterfaceEndpoint(
          role: UdpPortRole.data,
          localAddress: InternetAddress.loopbackIPv4.address,
          port: occupied.port,
          bindMode: UdpInterfaceBindMode.specificAddress,
        ),
        portRange: range,
        ownerId: 'transfer-001',
      );
      addTearDown(lease.close);

      expect(lease.localEndpoint.port, occupied.port + 1);
    } finally {
      occupied.close();
      await manager.closeAll();
    }
  });
}

class _NoopLogger implements AppLogger {
  @override
  AppLogLevel get minimumLevel => AppLogLevel.error;

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
