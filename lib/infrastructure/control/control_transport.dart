import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_socket_bind_policy.dart';

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

class ControlTransportBindException implements Exception {
  const ControlTransportBindException({
    required this.reasonCode,
    this.localEndpoint,
    this.cause,
  });

  final String reasonCode;
  final UdpInterfaceEndpoint? localEndpoint;
  final Object? cause;

  @override
  String toString() {
    final address = localEndpoint?.localAddress;
    return 'ControlTransportBindException($reasonCode'
        '${address == null ? '' : ', localAddress=$address'}'
        '${cause == null ? '' : ', cause=$cause'})';
  }
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
    if (localEndpoint != null && !localEndpoint.isWildcardBind) {
      throw UnsupportedError(
        'AuthControlTransportAdapter cannot bind selected local endpoint.',
      );
    }
    return _authTransport.send(packet, address: address, port: port);
  }

  @override
  Future<void> close() => _authTransport.close();
}

class RawUdpControlTransport implements ControlTransport {
  RawUdpControlTransport({
    required AppLogger logger,
    required MessageBus messageBus,
    ControlSocketBindPolicy? bindPolicy,
  }) : _logger = logger,
       _messageBus = messageBus,
       _bindPolicy = bindPolicy ?? _currentBindPolicy();

  final AppLogger _logger;
  final MessageBus _messageBus;
  final ControlSocketBindPolicy _bindPolicy;
  final StreamController<ControlDatagram> _packetsController =
      StreamController<ControlDatagram>.broadcast();
  final Map<String, _ControlSenderSocket> _senderSockets = {};

  RawDatagramSocket? _receiveSocket;
  StreamSubscription<RawSocketEvent>? _receiveSubscription;
  _ControlSenderSocket? _fallbackSenderSocket;
  int? _localPort;

  @override
  Stream<ControlDatagram> get packets => _packetsController.stream;

