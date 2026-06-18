import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_metadata_frame_prepare_adapter.dart';
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

  test('decodes metadata and prepares writer session', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final adapter = TcpIncomingMetadataFramePrepareAdapter(
      codec: const TcpIncomingTransferMetadataCodec(),
      prepareCommand: TcpIncomingTransferWriterSessionPrepareCommand(
        registry: registry,
        fileService: _RecordingTransferFileService(),
      ),
      destinationDirectory: '/downloads',
    );

    final result = await adapter.prepare(
      key: key,
      payload: const TcpIncomingTransferMetadataCodec().encode(metadata),
    );

    expect(result.prepared, isTrue);
    expect(result.issueCode, isNull);
    expect(registry.lookup(key), isNotNull);
  });

  test('rejects malformed metadata without preparing writer session', () async {
    final registry = InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    final adapter = TcpIncomingMetadataFramePrepareAdapter(
      codec: const TcpIncomingTransferMetadataCodec(),
      prepareCommand: TcpIncomingTransferWriterSessionPrepareCommand(
        registry: registry,
        fileService: _RecordingTransferFileService(),
      ),
      destinationDirectory: '/downloads',
    );

    final result = await adapter.prepare(key: key, payload: [1, 2, 3]);

    expect(result.prepared, isFalse);
    expect(result.issueCode, 'tcp_incoming_metadata_decode_failed');
    expect(registry.lookup(key), isNull);
  });
}

class _RecordingTransferFileService implements TransferFileService {
  @override
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) async {
    return IncomingTransferDraft(
      transferId: transferId,
      fileName: fileName,
      tempDirectoryPath: '/tmp/$transferId',
      tempFilePath: '/tmp/$transferId/$fileName.part',
    );
  }

  @override
  Future<IncomingDigestingTransferWriter> openIncomingDigestingWriter(
    String tempFilePath,
  ) async {
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
  Future<void> discardDraft(String tempFilePath) async {}

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
