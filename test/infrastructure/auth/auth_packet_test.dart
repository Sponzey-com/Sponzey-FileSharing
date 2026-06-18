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

  test('encodes and decodes TCP data channel endpoint offer', () {
    const packet = AuthPacket(
      type: AuthPacketType.dataChannelOffer,
      protocolVersion: '1.0',
      sessionId: 'auth-session-a',
      fromUserId: 'admin',
      fromDeviceId: 'device-a',
      fromInstanceId: 'instance-a',
      dataChannelSessionId: 'tcp-session-a',
      dataChannelHost: '10.211.55.2',
      dataChannelPort: 50001,
      dataChannelDirection: 'inbound',
      sentAtEpochMs: 123,
    );

    final decoded = AuthPacket.decode(packet.encode());

    expect(decoded.type, AuthPacketType.dataChannelOffer);
    expect(decoded.dataChannelSessionId, 'tcp-session-a');
    expect(decoded.dataChannelHost, '10.211.55.2');
    expect(decoded.dataChannelPort, 50001);
    expect(decoded.dataChannelDirection, 'inbound');
  });

  test('encodes and decodes TCP data channel reject reason', () {
    const packet = AuthPacket(
      type: AuthPacketType.dataChannelReject,
      protocolVersion: '1.0',
      sessionId: 'auth-session-a',
      fromUserId: 'admin',
      fromDeviceId: 'device-a',
      dataChannelSessionId: 'tcp-session-a',
      rejectCode: 'invalid_tcp_data_endpoint_port',
      rejectMessage: 'invalid endpoint',
      sentAtEpochMs: 123,
    );

    final decoded = AuthPacket.decode(packet.encode());

    expect(decoded.type, AuthPacketType.dataChannelReject);
    expect(decoded.dataChannelSessionId, 'tcp-session-a');
    expect(decoded.rejectCode, 'invalid_tcp_data_endpoint_port');
    expect(decoded.rejectMessage, 'invalid endpoint');
  });
}
