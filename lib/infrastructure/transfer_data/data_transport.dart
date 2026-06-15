import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/raw_udp_data_transport.dart';

class DataDatagram {
  const DataDatagram({
    required this.packet,
    required this.address,
    required this.port,
    required this.localEndpoint,
  });

  final DataPacket packet;
  final InternetAddress address;
  final int port;
  final UdpInterfaceEndpoint localEndpoint;
}

class DataFrameDatagram {
  const DataFrameDatagram({
    required this.frame,
    required this.address,
    required this.port,
    required this.localEndpoint,
    required this.datagramBytes,
  });

  final DataFrame frame;
  final InternetAddress address;
  final int port;
  final UdpInterfaceEndpoint localEndpoint;
  final int datagramBytes;
}

class DataBindResult {
  const DataBindResult({required this.endpoint});

  final UdpInterfaceEndpoint endpoint;
}

class DataSendResult {
  const DataSendResult({
    required this.success,
    required this.bytesRequested,
    required this.bytesSent,
    this.reasonCode,
  });

  final bool success;
  final int bytesRequested;
  final int bytesSent;
  final String? reasonCode;
}

abstract interface class DataTransport {
  Stream<DataDatagram> get packets;

  Stream<DataFrameDatagram> get frames;

  Future<DataBindResult> bind({
    required UdpInterfaceEndpoint localEndpoint,
    required UdpPortRange portRange,
  });

  Future<void> send(
    DataPacket packet, {
    required InternetAddress address,
    required int port,
  });

  Future<DataSendResult> sendFrame(
    DataFrame frame, {
    required InternetAddress address,
    required int port,
  });

  Future<void> close();
}

final dataTransportProvider = Provider<DataTransport>((ref) {
  final transport = RawUdpDataTransport(logger: ref.watch(appLoggerProvider));
  ref.onDispose(transport.close);
  return transport;
});
