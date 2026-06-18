import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_session_hello_codec.dart';

void main() {
  const codec = TcpDataSessionHelloCodec();
  final frame = codec.encode(
    const TcpDataSessionHello(
      sessionId: TcpDataSessionId('session-1'),
      peerId: 'peer-1',
      instanceId: 'instance-1',
      authSessionId: 'auth-1',
      protocolVersion: 1,
      dataProtocolVersion: 1,
      proof: 'proof-1',
    ),
  );

  test('does not emit incomplete frame', () {
    final buffer = TcpDataLengthPrefixedFrameBuffer();

    final frames = buffer.add(frame.sublist(0, 8));

    expect(frames, isEmpty);
  });

  test('emits frame after split chunks complete it', () {
    final buffer = TcpDataLengthPrefixedFrameBuffer();

    expect(buffer.add(frame.sublist(0, 8)), isEmpty);
    final frames = buffer.add(frame.sublist(8));

    expect(frames, hasLength(1));
    expect(codec.decode(frames.single).peerId, 'peer-1');
  });

  test('emits multiple frames from one chunk', () {
    final buffer = TcpDataLengthPrefixedFrameBuffer();
    final combined = Uint8List(frame.length * 2)
      ..setRange(0, frame.length, frame)
      ..setRange(frame.length, frame.length * 2, frame);

    final frames = buffer.add(combined);

    expect(frames, hasLength(2));
    expect(codec.decode(frames[0]).instanceId, 'instance-1');
    expect(codec.decode(frames[1]).instanceId, 'instance-1');
  });

  test('rejects frame over maximum body length', () {
    final buffer = TcpDataLengthPrefixedFrameBuffer(maxBodyLength: 4);

    expect(() => buffer.add(frame), throwsFormatException);
  });
}
