import 'dart:typed_data';

class TcpDataLengthPrefixedFrameBuffer {
  TcpDataLengthPrefixedFrameBuffer({this.maxBodyLength = 1024 * 1024});

  final int maxBodyLength;
  final List<int> _buffer = [];

  List<Uint8List> add(List<int> bytes) {
    _buffer.addAll(bytes);
    final frames = <Uint8List>[];

    while (_buffer.length >= 4) {
      final bodyLength = _bodyLength();
      if (bodyLength > maxBodyLength) {
        throw const FormatException('TCP frame body exceeds maximum length.');
      }
      final frameLength = 4 + bodyLength;
      if (_buffer.length < frameLength) {
        break;
      }
      frames.add(Uint8List.fromList(_buffer.sublist(0, frameLength)));
      _buffer.removeRange(0, frameLength);
    }

    return frames;
  }

  int _bodyLength() {
    final header = Uint8List.fromList(_buffer.take(4).toList());
    return ByteData.view(header.buffer).getUint32(0, Endian.big);
  }
}
