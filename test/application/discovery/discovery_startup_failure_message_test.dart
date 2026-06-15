import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_startup_failure_message.dart';

void main() {
  test('socket startup failures include actionable UDP and firewall guidance', () {
    final message = discoveryStartupFailureMessage(
      stage: 'transport-start',
      error: const SocketException(
        'Permission denied at /Users/dongwooshin/private/socket.log',
      ),
      discoveryPort: 38400,
      controlPort: 38401,
      dataPortRangeStart: 38410,
      dataPortRangeEnd: 38430,
    );

    expect(message, contains('방화벽'));
    expect(message, contains('소켓 권한'));
    expect(message, contains('discovery 38400/udp'));
    expect(message, contains('control 38401/udp'));
    expect(message, contains('data 38410-38430/udp'));
    expect(message, contains('diagnostics export'));
    expect(message, isNot(contains('/Users/dongwooshin')));
  });

  test('non-socket failures keep safe diagnostics guidance', () {
    final message = discoveryStartupFailureMessage(
      stage: 'first-broadcast',
      error: StateError('failed with token=secret-value'),
      discoveryPort: 38400,
      controlPort: 38401,
      dataPortRangeStart: 38410,
      dataPortRangeEnd: 38430,
    );
    final decision = discoveryStartupFailureDecision(
      stage: 'first-broadcast',
      error: StateError('failed with token=secret-value'),
    );

    expect(message, contains('diagnostics export'));
    expect(message, isNot(contains('secret-value')));
    expect(decision, isNot(contains('secret-value')));
  });
}
