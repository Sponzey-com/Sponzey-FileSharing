import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';

void main() {
  const key = TcpIncomingTransferFrameContextKey(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    transferId: 'transfer-1',
  );

  test('writes chunk payload to the registered digesting writer', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final writer = _RecordingDigestingWriter(digest: 'expected-digest');
    final service = _RecordingTransferFileService();
    registry.register(
      TcpIncomingTransferPayloadWriterSession(
        key: key,
        tempFilePath: '/tmp/transfer-1.part',
        destinationDirectory: '/downloads',
        fileName: 'sample.txt',
        expectedSha256: 'expected-digest',
        writer: writer,
      ),
    );
    final adapter = TcpIncomingTransferPayloadWriterAdapter(
      registry: registry,
      fileService: service,
    );

    await adapter.open(key);
    await adapter.writeChunk(key, utf8.encode('hello'));

    expect(writer.appendedPayloads, [utf8.encode('hello')]);
    expect(registry.lookup(key), isNotNull);
  });

  test('yields periodically while writing many incoming chunks', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final writer = _RecordingDigestingWriter(digest: 'expected-digest');
    final service = _RecordingTransferFileService();
    var yieldCount = 0;
    registry.register(
      TcpIncomingTransferPayloadWriterSession(
        key: key,
        tempFilePath: '/tmp/transfer-1.part',
        destinationDirectory: '/downloads',
        fileName: 'sample.txt',
        expectedSha256: 'expected-digest',
        writer: writer,
      ),
    );
    final adapter = TcpIncomingTransferPayloadWriterAdapter(
      registry: registry,
      fileService: service,
      yieldEveryChunks: 2,
      yieldAfterBytes: 1024 * 1024,
      yieldScheduler: () async {
        yieldCount += 1;
      },
    );

    await adapter.writeChunk(key, utf8.encode('chunk-1'));
    await adapter.writeChunk(key, utf8.encode('chunk-2'));
    await adapter.writeChunk(key, utf8.encode('chunk-3'));
    await adapter.writeChunk(key, utf8.encode('chunk-4'));

    expect(writer.appendedPayloads, hasLength(4));
    expect(yieldCount, 2);
  });

  test('verifies digest and finalizes through transfer file service', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final writer = _RecordingDigestingWriter(digest: 'expected-digest');
    final service = _RecordingTransferFileService();
    registry.register(
      TcpIncomingTransferPayloadWriterSession(
        key: key,
        tempFilePath: '/tmp/transfer-1.part',
        destinationDirectory: '/downloads',
        fileName: 'sample.txt',
        expectedSha256: 'expected-digest',
        writer: writer,
      ),
    );
    final adapter = TcpIncomingTransferPayloadWriterAdapter(
      registry: registry,
      fileService: service,
    );

    await adapter.writeChunk(key, utf8.encode('payload'));
    await adapter.verify(key);
    await adapter.finalize(key);
    await adapter.complete(key);

    expect(writer.closeWithDigestCount, 1);
    expect(service.finalizeCalls, [
      'finalize:/tmp/transfer-1.part:/downloads:sample.txt',
    ]);
    expect(registry.lookup(key), isNull);
  });

  test('fails with explicit code when writer session is missing', () async {
    final adapter = TcpIncomingTransferPayloadWriterAdapter(
      registry: InMemoryTcpIncomingTransferPayloadWriterSessionRegistry(),
      fileService: _RecordingTransferFileService(),
    );

    await expectLater(
      adapter.writeChunk(key, utf8.encode('payload')),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'tcp_incoming_payload_writer_missing',
        ),
      ),
    );
  });

  test('digest mismatch prevents finalize', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final writer = _RecordingDigestingWriter(digest: 'actual-digest');
    final service = _RecordingTransferFileService();
    registry.register(
      TcpIncomingTransferPayloadWriterSession(
        key: key,
        tempFilePath: '/tmp/transfer-1.part',
        destinationDirectory: '/downloads',
        fileName: 'sample.txt',
        expectedSha256: 'expected-digest',
        writer: writer,
      ),
    );
    final adapter = TcpIncomingTransferPayloadWriterAdapter(
      registry: registry,
      fileService: service,
    );

    await expectLater(
      adapter.verify(key),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'tcp_incoming_payload_digest_mismatch',
        ),
      ),
    );

    expect(service.finalizeCalls, isEmpty);
    expect(registry.lookup(key), isNotNull);
  });

  test('cancel cleanup and fail discard draft and remove session', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final writer = _RecordingDigestingWriter(digest: 'expected-digest');
    final service = _RecordingTransferFileService();
    registry.register(
      TcpIncomingTransferPayloadWriterSession(
        key: key,
        tempFilePath: '/tmp/transfer-1.part',
        destinationDirectory: '/downloads',
        fileName: 'sample.txt',
        expectedSha256: 'expected-digest',
        writer: writer,
      ),
    );
    final adapter = TcpIncomingTransferPayloadWriterAdapter(
      registry: registry,
      fileService: service,
    );

    await adapter.cancel(key);

    expect(writer.closeCount, 1);
    expect(service.discardCalls, ['/tmp/transfer-1.part']);
    expect(registry.lookup(key), isNull);

    registry.register(
      TcpIncomingTransferPayloadWriterSession(
        key: key,
        tempFilePath: '/tmp/transfer-2.part',
        destinationDirectory: '/downloads',
        fileName: 'sample.txt',
        expectedSha256: 'expected-digest',
        writer: _RecordingDigestingWriter(digest: 'expected-digest'),
      ),
    );

    await adapter.fail(key);
    expect(service.discardCalls, [
      '/tmp/transfer-1.part',
      '/tmp/transfer-2.part',
    ]);
    expect(registry.lookup(key), isNull);
  });
}

