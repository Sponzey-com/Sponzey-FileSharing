import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_benchmark_result.dart';

void main() {
  test(
    'benchmark result schema includes throughput and receiver digest gate',
    () {
      const result = TransferBenchmarkResult(
        routeType: 'vm-bridge',
        operatingSystem: 'macos-to-windows',
        buildMode: 'release',
        fileSizeBytes: 100 * 1024 * 1024,
        durationMs: 10000,
        averageBytesPerSecond: 10 * 1024 * 1024,
        lossRate: 0,
        retryCount: 0,
        receiverDigestVerified: true,
      );

      expect(result.averageMegabytesPerSecond, 10);
      expect(result.isReleaseGateEligible, isTrue);
      expect(result.toJson(), {
        'routeType': 'vm-bridge',
        'operatingSystem': 'macos-to-windows',
        'buildMode': 'release',
        'fileSizeBytes': 104857600,
        'durationMs': 10000,
        'averageBytesPerSecond': 10485760.0,
        'averageMegabytesPerSecond': 10.0,
        'lossRate': 0.0,
        'retryCount': 0,
        'receiverDigestVerified': true,
      });
    },
  );

  test(
    'benchmark result is not release-gate eligible without receiver digest',
    () {
      const result = TransferBenchmarkResult(
        routeType: 'same-host',
        operatingSystem: 'macos',
        buildMode: 'release',
        fileSizeBytes: 100 * 1024 * 1024,
        durationMs: 5000,
        averageBytesPerSecond: 20 * 1024 * 1024,
        lossRate: 0,
        retryCount: 0,
        receiverDigestVerified: false,
      );

      expect(result.isReleaseGateEligible, isFalse);
    },
  );
}
