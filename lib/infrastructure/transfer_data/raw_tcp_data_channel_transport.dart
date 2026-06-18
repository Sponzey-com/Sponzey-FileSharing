import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_session_hello_codec.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_frame_codec.dart';

class RawTcpDataListener implements TcpDataListenerPort {
  RawTcpDataListener({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  final StreamController<TcpDataAcceptedConnection> _acceptedController =
      StreamController<TcpDataAcceptedConnection>.broadcast();
  final StreamController<TcpDataReceivedHello> _helloController =
      StreamController<TcpDataReceivedHello>.broadcast();
  final StreamController<TcpDataReceivedHelloError> _helloErrorController =
      StreamController<TcpDataReceivedHelloError>.broadcast();
  final StreamController<TcpDataReceivedStreamFrame> _frameController =
      StreamController<TcpDataReceivedStreamFrame>.broadcast();
  final StreamController<TcpDataReceivedStreamFrameError>
  _frameErrorController =
      StreamController<TcpDataReceivedStreamFrameError>.broadcast();
  final TcpDataSessionHelloCodec _helloCodec = const TcpDataSessionHelloCodec();
  final TcpDataStreamFrameCodec _frameCodec = const TcpDataStreamFrameCodec();
  final List<Socket> _acceptedSockets = [];
  final List<StreamSubscription<List<int>>> _socketSubscriptions = [];

  ServerSocket? _server;
  StreamSubscription<Socket>? _subscription;
  TcpDataListenerBinding? _binding;
  var _nextChannelIndex = 0;

  @override
  Stream<TcpDataAcceptedConnection> get acceptedConnections =>
      _acceptedController.stream;

  @override
  Stream<TcpDataReceivedHello> get hellos => _helloController.stream;

  @override
  Stream<TcpDataReceivedHelloError> get helloErrors =>
      _helloErrorController.stream;

  @override
  Stream<TcpDataReceivedStreamFrame> get frames => _frameController.stream;

  @override
  Stream<TcpDataReceivedStreamFrameError> get frameErrors =>
      _frameErrorController.stream;

  @override
  Future<TcpDataListenerBinding> bind(
    TcpDataListenerBindRequest request,
  ) async {
    final existing = _binding;
    if (existing != null) {
      return existing;
    }

    final server = await ServerSocket.bind(
      InternetAddress(request.host),
      request.port,
    );
    final binding = TcpDataListenerBinding(
      host: server.address.address,
      port: server.port,
    );
    _server = server;
    _binding = binding;
    _subscription = server.listen(
      (socket) => _handleAcceptedSocket(socket, binding),
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning(
          AppLogCategory.transferData,
          'TCP data listener accept failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    return binding;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _server?.close();
    _server = null;
    _binding = null;
    for (final socket in _acceptedSockets) {
      socket.destroy();
    }
    for (final subscription in _socketSubscriptions) {
      await subscription.cancel();
    }
    _socketSubscriptions.clear();
    _acceptedSockets.clear();
    if (!_acceptedController.isClosed) {
      await _acceptedController.close();
    }
    if (!_helloController.isClosed) {
      await _helloController.close();
    }
    if (!_helloErrorController.isClosed) {
      await _helloErrorController.close();
    }
    if (!_frameController.isClosed) {
      await _frameController.close();
    }
    if (!_frameErrorController.isClosed) {
      await _frameErrorController.close();
    }
  }

  void _handleAcceptedSocket(Socket socket, TcpDataListenerBinding binding) {
    _acceptedSockets.add(socket);
    final channelId = TcpDataChannelId('tcp-in-${_nextChannelIndex++}');
    final buffer = TcpDataLengthPrefixedFrameBuffer();
    var helloReceived = false;
    _socketSubscriptions.add(
      socket.listen((bytes) {
        for (final frame in buffer.add(bytes)) {
          if (!helloReceived) {
            helloReceived = _emitHelloFrame(channelId, frame);
            continue;
          }

          _emitStreamFrame(channelId, frame);
        }
      }),
    );
    _acceptedController.add(
      TcpDataAcceptedConnection(
        channelId: channelId,
        localEndpoint: TcpDataEndpoint(host: binding.host, port: binding.port),
        remoteEndpoint: TcpDataEndpoint(
          host: socket.remoteAddress.address,
          port: socket.remotePort,
        ),
      ),
    );
    _logger.debug(
      AppLogCategory.transferData,
      'TCP data listener accepted channel ${channelId.value}',
    );
  }

  bool _emitHelloFrame(TcpDataChannelId channelId, List<int> frame) {
    try {
      _helloController.add(
        TcpDataReceivedHello(
          channelId: channelId,
          hello: _helloCodec.decode(frame),
        ),
      );
      return true;
    } on FormatException catch (error) {
      _helloErrorController.add(
        TcpDataReceivedHelloError(
          channelId: channelId,
          issueCode: 'malformed_tcp_data_hello',
          error: error,
        ),
      );
      return false;
    }
  }

  void _emitStreamFrame(TcpDataChannelId channelId, List<int> frame) {
    try {
      _frameController.add(
        TcpDataReceivedStreamFrame(
          channelId: channelId,
          frame: _frameCodec.decode(frame),
        ),
      );
    } on FormatException catch (error) {
      _frameErrorController.add(
        TcpDataReceivedStreamFrameError(
          channelId: channelId,
          issueCode: 'malformed_tcp_data_stream_frame',
          error: error,
        ),
      );
    }
  }
}

class RawTcpDataConnector implements TcpDataConnectorPort {
  RawTcpDataConnector({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;
  final TcpDataSessionHelloCodec _helloCodec = const TcpDataSessionHelloCodec();
  final TcpDataStreamFrameCodec _frameCodec = const TcpDataStreamFrameCodec();
  final Map<TcpDataChannelId, Socket> _sockets = {};
  var _nextChannelIndex = 0;

  @override
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request) async {
    final socket = await Socket.connect(request.host, request.port);
    final channelId = TcpDataChannelId('tcp-out-${_nextChannelIndex++}');
    _sockets[channelId] = socket;
    _logger.debug(
      AppLogCategory.transferData,
      'TCP data connector opened channel ${channelId.value}',
    );
    return channelId;
  }

  @override
  Future<void> sendHello(
    TcpDataChannelId channelId,
    TcpDataSessionHello hello,
  ) async {
    final socket = _sockets[channelId];
    if (socket == null) {
      throw StateError('TCP data channel ${channelId.value} is not connected.');
    }
    socket.add(_helloCodec.encode(hello));
    await socket.flush();
  }

  @override
  Future<void> sendFrame(
    TcpDataChannelId channelId,
    TcpDataStreamFrame frame,
  ) async {
    final socket = _sockets[channelId];
    if (socket == null) {
      throw StateError('TCP data channel ${channelId.value} is not connected.');
    }
    socket.add(_frameCodec.encode(frame));
    await socket.flush();
  }

  @override
  Future<void> close() async {
    for (final socket in _sockets.values) {
      socket.destroy();
    }
    _sockets.clear();
  }
}
