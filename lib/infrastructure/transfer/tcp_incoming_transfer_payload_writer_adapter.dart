import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_effect_executor.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';

typedef TcpIncomingPayloadYieldScheduler = Future<void> Function();

class TcpIncomingTransferPayloadWriterSession {
  TcpIncomingTransferPayloadWriterSession({
    required this.key,
    required this.tempFilePath,
    required this.destinationDirectory,
    required this.fileName,
    required this.expectedSha256,
    required this.writer,
  });

  final TcpIncomingTransferFrameContextKey key;
  final String tempFilePath;
  final String destinationDirectory;
  final String fileName;
  final String? expectedSha256;
  final IncomingDigestingTransferWriter writer;

  String? actualSha256;
  String? finalPath;
  int chunksWritten = 0;
  int bytesWrittenSinceYield = 0;
  bool writerClosed = false;
  bool finalized = false;
}

abstract interface class TcpIncomingTransferPayloadWriterSessionRegistry {
  Map<
    TcpIncomingTransferFrameContextKey,
    TcpIncomingTransferPayloadWriterSession
  >
  get entries;

  void register(TcpIncomingTransferPayloadWriterSession session);

  TcpIncomingTransferPayloadWriterSession? lookup(
    TcpIncomingTransferFrameContextKey key,
  );

  TcpIncomingTransferPayloadWriterSession? remove(
    TcpIncomingTransferFrameContextKey key,
  );
}

class InMemoryTcpIncomingTransferPayloadWriterSessionRegistry
    implements TcpIncomingTransferPayloadWriterSessionRegistry {
  final Map<
    TcpIncomingTransferFrameContextKey,
    TcpIncomingTransferPayloadWriterSession
  >
  _entries = {};

  @override
  Map<
    TcpIncomingTransferFrameContextKey,
    TcpIncomingTransferPayloadWriterSession
  >
  get entries => Map.unmodifiable(_entries);

  @override
  TcpIncomingTransferPayloadWriterSession? lookup(
    TcpIncomingTransferFrameContextKey key,
  ) {
    return _entries[key];
  }

  @override
  void register(TcpIncomingTransferPayloadWriterSession session) {
    _entries[session.key] = session;
  }

  @override
  TcpIncomingTransferPayloadWriterSession? remove(
    TcpIncomingTransferFrameContextKey key,
  ) {
    return _entries.remove(key);
  }
}

class TcpIncomingTransferPayloadWriterAdapter
    implements TcpIncomingTransferPayloadWriterPort {
  const TcpIncomingTransferPayloadWriterAdapter({
    required this.registry,
    required this.fileService,
    this.yieldEveryChunks = 32,
    this.yieldAfterBytes = 2 * 1024 * 1024,
    this.yieldScheduler = _defaultYieldScheduler,
  });

  final TcpIncomingTransferPayloadWriterSessionRegistry registry;
  final TransferFileService fileService;
  final int yieldEveryChunks;
  final int yieldAfterBytes;
  final TcpIncomingPayloadYieldScheduler yieldScheduler;

  @override
  Future<void> open(TcpIncomingTransferFrameContextKey key) async {
    _requireSession(key);
  }

  @override
  Future<void> writeChunk(
    TcpIncomingTransferFrameContextKey key,
    List<int> payload,
  ) async {
    final session = _requireSession(key);
    try {
      await session.writer.append(payload);
      session.chunksWritten += 1;
      session.bytesWrittenSinceYield += payload.length;
      if (_shouldYield(session)) {
        session.bytesWrittenSinceYield = 0;
        await yieldScheduler();
      }
    } catch (_) {
      throw const AppException(
        code: 'tcp_incoming_payload_write_failed',
        message: '수신 TCP data chunk를 저장하지 못했습니다.',
      );
    }
  }

  @override
  Future<void> verify(TcpIncomingTransferFrameContextKey key) async {
    final session = _requireSession(key);
    final actual = await _closeWithDigest(session);
    final expected = session.expectedSha256;
    if (expected != null && expected.isNotEmpty && actual != expected) {
      throw const AppException(
        code: 'tcp_incoming_payload_digest_mismatch',
        message: '수신 파일 검증에 실패했습니다.',
      );
    }
  }

  @override
  Future<void> finalize(TcpIncomingTransferFrameContextKey key) async {
    final session = _requireSession(key);
    try {
      session.finalPath = await fileService.finalizeIncomingFile(
        tempFilePath: session.tempFilePath,
        destinationDirectory: session.destinationDirectory,
        fileName: session.fileName,
      );
      session.finalized = true;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        code: 'tcp_incoming_payload_finalize_failed',
        message: '수신 TCP 파일을 최종 저장 경로로 이동하지 못했습니다.',
      );
    }
  }

  @override
  Future<void> complete(TcpIncomingTransferFrameContextKey key) async {
    registry.remove(key);
  }

  @override
  Future<void> cancel(TcpIncomingTransferFrameContextKey key) {
    return _closeDiscardAndRemove(key);
  }

  @override
  Future<void> cleanup(TcpIncomingTransferFrameContextKey key) {
    return _closeDiscardAndRemove(key);
  }

  @override
  Future<void> fail(TcpIncomingTransferFrameContextKey key) {
    return _closeDiscardAndRemove(key);
  }

  TcpIncomingTransferPayloadWriterSession _requireSession(
    TcpIncomingTransferFrameContextKey key,
  ) {
    final session = registry.lookup(key);
    if (session == null) {
      throw const AppException(
        code: 'tcp_incoming_payload_writer_missing',
        message: '수신 TCP writer session을 찾을 수 없습니다.',
      );
    }
    return session;
  }

  bool _shouldYield(TcpIncomingTransferPayloadWriterSession session) {
    final chunkThresholdReached =
        yieldEveryChunks > 0 && session.chunksWritten % yieldEveryChunks == 0;
    final byteThresholdReached =
        yieldAfterBytes > 0 &&
        session.bytesWrittenSinceYield >= yieldAfterBytes;
    return chunkThresholdReached || byteThresholdReached;
  }

  Future<String> _closeWithDigest(
    TcpIncomingTransferPayloadWriterSession session,
  ) async {
    if (session.actualSha256 != null) {
      return session.actualSha256!;
    }
    try {
      final digest = await session.writer.closeWithDigest();
      session.writerClosed = true;
      session.actualSha256 = digest;
      return digest;
    } catch (_) {
      throw const AppException(
        code: 'tcp_incoming_payload_verify_failed',
        message: '수신 TCP 파일 digest를 계산하지 못했습니다.',
      );
    }
  }

  Future<void> _closeDiscardAndRemove(
    TcpIncomingTransferFrameContextKey key,
  ) async {
    final session = registry.remove(key);
    if (session == null) {
      return;
    }
    if (!session.writerClosed) {
      try {
        await session.writer.close();
      } catch (_) {
        // Cleanup remains best-effort after cancellation or failure.
      }
      session.writerClosed = true;
    }
    if (!session.finalized) {
      try {
        await fileService.discardDraft(session.tempFilePath);
      } catch (_) {
        // Cleanup remains best-effort after cancellation or failure.
      }
    }
  }
}

Future<void> _defaultYieldScheduler() {
  return Future<void>.delayed(const Duration(milliseconds: 1));
}
