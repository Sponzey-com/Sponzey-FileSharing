import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_terminal_status_command.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferJobTerminalStatusCommand', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final previousUpdatedAt = DateTime.utc(2026, 1, 1, 1);
    final terminalUpdatedAt = DateTime.utc(2026, 1, 1, 2);

    TransferJob job() {
      return TransferJob(
        id: 'job-1',
        transferId: 'transfer-1',
        direction: TransferDirection.outgoing,
        peerId: 'peer-1',
        peerDisplayName: 'Peer One',
        fileName: 'sample.bin',
        fileSize: 1024,
        bytesTransferred: 256,
        totalChunks: 4,
        completedChunks: 1,
        status: TransferJobStatus.sending,
        createdAt: createdAt,
        updatedAt: previousUpdatedAt,
        windowSize: 8,
        retryCount: 3,
        duplicateCount: 2,
        lossRate: 0.25,
        throughputBytesPerSec: 4096,
        rttMs: 12,
        localFilePath: '/tmp/sample.bin',
        destinationPath: '/downloads/sample.bin',
        message: 'sending',
      );
    }

    test('marks a job rejected while preserving transfer metadata', () {
      final next = TransferJobTerminalStatusCommand.rejected(
        job(),
        updatedAt: terminalUpdatedAt,
        message: 'receiver rejected transfer',
      );

      expect(next.status, TransferJobStatus.rejected);
      expect(next.updatedAt, terminalUpdatedAt);
      expect(next.message, 'receiver rejected transfer');
      expect(next.id, 'job-1');
      expect(next.transferId, 'transfer-1');
      expect(next.bytesTransferred, 256);
      expect(next.windowSize, 8);
      expect(next.localFilePath, '/tmp/sample.bin');
      expect(next.destinationPath, '/downloads/sample.bin');
      expect(next.isTerminal, isTrue);
    });

    test('marks a job failed while preserving transfer metadata', () {
      final next = TransferJobTerminalStatusCommand.failed(
        job(),
        updatedAt: terminalUpdatedAt,
        message: 'data channel closed',
      );

      expect(next.status, TransferJobStatus.failed);
      expect(next.updatedAt, terminalUpdatedAt);
      expect(next.message, 'data channel closed');
      expect(next.id, 'job-1');
      expect(next.transferId, 'transfer-1');
      expect(next.bytesTransferred, 256);
      expect(next.retryCount, 3);
      expect(next.duplicateCount, 2);
      expect(next.lossRate, 0.25);
      expect(next.isTerminal, isTrue);
    });

    test('controller delegates terminal status transitions to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferJobTerminalStatusCommand.rejected'));
      expect(source, contains('TransferJobTerminalStatusCommand.failed'));
      expect(source, isNot(contains('status: TransferJobStatus.rejected')));
      expect(source, isNot(contains('status: TransferJobStatus.failed')));
    });
  });
}
