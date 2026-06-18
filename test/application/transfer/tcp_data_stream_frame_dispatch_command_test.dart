import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test(
    'creates allowed dispatch decision for registered inbound chunk frame',
    () {
      final registry = _registryWithInboundSession();
      const command = TcpDataStreamFrameDispatchCommand(
        contextCommand: TcpDataStreamFrameChannelContextCommand(),
        dispatcher: TcpDataStreamFrameDispatcher(),
      );

      final decision = command.decide(
        registry: registry,
        received: TcpDataReceivedStreamFrame(
          channelId: const TcpDataChannelId('channel-1'),
          frame: _frame(TcpDataStreamFrameType.chunk),
        ),
      );

      expect(decision.allowed, isTrue);
      expect(decision.route, TcpDataStreamFrameRoute.chunk);
      expect(decision.peerId, 'peer-1');
      expect(decision.authSessionId, 'auth-1');
      expect(decision.transferId, 'transfer-1');
      expect(decision.frame?.sequence, 7);
    },
  );

  test('rejects dispatch decision for missing channel context', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    const command = TcpDataStreamFrameDispatchCommand(
      contextCommand: TcpDataStreamFrameChannelContextCommand(),
      dispatcher: TcpDataStreamFrameDispatcher(),
    );

    final decision = command.decide(
      registry: registry,
      received: TcpDataReceivedStreamFrame(
        channelId: const TcpDataChannelId('missing-channel'),
        frame: _frame(TcpDataStreamFrameType.chunk),
      ),
    );

    expect(decision.allowed, isFalse);
    expect(decision.issueCode, 'missing_tcp_data_channel_context');
    expect(decision.route, isNull);
    expect(decision.frame, isNull);
  });

  test('preserves route for non-chunk TCP stream frame types', () {
    final registry = _registryWithInboundSession();
    const command = TcpDataStreamFrameDispatchCommand(
      contextCommand: TcpDataStreamFrameChannelContextCommand(),
      dispatcher: TcpDataStreamFrameDispatcher(),
    );

    expect(
      command
          .decide(
            registry: registry,
            received: TcpDataReceivedStreamFrame(
              channelId: const TcpDataChannelId('channel-1'),
              frame: _frame(TcpDataStreamFrameType.metadata),
            ),
          )
          .route,
      TcpDataStreamFrameRoute.metadata,
    );
    expect(
      command
          .decide(
            registry: registry,
            received: TcpDataReceivedStreamFrame(
              channelId: const TcpDataChannelId('channel-1'),
              frame: _frame(TcpDataStreamFrameType.complete),
            ),
          )
          .route,
      TcpDataStreamFrameRoute.complete,
    );
    expect(
      command
          .decide(
            registry: registry,
            received: TcpDataReceivedStreamFrame(
              channelId: const TcpDataChannelId('channel-1'),
              frame: _frame(TcpDataStreamFrameType.cancel),
            ),
          )
          .route,
      TcpDataStreamFrameRoute.cancel,
    );
    expect(
      command
          .decide(
            registry: registry,
            received: TcpDataReceivedStreamFrame(
              channelId: const TcpDataChannelId('channel-1'),
              frame: _frame(TcpDataStreamFrameType.error),
            ),
          )
          .route,
      TcpDataStreamFrameRoute.error,
    );
  });
}

InMemoryDataChannelSessionRegistry _registryWithInboundSession() {
  final registry = InMemoryDataChannelSessionRegistry(
    mode: DataChannelMode.tcp,
  );
  registry.register(
    const DataChannelSessionKey(
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      direction: TcpDataChannelDirection.inbound,
    ),
    const TcpDataPeerSessionSnapshot(
      peerId: 'peer-1',
      sessionId: TcpDataSessionId('session-1'),
      channelId: TcpDataChannelId('channel-1'),
      direction: TcpDataChannelDirection.inbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: '10.0.0.1:50000',
      remoteEndpointLabel: '10.0.0.2:50001',
    ),
  );
  return registry;
}

TcpDataStreamFrame _frame(TcpDataStreamFrameType type) {
  return TcpDataStreamFrame(
    type: type,
    transferId: 'transfer-1',
    sequence: 7,
    payload: Uint8List.fromList([1, 2, 3]),
  );
}
