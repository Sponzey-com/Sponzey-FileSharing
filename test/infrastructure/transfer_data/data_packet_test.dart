import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_packet.dart';

void main() {
  test('encodes and decodes data packets with AEAD metadata', () {
    const packet = DataPacket(
      type: DataPacketType.dataChunk,
      protocolVersion: '1.0',
      messageId: 'msg-1',
      correlationId: 'corr-1',
      sourcePeerId: 'alice@mac',
      targetPeerId: 'bob@pc',
      sessionId: 'session-1',
      transferId: 'transfer-1',
      sentAtEpochMs: 1,
      fileId: 'file-1',
      chunkIndex: 3,
      payloadBase64: 'YWJj',
      payloadChecksum: 'checksum',
      aeadNonce: 'nonce',
      aeadTag: 'tag',
    );

    final decoded = DataPacket.decode(packet.encode());

    expect(decoded.type, DataPacketType.dataChunk);
    expect(decoded.chunkIndex, 3);
    expect(decoded.aeadNonce, 'nonce');
    expect(decoded.aeadTag, 'tag');
  });

  test('encodes selective nack indexes', () {
    const packet = DataPacket(
      type: DataPacketType.dataNack,
      protocolVersion: '1.0',
      messageId: 'msg-1',
      correlationId: 'corr-1',
      sourcePeerId: 'bob@pc',
      targetPeerId: 'alice@mac',
      sessionId: 'session-1',
      transferId: 'transfer-1',
      sentAtEpochMs: 1,
      chunkIndexes: [1, 3, 5],
    );

    final decoded = DataPacket.decode(packet.encode());

    expect(decoded.chunkIndexes, [1, 3, 5]);
  });
}
