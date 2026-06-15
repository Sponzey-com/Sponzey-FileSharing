import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';
import 'package:sponzey_file_sharing/infrastructure/database/app_database.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/transfer_history_repository.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'sponzey-transfer-history-test-',
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('saves completed transfer job and file item', () async {
    final database = openDatabase(directory, 'completed.sqlite');
    addTearDown(database.close);
    final repository = DriftTransferHistoryRepository(database);

    await repository.saveTerminalJob(
      _job(
        status: TransferJobStatus.completed,
        destinationPath: '${directory.path}/Downloads/demo.txt',
      ),
    );

    final history = await repository.loadRecentHistory();
    expect(history, hasLength(1));
    expect(history.single.job.status, TransferJobStatus.completed);
    expect(history.single.files.single.fileName, 'demo.txt');
    expect(
      history.single.failureDecision.category,
      TransferFailureCategory.none,
    );
  });

  test('saves failed transfer job with retry policy', () async {
    final database = openDatabase(directory, 'failed.sqlite');
    addTearDown(database.close);
    final repository = DriftTransferHistoryRepository(database);

    await repository.saveTerminalJob(
      _job(
        status: TransferJobStatus.failed,
        message: '상대 노드의 전송 응답 시간이 초과되었습니다.',
      ),
    );

    final history = await repository.loadRecentHistory();
    expect(history.single.job.status, TransferJobStatus.failed);
    expect(
      history.single.failureDecision.category,
      TransferFailureCategory.network,
    );
    expect(history.single.failureDecision.retryable, isTrue);
  });

  test('loads recent history after database reopen', () async {
    final path = '${directory.path}/restart.sqlite';
    final firstDatabase = AppDatabase.forTesting(NativeDatabase(File(path)));
    final firstRepository = DriftTransferHistoryRepository(firstDatabase);
    await firstRepository.saveTerminalJob(
      _job(
        status: TransferJobStatus.completed,
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await firstDatabase.close();

    final secondDatabase = AppDatabase.forTesting(NativeDatabase(File(path)));
    addTearDown(secondDatabase.close);
    final secondRepository = DriftTransferHistoryRepository(secondDatabase);

    final history = await secondRepository.loadRecentHistory();
    expect(history, hasLength(1));
    expect(history.single.job.transferId, 'transfer-1');
    expect(history.single.files.single.transferId, 'transfer-1');
  });
}

AppDatabase openDatabase(Directory directory, String fileName) {
  return AppDatabase.forTesting(
    NativeDatabase(File('${directory.path}/$fileName')),
  );
}

TransferJob _job({
  required TransferJobStatus status,
  DateTime? updatedAt,
  String? message,
  String? destinationPath,
}) {
  final createdAt = DateTime.utc(2026, 1, 1);
  final completed = status == TransferJobStatus.completed;
  return TransferJob(
    id: 'job-1',
    transferId: 'transfer-1',
    direction: TransferDirection.outgoing,
    peerId: 'peer-1',
    peerDisplayName: 'peer',
    fileName: 'demo.txt',
    fileSize: 12,
    bytesTransferred: completed ? 12 : 0,
    totalChunks: 1,
    completedChunks: completed ? 1 : 0,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
    localFilePath: '${Directory.systemTemp.path}/demo.txt',
    destinationPath: destinationPath,
    message: message,
  );
}
