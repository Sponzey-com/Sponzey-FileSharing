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

class DiscoveryTransportSnapshot {
  const DiscoveryTransportSnapshot({
    required this.mode,
    required this.preferredPort,
    this.receivePort,
    this.sendPort,
    this.receivePortFallback = false,
    this.lastError,
    this.broadcastTargets = const [],
    this.lastBroadcastAttemptCount = 0,
    this.lastBroadcastSuccessCount = 0,
    this.lastBroadcastFailureCount = 0,
    this.lastBroadcastAttemptPreview = const [],
  });

  final String mode;
  final int preferredPort;
  final int? receivePort;
  final int? sendPort;
  final bool receivePortFallback;
  final String? lastError;
  final List<String> broadcastTargets;
  final int lastBroadcastAttemptCount;
  final int lastBroadcastSuccessCount;
  final int lastBroadcastFailureCount;
  final List<String> lastBroadcastAttemptPreview;

  int get broadcastTargetCount => broadcastTargets.length;
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

abstract interface class DiscoveryTransportDiagnostics {
  DiscoveryTransportSnapshot snapshot();
}

final discoveryTransportProvider = Provider<DiscoveryTransport>((ref) {
  final transport = RawUdpDiscoveryTransport(
    logger: ref.watch(appLoggerProvider),
  );
  ref.onDispose(transport.close);
  return transport;
});
