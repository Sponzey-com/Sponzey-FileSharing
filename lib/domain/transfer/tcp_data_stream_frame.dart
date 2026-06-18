import 'dart:typed_data';

enum TcpDataStreamFrameType {
  metadata(1),
  chunk(2),
  complete(3),
  cancel(4),
  error(5);

  const TcpDataStreamFrameType(this.code);

  final int code;

  static TcpDataStreamFrameType fromCode(int code) {
    return TcpDataStreamFrameType.values.firstWhere(
      (type) => type.code == code,
      orElse: () {
        throw FormatException('Unsupported TCP data stream frame type $code.');
      },
    );
  }
}

class TcpDataStreamFrame {
  TcpDataStreamFrame({
    required this.type,
    required this.transferId,
    required this.sequence,
    required Uint8List payload,
  }) : payload = Uint8List.fromList(payload);

  final TcpDataStreamFrameType type;
  final String transferId;
  final int sequence;
  final Uint8List payload;
}
