import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_event_factory.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferJobEventFactory', () {
    final occurredAt = DateTime.utc(2026, 1, 1, 1);

    TransferJob job({required TransferJobStatus status, String? message}) {
      return TransferJob(
        id: 'job-1',
        transferId: 'transfer-1',
        direction: TransferDirection.outgoing,
        peerId: 'peer-1',
        peerDisplayName: 'Peer One',
        fileName: 'sample.bin',
        fileSize: 100,
        bytesTransferred: 0,
        totalChunks: 1,
        completedChunks: 0,
        status: status,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: occurredAt,
        message: message,
      );
    }

    test('creates product severity event for failed job', () {
      final event = TransferJobEventFactory.sessionEvent(
        job(status: TransferJobStatus.failed, message: 'network failed'),
        eventId: 'event-1',
        occurredAt: occurredAt,
        source: 'TransferController',
      );

      expect(event.eventId, 'event-1');
      expect(event.occurredAt, occurredAt);
      expect(event.correlationId, 'transfer-1');
      expect(event.source, 'TransferController');
      expect(event.severity, AppEventSeverity.product);
      expect(event.eventType, 'transferfailed');
      expect(event.transferId, 'transfer-1');
      expect(event.jobId, 'job-1');
      expect(event.peerId, 'peer-1');
      expect(event.reasonCode, 'network failed');
    });

    test('creates product severity event for rejected job', () {
      final event = TransferJobEventFactory.sessionEvent(
        job(status: TransferJobStatus.rejected, message: 'receiver rejected'),
        eventId: 'event-2',
        occurredAt: occurredAt,
        source: 'TransferController',
      );

      expect(event.severity, AppEventSeverity.product);
      expect(event.eventType, 'transferrejected');
      expect(event.reasonCode, 'receiver rejected');
    });

    test('creates debug severity event without reason for active job', () {
      final event = TransferJobEventFactory.sessionEvent(
        job(status: TransferJobStatus.sending, message: 'chunk sent'),
        eventId: 'event-3',
        occurredAt: occurredAt,
        source: 'TransferController',
      );

      expect(event.severity, AppEventSeverity.debug);
      expect(event.eventType, 'transfersending');
      expect(event.reasonCode, isNull);
    });

    test('controller delegates transfer job event creation to factory', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferJobEventFactory.sessionEvent'));
      expect(source, isNot(contains('TransferSessionAppEvent(')));
    });
  });
}
