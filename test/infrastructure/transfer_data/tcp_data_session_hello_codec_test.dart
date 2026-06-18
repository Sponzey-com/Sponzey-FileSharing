import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_session_hello_codec.dart';

void main() {
  const codec = TcpDataSessionHelloCodec();
  const hello = TcpDataSessionHello(
    sessionId: TcpDataSessionId('session-1'),
    peerId: 'peer-1',
    instanceId: 'instance-1',
    authSessionId: 'auth-1',
    protocolVersion: 1,
    dataProtocolVersion: 1,
    proof: 'proof-1',
  );

  test('encodes and decodes data session hello frame', () {
    final bytes = codec.encode(hello);
    final decoded = codec.decode(bytes);

    expect(decoded.peerId, hello.peerId);
    expect(decoded.sessionId, hello.sessionId);
    expect(decoded.instanceId, hello.instanceId);
    expect(decoded.authSessionId, hello.authSessionId);
    expect(decoded.protocolVersion, hello.protocolVersion);
    expect(decoded.dataProtocolVersion, hello.dataProtocolVersion);
    expect(decoded.proof, hello.proof);
  });

  test('rejects wrong frame type', () {
    final bytes = codec.encode(hello);
    final text = String.fromCharCodes(bytes);
    final tampered = Uint8List.fromList(
      text.replaceFirst('DATA_SESSION_HELLO', 'OTHER_FRAME_TYPE').codeUnits,
    );

    expect(() => codec.decode(tampered), throwsFormatException);
  });

  test('rejects truncated body', () {
    final bytes = codec.encode(hello);
    final truncated = bytes.sublist(0, bytes.length - 4);

    expect(() => codec.decode(truncated), throwsFormatException);
  });

  test('rejects hello frame without data session id', () {
    final body = utf8.encode(
      jsonEncode({
        'type': TcpDataSessionHelloCodec.frameType,
        'peerId': hello.peerId,
        'instanceId': hello.instanceId,
        'authSessionId': hello.authSessionId,
        'protocolVersion': hello.protocolVersion,
        'dataProtocolVersion': hello.dataProtocolVersion,
        'proof': hello.proof,
      }),
    );
    final bytes = Uint8List(4 + body.length);
    ByteData.view(bytes.buffer).setUint32(0, body.length, Endian.big);
    bytes.setRange(4, bytes.length, body);

    expect(() => codec.decode(bytes), throwsFormatException);
  });
}
