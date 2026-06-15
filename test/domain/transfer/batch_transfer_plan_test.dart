import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/batch_transfer_plan.dart';

void main() {
  test('creates one child session per target peer', () {
    const planner = BatchTransferPlanner();
    const files = [
      BatchTransferFile(
        fileId: 'file-1',
        fileName: 'report.txt',
        fileSize: 12,
        sha256: 'hash',
        chunkCount: 1,
      ),
    ];

    final plan = planner.createPlan(
      jobId: 'job-1',
      peerIds: ['alice@mac', 'bob@pc'],
      files: files,
    );

    expect(plan.children, hasLength(2));
    expect(plan.children.map((child) => child.peerId), ['alice@mac', 'bob@pc']);
    expect(plan.children.first.files.single.sha256, 'hash');
  });

  test('keeps multi-file items attached to each child session', () {
    const planner = BatchTransferPlanner();
    const files = [
      BatchTransferFile(
        fileId: 'file-1',
        fileName: 'report.txt',
        fileSize: 12,
        sha256: 'hash-1',
        chunkCount: 1,
      ),
      BatchTransferFile(
        fileId: 'file-2',
        fileName: 'archive.zip',
        fileSize: 4096,
        sha256: 'hash-2',
        chunkCount: 4,
      ),
    ];

    final plan = planner.createPlan(
      jobId: 'job-1',
      peerIds: ['alice@mac', 'bob@pc'],
      files: files,
    );

    expect(plan.children, hasLength(2));
    expect(plan.children.first.files, hasLength(2));
    expect(plan.children.last.files.map((file) => file.fileId), [
      'file-1',
      'file-2',
    ]);
    expect(plan.children.map((child) => child.sessionId), [
      'job-1::alice@mac',
      'job-1::bob@pc',
    ]);
  });
}
