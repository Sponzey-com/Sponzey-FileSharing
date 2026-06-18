import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

void main() {
  const channelId = TcpDataChannelId('channel-1');

  test('sends metadata chunks and complete frames in order', () async {
    final fileService = _RecordingTransferFileService(
      chunks: [utf8.encode('abc'), utf8.encode('def')],
    );
    final connector = _RecordingTcpDataConnector();
    final command = TcpOutgoingTransferStreamSendCommand(
      fileService: fileService,
      connector: connector,
      metadataCodec: const TcpIncomingTransferMetadataCodec(),
    );
    final progressEvents = <TcpOutgoingTransferStreamProgress>[];

    final result = await command.send(
      channelId: channelId,
      transferId: 'transfer-1',
      filePath: '/files/report.pdf',
      chunkSize: 3,
      onProgress: progressEvents.add,
    );

    expect(result.sent, isTrue);
    expect(result.framesSent, 4);
    expect(result.bytesSent, 6);
    expect(connector.frames.map((frame) => frame.type), [
      TcpDataStreamFrameType.metadata,
      TcpDataStreamFrameType.chunk,
      TcpDataStreamFrameType.chunk,
      TcpDataStreamFrameType.complete,
    ]);
    expect(connector.frames.map((frame) => frame.sequence), [0, 1, 2, 3]);

    final metadata = const TcpIncomingTransferMetadataCodec().decode(
      connector.frames.first.payload,
    );
    expect(metadata.fileName, 'report.pdf');
    expect(metadata.fileSize, 6);
    expect(metadata.chunkCount, 2);
    expect(metadata.sha256, 'sha256-report');
    expect(fileService.openedReaders, 1);
    expect(fileService.reader.closeCount, 1);
    expect(progressEvents.map((event) => event.framesSent), [1, 2, 3, 4]);
    expect(progressEvents.map((event) => event.bytesSent), [0, 3, 6, 6]);
    expect(progressEvents.map((event) => event.completedChunks), [0, 1, 2, 2]);
  });

  test(
    'closes reader and returns issue code when connector send fails',
    () async {
      final fileService = _RecordingTransferFileService(
        chunks: [utf8.encode('abc'), utf8.encode('def')],
      );
      final connector = _RecordingTcpDataConnector(failAtSequence: 1);
      final command = TcpOutgoingTransferStreamSendCommand(
        fileService: fileService,
        connector: connector,
        metadataCodec: const TcpIncomingTransferMetadataCodec(),
      );

      final result = await command.send(
        channelId: channelId,
        transferId: 'transfer-1',
        filePath: '/files/report.pdf',
        chunkSize: 3,
      );

      expect(result.sent, isFalse);
      expect(result.issueCode, 'tcp_outgoing_stream_send_failed');
      expect(fileService.reader.closeCount, 1);
    },
  );
}

class _RecordingTcpDataConnector implements TcpDataConnectorPort {
  _RecordingTcpDataConnector({this.failAtSequence});

  final int? failAtSequence;
  final List<TcpDataStreamFrame> frames = [];

  @override
  Future<TcpDataChannelId> connect(TcpDataConnectRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendHello(
    TcpDataChannelId channelId,
    TcpDataSessionHello hello,
  ) async {}

  @override
  Future<void> sendFrame(
    TcpDataChannelId channelId,
    TcpDataStreamFrame frame,
  ) async {
    if (frame.sequence == failAtSequence) {
      throw StateError('send failed');
    }
    frames.add(frame);
  }

  @override
  Future<void> close() async {}
}

class _RecordingTransferFileService implements TransferFileService {
  _RecordingTransferFileService({required List<List<int>> chunks})
    : reader = _RecordingOutgoingReader(chunks);

  final _RecordingOutgoingReader reader;
  int openedReaders = 0;

  @override
  Future<PreparedTransferFile> prepareOutgoingFile(
    String filePath, {
    required int chunkSize,
  }) async {
    return const PreparedTransferFile(
      filePath: '/files/report.pdf',
      fileName: 'report.pdf',
      fileSize: 6,
      sha256: 'sha256-report',
      chunkSize: 3,
      chunkCount: 2,
    );
  }

  @override
  Future<OutgoingTransferReader> openOutgoingReader(String filePath) async {
    openedReaders += 1;
    return reader;
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
  Future<IncomingTransferDraft> createIncomingDraft({
    required String transferId,
    required String fileName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> discardDraft(String tempFilePath) {
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

class _RecordingOutgoingReader implements OutgoingTransferReader {
  _RecordingOutgoingReader(this.chunks);

  final List<List<int>> chunks;
  int closeCount = 0;

  @override
  Future<void> close() async {
    closeCount += 1;
  }

  @override
  Future<List<int>> readAt({
    required int chunkSize,
    required int chunkIndex,
  }) async {
    return Uint8List.fromList(chunks[chunkIndex]);
  }
}