class _RecordingDigestingWriter implements IncomingDigestingTransferWriter {
  _RecordingDigestingWriter({required this.digest});

  final String digest;
  final List<List<int>> appendedPayloads = [];
  int closeCount = 0;
  int closeWithDigestCount = 0;

  @override
  Future<void> append(List<int> bytes) async {
    appendedPayloads.add(List<int>.from(bytes));
  }

  @override
  Future<void> close() async {
    closeCount += 1;
  }

  @override
  Future<String> closeWithDigest() async {
    closeWithDigestCount += 1;
    return digest;
  }
}

class _RecordingTransferFileService implements TransferFileService {
  final List<String> finalizeCalls = [];
  final List<String> discardCalls = [];

  @override
  Future<void> appendChunk({
    required String tempFilePath,
    required List<int> bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> computeSha256(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> discardDraft(String tempFilePath) async {
    discardCalls.add(tempFilePath);
  }

  @override
  Future<String> finalizeIncomingFile({
    required String tempFilePath,
    required String destinationDirectory,
    required String fileName,
  }) async {
    finalizeCalls.add('finalize:$tempFilePath:$destinationDirectory:$fileName');
    return '$destinationDirectory/$fileName';
  }

  @override
  Future<IncomingDigestingTransferWriter> openIncomingDigestingWriter(
    String tempFilePath,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<IncomingTransferWriter> openIncomingWriter(String tempFilePath) {
    throw UnimplementedError();
  }

  @override
  Future<OutgoingTransferReader> openOutgoingReader(String filePath) {
    throw UnimplementedError();
  }

  @override
  Future<PreparedTransferFile> prepareOutgoingFile(
    String filePath, {
    required int chunkSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PreparedTransferMetadata> prepareOutgoingMetadata(
    String filePath, {
    required int chunkSize,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<int>> readChunkAt(
    String filePath, {
    required int chunkSize,
    required int chunkIndex,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<TransferChunk> readChunks(String filePath, {required int chunkSize}) {
    throw UnimplementedError();
  }
}
