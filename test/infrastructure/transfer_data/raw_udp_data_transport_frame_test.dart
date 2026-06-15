import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/raw_udp_data_transport.dart';

void main() {
  test('sends and receives binary data frame over loopback UDP', () async {
    final sender = RawUdpDataTransport(logger: _MemoryLogger());
    final receiver = RawUdpDataTransport(logger: _MemoryLogger());
    addTearDown(sender.close);
    addTearDown(receiver.close);

    final receiverBind = await receiver.bind(
      localEndpoint: UdpInterfaceEndpoint(
        role: UdpPortRole.data,
        localAddress: InternetAddress.loopbackIPv4.address,
        port: 0,
        bindMode: UdpInterfaceBindMode.specificAddress,
      ),
      portRange: const UdpPortRange(start: 53000, end: 53010),
    );
    await sender.bind(
      localEndpoint: UdpInterfaceEndpoint(
        role: UdpPortRole.data,
        localAddress: InternetAddress.loopbackIPv4.address,
        port: 0,
        bindMode: UdpInterfaceBindMode.specificAddress,
      ),
      portRange: const UdpPortRange(start: 53011, end: 53020),
    );

    final frame = DataFrame(
      version: DataFrameCodec.version,
      type: DataFrameType.dataChunk,
      flags: 0,
      sessionHash: 9,
      transferIdBytes: transferIdBytesFromString('transfer-loopback'),
      sequence: 1,
      chunkIndex: 0,
      windowStart: 0,
      windowSize: 128,
      ackBase: 0,
      payload: Uint8List.fromList([7, 8, 9]),
    );

    final result = await sender.sendFrame(
      frame,
      address: InternetAddress.loopbackIPv4,
      port: receiverBind.endpoint.port,
    );

    expect(result.success, isTrue);
    final datagram = await receiver.frames.first.timeout(
      const Duration(seconds: 2),
    );
    expect(datagram.frame.type, DataFrameType.dataChunk);
    expect(datagram.frame.payload, [7, 8, 9]);
    expect(datagram.localEndpoint.port, receiverBind.endpoint.port);
  });
}

class _MemoryLogger implements AppLogger {
  @override
  AppLogLevel get minimumLevel => AppLogLevel.debug;

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
