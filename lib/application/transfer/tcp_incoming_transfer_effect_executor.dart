import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';

abstract interface class TcpIncomingTransferPayloadWriterPort {
  Future<void> open(TcpIncomingTransferFrameContextKey key);

  Future<void> writeChunk(
    TcpIncomingTransferFrameContextKey key,
    List<int> payload,
  );

  Future<void> verify(TcpIncomingTransferFrameContextKey key);

  Future<void> finalize(TcpIncomingTransferFrameContextKey key);

  Future<void> complete(TcpIncomingTransferFrameContextKey key);

  Future<void> cancel(TcpIncomingTransferFrameContextKey key);

  Future<void> cleanup(TcpIncomingTransferFrameContextKey key);

  Future<void> fail(TcpIncomingTransferFrameContextKey key);
}

class TcpIncomingTransferEffectExecutor
    implements IncomingTransferSessionEffectExecutor {
  const TcpIncomingTransferEffectExecutor({
    required this.key,
    required this.frameContextStore,
    required this.writer,
  });

  final TcpIncomingTransferFrameContextKey key;
  final TcpIncomingTransferFrameContextStore frameContextStore;
  final TcpIncomingTransferPayloadWriterPort writer;

  @override
  Future<void> openIncomingWriter() {
    return writer.open(key);
  }

  @override
  Future<void> writeChunk() {
    final context = frameContextStore.lookup(key);
    if (context == null || context.route != TcpDataStreamFrameRoute.chunk) {
      return Future<void>.error(
        StateError('missing_tcp_incoming_frame_context:${key.transferId}'),
      );
    }
    return writer.writeChunk(key, context.frame.payload);
  }

  @override
  Future<void> verifyIncomingDigest() {
    return writer.verify(key);
  }

  @override
  Future<void> finalizeFile() {
    return writer.finalize(key);
  }

  @override
  Future<void> completeTransfer() {
    return writer.complete(key);
  }

  @override
  Future<void> cancelTransfer() {
    return writer.cancel(key);
  }

  @override
  Future<void> cleanupPartialFile() {
    return writer.cleanup(key);
  }

  @override
  Future<void> failTransfer() {
    return writer.fail(key);
  }

  @override
  Future<void> prepareStorage() async {}

  @override
  Future<void> rejectTransferInit() async {}

  @override
  Future<void> sendTransferInitAck() async {}

  @override
  Future<void> bufferOutOfOrderChunk() async {}

  @override
  Future<void> flushBufferedChunks() async {}

  @override
  Future<void> scheduleAckBatch() async {}

  @override
  Future<void> scheduleNackBatch() async {}

  @override
  Future<void> completeCancellation() async {}
}
