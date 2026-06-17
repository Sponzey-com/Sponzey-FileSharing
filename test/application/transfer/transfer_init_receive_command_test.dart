import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_init_receive_command.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';

void main() {
  test('builds command from complete TRANSFER_INIT packet', () {
    final result = TransferInitReceiveCommand.fromPacket(
      const AuthPacket(
        type: AuthPacketType.transferInit,
        protocolVersion: '1',
        sessionId: 'session-1',
        fromUserId: 'team',
        fromDeviceId: 'device-a',
        fromInstanceId: 'instance-a',
        fromDisplayName: 'Team Sender',
        transferId: 'transfer-1',
        transferFileName: 'report.pdf',
        transferFileSize: 1200,
        transferSha256: 'digest',
        transferChunkCount: 3,
        transferAcceptedChunkSize: 1024,
        transferDataAuthContextId: 'data-auth-1',
        sentAtEpochMs: 1,
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.issueCode, isNull);
    expect(result.command, isNotNull);
    final command = result.command!;
    expect(command.sessionId, 'session-1');
    expect(command.transferId, 'transfer-1');
    expect(command.fileName, 'report.pdf');
    expect(command.fileSize, 1200);
    expect(command.sha256, 'digest');
    expect(command.chunkCount, 3);
    expect(command.packetPeerId, 'team@instance-a');
    expect(command.peerDisplayName, 'Team Sender');
    expect(command.acceptedChunkSize, 1024);
    expect(command.dataAuthContextId, 'data-auth-1');
  });

  test('falls back to device id when instance id is missing', () {
    final result = TransferInitReceiveCommand.fromPacket(
      const AuthPacket(
        type: AuthPacketType.transferInit,
        protocolVersion: '1',
        sessionId: 'session-1',
        fromUserId: 'team',
        fromDeviceId: 'device-a',
        transferId: 'transfer-1',
        transferFileName: 'report.pdf',
        transferFileSize: 1200,
        transferChunkCount: 3,
        sentAtEpochMs: 1,
      ),
    );

    expect(result.command?.packetPeerId, 'team@device-a');
    expect(result.command?.peerDisplayName, 'team');
  });

  test('returns invalid result when required transfer fields are missing', () {
    final result = TransferInitReceiveCommand.fromPacket(
      const AuthPacket(
        type: AuthPacketType.transferInit,
        protocolVersion: '1',
        sessionId: 'session-1',
        fromUserId: 'team',
        fromDeviceId: 'device-a',
        transferFileName: 'report.pdf',
        transferFileSize: 1200,
        transferChunkCount: 3,
        sentAtEpochMs: 1,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.command, isNull);
    expect(result.issueCode, 'missing_transfer_init_fields');
  });

  test(
    'command boundary stays independent from framework and IO adapters',
    () async {
      final source = await File(
        'lib/application/transfer/transfer_init_receive_command.dart',
      ).readAsString();

      expect(source, isNot(contains('flutter')));
      expect(source, isNot(contains('riverpod')));
      expect(source, isNot(contains('dart:io')));
      expect(source, isNot(contains('TransferFileService')));
      expect(source, isNot(contains('ControlTransport')));
      expect(source, isNot(contains('DataTransport')));
    },
  );
}
