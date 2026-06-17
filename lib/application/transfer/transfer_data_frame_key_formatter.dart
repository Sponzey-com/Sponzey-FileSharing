import 'dart:convert';
import 'dart:typed_data';

class TransferDataFrameKeyFormatter {
  const TransferDataFrameKeyFormatter._();

  static String format(Uint8List transferIdBytes) {
    return base64Url.encode(transferIdBytes);
  }
}
