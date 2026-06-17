import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_metric_calculation_command.dart';

void main() {
  group('TransferMetricCalculationCommand', () {
    test('returns zero throughput for no elapsed time or no bytes', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        TransferMetricCalculationCommand.throughputBytesPerSec(
          transferredBytes: 2048,
          startedAt: now,
          now: now,
        ),
        0,
      );
      expect(
        TransferMetricCalculationCommand.throughputBytesPerSec(
          transferredBytes: 0,
          startedAt: now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        0,
      );
    });

    test('calculates throughput bytes per second', () {
      final now = DateTime(2026, 1, 1, 12);

      expect(
        TransferMetricCalculationCommand.throughputBytesPerSec(
          transferredBytes: 2048,
          startedAt: now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        2048,
      );
    });

    test(
      'returns zero loss rate when no acknowledged or retry count exists',
      () {
        expect(
          TransferMetricCalculationCommand.lossRate(
            acknowledgedChunkCount: 0,
            retryCount: 0,
          ),
          0,
        );
      },
    );

    test('calculates retry ratio over acknowledged plus retry count', () {
      expect(
        TransferMetricCalculationCommand.lossRate(
          acknowledgedChunkCount: 8,
          retryCount: 2,
        ),
        0.2,
      );
    });
  });
}
