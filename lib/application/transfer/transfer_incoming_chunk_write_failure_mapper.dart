import 'dart:io';

import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

class TransferIncomingChunkWriteFailureMapper {
  const TransferIncomingChunkWriteFailureMapper._();

  static String messageFor(Object error) {
    final reason = switch (error) {
      AppException(:final message) => message,
      FileSystemException(:final message) when message.isNotEmpty => message,
      StateError(:final message) => message,
      _ => error.runtimeType.toString(),
    };
    return '수신 data chunk 를 저장하지 못했습니다. '
        '저장 경로 또는 임시 파일 권한을 확인해 주세요. '
        '원인: $reason';
  }
}
