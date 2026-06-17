import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_chunk_byte_length_command.dart';

void main() {
  group('TransferOutgoingChunkByteLengthCommand', () {
    test('returns chunk size for a full chunk', () {
      expect(
        TransferOutgoingChunkByteLengthCommand.calculate(
          fileSize: 10_000,
          chunkSize: 1024,
          chunkIndex: 3,
        ),
        1024,
      );
    });

    test('returns remaining bytes for the final partial chunk', () {
      expect(
        TransferOutgoingChunkByteLengthCommand.calculate(
          fileSize: 2500,
          chunkSize: 1024,
          chunkIndex: 2,
        ),
        452,
      );
    });
  });
}