  @override
  Future<int> start({required int preferredPort}) async {
    if (_receiveSocket != null && _localPort != null) {
      return _localPort!;
    }

    RawDatagramSocket socket;
    try {
      socket = await _bindReceiveSocket(preferredPort);
    } catch (error, stackTrace) {
      if (!_isAddressInUse(error)) {
        rethrow;
      }
      _logger.warning(
        AppLogCategory.auth,
        'Control receive port $preferredPort is already in use. '
        'Falling back to an ephemeral UDP port.',
        error: error,
        stackTrace: stackTrace,
      );
      socket = await _bindReceiveSocket(0);
    }

    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;
    socket.writeEventsEnabled = false;

    _receiveSocket = socket;
    _localPort = socket.port;
    _receiveSubscription = socket.listen(
      (event) => _handleSocketEvent(
        event,
        socket: socket,
        localEndpoint: UdpInterfaceEndpoint(
          role: UdpPortRole.control,
          localAddress: InternetAddress.anyIPv4.address,
          port: socket.port,
          bindMode: UdpInterfaceBindMode.any,
        ),
      ),
    );

    _logger.info(
      AppLogCategory.auth,
      'Control transport listening on UDP ${socket.port} '
      '(preferred $preferredPort)',
    );
    return socket.port;
  }

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  }) async {
    final socket = await _senderSocketFor(localEndpoint);
    _logger.info(
      AppLogCategory.auth,
      'Sending ${packet.type.wireName} to ${address.address}:$port '
      '(session ${_safeSession(packet.sessionId)})',
    );
    socket.send(packet.encode(), address, port);
  }

  @override
  Future<void> close() async {
    await _receiveSubscription?.cancel();
    _receiveSubscription = null;
    _receiveSocket?.close();
    _receiveSocket = null;
    _localPort = null;
    for (final sender in _senderSockets.values) {
      await sender.close();
    }
    _senderSockets.clear();
    await _fallbackSenderSocket?.close();
    _fallbackSenderSocket = null;
    if (!_packetsController.isClosed) {
      await _packetsController.close();
    }
  }

  Future<RawDatagramSocket> _senderSocketFor(
    UdpInterfaceEndpoint? localEndpoint,
  ) async {
    if (localEndpoint != null && !localEndpoint.isWildcardBind) {
      try {
        return (await _selectedSenderSocket(localEndpoint)).socket;
      } catch (error, stackTrace) {
        _publishBindEvent(
          eventType: 'controlSenderBindFallback',
          localEndpoint: localEndpoint,
          reasonCode: 'controlBindFallback',
        );
        _logger.warning(
          AppLogCategory.auth,
          'Failed to bind selected control sender on '
          '${localEndpoint.localAddress}. Falling back to anyIPv4 sender.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      return (await _fallbackSender()).socket;
    } catch (error) {
      throw ControlTransportBindException(
        reasonCode: 'controlBindFailed',
        localEndpoint: localEndpoint,
        cause: error,
      );
    }
  }

  Future<_ControlSenderSocket> _selectedSenderSocket(
    UdpInterfaceEndpoint localEndpoint,
  ) async {
    final key = _senderKey(localEndpoint);
    final existing = _senderSockets[key];
    if (existing != null) {
      return existing;
    }

    final options = _bindPolicy.senderSocket();
    final socket = await RawDatagramSocket.bind(
      InternetAddress(localEndpoint.localAddress),
      0,
      reuseAddress: options.reuseAddress,
      reusePort: options.reusePort,
    );
    final boundEndpoint = UdpInterfaceEndpoint(
      role: UdpPortRole.control,
      interfaceId: localEndpoint.interfaceId,
      localAddress: localEndpoint.localAddress,
      port: socket.port,
      bindMode: localEndpoint.bindMode,
      reuseAddress: options.reuseAddress,
      reusePort: options.reusePort,
    );
    final sender = _ControlSenderSocket(
      socket: socket,
      localEndpoint: boundEndpoint,
    );
    _configureSenderSocket(sender);
    _senderSockets[key] = sender;
    _publishBindEvent(
      eventType: 'controlSenderBound',
      localEndpoint: boundEndpoint,
      reasonCode: null,
    );
    return sender;
  }

  Future<_ControlSenderSocket> _fallbackSender() async {
    final existing = _fallbackSenderSocket;
    if (existing != null) {
      return existing;
    }
    final options = _bindPolicy.senderSocket();
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: options.reuseAddress,
      reusePort: options.reusePort,
    );
    final sender = _ControlSenderSocket(
      socket: socket,
      localEndpoint: UdpInterfaceEndpoint(
        role: UdpPortRole.control,
        localAddress: InternetAddress.anyIPv4.address,
        port: socket.port,
        bindMode: UdpInterfaceBindMode.any,
        reuseAddress: options.reuseAddress,
        reusePort: options.reusePort,
      ),
    );
    _configureSenderSocket(sender);
    _fallbackSenderSocket = sender;
    return sender;
  }

  void _configureSenderSocket(_ControlSenderSocket sender) {
    sender.socket.broadcastEnabled = true;
    sender.socket.readEventsEnabled = true;
    sender.socket.writeEventsEnabled = false;
    sender.subscription = sender.socket.listen(
      (event) => _handleSocketEvent(
        event,
        socket: sender.socket,
        localEndpoint: sender.localEndpoint,
      ),
    );
  }

  Future<RawDatagramSocket> _bindReceiveSocket(int port) {
    final options = _bindPolicy.receiveSocket();
    return RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: options.reuseAddress,
      reusePort: options.reusePort,
    );
  }

  void _handleSocketEvent(
    RawSocketEvent event, {
    required RawDatagramSocket socket,
    required UdpInterfaceEndpoint localEndpoint,
  }) {
    if (event != RawSocketEvent.read) {
      return;
    }
    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      final current = datagram!;
      try {
        final packet = AuthPacket.decode(current.data);
        _logger.info(
          AppLogCategory.auth,
          'Received ${packet.type.wireName} from '
          '${current.address.address}:${current.port} '
          '(session ${_safeSession(packet.sessionId)})',
        );
        _packetsController.add(
          ControlDatagram(
            packet: packet,
            address: current.address,
            port: current.port,
            localEndpoint: localEndpoint,
          ),
        );
      } on FormatException catch (error, stackTrace) {
        _logger.warning(
          AppLogCategory.auth,
          'Ignored malformed control datagram',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  void _publishBindEvent({
    required String eventType,
    required UdpInterfaceEndpoint localEndpoint,
    required String? reasonCode,
  }) {
    _messageBus.publish(
      UdpPortAppEvent(
        eventId: '$eventType-${DateTime.now().microsecondsSinceEpoch}',
        occurredAt: DateTime.now(),
        correlationId: localEndpoint.localAddress,
        source: 'RawUdpControlTransport',
        severity: AppEventSeverity.debug,
        eventType: eventType,
        portRole: UdpPortRole.control.name,
        port: localEndpoint.port,
        reasonCode: reasonCode,
      ),
    );
  }

  String _senderKey(UdpInterfaceEndpoint endpoint) {
    return '${endpoint.localAddress}|${endpoint.bindMode.name}|'
        '${endpoint.interfaceId?.stableId ?? 'unknown'}';
  }

  String _safeSession(String sessionId) {
    return sessionId.length <= 8 ? sessionId : sessionId.substring(0, 8);
  }

  bool _isAddressInUse(Object error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      final code = error.osError?.errorCode;
      return code == 48 ||
          code == 98 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    if (error is OSError) {
      final message = error.message.toLowerCase();
      final code = error.errorCode;
      return code == 48 ||
          code == 98 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    return error.toString().toLowerCase().contains('address already in use');
  }

  static ControlSocketBindPolicy _currentBindPolicy() {
    if (Platform.isWindows) {
      return const ControlSocketBindPolicy(
        platform: ControlSocketPlatform.windows,
      );
    }
    if (Platform.isMacOS) {
      return const ControlSocketBindPolicy(
        platform: ControlSocketPlatform.macos,
      );
    }
    if (Platform.isLinux) {
      return const ControlSocketBindPolicy(
        platform: ControlSocketPlatform.linux,
      );
    }
    return const ControlSocketBindPolicy(platform: ControlSocketPlatform.other);
  }
}

class _ControlSenderSocket {
  _ControlSenderSocket({required this.socket, required this.localEndpoint});

  final RawDatagramSocket socket;
  final UdpInterfaceEndpoint localEndpoint;
  StreamSubscription<RawSocketEvent>? subscription;

  Future<void> close() async {
    await subscription?.cancel();
    socket.close();
  }
}

final controlTransportProvider = Provider<ControlTransport>((ref) {
  final transport = RawUdpControlTransport(
    logger: ref.watch(appLoggerProvider),
    messageBus: ref.watch(messageBusProvider),
  );
  ref.onDispose(transport.close);
  return transport;
});
