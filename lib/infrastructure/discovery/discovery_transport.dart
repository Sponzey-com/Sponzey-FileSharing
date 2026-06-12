import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/raw_udp_discovery_transport.dart';

class DiscoveryDatagram {
  const DiscoveryDatagram({
    required this.packet,
    required this.address,
    required this.port,
  });

  final DiscoveryPacket packet;
  final InternetAddress address;
  final int port;
}

abstract interface class DiscoveryTransport {
  Stream<DiscoveryDatagram> get packets;

  Future<void> start({required int port});

  Future<void> sendBroadcast(DiscoveryPacket packet, {required int port});

  Future<void> sendUnicast(
    DiscoveryPacket packet, {
    required InternetAddress address,
    required int port,
  });

  Future<void> close();
}

final discoveryTransportProvider = Provider<DiscoveryTransport>((ref) {
  final transport = RawUdpDiscoveryTransport(
    logger: ref.watch(appLoggerProvider),
  );
  ref.onDispose(transport.close);
  return transport;
});
