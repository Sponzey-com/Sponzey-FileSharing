class TransferLogSafeFormatter {
  const TransferLogSafeFormatter._();

  static String session(String sessionId) {
    return sessionId.length <= 8 ? sessionId : sessionId.substring(0, 8);
  }

  static String transfer(String? transferId) {
    if (transferId == null || transferId.isEmpty) {
      return '-';
    }
    return transferId.length <= 8 ? transferId : transferId.substring(0, 8);
  }

  static String fileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    final posixBase = trimmed.split('/').last;
    final basename = posixBase.split('\\').last;
    if (basename.length <= 80) {
      return basename;
    }
    return '${basename.substring(0, 77)}...';
  }
}
