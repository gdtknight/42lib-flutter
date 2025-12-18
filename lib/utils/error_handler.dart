/// 에러 핸들링 유틸리티
class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  static void handleError(dynamic error, {Function? onError}) {
    final message = getErrorMessage(error);
    print('Error: $message');
    onError?.call(message);
  }
}
