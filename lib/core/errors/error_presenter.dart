import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';

class ErrorPresenter {
  String toUserMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return '문제가 발생했습니다. 다시 시도해 주세요.';
  }
}

final errorPresenterProvider = Provider<ErrorPresenter>((ref) {
  return ErrorPresenter();
});
