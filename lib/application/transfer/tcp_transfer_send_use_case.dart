import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_peer_file_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';

class TcpTransferSendUseCaseInput {
  const TcpTransferSendUseCaseInput({
    required this.peerId,
    required this.authSessionId,
    required this.transferId,
    required this.filePath,
    required this.chunkSize,
    this.onPrepared,
    this.onProgress,
  });

  final String peerId;
  final String authSessionId;
  final String transferId;
  final String filePath;
  final int chunkSize;
  final void Function(PreparedTransferMetadata metadata)? onPrepared;
  final void Function(TcpOutgoingTransferStreamProgress progress)? onProgress;
}

class TcpTransferSendUseCaseResult {
  const TcpTransferSendUseCaseResult({
    required this.sent,
    this.filePath,
    this.fileName,
    this.fileSize = 0,
    this.chunkSize = 0,
    this.chunkCount = 0,
    this.framesSent = 0,
    this.bytesSent = 0,
    this.issueCode,
    this.message,
  });

  final bool sent;
  final String? filePath;
  final String? fileName;
  final int fileSize;
  final int chunkSize;
  final int chunkCount;
  final int framesSent;
  final int bytesSent;
  final String? issueCode;
  final String? message;
}

class TcpTransferSendUseCase {
  const TcpTransferSendUseCase({
    required this.fileService,
    required this.peerSender,
    required this.dataChannelRegistry,
  });

  final TransferFileService fileService;
  final TcpPeerFileSenderPort peerSender;
  final DataChannelSessionRegistry dataChannelRegistry;

  Future<TcpTransferSendUseCaseResult> send(
    TcpTransferSendUseCaseInput input,
  ) async {
    final PreparedTransferMetadata metadata;
    try {
      metadata = await fileService.prepareOutgoingMetadata(
        input.filePath,
        chunkSize: input.chunkSize,
      );
    } catch (_) {
      return const TcpTransferSendUseCaseResult(
        sent: false,
        issueCode: 'tcp_transfer_metadata_prepare_failed',
        message: '전송할 파일 정보를 준비하지 못했습니다.',
      );
    }
    input.onPrepared?.call(metadata);

    final result = await peerSender.send(
      registry: dataChannelRegistry,
      peerId: input.peerId,
      authSessionId: input.authSessionId,
      transferId: input.transferId,
      filePath: metadata.filePath,
      chunkSize: metadata.chunkSize,
      onProgress: input.onProgress,
    );
    return TcpTransferSendUseCaseResult(
      sent: result.sent,
      filePath: metadata.filePath,
      fileName: metadata.fileName,
      fileSize: metadata.fileSize,
      chunkSize: metadata.chunkSize,
      chunkCount: metadata.chunkCount,
      framesSent: result.framesSent,
      bytesSent: result.bytesSent,
      issueCode: result.issueCode,
      message: result.sent ? null : _messageForIssue(result.issueCode),
    );
  }

  String _messageForIssue(String? issueCode) {
    return switch (issueCode) {
      'missing_tcp_outgoing_data_channel' => '연결된 TCP data channel을 찾지 못했습니다.',
      'tcp_outgoing_data_channel_not_connected' =>
        'TCP data channel이 아직 연결 완료 상태가 아닙니다.',
      'tcp_outgoing_stream_send_failed' => 'TCP 파일 전송에 실패했습니다.',
      _ => 'TCP 파일 전송을 시작하지 못했습니다.',
    };
  }
}
