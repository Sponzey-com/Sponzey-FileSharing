import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

void main() {
  const codec = TcpIncomingTransferMetadataCodec();

  test('encodes and decodes metadata payload', () {
    const metadata = TcpIncomingTransferMetadata(
      fileName: 'report.pdf',
      fileSize: 12345,
      chunkCount: 8,
      sha256: 'abc123',
    );

    final decoded = codec.decode(codec.encode(metadata));

    expect(decoded.fileName, 'report.pdf');
    expect(decoded.fileSize, 12345);
    expect(decoded.chunkCount, 8);
    expect(decoded.sha256, 'abc123');
  });

  test('allows missing sha256 for peers that do not provide a digest', () {
    const metadata = TcpIncomingTransferMetadata(
      fileName: 'report.pdf',
      fileSize: 12345,
      chunkCount: 8,
    );

    final decoded = codec.decode(codec.encode(metadata));

    expect(decoded.sha256, isNull);
  });

  test('rejects malformed metadata payload', () {
    expect(
      () => codec.decode([123, 34, 102]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Invalid TCP metadata payload'),
        ),
      ),
    );
  });

  test('rejects missing required fields and invalid numeric values', () {
    expect(
      () => codec.decode(
        '{"fileName":"report.pdf","fileSize":0,"chunkCount":1}'.codeUnits,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decode(
        '{"fileName":"","fileSize":10,"chunkCount":1}'.codeUnits,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => codec.decode(
        '{"fileName":"report.pdf","fileSize":10,"chunkCount":0}'.codeUnits,
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
