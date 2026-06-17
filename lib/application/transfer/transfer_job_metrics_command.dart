import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferJobMetricsCommand {
  const TransferJobMetricsCommand._();

  static TransferJob outgoing(
    TransferJob job, {
    required int bytesTransferred,
    required int completedChunks,
    required int retryCount,
    required int duplicateCount,
    required double lossRate,
    required double throughputBytesPerSec,
    required double? rttMs,
    required int windowSize,
    required DateTime updatedAt,
    required String message,
  }) {
    return job.copyWith(
      bytesTransferred: bytesTransferred,
      completedChunks: completedChunks,
      retryCount: retryCount,
      duplicateCount: duplicateCount,
      lossRate: lossRate,
      throughputBytesPerSec: throughputBytesPerSec,
      rttMs: rttMs,
      windowSize: windowSize,
      updatedAt: updatedAt,
      message: message,
    );
  }

  static TransferJob incoming(
    TransferJob job, {
    required int bytesTransferred,
    required int completedChunks,
    required int duplicateCount,
    required double throughputBytesPerSec,
    required int windowSize,
    required DateTime updatedAt,
    required String message,
  }) {
    return job.copyWith(
      status: TransferJobStatus.receiving,
      bytesTransferred: bytesTransferred,
      completedChunks: completedChunks,
      duplicateCount: duplicateCount,
      throughputBytesPerSec: throughputBytesPerSec,
      windowSize: windowSize,
      updatedAt: updatedAt,
      message: message,
    );
  }
}
