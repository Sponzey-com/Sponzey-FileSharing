import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test('stages allowed frame decision by peer auth and transfer id', () {
    final store = InMemoryTcpIncomingTransferFrameContextStore();
    const command = TcpIncomingTransferFrameContextStageCommand();

    final result = command.stage(store: store, decision: _decision());

    expect(result.staged, isTrue);
    final context = store.lookup(
      const TcpIncomingTransferFrameContextKey(
        peerId: 'peer-1',
        authSessionId: 'auth-1',
        transferId: 'transfer-1',
      ),
    );
    expect(context?.route, TcpDataStreamFrameRoute.chunk);
    expect(context?.frame.payload, [1, 2, 3]);
  });

  test('clear removes staged frame context', () {
    final store = InMemoryTcpIncomingTransferFrameContextStore();
    const key = TcpIncomingTransferFrameContextKey(
      peerId: 'peer-1',
      authSessionId: 'auth-1',
      transferId: 'transfer-1',
    );
    store.stage(
      key,
      TcpIncomingTransferFrameContext(
        key: key,
        route: TcpDataStreamFrameRoute.chunk,
        frame: _frame(),
        session: _session(),
      ),
    );

    expect(store.lookup(key), isNotNull);
    expect(store.clear(key), isNotNull);
    expect(store.lookup(key), isNull);
  });

  test('denied decision is not staged', () {
    final store = InMemoryTcpIncomingTransferFrameContextStore();
    const command = TcpIncomingTransferFrameContextStageCommand();

    final result = command.stage(
      store: store,
      decision: const TcpDataStreamFrameDispatchDecision(
        allowed: false,
        issueCode: 'missing_tcp_data_channel_context',
      ),
    );

    expect(result.staged, isFalse);
    expect(result.issueCode, 'tcp_stream_frame_context_not_allowed');
    expect(store.entries, isEmpty);
  });
}

TcpDataStreamFrameDispatchDecision _decision() {
  return TcpDataStreamFrameDispatchDecision(
    allowed: true,
    route: TcpDataStreamFrameRoute.chunk,
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    session: _session(),
    transferId: 'transfer-1',
    frame: _frame(),
  );
}

TcpDataPeerSessionSnapshot _session() {
  return const TcpDataPeerSessionSnapshot(
    peerId: 'peer-1',
    sessionId: TcpDataSessionId('session-1'),
    channelId: TcpDataChannelId('channel-1'),
    direction: TcpDataChannelDirection.inbound,
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
    payload: Uint8List.fromList([1, 2, 3]),
  );
}
