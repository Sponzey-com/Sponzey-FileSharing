import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_transport.dart';

class RawUdpDataTransport implements DataTransport {
  RawUdpDataTransport({required AppLogger logger, DataFrameCodec? frameCodec})
    : _logger = logger,
      _frameCodec = frameCodec ?? const DataFrameCodec();

  final AppLogger _logger;
  final DataFrameCodec _frameCodec;
  final StreamController<DataDatagram> _packetsController =
      StreamController<DataDatagram>.broadcast();
  final StreamController<DataFrameDatagram> _framesController =
      StreamController<DataFrameDatagram>.broadcast();

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  UdpInterfaceEndpoint? _localEndpoint;

  @override
  Stream<DataDatagram> get packets => _packetsController.stream;

  @override
  Stream<DataFrameDatagram> get frames => _framesController.stream;

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
    final bytes = packet.encode();
    final sent = await _sendWithBoundedRetry(socket, bytes, address, port);
    if (sent != bytes.length) {
      throw StateError(
        'Data packet partial send: requested ${bytes.length}, sent $sent.',
      );
    }
  }

  @override
  Future<DataSendResult> sendFrame(
    DataFrame frame, {
    required InternetAddress address,
    required int port,
  }) async {
    try {
      final socket = _requireSocket();
      final bytes = _frameCodec.encode(frame);
      final sent = await _sendWithBoundedRetry(socket, bytes, address, port);
      if (sent != bytes.length) {
        _logger.debug(
          AppLogCategory.transferData,
          'Data frame partial send type=${frame.type.name} '
          'requested=${bytes.length} sent=$sent target=${address.address}:$port',
        );
        return DataSendResult(
          success: false,
          bytesRequested: bytes.length,
          bytesSent: sent,
          reasonCode: 'partialSend',
        );
      }
      return DataSendResult(
        success: true,
        bytesRequested: bytes.length,
        bytesSent: sent,
      );
    } on Object catch (error, stackTrace) {
      _logger.debug(
        AppLogCategory.transferData,
        'Data frame send failed type=${frame.type.name} '
        'target=${address.address}:$port',
        error: error,
        stackTrace: stackTrace,
      );
      return DataSendResult(
        success: false,
        bytesRequested: 0,
        bytesSent: 0,
        reasonCode: 'sendFailed',
      );
    }
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
    if (!_framesController.isClosed) {
      await _framesController.close();
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
        final frame = _frameCodec.decode(current.data);
        _framesController.add(
          DataFrameDatagram(
            frame: frame,
            address: current.address,
            port: current.port,
            localEndpoint: endpoint,
            datagramBytes: current.data.length,
          ),
        );
        continue;
      } on FormatException {
        // Fall through to the legacy JSON DataPacket decoder below.
      }
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

  Future<int> _sendWithBoundedRetry(
    RawDatagramSocket socket,
    List<int> bytes,
    InternetAddress address,
    int port,
  ) async {
    var sent = 0;
    for (var attempt = 0; attempt < 3; attempt += 1) {
      sent = socket.send(bytes, address, port);
      if (sent == bytes.length) {
        return sent;
      }
      await Future<void>.delayed(Duration.zero);
    }
    return sent;
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
}
