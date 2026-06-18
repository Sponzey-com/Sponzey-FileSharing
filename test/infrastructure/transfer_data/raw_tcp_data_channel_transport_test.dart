import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_session_hello_codec.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_frame_codec.dart';

void main() {
  test('listener and connector establish a loopback TCP channel', () async {
    final listener = RawTcpDataListener(logger: _MemoryLogger());
    final connector = RawTcpDataConnector(logger: _MemoryLogger());
    addTearDown(listener.close);
    addTearDown(connector.close);

    final binding = await listener.bind(
      const TcpDataListenerBindRequest(host: '127.0.0.1', port: 0),
    );

    expect(binding.host, '127.0.0.1');
    expect(binding.port, greaterThan(0));

    final acceptedFuture = listener.acceptedConnections.first.timeout(
      const Duration(seconds: 2),
    );
    final channelId = await connector.connect(
      TcpDataConnectRequest(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        sessionId: const TcpDataSessionId('session-1'),
        host: binding.host,
        port: binding.port,
      ),
    );

    final accepted = await acceptedFuture;

    expect(channelId.value, startsWith('tcp-out-'));
    expect(accepted.channelId.value, startsWith('tcp-in-'));
    expect(accepted.localEndpoint.port, binding.port);
    expect(accepted.remoteEndpoint.port, greaterThan(0));
  });

  test('connector writes hello and listener receives decoded hello', () async {
    final listener = RawTcpDataListener(logger: _MemoryLogger());
    final connector = RawTcpDataConnector(logger: _MemoryLogger());
    addTearDown(listener.close);
    addTearDown(connector.close);

    final binding = await listener.bind(
      const TcpDataListenerBindRequest(host: '127.0.0.1', port: 0),
    );
    final acceptedFuture = listener.acceptedConnections.first.timeout(
      const Duration(seconds: 2),
    );
    final helloFuture = listener.hellos.first.timeout(
      const Duration(seconds: 2),
    );

    final channelId = await connector.connect(
      TcpDataConnectRequest(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        sessionId: const TcpDataSessionId('session-1'),
        host: binding.host,
        port: binding.port,
      ),
    );
    final accepted = await acceptedFuture;
    await connector.sendHello(
      channelId,
      const TcpDataSessionHello(
        sessionId: TcpDataSessionId('session-1'),
        peerId: 'peer-1',
        instanceId: 'instance-1',
        authSessionId: 'auth-1',
        protocolVersion: 1,
        dataProtocolVersion: 1,
        proof: 'proof-1',
      ),
    );

    final received = await helloFuture;

    expect(accepted.channelId, received.channelId);
    expect(received.hello.peerId, 'peer-1');
    expect(received.hello.authSessionId, 'auth-1');
  });

  test('malformed hello frame is isolated as listener error', () async {
    final listener = RawTcpDataListener(logger: _MemoryLogger());
    addTearDown(listener.close);

    final binding = await listener.bind(
      const TcpDataListenerBindRequest(host: '127.0.0.1', port: 0),
    );
    final errorFuture = listener.helloErrors.first.timeout(
      const Duration(seconds: 2),
    );

    final socket = await Socket.connect(binding.host, binding.port);
    addTearDown(socket.destroy);
    socket.add(_lengthPrefixedJson({'type': 'WRONG_HELLO'}));
    await socket.flush();

    final error = await errorFuture;

    expect(error.issueCode, 'malformed_tcp_data_hello');
    expect(
      listener.hellos.timeout(const Duration(milliseconds: 100)).first,
      throwsA(isA<TimeoutException>()),
    );
  });

  test(
    'connector writes stream frame after hello and listener receives it',
    () async {
      final TcpDataListenerPort listener = RawTcpDataListener(
        logger: _MemoryLogger(),
      );
      final connector = RawTcpDataConnector(logger: _MemoryLogger());
      addTearDown(listener.close);
      addTearDown(connector.close);

      final binding = await listener.bind(
        const TcpDataListenerBindRequest(host: '127.0.0.1', port: 0),
      );
      final acceptedFuture = listener.acceptedConnections.first.timeout(
        const Duration(seconds: 2),
      );
      final helloFuture = listener.hellos.first.timeout(
        const Duration(seconds: 2),
      );
      final frameFuture = listener.frames.first.timeout(
        const Duration(seconds: 2),
      );

      final channelId = await connector.connect(
        TcpDataConnectRequest(
          peerId: 'peer-1',
          authSessionId: 'auth-1',
          sessionId: const TcpDataSessionId('session-1'),
          host: binding.host,
          port: binding.port,
        ),
      );
      await connector.sendHello(
        channelId,
        const TcpDataSessionHello(
          sessionId: TcpDataSessionId('session-1'),
          peerId: 'peer-1',
          instanceId: 'instance-1',
          authSessionId: 'auth-1',
          protocolVersion: 1,
          dataProtocolVersion: 1,
          proof: 'proof-1',
        ),
      );
      await connector.sendFrame(
        channelId,
        TcpDataStreamFrame(
          type: TcpDataStreamFrameType.chunk,
          transferId: 'transfer-1',
          sequence: 1,
          payload: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final accepted = await acceptedFuture;
      final hello = await helloFuture;
      final received = await frameFuture;

      expect(hello.channelId, accepted.channelId);
      expect(received.channelId, accepted.channelId);
      expect(received.frame.type, TcpDataStreamFrameType.chunk);
      expect(received.frame.transferId, 'transfer-1');
      expect(received.frame.sequence, 1);
      expect(received.frame.payload, [1, 2, 3]);
    },
  );

  test('malformed stream frame is isolated from hello errors', () async {
    final listener = RawTcpDataListener(logger: _MemoryLogger());
    addTearDown(listener.close);

    final binding = await listener.bind(
      const TcpDataListenerBindRequest(host: '127.0.0.1', port: 0),
    );
    final frameErrorFuture = listener.frameErrors.first.timeout(
      const Duration(seconds: 2),
    );

    final socket = await Socket.connect(binding.host, binding.port);
    addTearDown(socket.destroy);
    socket.add(
      const TcpDataSessionHelloCodec().encode(
        const TcpDataSessionHello(
          sessionId: TcpDataSessionId('session-1'),
          peerId: 'peer-1',
          instanceId: 'instance-1',
          authSessionId: 'auth-1',
          protocolVersion: 1,
          dataProtocolVersion: 1,
          proof: 'proof-1',
        ),
      ),
    );
    final frame = const TcpDataStreamFrameCodec().encode(
      TcpDataStreamFrame(
        type: TcpDataStreamFrameType.chunk,
        transferId: 'transfer-1',
        sequence: 1,
        payload: Uint8List(0),
      ),
    );
    frame[4] = 0x58;
    socket.add(frame);
    await socket.flush();

    final error = await frameErrorFuture;

    expect(error.issueCode, 'malformed_tcp_data_stream_frame');
    expect(
      listener.helloErrors.timeout(const Duration(milliseconds: 100)).first,
      throwsA(isA<TimeoutException>()),
    );
  });
}

Uint8List _lengthPrefixedJson(Map<String, Object?> body) {
  final payload = utf8.encode(jsonEncode(body));
  final frame = Uint8List(4 + payload.length);
  ByteData.view(frame.buffer).setUint32(0, payload.length, Endian.big);
  frame.setRange(4, frame.length, payload);
  return frame;
}

class _MemoryLogger implements AppLogger {
  @override
  AppLogLevel get minimumLevel => AppLogLevel.debug;

  @override
  void debug(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void error(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void info(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warning(
    AppLogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
