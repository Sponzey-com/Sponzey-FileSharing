import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_update_lookup_command.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferJobUpdateLookupCommand', () {
    TransferJob job(String id) {
      return TransferJob(
        id: id,
        transferId: 'transfer-$id',
        direction: TransferDirection.outgoing,
        peerId: 'peer-$id',
        peerDisplayName: 'Peer $id',
        fileName: '$id.bin',
        fileSize: 100,
        bytesTransferred: 0,
        totalChunks: 1,
        completedChunks: 0,
        status: TransferJobStatus.sending,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('returns updated job when id exists', () {
      final existing = job('a');
      final updatedAt = DateTime.utc(2026, 1, 1, 2);

      final result = TransferJobUpdateLookupCommand.updateById(
        jobs: [existing],
        jobId: 'a',
        update: (current) => current.copyWith(
          status: TransferJobStatus.completed,
          updatedAt: updatedAt,
        ),
      );

      expect(result, isNotNull);
      expect(result!.id, 'a');
      expect(result.status, TransferJobStatus.completed);
      expect(result.updatedAt, updatedAt);
    });

    test('returns null when id is missing', () {
      var updateCount = 0;

      final result = TransferJobUpdateLookupCommand.updateById(
        jobs: [job('a')],
        jobId: 'missing',
        update: (current) {
          updateCount++;
          return current;
        },
      );

      expect(result, isNull);
      expect(updateCount, 0);
    });

    test('updates only the first matching job', () {
      var updateCount = 0;

      final result = TransferJobUpdateLookupCommand.updateById(
        jobs: [job('a'), job('a')],
        jobId: 'a',
        update: (current) {
          updateCount++;
          return current.copyWith(message: 'updated');
        },
      );

      expect(result?.message, 'updated');
      expect(updateCount, 1);
    });

    test('controller delegates job lookup update to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferJobUpdateLookupCommand.updateById'));
      expect(source, isNot(contains('TransferJob? currentJob;')));
    });
  });
}
