import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_metadata_frame_prepare_port.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_writer_session_prepare_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

class TcpIncomingMetadataFramePrepareAdapter
    implements TcpIncomingMetadataFramePreparePort {
  const TcpIncomingMetadataFramePrepareAdapter({
    required this.codec,
    required this.prepareCommand,
    required this.destinationDirectory,
  });

  final TcpIncomingTransferMetadataCodec codec;
  final TcpIncomingTransferWriterSessionPrepareCommand prepareCommand;
  final String destinationDirectory;

  @override
  Future<TcpIncomingMetadataFramePrepareResult> prepare({
    required TcpIncomingTransferFrameContextKey key,
    required List<int> payload,
  }) async {
    final TcpIncomingTransferMetadata metadata;
    try {
      metadata = codec.decode(payload);
    } catch (_) {
      return const TcpIncomingMetadataFramePrepareResult(
        prepared: false,
        issueCode: 'tcp_incoming_metadata_decode_failed',
      );
    }

    final result = await prepareCommand.prepare(
      key: key,
      metadata: metadata,
      destinationDirectory: destinationDirectory,
    );
    return TcpIncomingMetadataFramePrepareResult(
      prepared: result.prepared,
      metadata: result.prepared
          ? TcpIncomingMetadataProjection(
              fileName: metadata.fileName,
              fileSize: metadata.fileSize,
              chunkCount: metadata.chunkCount,
              destinationDirectory: destinationDirectory,
            )
          : null,
      issueCode: result.issueCode,
    );
  }
}
