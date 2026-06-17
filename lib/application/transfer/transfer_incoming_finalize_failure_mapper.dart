import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

class TransferIncomingFinalizeFailure {
  const TransferIncomingFinalizeFailure({
    required this.reasonCode,
    required this.userMessage,
    required this.isExpectedRejection,
  });

  final String reasonCode;
  final String userMessage;
  final bool isExpectedRejection;
}

class TransferIncomingFinalizeFailureMapper {
  const TransferIncomingFinalizeFailureMapper._();

  static TransferIncomingFinalizeFailure map(Object error) {
    if (error is AppException) {
      return TransferIncomingFinalizeFailure(
        reasonCode: error.code,
        userMessage: error.message,
        isExpectedRejection: true,
      );
    }
    return const TransferIncomingFinalizeFailure(
      reasonCode: 'transfer_finalize_failed',
      userMessage: '수신 파일을 완료하지 못했습니다.',
      isExpectedRejection: false,
    );
  }
}
