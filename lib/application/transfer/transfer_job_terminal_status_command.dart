import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferJobTerminalStatusCommand {
  const TransferJobTerminalStatusCommand._();

  static TransferJob rejected(
    TransferJob job, {
    required DateTime updatedAt,
    required String message,
  }) {
    return job.copyWith(
      status: TransferJobStatus.rejected,
      updatedAt: updatedAt,
      message: message,
    );
  }

  static TransferJob failed(
    TransferJob job, {
    required DateTime updatedAt,
    required String message,
  }) {
    return job.copyWith(
      status: TransferJobStatus.failed,
      updatedAt: updatedAt,
      message: message,
    );
  }
}
