import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_rtt_estimator.dart';

void main() {
  test('recalculates timeout from RTT samples and backs off on timeout', () {
    final estimator = TransferRttEstimator(
      initialTimeout: const Duration(milliseconds: 400),
      minimumTimeout: const Duration(milliseconds: 200),
      maximumTimeout: const Duration(seconds: 2),
    );

    expect(estimator.currentTimeout, const Duration(milliseconds: 400));

    estimator.recordSample(const Duration(milliseconds: 120));
    final firstTimeout = estimator.currentTimeout;
    expect(firstTimeout, greaterThan(const Duration(milliseconds: 200)));
    expect(estimator.smoothedRttMs, closeTo(120, 0.1));

    estimator.recordSample(const Duration(milliseconds: 200));
    final secondTimeout = estimator.currentTimeout;
    expect(secondTimeout, isNot(equals(firstTimeout)));
    expect(estimator.smoothedRttMs, greaterThan(120));

    estimator.noteTimeoutBackoff();
    expect(estimator.currentTimeout, greaterThan(secondTimeout));
    expect(
      estimator.currentTimeout,
      lessThanOrEqualTo(const Duration(seconds: 2)),
    );
  });
}
