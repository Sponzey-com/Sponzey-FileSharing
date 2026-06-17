class TransferEventIdFormatter {
  const TransferEventIdFormatter._();

  static String format({required String prefix, required DateTime now}) {
    return '$prefix-${now.microsecondsSinceEpoch}';
  }
}
