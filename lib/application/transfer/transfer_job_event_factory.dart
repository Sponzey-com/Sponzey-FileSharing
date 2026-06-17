import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferJobEventFactory {
  const TransferJobEventFactory._();

  static TransferSessionAppEvent sessionEvent(
    TransferJob job, {
    required String eventId,
    required DateTime occurredAt,
    required String source,
  }) {
    final isProductSeverity =
        job.status == TransferJobStatus.failed ||
        job.status == TransferJobStatus.rejected;
    return TransferSessionAppEvent(
      eventId: eventId,
      occurredAt: occurredAt,
      correlationId: job.transferId,
      source: source,
      severity: isProductSeverity
          ? AppEventSeverity.product
          : AppEventSeverity.debug,
      eventType: 'transfer${job.status.name}',
      transferId: job.transferId,
      jobId: job.id,
      peerId: job.peerId,
      reasonCode: isProductSeverity ? job.message : null,
    );
  }
}
