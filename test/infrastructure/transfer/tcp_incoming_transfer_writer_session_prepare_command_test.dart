import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_writer_session_prepare_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

void main() {
  const key = TcpIncomingTransferFrameContextKey(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    transferId: 'transfer-1',
  );
  const metadata = TcpIncomingTransferMetadata(
    fileName: 'report.pdf',
    fileSize: 1024,
    chunkCount: 4,
    sha256: 'expected-digest',
  );

  test(
    'creates draft opens digest writer and registers writer session',
    () async {
      final registry =
          InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
      final fileService = _RecordingTransferFileService();
      final command = TcpIncomingTransferWriterSessionPrepareCommand(
        registry: registry,
        fileService: fileService,
      );

      final result = await command.prepare(
        key: key,
        metadata: metadata,
        destinationDirectory: '/downloads',
      );

      final session = registry.lookup(key);
      expect(result.prepared, isTrue);
      expect(result.issueCode, isNull);
      expect(result.tempFilePath, '/tmp/transfer-1/report.pdf.part');
      expect(session, isNotNull);
      expect(session!.tempFilePath, '/tmp/transfer-1/report.pdf.part');
      expect(session.destinationDirectory, '/downloads');
      expect(session.fileName, 'safe-report.pdf');
      expect(session.expectedSha256, 'expected-digest');
      expect(fileService.calls, [
        'createDraft:transfer-1:report.pdf',
        'openDigestingWriter:/tmp/transfer-1/report.pdf.part',
      ]);
    },
  );

  test(
    'rejects empty destination directory before file service access',
    () async {
      final fileService = _RecordingTransferFileService();
      final command = TcpIncomingTransferWriterSessionPrepareCommand(
        registry: InMemoryTcpIncomingTransferPayloadWriterSessionRegistry(),
        fileService: fileService,
      );

      final result = await command.prepare(
        key: key,
        metadata: metadata,
        destinationDirectory: '  ',
      );

      expect(result.prepared, isFalse);
      expect(result.issueCode, 'tcp_incoming_destination_required');
      expect(fileService.calls, isEmpty);
    },
  );

  test('discards draft when writer open fails', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final fileService = _RecordingTransferFileService(failOpenWriter: true);
    final command = TcpIncomingTransferWriterSessionPrepareCommand(
      registry: registry,
      fileService: fileService,
    );

    final result = await command.prepare(
      key: key,
      metadata: metadata,
      destinationDirectory: '/downloads',
    );

    expect(result.prepared, isFalse);
    expect(result.issueCode, 'tcp_incoming_writer_open_failed');
    expect(registry.lookup(key), isNull);
    expect(fileService.calls, [
      'createDraft:transfer-1:report.pdf',
      'openDigestingWriter:/tmp/transfer-1/report.pdf.part',
      'discard:/tmp/transfer-1/report.pdf.part',
    ]);
  });

  test('maps draft creation failure to explicit issue code', () async {
    final command = TcpIncomingTransferWriterSessionPrepareCommand(
      registry: InMemoryTcpIncomingTransferPayloadWriterSessionRegistry(),
      fileService: _RecordingTransferFileService(failCreateDraft: true),
    );

    final result = await command.prepare(
      key: key,
      metadata: metadata,
      destinationDirectory: '/downloads',
    );

    expect(result.prepared, isFalse);
    expect(result.issueCode, 'tcp_incoming_draft_prepare_failed');
  });
}

class _RecordingTransferFileService implements TransferFileService {
  _RecordingTransferFileService({
    this.failCreateDraft = false,
    this.failOpenWriter = false,
  });

  final bool failCreateDraft;
  final bool failOpenWriter;
  final List<String> calls = [];

  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) async {
    calls.add('createDraft:$transferId:$fileName');
    if (failCreateDraft) {
      throw const AppException(
        code: 'incoming_draft_prepare_failed',
        message: 'failed',
      );
    }
    return IncomingTransferDraft(
      transferId: transferId,
      fileName: 'safe-report.pdf',
      tempDirectoryPath: '/tmp/transfer-1',
      tempFilePath: '/tmp/transfer-1/report.pdf.part',
    );
  }

  @override
  Future<void> discardDraft(String tempFilePath) async {
    calls.add('discard:$tempFilePath');
  }

  @override
  Future<IncomingDigestingTransferWriter> openIncomingDigestingWriter(
    String tempFilePath,
  ) async {
    calls.add('openDigestingWriter:$tempFilePath');
    if (failOpenWriter) {
      throw const AppException(code: 'open_failed', message: 'failed');
    }
    return _NoopDigestingWriter();
  }

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
  Future<String> finalizeIncomingFile({
    required String tempFilePath,
    required String destinationDirectory,
    required String fileName,
  }) {
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

class _NoopDigestingWriter implements IncomingDigestingTransferWriter {
  @override
  Future<void> append(List<int> bytes) async {}

  @override
  Future<void> close() async {}

  @override
  Future<String> closeWithDigest() async {
    return 'expected-digest';
  }
}
