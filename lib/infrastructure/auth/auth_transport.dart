import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/raw_udp_auth_transport.dart';

class AuthDatagram {
  const AuthDatagram({
    required this.packet,
    required this.address,
    required this.port,
  });

  final AuthPacket packet;
  final InternetAddress address;
  final int port;
}

abstract interface class AuthTransport {
  Stream<AuthDatagram> get packets;

  Future<int> start({required int preferredPort});

  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  });

  Future<void> close();
}

final authTransportProvider = Provider<AuthTransport>((ref) {
  final transport = RawUdpAuthTransport(logger: ref.watch(appLoggerProvider));
  ref.onDispose(transport.close);
  return transport;
});
