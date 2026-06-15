import 'dart:async';

import 'package:crypto/crypto.dart';

class StreamingSha256Digest {
  StreamingSha256Digest() {
    _sink = sha256.startChunkedConversion(_digestSink);
  }

  final _DigestSink _digestSink = _DigestSink();
  late final Sink<List<int>> _sink;
  bool _closed = false;

  void add(List<int> bytes) {
    if (_closed) {
      throw StateError('Streaming digest is already closed.');
    }
    _sink.add(bytes);
  }

  Future<String> close() async {
    if (!_closed) {
      _closed = true;
      _sink.close();
    }
    return _digestSink.digest.toString();
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? _digest;

  Digest get digest {
    final digest = _digest;
    if (digest == null) {
      throw StateError('Digest is not ready yet.');
    }
    return digest;
  }

  @override
  void add(Digest data) {
    _digest = data;
  }

  @override
  void close() {}
}
