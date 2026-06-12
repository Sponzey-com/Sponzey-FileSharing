import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';

void main() {
  test(
    'adapter keeps existing auth transport path without selected endpoint',
    () async {
      final auth = _FakeAuthTransport();
      final control = AuthControlTransportAdapter(authTransport: auth);

      final port = await control.start(preferredPort: 38401);
      await control.send(
        _packet(),
        address: InternetAddress.loopbackIPv4,
        port: port,
      );

      expect(port, 38401);
      expect(auth.sent, hasLength(1));
    },
  );

  test(
    'control transport API can carry selected local endpoint in fakes',
    () async {
      final control = _FakeControlTransport();
      const endpoint = UdpInterfaceEndpoint(
        role: UdpPortRole.control,
        localAddress: '10.0.1.10',
        port: 38401,
        bindMode: UdpInterfaceBindMode.specificAddress,
      );

      await control.send(
        _packet(),
        address: InternetAddress('10.0.1.20'),
        port: 38401,
        localEndpoint: endpoint,
      );

      expect(control.sent.single.localEndpoint, endpoint);
    },
  );
}

class _SentAuth {
  const _SentAuth();
}

class _FakeAuthTransport implements AuthTransport {
  final sent = <_SentAuth>[];
  final _controller = StreamController<AuthDatagram>.broadcast();

  @override
  Stream<AuthDatagram> get packets => _controller.stream;

  @override
  Future<int> start({required int preferredPort}) async => preferredPort;

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {
    sent.add(const _SentAuth());
  }

  @override
  Future<void> close() => _controller.close();
}

class _FakeControlTransport implements ControlTransport {
  final sent = <ControlDatagram>[];
  final _controller = StreamController<ControlDatagram>.broadcast();

  @override
  Stream<ControlDatagram> get packets => _controller.stream;

  @override
  Future<int> start({required int preferredPort}) async => preferredPort;

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  }) async {
    sent.add(
      ControlDatagram(
        packet: packet,
        address: address,
        port: port,
        localEndpoint: localEndpoint,
      ),
    );
  }

  @override
  Future<void> close() => _controller.close();
}

AuthPacket _packet() {
  return const AuthPacket(
    type: AuthPacketType.connectRequest,
    protocolVersion: '1.0',
    sessionId: 'session',
    fromUserId: 'user',
    fromDeviceId: 'device',
    sentAtEpochMs: 1,
  );
}
