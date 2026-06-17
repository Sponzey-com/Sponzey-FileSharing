import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_identity_selection_command.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

void main() {
  group('TransferIdentitySelectionCommand', () {
    test('returns required user id when present', () {
      expect(
        TransferIdentitySelectionCommand.requiredUserId('user-1'),
        'user-1',
      );
    });

    test('rejects missing or blank user id', () {
      expect(
        () => TransferIdentitySelectionCommand.requiredUserId(null),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'transfer_no_session',
          ),
        ),
      );
      expect(
        () => TransferIdentitySelectionCommand.requiredUserId('  '),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'transfer_no_session',
          ),
        ),
      );
    });

    test('uses display name when present and falls back to user id', () {
      expect(
        TransferIdentitySelectionCommand.displayName(
          displayName: 'Display User',
          userId: 'user-1',
        ),
        'Display User',
      );
      expect(
        TransferIdentitySelectionCommand.displayName(
          displayName: null,
          userId: 'user-1',
        ),
        'user-1',
      );
      expect(
        TransferIdentitySelectionCommand.displayName(
          displayName: '  ',
          userId: 'user-1',
        ),
        'user-1',
      );
    });

    test('returns required device id and rejects missing value', () {
      expect(
        TransferIdentitySelectionCommand.requiredDeviceId('device-1'),
        'device-1',
      );
      expect(
        () => TransferIdentitySelectionCommand.requiredDeviceId(' '),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'transfer_local_device_missing',
          ),
        ),
      );
    });

    test('returns required instance id and rejects missing value', () {
      expect(
        TransferIdentitySelectionCommand.requiredInstanceId('instance-1'),
        'instance-1',
      );
      expect(
        () => TransferIdentitySelectionCommand.requiredInstanceId(null),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'transfer_local_instance_missing',
          ),
        ),
      );
    });

    test('controller delegates identity selection to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('TransferIdentitySelectionCommand.requiredUserId'),
      );
      expect(source, contains('TransferIdentitySelectionCommand.displayName'));
      expect(
        source,
        contains('TransferIdentitySelectionCommand.requiredDeviceId'),
      );
      expect(
        source,
        contains('TransferIdentitySelectionCommand.requiredInstanceId'),
      );
    });
  });
}
