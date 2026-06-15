import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';

class TransferHistoryFileItem {
  const TransferHistoryFileItem({
    required this.id,
    required this.jobId,
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.localPath,
    this.destinationPath,
    this.sha256,
    this.message,
  });

  final String id;
  final String jobId;
  final String transferId;
  final String fileName;
  final int fileSize;
  final String? localPath;
  final String? destinationPath;
  final String? sha256;
  final TransferJobStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class TransferHistorySnapshot {
  const TransferHistorySnapshot({
    required this.job,
    required this.files,
    required this.failureDecision,
  });

  final TransferJob job;
  final List<TransferHistoryFileItem> files;
  final TransferFailureDecision failureDecision;
}

abstract interface class TransferHistoryRepository {
  Future<void> saveTerminalJob(TransferJob job);

  Future<List<TransferHistorySnapshot>> loadRecentHistory({int limit = 100});

  Future<List<TransferJob>> loadRecentJobs({int limit = 100}) async {
    final snapshots = await loadRecentHistory(limit: limit);
    return snapshots.map((snapshot) => snapshot.job).toList(growable: false);
  }
}
