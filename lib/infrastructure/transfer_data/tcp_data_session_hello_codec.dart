import 'dart:convert';
import 'dart:typed_data';

import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataSessionHelloCodec {
  const TcpDataSessionHelloCodec();

  static const frameType = 'DATA_SESSION_HELLO';

  Uint8List encode(TcpDataSessionHello hello) {
    final body = utf8.encode(
      jsonEncode({
        'type': frameType,
        'sessionId': hello.sessionId.value,
        'peerId': hello.peerId,
        'instanceId': hello.instanceId,
        'authSessionId': hello.authSessionId,
        'protocolVersion': hello.protocolVersion,
        'dataProtocolVersion': hello.dataProtocolVersion,
        'proof': hello.proof,
      }),
    );
    final bytes = Uint8List(4 + body.length);
    final view = ByteData.view(bytes.buffer);
    view.setUint32(0, body.length, Endian.big);
    bytes.setRange(4, bytes.length, body);
    return bytes;
  }

  TcpDataSessionHello decode(List<int> bytes) {
    if (bytes.length < 4) {
      throw const FormatException('TCP hello frame is shorter than header.');
    }
    final raw = Uint8List.fromList(bytes);
    final view = ByteData.view(raw.buffer);
    final bodyLength = view.getUint32(0, Endian.big);
    if (raw.length - 4 != bodyLength) {
      throw const FormatException('TCP hello frame body length mismatch.');
    }
    final decoded = jsonDecode(utf8.decode(raw.sublist(4)));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('TCP hello frame body must be an object.');
    }
    if (decoded['type'] != frameType) {
      throw const FormatException('Unexpected TCP data session frame type.');
    }
    return TcpDataSessionHello(
      sessionId: TcpDataSessionId(_stringField(decoded, 'sessionId')),
      peerId: _stringField(decoded, 'peerId'),
      instanceId: _stringField(decoded, 'instanceId'),
      authSessionId: _stringField(decoded, 'authSessionId'),
      protocolVersion: _intField(decoded, 'protocolVersion'),
      dataProtocolVersion: _intField(decoded, 'dataProtocolVersion'),
      proof: _stringField(decoded, 'proof'),
    );
  }

  String _stringField(Map<String, Object?> decoded, String key) {
    final value = decoded[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('TCP hello frame field $key must be a string.');
    }
    return value;
  }

  int _intField(Map<String, Object?> decoded, String key) {
    final value = decoded[key];
    if (value is! int) {
      throw FormatException('TCP hello frame field $key must be an int.');
    }
    return value;
  }
}
