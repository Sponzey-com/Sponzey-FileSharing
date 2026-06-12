import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';

class ControlDatagram {
  const ControlDatagram({
    required this.packet,
    required this.address,
    required this.port,
    this.localEndpoint,
  });

  final AuthPacket packet;
  final InternetAddress address;
  final int port;
  final UdpInterfaceEndpoint? localEndpoint;
}

abstract interface class ControlTransport {
  Stream<ControlDatagram> get packets;

  Future<int> start({required int preferredPort});

  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  });

  Future<void> close();
}

class AuthControlTransportAdapter implements ControlTransport {
  AuthControlTransportAdapter({required AuthTransport authTransport})
    : _authTransport = authTransport;

  final AuthTransport _authTransport;

  @override
  Stream<ControlDatagram> get packets {
    return _authTransport.packets.map(
      (datagram) => ControlDatagram(
        packet: datagram.packet,
        address: datagram.address,
        port: datagram.port,
      ),
    );
  }

  @override
  Future<int> start({required int preferredPort}) {
    return _authTransport.start(preferredPort: preferredPort);
  }

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    return _authTransport.send(packet, address: address, port: port);
  }

  @override
  Future<void> close() => _authTransport.close();
}

final controlTransportProvider = Provider<ControlTransport>((ref) {
  return AuthControlTransportAdapter(
    authTransport: ref.watch(authTransportProvider),
  );
});
