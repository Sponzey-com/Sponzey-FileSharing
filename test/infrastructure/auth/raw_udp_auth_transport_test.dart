import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/raw_udp_auth_transport.dart';

void main() {
  test(
    'falls back to a unique UDP port when preferred port is occupied',
    () async {
      final occupied = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(occupied.close);

      final transport = RawUdpAuthTransport(
        logger: const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      );
      addTearDown(transport.close);

      final localPort = await transport.start(preferredPort: occupied.port);

      expect(localPort, isNot(occupied.port));
      expect(localPort, greaterThan(0));
    },
  );
}
