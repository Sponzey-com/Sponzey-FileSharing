import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';

class DataFrameCodec {
  const DataFrameCodec({this.authenticator});

  static const int version = 1;
  static const int safeUdpPayloadBytes = 1472;
  static const int defaultAuthTagBytes = 16;
  static const int fixedHeaderBytes = 72;
  static const List<int> magic = [0x53, 0x5a, 0x44, 0x46]; // SZDF

  final DataFrameAuthenticator? authenticator;

  int maxPayloadBytes({
    int safeDatagramBytes = safeUdpPayloadBytes,
    int ackBitmapWords = 0,
    int authTagBytes = defaultAuthTagBytes,
  }) {
    final headerBytes = fixedHeaderBytes + ackBitmapWords * 4;
    final payloadBytes = safeDatagramBytes - headerBytes - authTagBytes;
    return payloadBytes < 0 ? 0 : payloadBytes;
  }

  Uint8List encode(DataFrame frame) {
    _validateTransferId(frame.transferIdBytes);
    final authenticator = this.authenticator;
    final ackWords = frame.ackBitmapWords;
    final headerLength = fixedHeaderBytes + ackWords.length * 4;
    final tagLength = authenticator == null ? frame.authTag.length : 16;
    final bytes = Uint8List(headerLength + frame.payload.length + tagLength);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, magic.length, magic);
    data.setUint8(4, frame.version);
    data.setUint8(5, frame.type.code);
    data.setUint16(6, frame.flags);
    data.setUint32(8, headerLength);
    data.setUint32(12, frame.payload.length);
    data.setUint64(16, frame.sessionHash);
    bytes.setRange(24, 40, frame.transferIdBytes);
    data.setUint64(40, frame.sequence);
    data.setUint64(48, frame.chunkIndex);
    data.setUint32(56, frame.windowStart);
    data.setUint32(60, frame.windowSize);
    data.setUint32(64, frame.ackBase);
    data.setUint32(68, ackWords.length);
    for (var i = 0; i < ackWords.length; i += 1) {
      data.setUint32(72 + i * 4, ackWords[i]);
    }
    bytes.setRange(
      headerLength,
      headerLength + frame.payload.length,
      frame.payload,
    );

    if (authenticator == null) {
      if (frame.authTag.isNotEmpty) {
        bytes.setRange(
          headerLength + frame.payload.length,
          bytes.length,
          frame.authTag,
        );
      }
      return bytes;
    }

    final tag = authenticator.sign(
      bytes.sublist(0, headerLength + frame.payload.length),
    );
    bytes.setRange(headerLength + frame.payload.length, bytes.length, tag);
    return bytes;
  }

  DataFrame decode(Uint8List bytes) {
    if (bytes.length < fixedHeaderBytes) {
      throw const FormatException('Data frame is shorter than fixed header.');
    }
    if (!_hasMagic(bytes)) {
      throw const FormatException('Data frame magic mismatch.');
    }
    final data = ByteData.sublistView(bytes);
    final frameVersion = data.getUint8(4);
    if (frameVersion != version) {
      throw FormatException('Unsupported data frame version $frameVersion.');
    }
    final type = DataFrameType.fromCode(data.getUint8(5));
    final flags = data.getUint16(6);
    final headerLength = data.getUint32(8);
    final payloadLength = data.getUint32(12);
    final ackBitmapWordCount = data.getUint32(68);
    if (headerLength != fixedHeaderBytes + ackBitmapWordCount * 4) {
      throw const FormatException('Data frame header length mismatch.');
    }
    if (bytes.length < headerLength + payloadLength) {
      throw const FormatException('Data frame payload length mismatch.');
    }
    final authTag = bytes.sublist(headerLength + payloadLength);
    final authenticator = this.authenticator;
    if (authenticator != null) {
      if (!authenticator.verify(
        bytes.sublist(0, headerLength + payloadLength),
        authTag,
      )) {
        throw const FormatException('Data frame auth tag mismatch.');
      }
    }
    final ackWords = <int>[
      for (var i = 0; i < ackBitmapWordCount; i += 1)
        data.getUint32(72 + i * 4),
    ];
    return DataFrame(
      version: frameVersion,
      type: type,
      flags: flags,
      sessionHash: data.getUint64(16),
      transferIdBytes: bytes.sublist(24, 40),
      sequence: data.getUint64(40),
      chunkIndex: data.getUint64(48),
      windowStart: data.getUint32(56),
      windowSize: data.getUint32(60),
      ackBase: data.getUint32(64),
      ackBitmapWords: ackWords,
      payload: bytes.sublist(headerLength, headerLength + payloadLength),
      authTag: authTag,
    );
  }

  bool _hasMagic(Uint8List bytes) {
    for (var i = 0; i < magic.length; i += 1) {
      if (bytes[i] != magic[i]) {
        return false;
      }
    }
    return true;
  }

  void _validateTransferId(Uint8List transferIdBytes) {
    if (transferIdBytes.length != 16) {
      throw ArgumentError.value(
        transferIdBytes.length,
        'transferIdBytes.length',
        'Data frame transfer id must be exactly 16 bytes.',
      );
    }
  }
}

class DataFrameAuthenticator {
  const DataFrameAuthenticator({required List<int> key, this.tagBytes = 16})
    : _key = key;

  final List<int> _key;
  final int tagBytes;

  Uint8List sign(List<int> bytes) {
    final digest = Hmac(sha256, _key).convert(bytes).bytes;
    return Uint8List.fromList(digest.take(tagBytes).toList(growable: false));
  }

  bool verify(List<int> bytes, List<int> tag) {
    final expected = sign(bytes);
    if (tag.length != expected.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < expected.length; i += 1) {
      diff |= expected[i] ^ tag[i];
    }
    return diff == 0;
  }
}

Uint8List transferIdBytesFromString(String transferId) {
  final digest = sha256.convert(transferId.codeUnits).bytes;
  return Uint8List.fromList(digest.take(16).toList(growable: false));
}
