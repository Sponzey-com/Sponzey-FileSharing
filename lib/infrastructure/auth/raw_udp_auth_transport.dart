import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_transport.dart';

class RawUdpAuthTransport implements AuthTransport {
  RawUdpAuthTransport({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  final StreamController<AuthDatagram> _packetsController =
      StreamController<AuthDatagram>.broadcast();

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;
  int? _localPort;

  @override
  Stream<AuthDatagram> get packets => _packetsController.stream;

  @override
  Future<int> start({required int preferredPort}) async {
    if (_socket != null && _localPort != null) {
      return _localPort!;
    }

    RawDatagramSocket socket;
    try {
      socket = await _bindSocket(preferredPort);
    } catch (error, stackTrace) {
      if (!_isAddressInUse(error)) {
        rethrow;
      }
      _logger.warning(
        AppLogCategory.auth,
        'Auth transport port $preferredPort is already in use. '
        'Falling back to an ephemeral UDP port.',
        error: error,
        stackTrace: stackTrace,
      );
      socket = await _bindSocket(0);
    }
    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;
    socket.writeEventsEnabled = false;

    _socket = socket;
    _localPort = socket.port;
    _socketSubscription = socket.listen(_handleSocketEvent);

    _logger.info(
      AppLogCategory.auth,
      'Auth transport listening on UDP ${socket.port} '
      '(preferred $preferredPort)',
    );
    return socket.port;
  }

  @override
  Future<void> send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {
    final socket = _requireSocket();
    _logger.info(
      AppLogCategory.auth,
      'Sending ${packet.type.wireName} to ${address.address}:$port '
      '(session ${packet.sessionId})',
    );
    socket.send(packet.encode(), address, port);
  }

  @override
  Future<void> close() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    _localPort = null;
    if (!_packetsController.isClosed) {
      await _packetsController.close();
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final socket = _socket;
    if (socket == null) {
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
          '(session ${packet.sessionId})',
        );
        _packetsController.add(
          AuthDatagram(
            packet: packet,
            address: current.address,
            port: current.port,
          ),
        );
      } on FormatException catch (error, stackTrace) {
        _logger.warning(
          AppLogCategory.auth,
          'Ignored malformed auth datagram',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  RawDatagramSocket _requireSocket() {
    final socket = _socket;
    if (socket == null) {
      throw StateError('Auth transport has not been started.');
    }
    return socket;
  }

  Future<RawDatagramSocket> _bindSocket(int port) {
    return RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: false,
      reusePort: false,
    );
  }

  bool _isAddressInUse(Object error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      final code = error.osError?.errorCode;
      return code == 48 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    if (error is OSError) {
      final message = error.message.toLowerCase();
      final code = error.errorCode;
      return code == 48 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    return error.toString().toLowerCase().contains('address already in use');
  }
}
