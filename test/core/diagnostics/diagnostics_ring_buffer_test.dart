import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/diagnostics/diagnostics_ring_buffer.dart';

void main() {
  test('keeps newest entries and evicts oldest entry when capacity is reached', () {
    final buffer = DiagnosticsRingBuffer<int>(capacity: 2);

    buffer.add(1);
    buffer.add(2);
    buffer.add(3);

    expect(buffer.snapshot(), [2, 3]);
    expect(() => buffer.snapshot().add(4), throwsUnsupportedError);
  });

  test('rejects non-positive capacity', () {
    expect(() => DiagnosticsRingBuffer<int>(capacity: 0), throwsArgumentError);
  });
}
