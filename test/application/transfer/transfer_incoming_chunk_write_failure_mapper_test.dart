import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_chunk_write_failure_mapper.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

void main() {
  group('TransferIncomingChunkWriteFailureMapper', () {
    test('uses AppException message as reason', () {
      expect(
        TransferIncomingChunkWriteFailureMapper.messageFor(
          const AppException(code: 'x', message: '앱 오류'),
        ),
        contains('원인: 앱 오류'),
      );
    });

    test('uses FileSystemException message as reason', () {
      expect(
        TransferIncomingChunkWriteFailureMapper.messageFor(
          const FileSystemException('권한 없음'),
        ),
        contains('원인: 권한 없음'),
      );
    });

    test('uses StateError message as reason', () {
      expect(
        TransferIncomingChunkWriteFailureMapper.messageFor(
          StateError('writer closed'),
        ),
        contains('원인: writer closed'),
      );
    });

    test('uses runtime type as fallback reason', () {
      expect(
        TransferIncomingChunkWriteFailureMapper.messageFor(ArgumentError()),
        contains('원인: ArgumentError'),
      );
    });
  });
}
