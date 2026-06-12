import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';

void main() {
  test('encodes and decodes discovery packets', () {
    const packet = DiscoveryPacket(
      type: DiscoveryPacketType.discover,
      protocolVersion: '1.0',
      userId: 'admin',
      pairingProof: 'proof-001',
      instanceId: 'instance-001',
      displayName: 'Sponzey Admin',
      deviceId: 'device-001',
      deviceName: 'Main Mac',
      osType: 'macos',
      port: 38401,
      receiveAvailable: true,
      sentAtEpochMs: 123456789,
      sourceInterfaceId: 'en0#4',
      sourceInterfaceHint: 'ethernet',
      sourceAddress: '192.168.10.23',
    );

    final encoded = packet.encode();
    final decoded = DiscoveryPacket.decode(encoded);

    expect(decoded.type, DiscoveryPacketType.discover);
    expect(decoded.protocolVersion, '1.0');
    expect(decoded.userId, 'admin');
    expect(decoded.pairingProof, 'proof-001');
    expect(decoded.instanceId, 'instance-001');
    expect(decoded.displayName, 'Sponzey Admin');
    expect(decoded.deviceId, 'device-001');
    expect(decoded.deviceName, 'Main Mac');
    expect(decoded.osType, 'macos');
    expect(decoded.port, 38401);
    expect(decoded.receiveAvailable, isTrue);
    expect(decoded.sentAtEpochMs, 123456789);
    expect(decoded.sourceInterfaceId, 'en0#4');
    expect(decoded.sourceInterfaceHint, 'ethernet');
    expect(decoded.sourceAddress, '192.168.10.23');
  });

  test('decodes legacy packets without source hints', () {
    const payload = '''
{
  "type": "DISCOVER",
  "protocolVersion": "1.0",
  "userId": "admin",
  "pairingProof": "proof-001",
  "instanceId": "instance-001",
  "displayName": "Sponzey Admin",
  "deviceId": "device-001",
  "deviceName": "Main Mac",
  "osType": "macos",
  "port": 38401,
  "receiveAvailable": true,
  "sentAtEpochMs": 123456789
}
''';

    final decoded = DiscoveryPacket.decode(payload.codeUnits);

    expect(decoded.sourceInterfaceId, isNull);
    expect(decoded.sourceInterfaceHint, isNull);
    expect(decoded.sourceAddress, isNull);
  });

  test('rejects malformed payloads', () {
    expect(
      () => DiscoveryPacket.decode('{"type":"DISCOVER"}'.codeUnits),
      throwsFormatException,
    );
  });
}
