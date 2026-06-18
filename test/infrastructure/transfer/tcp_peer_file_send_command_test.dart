import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_outgoing_connected_channel_lookup_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_peer_file_send_command.dart';

void main() {
  test('sends file through connected outbound TCP channel', () async {
    final registry = _registryWithConnectedOutbound();
    final sender = _RecordingStreamSender();
    final command = TcpPeerFileSendCommand(
      channelLookupCommand: const TcpOutgoingConnectedChannelLookupCommand(),
      sender: sender,
    );

    final result = await command.send(
      registry: registry,
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      transferId: 'transfer-1',
      filePath: '/files/report.pdf',
      chunkSize: 8192,
    );

    expect(result.sent, isTrue);
    expect(result.issueCode, isNull);
    expect(sender.calls, ['send:channel-1:transfer-1:/files/report.pdf:8192']);
  });

  test('does not invoke sender when outbound channel is missing', () async {
    final sender = _RecordingStreamSender();
    final command = TcpPeerFileSendCommand(
      channelLookupCommand: const TcpOutgoingConnectedChannelLookupCommand(),
      sender: sender,
    );

    final result = await command.send(
      registry: InMemoryDataChannelSessionRegistry(mode: DataChannelMode.tcp),
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      transferId: 'transfer-1',
      filePath: '/files/report.pdf',
      chunkSize: 8192,
    );

    expect(result.sent, isFalse);
    expect(result.issueCode, 'missing_tcp_outgoing_data_channel');
    expect(sender.calls, isEmpty);
  });

  test('preserves sender failure issue code', () async {
    final sender = _RecordingStreamSender(
      result: const TcpOutgoingTransferStreamSendResult(
        sent: false,
        framesSent: 1,
        bytesSent: 0,
        issueCode: 'tcp_outgoing_stream_send_failed',
      ),
    );
    final command = TcpPeerFileSendCommand(
      channelLookupCommand: const TcpOutgoingConnectedChannelLookupCommand(),
      sender: sender,
    );

    final result = await command.send(
      registry: _registryWithConnectedOutbound(),
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      transferId: 'transfer-1',
      filePath: '/files/report.pdf',
      chunkSize: 8192,
    );

    expect(result.sent, isFalse);
    expect(result.issueCode, 'tcp_outgoing_stream_send_failed');
  });
}

InMemoryDataChannelSessionRegistry _registryWithConnectedOutbound() {
  final registry = InMemoryDataChannelSessionRegistry(
    mode: DataChannelMode.tcp,
  );
  registry.register(
    const DataChannelSessionKey(
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      direction: TcpDataChannelDirection.outbound,
    ),
    const TcpDataPeerSessionSnapshot(
      peerId: 'peer-1',
      sessionId: TcpDataSessionId('session-1'),
      channelId: TcpDataChannelId('channel-1'),
      direction: TcpDataChannelDirection.outbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: '10.0.0.1:50000',
      remoteEndpointLabel: '10.0.0.2:50001',
    ),
  );
  return registry;
}

class _RecordingStreamSender implements TcpOutgoingTransferStreamSenderPort {
  _RecordingStreamSender({
    this.result = const TcpOutgoingTransferStreamSendResult(
      sent: true,
      framesSent: 3,
      bytesSent: 1024,
    ),
  });

  final TcpOutgoingTransferStreamSendResult result;
  final List<String> calls = [];

  @override
  Future<TcpOutgoingTransferStreamSendResult> send({
    required TcpDataChannelId channelId,
    required String transferId,
    required String filePath,
    required int chunkSize,
    void Function(TcpOutgoingTransferStreamProgress progress)? onProgress,
  }) async {
    calls.add('send:${channelId.value}:$transferId:$filePath:$chunkSize');
    return result;
  }
}
