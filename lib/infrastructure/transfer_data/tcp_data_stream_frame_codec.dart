import 'dart:convert';
import 'dart:typed_data';

import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

class TcpDataStreamFrameCodec {
  const TcpDataStreamFrameCodec();

  static const version = 1;
  static const _bodyHeaderLength = 22;
  static const _magic = [0x53, 0x46, 0x54, 0x44]; // SFTD

  Uint8List encode(TcpDataStreamFrame frame) {
    final transferIdBytes = utf8.encode(frame.transferId);
    if (transferIdBytes.isEmpty) {
      throw const FormatException('TCP stream frame transfer id is empty.');
    }
    if (transferIdBytes.length > 65535) {
      throw const FormatException('TCP stream frame transfer id is too long.');
    }
    if (frame.sequence < 0) {
      throw const FormatException('TCP stream frame sequence is negative.');
    }

    final bodyLength =
        _bodyHeaderLength + transferIdBytes.length + frame.payload.length;
    final bytes = Uint8List(4 + bodyLength);
    final view = ByteData.view(bytes.buffer);
    view.setUint32(0, bodyLength, Endian.big);
    bytes.setRange(4, 8, _magic);
    view.setUint8(8, version);
    view.setUint8(9, frame.type.code);
    view.setUint16(10, 0, Endian.big);
    view.setUint16(12, transferIdBytes.length, Endian.big);
    view.setUint64(14, frame.sequence, Endian.big);
    view.setUint32(22, frame.payload.length, Endian.big);
    bytes.setRange(26, 26 + transferIdBytes.length, transferIdBytes);
    bytes.setRange(26 + transferIdBytes.length, bytes.length, frame.payload);
    return bytes;
  }

  TcpDataStreamFrame decode(List<int> bytes) {
    if (bytes.length < 4 + _bodyHeaderLength) {
      throw const FormatException('TCP stream frame is shorter than header.');
    }
    final raw = Uint8List.fromList(bytes);
    final view = ByteData.view(raw.buffer);
    final bodyLength = view.getUint32(0, Endian.big);
    if (raw.length - 4 != bodyLength) {
      throw const FormatException('TCP stream frame body length mismatch.');
    }
    for (var index = 0; index < _magic.length; index++) {
      if (raw[4 + index] != _magic[index]) {
        throw const FormatException('TCP stream frame magic mismatch.');
      }
    }
    final frameVersion = view.getUint8(8);
    if (frameVersion != version) {
      throw FormatException(
        'Unsupported TCP stream frame version $frameVersion.',
      );
    }

    final type = TcpDataStreamFrameType.fromCode(view.getUint8(9));
    final transferIdLength = view.getUint16(12, Endian.big);
    final sequence = view.getUint64(14, Endian.big);
    final payloadLength = view.getUint32(22, Endian.big);
    final expectedBodyLength =
        _bodyHeaderLength + transferIdLength + payloadLength;
    if (bodyLength != expectedBodyLength) {
      throw const FormatException('TCP stream frame payload length mismatch.');
    }
    final transferIdStart = 26;
    final transferIdEnd = transferIdStart + transferIdLength;
    final payloadEnd = transferIdEnd + payloadLength;
    if (payloadEnd != raw.length) {
      throw const FormatException('TCP stream frame boundary mismatch.');
    }
    final transferId = utf8.decode(raw.sublist(transferIdStart, transferIdEnd));
    if (transferId.isEmpty) {
      throw const FormatException('TCP stream frame transfer id is empty.');
    }

    return TcpDataStreamFrame(
      type: type,
      transferId: transferId,
      sequence: sequence,
      payload: raw.sublist(transferIdEnd, payloadEnd),
    );
  }
}
