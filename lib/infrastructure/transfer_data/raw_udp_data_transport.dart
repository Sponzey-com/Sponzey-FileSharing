import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_transport.dart';

class RawUdpDataTransport implements DataTransport {
  RawUdpDataTransport({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  final StreamController<DataDatagram> _packetsController =
      StreamController<DataDatagram>.broadcast();

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  UdpInterfaceEndpoint? _localEndpoint;

  @override
  Stream<DataDatagram> get packets => _packetsController.stream;

  @override
  Future<DataBindResult> bind({
    required UdpInterfaceEndpoint localEndpoint,
    required UdpPortRange portRange,
  }) async {
    if (_socket != null && _localEndpoint != null) {
      return DataBindResult(endpoint: _localEndpoint!);
    }

    Object? lastError;
    for (final port in portRange.ports) {
      try {
        final endpoint = UdpInterfaceEndpoint(
          role: UdpPortRole.data,
          interfaceId: localEndpoint.interfaceId,
          localAddress: localEndpoint.localAddress,
          port: port,
          bindMode: localEndpoint.bindMode,
          reuseAddress: localEndpoint.reuseAddress,
          reusePort: localEndpoint.reusePort,
        );
        final socket = await RawDatagramSocket.bind(
          InternetAddress(endpoint.localAddress),
          endpoint.port,
          reuseAddress: endpoint.reuseAddress,
          reusePort: endpoint.reusePort,
        );
        socket.readEventsEnabled = true;
        socket.writeEventsEnabled = false;
        _socket = socket;
        _localEndpoint = endpoint;
        _subscription = socket.listen(_handleSocketEvent);
        _logger.info(
          AppLogCategory.transferData,
          'Data transport listening on ${endpoint.localAddress}:${endpoint.port}',
        );
        return DataBindResult(endpoint: endpoint);
      } on SocketException catch (error) {
        lastError = error;
        if (!_isAddressInUse(error)) {
          break;
        }
      } on OSError catch (error) {
        lastError = error;
        if (!_isAddressInUse(error)) {
          break;
        }
      }
    }
    throw StateError(
      'Failed to bind data transport in ${portRange.start}-${portRange.end}: '
      '$lastError',
    );
  }

  @override
  Future<void> send(
    DataPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {
    final socket = _requireSocket();
    socket.send(packet.encode(), address, port);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
    _localEndpoint = null;
    if (!_packetsController.isClosed) {
      await _packetsController.close();
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    final socket = _socket;
    final endpoint = _localEndpoint;
    if (socket == null || endpoint == null) {
      return;
    }
    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      final current = datagram!;
      try {
        _packetsController.add(
          DataDatagram(
            packet: DataPacket.decode(current.data),
            address: current.address,
            port: current.port,
            localEndpoint: endpoint,
          ),
        );
      } on FormatException catch (error, stackTrace) {
        _logger.warning(
          AppLogCategory.transferData,
          'Ignored malformed data datagram',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  RawDatagramSocket _requireSocket() {
    final socket = _socket;
    if (socket == null) {
      throw StateError('Data transport has not been bound.');
    }
    return socket;
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
