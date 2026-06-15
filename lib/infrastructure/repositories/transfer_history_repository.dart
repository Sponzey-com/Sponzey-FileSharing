import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_history_repository.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';

final transferHistoryRepositoryProvider = Provider<TransferHistoryRepository>((
  ref,
) {
  return DriftTransferHistoryRepository(ref.watch(appDatabaseProvider));
});

class DriftTransferHistoryRepository implements TransferHistoryRepository {
  DriftTransferHistoryRepository(
    this._database, {
    TransferFailurePolicy failurePolicy = const TransferFailurePolicy(),
  }) : _failurePolicy = failurePolicy;

  final AppDatabase _database;
  final TransferFailurePolicy _failurePolicy;

  @override
  Future<void> saveTerminalJob(TransferJob job) async {
    if (!job.isTerminal) {
      return;
    }

    final failure = _failurePolicy.classify(job);
    final fileItemId = '${job.id}::${job.fileName}';
    await _database.transaction(() async {
      await _database
          .into(_database.transferHistoryJobs)
          .insertOnConflictUpdate(
            TransferHistoryJobsCompanion(
              id: Value(job.id),
              transferId: Value(job.transferId),
              direction: Value(job.direction.name),
              peerId: Value(job.peerId),
              peerDisplayName: Value(job.peerDisplayName),
              status: Value(job.status.name),
              failureCategory: job.status == TransferJobStatus.completed
                  ? const Value.absent()
                  : Value(failure.category.name),
              failureCode: job.status == TransferJobStatus.completed
                  ? const Value.absent()
                  : Value(failure.diagnosticCode),
              message: Value(job.message),
              fileCount: const Value(1),
              totalBytes: Value(job.fileSize),
              bytesTransferred: Value(job.bytesTransferred),
              totalChunks: Value(job.totalChunks),
              completedChunks: Value(job.completedChunks),
              retryCount: Value(job.retryCount),
              lossRate: Value(job.lossRate),
              throughputBytesPerSec: Value(job.throughputBytesPerSec),
              createdAt: Value(job.createdAt),
              updatedAt: Value(job.updatedAt),
            ),
          );

      await _database
          .into(_database.transferHistoryFiles)
          .insertOnConflictUpdate(
            TransferHistoryFilesCompanion(
              id: Value(fileItemId),
              jobId: Value(job.id),
              transferId: Value(job.transferId),
              fileName: Value(job.fileName),
              fileSize: Value(job.fileSize),
              localPath: Value(job.localFilePath),
              destinationPath: Value(job.destinationPath),
              sha256: const Value.absent(),
              status: Value(job.status.name),
              message: Value(job.message),
              createdAt: Value(job.createdAt),
              updatedAt: Value(job.updatedAt),
            ),
          );
    });
  }

  @override
  Future<List<TransferHistorySnapshot>> loadRecentHistory({
    int limit = 100,
  }) async {
    final rows = await _database.getTransferHistoryJobs(limit: limit);
    final snapshots = <TransferHistorySnapshot>[];
    for (final row in rows) {
      final fileRows = await _database.getTransferHistoryFilesForJob(row.id);
      final files = fileRows.map(_fileItemFromRow).toList(growable: false);
      final job = _jobFromRows(row, files);
      snapshots.add(
        TransferHistorySnapshot(
          job: job,
          files: files,
          failureDecision: _failurePolicy.classify(job),
        ),
      );
    }
    return snapshots;
  }

  @override
  Future<List<TransferJob>> loadRecentJobs({int limit = 100}) async {
    final snapshots = await loadRecentHistory(limit: limit);
    return snapshots.map((snapshot) => snapshot.job).toList(growable: false);
  }

  TransferJob _jobFromRows(
    TransferHistoryJob row,
    List<TransferHistoryFileItem> files,
  ) {
    final firstFile = files.isEmpty ? null : files.first;
    return TransferJob(
      id: row.id,
      transferId: row.transferId,
      direction: _parseDirection(row.direction),
      peerId: row.peerId,
      peerDisplayName: row.peerDisplayName,
      fileName: firstFile?.fileName ?? 'unknown',
      fileSize: firstFile?.fileSize ?? row.totalBytes,
      bytesTransferred: row.bytesTransferred,
      totalChunks: row.totalChunks,
      completedChunks: row.completedChunks,
      status: _parseStatus(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      retryCount: row.retryCount,
      lossRate: row.lossRate,
      throughputBytesPerSec: row.throughputBytesPerSec,
      localFilePath: firstFile?.localPath,
      destinationPath: firstFile?.destinationPath,
      message: row.message,
    );
  }

  TransferHistoryFileItem _fileItemFromRow(TransferHistoryFile row) {
    return TransferHistoryFileItem(
      id: row.id,
      jobId: row.jobId,
      transferId: row.transferId,
      fileName: row.fileName,
      fileSize: row.fileSize,
      localPath: row.localPath,
      destinationPath: row.destinationPath,
      sha256: row.sha256,
      status: _parseStatus(row.status),
      message: row.message,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TransferDirection _parseDirection(String value) {
    for (final direction in TransferDirection.values) {
      if (direction.name == value) {
        return direction;
      }
    }
    return TransferDirection.outgoing;
  }

  TransferJobStatus _parseStatus(String value) {
    for (final status in TransferJobStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return TransferJobStatus.failed;
  }
}
