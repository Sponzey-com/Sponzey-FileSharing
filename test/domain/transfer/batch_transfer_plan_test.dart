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
}
