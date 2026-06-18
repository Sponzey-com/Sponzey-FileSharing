import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

class TcpDataEndpoint {
  const TcpDataEndpoint({required this.host, required this.port});

  final String host;
  final int port;

  bool get hasValidPort => port > 0 && port <= 65535;
}

class TcpDataAcceptedConnection {
  const TcpDataAcceptedConnection({
    required this.channelId,
    required this.localEndpoint,
    required this.remoteEndpoint,
  });

  final TcpDataChannelId channelId;
  final TcpDataEndpoint localEndpoint;
  final TcpDataEndpoint remoteEndpoint;
}

class TcpDataReceivedHello {
  const TcpDataReceivedHello({required this.channelId, required this.hello});

  final TcpDataChannelId channelId;
  final TcpDataSessionHello hello;
}

class TcpDataReceivedHelloError {
  const TcpDataReceivedHelloError({
    required this.channelId,
    required this.issueCode,
    required this.error,
  });

  final TcpDataChannelId channelId;
  final String issueCode;
  final Object error;
}

class TcpDataReceivedStreamFrame {
  const TcpDataReceivedStreamFrame({
    required this.channelId,
    required this.frame,
  });

  final TcpDataChannelId channelId;
  final TcpDataStreamFrame frame;
}

class TcpDataReceivedStreamFrameError {
  const TcpDataReceivedStreamFrameError({
    required this.channelId,
    required this.issueCode,
    required this.error,
  });

  final TcpDataChannelId channelId;
  final String issueCode;
  final Object error;
}

class TcpDataEndpointOffer {
  const TcpDataEndpointOffer({
    required this.peerId,
    required this.authSessionId,
    required this.sessionId,
    required this.host,
    required this.port,
  });

  final String peerId;
  final String authSessionId;
  final TcpDataSessionId sessionId;
  final String host;
  final int port;

  TcpDataEndpoint get endpoint => TcpDataEndpoint(host: host, port: port);
}

class TcpDataConnectRequest {
  const TcpDataConnectRequest({
    required this.peerId,
    required this.authSessionId,
    required this.sessionId,
    required this.host,
    required this.port,
  });

  final String peerId;
  final String authSessionId;
  final TcpDataSessionId sessionId;
  final String host;
  final int port;
}

class TcpDataListenerBindRequest {
  const TcpDataListenerBindRequest({required this.host, required this.port});

  final String host;
  final int port;
}

class TcpDataListenerBinding {
  const TcpDataListenerBinding({required this.host, required this.port});

  final String host;
  final int port;
}

abstract interface class TcpDataListenerPort {
  Stream<TcpDataAcceptedConnection> get acceptedConnections;

  Stream<TcpDataReceivedHello> get hellos;

  Stream<TcpDataReceivedHelloError> get helloErrors;

  Stream<TcpDataReceivedStreamFrame> get frames;

  Stream<TcpDataReceivedStreamFrameError> get frameErrors;

  Future<TcpDataListenerBinding> bind(TcpDataListenerBindRequest request);

  Future<void> close();
}

abstract interface class TcpDataConnectorPort {
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request);

  Future<void> sendHello(TcpDataChannelId channelId, TcpDataSessionHello hello);

  Future<void> sendFrame(TcpDataChannelId channelId, TcpDataStreamFrame frame);

  Future<void> close();
}
