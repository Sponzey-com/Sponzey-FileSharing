import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_finalize_failure_mapper.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

void main() {
  test('preserves AppException code and message', () {
    final failure = TransferIncomingFinalizeFailureMapper.map(
      const AppException(
        code: 'transfer_hash_mismatch',
        message: '파일 해시가 일치하지 않습니다.',
      ),
    );

    expect(failure.reasonCode, 'transfer_hash_mismatch');
    expect(failure.userMessage, '파일 해시가 일치하지 않습니다.');
    expect(failure.isExpectedRejection, isTrue);
  });

  test('maps generic errors to finalize failed message', () {
    final failure = TransferIncomingFinalizeFailureMapper.map(
      StateError('disk closed'),
    );

    expect(failure.reasonCode, 'transfer_finalize_failed');
    expect(failure.userMessage, '수신 파일을 완료하지 못했습니다.');
    expect(failure.isExpectedRejection, isFalse);
  });

  test('mapper stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_incoming_finalize_failure_mapper.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });

  test(
    'TransferController uses mapper for data and legacy finalize failures',
    () async {
      final source = await File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsString();
      final mapperCalls = RegExp(
        'TransferIncomingFinalizeFailureMapper.map',
      ).allMatches(source);

      expect(mapperCalls.length, greaterThanOrEqualTo(4));
      expect(source, isNot(contains("message: '수신 파일을 완료하지 못했습니다.'")));
      expect(
        source,
        isNot(
          contains(
            "await _failIncomingTransfer(transferId, '수신 파일을 완료하지 못했습니다.');",
          ),
        ),
      );
    },
  );
}
