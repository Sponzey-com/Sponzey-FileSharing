import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_diagnostics_ring_buffer.dart';

void main() {
  test('keeps only the most recent bounded frame traces', () {
    final buffer = TransferDiagnosticsRingBuffer(capacity: 2);

    buffer
      ..add(_trace(sequence: 1))
      ..add(_trace(sequence: 2))
      ..add(_trace(sequence: 3));

    final snapshot = buffer.snapshot();
    expect(snapshot.map((trace) => trace.sequence), [2, 3]);
    expect(buffer.length, 2);
  });
}

TransferFrameTrace _trace({required int sequence}) {
  return TransferFrameTrace(
    occurredAt: DateTime(2026, 6, 14),
    direction: 'in',
    frameType: 'dataChunk',
    sequence: sequence,
    chunkIndex: sequence,
    ackBase: 0,
    datagramBytes: 1200,
    endpoint: '127.0.0.1:38410',
    decisionCode: 'received',
  );
}
