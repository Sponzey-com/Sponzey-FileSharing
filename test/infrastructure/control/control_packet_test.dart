import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_packet.dart';

void main() {
  test('encodes and decodes control packets', () {
    const packet = ControlPacket(
      type: ControlPacketType.linkRequest,
      protocolVersion: '1.0',
      messageId: 'msg-1',
      correlationId: 'corr-1',
      sourcePeerId: 'alice@mac',
      targetPeerId: 'bob@pc',
      sentAtEpochMs: 1,
      sessionId: 'session-1',
      nonce: 'nonce',
    );

    final decoded = ControlPacket.decode(packet.encode());

    expect(decoded.type, ControlPacketType.linkRequest);
    expect(decoded.correlationId, 'corr-1');
    expect(decoded.nonce, 'nonce');
  });

  test('rejects malformed control packets', () {
    expect(
      () => ControlPacket.decode(const []),
      throwsA(isA<FormatException>()),
    );
  });
}
