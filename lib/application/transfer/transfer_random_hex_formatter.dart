class TransferRandomHexFormatter {
  const TransferRandomHexFormatter._();

  static String formatBytes(Iterable<int> bytes) {
    return bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }
}
