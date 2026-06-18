import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';

class TcpIncomingMetadataProjection {
  const TcpIncomingMetadataProjection({
    required this.fileName,
    required this.fileSize,
    required this.chunkCount,
    required this.destinationDirectory,
  });

  final String fileName;
  final int fileSize;
  final int chunkCount;
  final String destinationDirectory;
}

class TcpIncomingMetadataFramePrepareResult {
  const TcpIncomingMetadataFramePrepareResult({
    required this.prepared,
    this.metadata,
    this.issueCode,
  });

  final bool prepared;
  final TcpIncomingMetadataProjection? metadata;
  final String? issueCode;
}

abstract interface class TcpIncomingMetadataFramePreparePort {
  Future<TcpIncomingMetadataFramePrepareResult> prepare({
    required TcpIncomingTransferFrameContextKey key,
    required List<int> payload,
  });
}

class PassthroughTcpIncomingMetadataFramePreparePort
    implements TcpIncomingMetadataFramePreparePort {
  const PassthroughTcpIncomingMetadataFramePreparePort();

  @override
  Future<TcpIncomingMetadataFramePrepareResult> prepare({
    required TcpIncomingTransferFrameContextKey key,
    required List<int> payload,
  }) async {
    return const TcpIncomingMetadataFramePrepareResult(prepared: true);
  }
}
