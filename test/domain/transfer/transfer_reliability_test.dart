import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_reliability.dart';

void main() {
  test('detects missing chunks', () {
    const detector = MissingChunkDetector();

    expect(
      detector.missingChunks(totalChunks: 6, receivedChunkIndexes: {0, 2, 5}),
      [1, 3, 4],
    );
  });

  test(
    'plans sliding window chunks excluding acknowledged and inflight chunks',
    () {
      const scheduler = SlidingWindowScheduler();

      final plan = scheduler.plan(
        nextChunkIndex: 0,
        totalChunks: 8,
        windowSize: 4,
        inflightChunkIndexes: {1},
        acknowledgedChunkIndexes: {0},
      );

      expect(plan.chunkIndexes, [2, 3, 4, 5]);
    },
  );

  test('retry policy fails and shrinks window predictably', () {
    const policy = RetryPolicy(
      maxRetries: 6,
      initialWindowSize: 8,
      minimumWindowSize: 1,
    );

    expect(policy.shouldFail(5), isFalse);
    expect(policy.shouldFail(6), isTrue);
    expect(policy.shrinkWindow(8), 4);
    expect(policy.shrinkWindow(1), 1);
  });
}
