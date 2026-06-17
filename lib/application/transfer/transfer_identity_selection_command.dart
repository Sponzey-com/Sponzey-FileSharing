import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

class TransferIdentitySelectionCommand {
  const TransferIdentitySelectionCommand._();

  static String requiredUserId(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      throw const AppException(
        code: 'transfer_no_session',
        message: '로그인 세션이 없어 전송할 수 없습니다.',
      );
    }
    return userId;
  }

  static String displayName({
    required String? displayName,
    required String userId,
  }) {
    if (displayName == null || displayName.trim().isEmpty) {
      return userId;
    }
    return displayName;
  }

  static String requiredDeviceId(String? deviceId) {
    if (deviceId == null || deviceId.trim().isEmpty) {
      throw const AppException(
        code: 'transfer_local_device_missing',
        message: '로컬 장치 식별 정보를 찾지 못했습니다.',
      );
    }
    return deviceId;
  }

  static String requiredInstanceId(String? instanceId) {
    if (instanceId == null || instanceId.trim().isEmpty) {
      throw const AppException(
        code: 'transfer_local_instance_missing',
        message: '로컬 실행 인스턴스 식별 정보를 찾지 못했습니다.',
      );
    }
    return instanceId;
  }
}
