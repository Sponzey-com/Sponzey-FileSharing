import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_metrics_command.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferJobMetricsCommand', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final previousUpdatedAt = DateTime.utc(2026, 1, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 1, 2);

    TransferJob baseJob({
      TransferJobStatus status = TransferJobStatus.sending,
    }) {
      return TransferJob(
        id: 'job-1',
        transferId: 'transfer-1',
        direction: TransferDirection.outgoing,
        peerId: 'peer-1',
        peerDisplayName: 'Peer One',
        fileName: 'sample.bin',
        fileSize: 1024,
        bytesTransferred: 0,
        totalChunks: 8,
        completedChunks: 0,
        status: status,
        createdAt: createdAt,
        updatedAt: previousUpdatedAt,
        localFilePath: '/tmp/sample.bin',
        destinationPath: '/downloads/sample.bin',
      );
    }

    test('updates outgoing metrics without changing status', () {
      final next = TransferJobMetricsCommand.outgoing(
        baseJob(status: TransferJobStatus.sending),
        bytesTransferred: 512,
        completedChunks: 4,
        retryCount: 3,
        duplicateCount: 2,
        lossRate: 0.25,
        throughputBytesPerSec: 4096,
        rttMs: 18,
        windowSize: 16,
        updatedAt: updatedAt,
        message: 'window pumped',
      );

      expect(next.status, TransferJobStatus.sending);
      expect(next.bytesTransferred, 512);
      expect(next.completedChunks, 4);
      expect(next.retryCount, 3);
      expect(next.duplicateCount, 2);
      expect(next.lossRate, 0.25);
      expect(next.throughputBytesPerSec, 4096);
      expect(next.rttMs, 18);
      expect(next.windowSize, 16);
      expect(next.updatedAt, updatedAt);
      expect(next.message, 'window pumped');
      expect(next.peerId, 'peer-1');
      expect(next.localFilePath, '/tmp/sample.bin');
    });

    test('updates incoming metrics and sets receiving status', () {
      final next = TransferJobMetricsCommand.incoming(
        baseJob(status: TransferJobStatus.awaitingAcceptance),
        bytesTransferred: 768,
        completedChunks: 6,
        duplicateCount: 5,
        throughputBytesPerSec: 2048,
        windowSize: 12,
        updatedAt: updatedAt,
        message: 'chunk received',
      );

      expect(next.status, TransferJobStatus.receiving);
      expect(next.bytesTransferred, 768);
      expect(next.completedChunks, 6);
      expect(next.duplicateCount, 5);
      expect(next.throughputBytesPerSec, 2048);
      expect(next.windowSize, 12);
      expect(next.updatedAt, updatedAt);
      expect(next.message, 'chunk received');
      expect(next.transferId, 'transfer-1');
      expect(next.destinationPath, '/downloads/sample.bin');
    });

    test('controller delegates metric job updates to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferJobMetricsCommand.outgoing'));
      expect(source, contains('TransferJobMetricsCommand.incoming'));
    });
  });
}
