import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_socket_bind_policy.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';

void main() {
  test(
    'selected local address sender socket receives the reply route',
    () async {
      final bus = InMemoryMessageBus();
      addTearDown(bus.dispose);
      final alice = _transport(bus);
      final bob = _transport(bus);
      addTearDown(alice.close);
      addTearDown(bob.close);
      await alice.start(preferredPort: 0);
      final bobPort = await bob.start(preferredPort: 0);

      final bobDatagramFuture = bob.packets.first;
      await alice.send(
        _packet(AuthPacketType.connectRequest, sessionId: 'session-a'),
        address: InternetAddress.loopbackIPv4,
        port: bobPort,
        localEndpoint: const UdpInterfaceEndpoint(
          role: UdpPortRole.control,
          localAddress: '127.0.0.1',
          port: 38401,
          bindMode: UdpInterfaceBindMode.specificAddress,
        ),
      );

      final bobDatagram = await bobDatagramFuture.timeout(
        const Duration(seconds: 2),
      );
      expect(bobDatagram.packet.type, AuthPacketType.connectRequest);
      expect(bobDatagram.address.address, '127.0.0.1');
      expect(bobDatagram.port, greaterThan(0));

      final aliceReplyFuture = alice.packets.first;
      await bob.send(
        _packet(AuthPacketType.authAccept, sessionId: 'session-a'),
        address: bobDatagram.address,
        port: bobDatagram.port,
      );
      final aliceReply = await aliceReplyFuture.timeout(
        const Duration(seconds: 2),
      );

      expect(aliceReply.packet.type, AuthPacketType.authAccept);
      expect(aliceReply.localEndpoint?.localAddress, '127.0.0.1');
    },
  );

  test(
    'selected bind failure falls back and publishes sanitized event',
    () async {
      final bus = InMemoryMessageBus();
      addTearDown(bus.dispose);
      final events = <UdpPortAppEvent>[];
      final subscription = bus.eventsOfType<UdpPortAppEvent>().listen(
        events.add,
      );
      addTearDown(subscription.cancel);
      final transport = _transport(bus);
      addTearDown(transport.close);
      await transport.start(preferredPort: 0);

      await transport.send(
        _packet(
          AuthPacketType.authToken,
          sessionId: 'session-token',
          token: 'secret-token-body',
        ),
        address: InternetAddress.loopbackIPv4,
        port: 9,
        localEndpoint: const UdpInterfaceEndpoint(
          role: UdpPortRole.control,
          localAddress: '192.0.2.55',
          port: 38401,
          bindMode: UdpInterfaceBindMode.specificAddress,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        events.where((event) => event.eventType == 'controlSenderBindFallback'),
        isNotEmpty,
      );
      expect(
        events.map((event) => event.reasonCode),
        isNot(contains('secret')),
      );
      expect(
        events.map((event) => event.correlationId),
        isNot(contains('secret')),
      );
    },
  );

  test('logs high-volume transfer packets at debug level', () async {
    final bus = InMemoryMessageBus();
    addTearDown(bus.dispose);
    final logger = _MemoryAppLogger(minimumLevel: AppLogLevel.debug);
    final transport = _transport(bus, logger: logger);
    addTearDown(transport.close);
    await transport.start(preferredPort: 0);

    await transport.send(
      _packet(
        AuthPacketType.transferChunk,
        sessionId: 'session-transfer',
        transferId: 'transfer-001',
      ),
      address: InternetAddress.loopbackIPv4,
      port: 9,
    );

    expect(
      logger.entries.where(
        (entry) =>
            entry.level == AppLogLevel.info &&
            entry.message.contains('TRANSFER_CHUNK'),
      ),
      isEmpty,
    );
    expect(
      logger.entries.where(
        (entry) =>
            entry.level == AppLogLevel.debug &&
            entry.message.contains('TRANSFER_CHUNK'),
      ),
      isNotEmpty,
    );
  });
}

RawUdpControlTransport _transport(MessageBus bus, {AppLogger? logger}) {
  return RawUdpControlTransport(
    logger: logger ?? const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
    messageBus: bus,
    bindPolicy: ControlSocketBindPolicy(
      platform: Platform.isWindows
          ? ControlSocketPlatform.windows
          : Platform.isLinux
          ? ControlSocketPlatform.linux
          : ControlSocketPlatform.macos,
    ),
  );
}

AuthPacket _packet(
  AuthPacketType type, {
  required String sessionId,
  String? token,
  String? transferId,
}) {
  return AuthPacket(
    type: type,
    protocolVersion: '1.0',
    sessionId: sessionId,
    fromUserId: 'team',
    fromDeviceId: 'device-a',
    token: token,
    transferId: transferId,
    sentAtEpochMs: 1,
  );
}

class _LogEntry {
  const _LogEntry({required this.level, required this.message});

  final AppLogLevel level;
  final String message;
}

class _MemoryAppLogger implements AppLogger {
  _MemoryAppLogger({required this.minimumLevel});

  @override
  final AppLogLevel minimumLevel;

  final List<_LogEntry> entries = [];

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.debug, message);

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.info, message);

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.warning, message);

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => _add(AppLogLevel.error, message);

  void _add(AppLogLevel level, String message) {
    if (level.index < minimumLevel.index) {
      return;
    }
    entries.add(_LogEntry(level: level, message: message));
  }
}
