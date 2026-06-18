import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

class TcpIncomingTransferWriterSessionPrepareResult {
  const TcpIncomingTransferWriterSessionPrepareResult({
    required this.prepared,
    this.key,
    this.tempFilePath,
    this.issueCode,
  });

  final bool prepared;
  final TcpIncomingTransferFrameContextKey? key;
  final String? tempFilePath;
  final String? issueCode;
}

class TcpIncomingTransferWriterSessionPrepareCommand {
  const TcpIncomingTransferWriterSessionPrepareCommand({
    required this.registry,
    required this.fileService,
  });

  final TcpIncomingTransferPayloadWriterSessionRegistry registry;
  final TransferFileService fileService;

  Future<TcpIncomingTransferWriterSessionPrepareResult> prepare({
    required TcpIncomingTransferFrameContextKey key,
    required TcpIncomingTransferMetadata metadata,
    required String destinationDirectory,
  }) async {
    final safeDestination = destinationDirectory.trim();
    if (safeDestination.isEmpty) {
      return const TcpIncomingTransferWriterSessionPrepareResult(
        prepared: false,
        issueCode: 'tcp_incoming_destination_required',
      );
    }

    IncomingTransferDraft? draft;
    try {
      draft = await fileService.createIncomingDraft(
        transferId: key.transferId,
        fileName: metadata.fileName,
      );
    } catch (_) {
      return const TcpIncomingTransferWriterSessionPrepareResult(
        prepared: false,
        issueCode: 'tcp_incoming_draft_prepare_failed',
      );
    }

    try {
      final writer = await fileService.openIncomingDigestingWriter(
        draft.tempFilePath,
      );
      registry.register(
        TcpIncomingTransferPayloadWriterSession(
          key: key,
          tempFilePath: draft.tempFilePath,
          destinationDirectory: safeDestination,
          fileName: draft.fileName,
          expectedSha256: metadata.sha256,
          writer: writer,
        ),
      );
      return TcpIncomingTransferWriterSessionPrepareResult(
        prepared: true,
        key: key,
        tempFilePath: draft.tempFilePath,
      );
    } on AppException {
      await _discardDraft(draft.tempFilePath);
      return const TcpIncomingTransferWriterSessionPrepareResult(
        prepared: false,
        issueCode: 'tcp_incoming_writer_open_failed',
      );
    } catch (_) {
      await _discardDraft(draft.tempFilePath);
      return const TcpIncomingTransferWriterSessionPrepareResult(
        prepared: false,
        issueCode: 'tcp_incoming_writer_open_failed',
      );
    }
  }

  Future<void> _discardDraft(String tempFilePath) async {
    try {
      await fileService.discardDraft(tempFilePath);
    } catch (_) {
      // Best-effort cleanup after prepare failure.
    }
  }
}
