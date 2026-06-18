import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_transfer_send_use_case.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_peer_file_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';

void main() {
  const input = TcpTransferSendUseCaseInput(
    peerId: 'peer-1',
    authSessionId: 'auth-1',
    transferId: 'transfer-1',
    filePath: '/files/report.pdf',
    chunkSize: 8192,
  );

  test(
    'prepares metadata and sends through connected TCP peer command',
    () async {
      final registry = _registryWithConnectedOutbound();
      final sender = _RecordingPeerSender();
      final useCase = TcpTransferSendUseCase(
        fileService: _RecordingTransferFileService(),
        peerSender: sender,
        dataChannelRegistry: registry,
      );

      final result = await useCase.send(input);

      expect(result.sent, isTrue);
      expect(result.issueCode, isNull);
      expect(result.fileName, 'report.pdf');
      expect(result.fileSize, 12);
      expect(sender.calls, [
        'send:peer-1:auth-1:transfer-1:/files/report.pdf:8192',
      ]);
    },
  );

  test('returns failure when connected TCP channel is missing', () async {
    final useCase = TcpTransferSendUseCase(
      fileService: _RecordingTransferFileService(),
      peerSender: _RecordingPeerSender(
        result: const TcpPeerFileSendResult(
          sent: false,
          issueCode: 'missing_tcp_outgoing_data_channel',
        ),
      ),
      dataChannelRegistry: InMemoryDataChannelSessionRegistry(
        mode: DataChannelMode.tcp,
      ),
    );

    final result = await useCase.send(input);

    expect(result.sent, isFalse);
    expect(result.issueCode, 'missing_tcp_outgoing_data_channel');
    expect(result.message, contains('TCP data channel'));
  });

  test('maps metadata preparation failure to explicit result', () async {
    final useCase = TcpTransferSendUseCase(
      fileService: _RecordingTransferFileService(failMetadata: true),
      peerSender: _RecordingPeerSender(),
      dataChannelRegistry: _registryWithConnectedOutbound(),
    );

    final result = await useCase.send(input);

    expect(result.sent, isFalse);
    expect(result.issueCode, 'tcp_transfer_metadata_prepare_failed');
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

class _RecordingPeerSender implements TcpPeerFileSenderPort {
  _RecordingPeerSender({
    this.result = const TcpPeerFileSendResult(
      sent: true,
      framesSent: 4,
      bytesSent: 12,
    ),
  });

  final TcpPeerFileSendResult result;
  final List<String> calls = [];

  @override
  Future<TcpPeerFileSendResult> send({
    required DataChannelSessionRegistry registry,
    required String peerId,
    required String authSessionId,
    required String transferId,
    required String filePath,
    required int chunkSize,
  }) async {
    calls.add('send:$peerId:$authSessionId:$transferId:$filePath:$chunkSize');
    return result;
  }
}

class _RecordingTransferFileService implements TransferFileService {
  const _RecordingTransferFileService({this.failMetadata = false});

  final bool failMetadata;

  @override
  Future<PreparedTransferMetadata> prepareOutgoingMetadata(
    String filePath, {
    required int chunkSize,
  }) async {
    if (failMetadata) {
      throw StateError('metadata failed');
    }
    return const PreparedTransferMetadata(
      filePath: '/files/report.pdf',
      fileName: 'report.pdf',
      fileSize: 12,
      chunkSize: 8192,
      chunkCount: 1,
    );
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
