import 'dart:typed_data';

import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

class TcpOutgoingTransferStreamSendResult {
  const TcpOutgoingTransferStreamSendResult({
    required this.sent,
    required this.framesSent,
    required this.bytesSent,
    this.issueCode,
  });

  final bool sent;
  final int framesSent;
  final int bytesSent;
  final String? issueCode;
}

class TcpOutgoingTransferStreamProgress {
  const TcpOutgoingTransferStreamProgress({
    required this.framesSent,
    required this.bytesSent,
    required this.completedChunks,
  });

  final int framesSent;
  final int bytesSent;
  final int completedChunks;
}

abstract interface class TcpOutgoingTransferStreamSenderPort {
  Future<TcpOutgoingTransferStreamSendResult> send({
    required TcpDataChannelId channelId,
    required String transferId,
    required String filePath,
    required int chunkSize,
    void Function(TcpOutgoingTransferStreamProgress progress)? onProgress,
  });
}

class TcpOutgoingTransferStreamSendCommand
    implements TcpOutgoingTransferStreamSenderPort {
  const TcpOutgoingTransferStreamSendCommand({
    required this.fileService,
    required this.connector,
    required this.metadataCodec,
  });

  final TransferFileService fileService;
  final TcpDataConnectorPort connector;
  final TcpIncomingTransferMetadataCodec metadataCodec;

  @override
  Future<TcpOutgoingTransferStreamSendResult> send({
    required TcpDataChannelId channelId,
    required String transferId,
    required String filePath,
    required int chunkSize,
    void Function(TcpOutgoingTransferStreamProgress progress)? onProgress,
  }) async {
    var framesSent = 0;
    var bytesSent = 0;
    OutgoingTransferReader? reader;
    try {
      final prepared = await fileService.prepareOutgoingFile(
        filePath,
        chunkSize: chunkSize,
      );
      reader = await fileService.openOutgoingReader(prepared.filePath);
      final metadata = TcpIncomingTransferMetadata(
        fileName: prepared.fileName,
        fileSize: prepared.fileSize,
        chunkCount: prepared.chunkCount,
        sha256: prepared.sha256,
      );
      await connector.sendFrame(
        channelId,
        TcpDataStreamFrame(
          type: TcpDataStreamFrameType.metadata,
          transferId: transferId,
          sequence: 0,
          payload: metadataCodec.encode(metadata),
        ),
      );
      framesSent += 1;
      onProgress?.call(
        TcpOutgoingTransferStreamProgress(
          framesSent: framesSent,
          bytesSent: bytesSent,
          completedChunks: 0,
        ),
      );

      for (var index = 0; index < prepared.chunkCount; index += 1) {
        final chunk = await reader.readAt(
          chunkSize: prepared.chunkSize,
          chunkIndex: index,
        );
        final payload = Uint8List.fromList(chunk);
        await connector.sendFrame(
          channelId,
          TcpDataStreamFrame(
            type: TcpDataStreamFrameType.chunk,
            transferId: transferId,
            sequence: index + 1,
            payload: payload,
          ),
        );
        framesSent += 1;
        bytesSent += payload.length;
        onProgress?.call(
          TcpOutgoingTransferStreamProgress(
            framesSent: framesSent,
            bytesSent: bytesSent,
            completedChunks: index + 1,
          ),
        );
      }

      await connector.sendFrame(
        channelId,
        TcpDataStreamFrame(
          type: TcpDataStreamFrameType.complete,
          transferId: transferId,
          sequence: prepared.chunkCount + 1,
          payload: Uint8List(0),
        ),
      );
      framesSent += 1;
      onProgress?.call(
        TcpOutgoingTransferStreamProgress(
          framesSent: framesSent,
          bytesSent: bytesSent,
          completedChunks: prepared.chunkCount,
        ),
      );
      return TcpOutgoingTransferStreamSendResult(
        sent: true,
        framesSent: framesSent,
        bytesSent: bytesSent,
      );
    } catch (_) {
      return TcpOutgoingTransferStreamSendResult(
        sent: false,
        framesSent: framesSent,
        bytesSent: bytesSent,
        issueCode: 'tcp_outgoing_stream_send_failed',
      );
    } finally {
      await reader?.close();
    }
  }
}
