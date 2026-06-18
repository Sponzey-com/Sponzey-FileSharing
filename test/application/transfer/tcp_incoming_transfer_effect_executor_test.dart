import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_effect_executor.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  const key = TcpIncomingTransferFrameContextKey(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    transferId: 'transfer-1',
  );

  test('writeChunk writes staged chunk payload through writer port', () async {
    final store = InMemoryTcpIncomingTransferFrameContextStore();
    final writer = _RecordingPayloadWriter();
    final executor = TcpIncomingTransferEffectExecutor(
      key: key,
      frameContextStore: store,
      writer: writer,
    );
    store.stage(key, _context(key, TcpDataStreamFrameRoute.chunk));

    await executor.writeChunk();

    expect(writer.calls, ['writeChunk:transfer-1:3']);
    expect(writer.lastPayload, [1, 2, 3]);
  });

  test('writeChunk fails when staged context is missing', () async {
    final executor = TcpIncomingTransferEffectExecutor(
      key: key,
      frameContextStore: InMemoryTcpIncomingTransferFrameContextStore(),
      writer: _RecordingPayloadWriter(),
    );

    expect(
      executor.writeChunk,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('missing_tcp_incoming_frame_context'),
        ),
      ),
    );
  });

  test('lifecycle effects delegate to writer port', () async {
    final writer = _RecordingPayloadWriter();
    final executor = TcpIncomingTransferEffectExecutor(
      key: key,
      frameContextStore: InMemoryTcpIncomingTransferFrameContextStore(),
      writer: writer,
    );

    await executor.openIncomingWriter();
    await executor.verifyIncomingDigest();
    await executor.finalizeFile();
    await executor.cancelTransfer();
    await executor.cleanupPartialFile();
    await executor.completeTransfer();
    await executor.failTransfer();

    expect(writer.calls, [
      'open:transfer-1',
      'verify:transfer-1',
      'finalize:transfer-1',
      'cancel:transfer-1',
      'cleanup:transfer-1',
      'complete:transfer-1',
      'fail:transfer-1',
    ]);
  });
}

TcpIncomingTransferFrameContext _context(
  TcpIncomingTransferFrameContextKey key,
  TcpDataStreamFrameRoute route,
) {
  return TcpIncomingTransferFrameContext(
    key: key,
    route: route,
    frame: TcpDataStreamFrame(
      type: TcpDataStreamFrameType.chunk,
      transferId: key.transferId,
      sequence: 1,
      payload: Uint8List.fromList([1, 2, 3]),
    ),
    session: const TcpDataPeerSessionSnapshot(
      peerId: 'peer-1',
      sessionId: TcpDataSessionId('session-1'),
      channelId: TcpDataChannelId('channel-1'),
      direction: TcpDataChannelDirection.inbound,
      status: TcpDataPeerSessionStatus.connected,
      localEndpointLabel: '10.0.0.1:50000',
      remoteEndpointLabel: '10.0.0.2:50001',
    ),
  );
}

class _RecordingPayloadWriter implements TcpIncomingTransferPayloadWriterPort {
  final List<String> calls = [];
  List<int>? lastPayload;

  @override
  Future<void> cancel(TcpIncomingTransferFrameContextKey key) async {
    calls.add('cancel:${key.transferId}');
  }

  @override
  Future<void> cleanup(TcpIncomingTransferFrameContextKey key) async {
    calls.add('cleanup:${key.transferId}');
  }

  @override
  Future<void> complete(TcpIncomingTransferFrameContextKey key) async {
    calls.add('complete:${key.transferId}');
  }

  @override
  Future<void> fail(TcpIncomingTransferFrameContextKey key) async {
    calls.add('fail:${key.transferId}');
  }

  @override
  Future<void> finalize(TcpIncomingTransferFrameContextKey key) async {
    calls.add('finalize:${key.transferId}');
  }

  @override
  Future<void> open(TcpIncomingTransferFrameContextKey key) async {
    calls.add('open:${key.transferId}');
  }

  @override
  Future<void> verify(TcpIncomingTransferFrameContextKey key) async {
    calls.add('verify:${key.transferId}');
  }

  @override
  Future<void> writeChunk(
    TcpIncomingTransferFrameContextKey key,
    List<int> payload,
  ) async {
    calls.add('writeChunk:${key.transferId}:${payload.length}');
    lastPayload = List<int>.from(payload);
  }
}
