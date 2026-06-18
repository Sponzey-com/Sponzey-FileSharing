import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test('resolves context for registered inbound channel', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(
      const DataChannelSessionKey(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        direction: TcpDataChannelDirection.inbound,
      ),
      _session(direction: TcpDataChannelDirection.inbound),
    );
    const command = TcpDataStreamFrameChannelContextCommand();

    final result = command.resolve(
      registry: registry,
      received: TcpDataReceivedStreamFrame(
        channelId: const TcpDataChannelId('channel-1'),
        frame: _frame(),
      ),
    );

    expect(result.allowed, isTrue);
    expect(result.peerId, 'peer-1');
    expect(result.authSessionId, 'auth-1');
    expect(result.session?.sessionId.value, 'session-1');
  });

  test('rejects stream frame from missing channel', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    const command = TcpDataStreamFrameChannelContextCommand();

    final result = command.resolve(
      registry: registry,
      received: TcpDataReceivedStreamFrame(
        channelId: const TcpDataChannelId('missing-channel'),
        frame: _frame(),
      ),
    );

    expect(result.allowed, isFalse);
    expect(result.issueCode, 'missing_tcp_data_channel_context');
  });

  test('rejects outbound-only channel for inbound stream frame', () {
    final registry = InMemoryDataChannelSessionRegistry(
      mode: DataChannelMode.tcp,
    );
    registry.register(
      const DataChannelSessionKey(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        direction: TcpDataChannelDirection.outbound,
      ),
      _session(direction: TcpDataChannelDirection.outbound),
    );
    const command = TcpDataStreamFrameChannelContextCommand();

    final result = command.resolve(
      registry: registry,
      received: TcpDataReceivedStreamFrame(
        channelId: const TcpDataChannelId('channel-1'),
        frame: _frame(),
      ),
    );

    expect(result.allowed, isFalse);
    expect(result.issueCode, 'missing_tcp_data_channel_context');
  });
}

TcpDataPeerSessionSnapshot _session({
  required TcpDataChannelDirection direction,
}) {
  return TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: const TcpDataSessionId('session-1'),
    channelId: const TcpDataChannelId('channel-1'),
    direction: direction,
    status: TcpDataPeerSessionStatus.connected,
    localEndpointLabel: '10.0.0.1:50000',
    remoteEndpointLabel: '10.0.0.2:50001',
  );
}

TcpDataStreamFrame _frame() {
  return TcpDataStreamFrame(
    type: TcpDataStreamFrameType.chunk,
    transferId: 'transfer-1',
    sequence: 1,
    payload: Uint8List(0),
  );
}
