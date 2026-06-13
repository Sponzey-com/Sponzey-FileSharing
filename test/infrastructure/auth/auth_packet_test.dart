import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';

void main() {
  test('encodes and decodes optional runtime instance id', () {
    const packet = AuthPacket(
      type: AuthPacketType.connectRequest,
      protocolVersion: '1.0',
      sessionId: 'session-a',
      fromUserId: 'admin',
      fromDeviceId: 'device-a',
      fromInstanceId: 'instance-a',
      sentAtEpochMs: 123,
    );

    final decoded = AuthPacket.decode(packet.encode());

    expect(decoded.fromDeviceId, 'device-a');
    expect(decoded.fromInstanceId, 'instance-a');
  });

  test('decodes legacy packets without runtime instance id', () {
    const packet = AuthPacket(
      type: AuthPacketType.connectRequest,
      protocolVersion: '1.0',
      sessionId: 'session-a',
      fromUserId: 'admin',
      fromDeviceId: 'device-a',
      sentAtEpochMs: 123,
    );

    final decoded = AuthPacket.decode(packet.encode());

    expect(decoded.fromDeviceId, 'device-a');
    expect(decoded.fromInstanceId, isNull);
  });
}
