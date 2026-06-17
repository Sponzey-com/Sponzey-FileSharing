import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_list_upsert_command.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferJobListUpsertCommand', () {
    TransferJob job({
      required String id,
      required DateTime updatedAt,
      String transferId = 'transfer',
      TransferJobStatus status = TransferJobStatus.sending,
    }) {
      return TransferJob(
        id: id,
        transferId: '$transferId-$id',
        direction: TransferDirection.outgoing,
        peerId: 'peer-$id',
        peerDisplayName: 'Peer $id',
        fileName: '$id.bin',
        fileSize: 100,
        bytesTransferred: 0,
        totalChunks: 1,
        completedChunks: 0,
        status: status,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: updatedAt,
      );
    }

    test('adds a job to an empty list', () {
      final nextJob = job(id: 'a', updatedAt: DateTime.utc(2026, 1, 1, 1));

      final result = TransferJobListUpsertCommand.upsert(
        currentJobs: const [],
        nextJob: nextJob,
      );

      expect(result, [nextJob]);
    });

    test('replaces existing job with the same id', () {
      final oldJob = job(id: 'a', updatedAt: DateTime.utc(2026, 1, 1, 1));
      final newJob = job(
        id: 'a',
        updatedAt: DateTime.utc(2026, 1, 1, 2),
        status: TransferJobStatus.completed,
      );

      final result = TransferJobListUpsertCommand.upsert(
        currentJobs: [oldJob],
        nextJob: newJob,
      );

      expect(result, hasLength(1));
      expect(result.single, newJob);
      expect(result.single.status, TransferJobStatus.completed);
    });

    test('preserves other jobs and sorts newest updated job first', () {
      final older = job(id: 'old', updatedAt: DateTime.utc(2026, 1, 1, 1));
      final newest = job(id: 'new', updatedAt: DateTime.utc(2026, 1, 1, 3));
      final middle = job(id: 'mid', updatedAt: DateTime.utc(2026, 1, 1, 2));

      final result = TransferJobListUpsertCommand.upsert(
        currentJobs: [older, newest],
        nextJob: middle,
      );

      expect(result.map((item) => item.id), ['new', 'mid', 'old']);
    });

    test('does not mutate the input list', () {
      final older = job(id: 'old', updatedAt: DateTime.utc(2026, 1, 1, 1));
      final input = [older];

      final result = TransferJobListUpsertCommand.upsert(
        currentJobs: input,
        nextJob: job(id: 'new', updatedAt: DateTime.utc(2026, 1, 1, 2)),
      );

      expect(input, [older]);
      expect(result, isNot(same(input)));
    });

    test('controller delegates job list upsert to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferJobListUpsertCommand.upsert'));
      expect(source, isNot(contains('if (job.id != nextJob.id) job,')));
      expect(source, isNot(contains('right.updatedAt.compareTo')));
    });
  });
}
