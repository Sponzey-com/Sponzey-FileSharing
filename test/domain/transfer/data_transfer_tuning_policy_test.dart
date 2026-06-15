import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_tuning_policy.dart';

void main() {
  test(
    'default policy uses batched ACKs and high throughput window budget',
    () {
      const policy = DataTransferTuningPolicy.defaults;

      expect(policy.validate(), isEmpty);
      expect(policy.initialWindowSize, greaterThanOrEqualTo(16));
      expect(policy.maximumWindowSize, greaterThanOrEqualTo(128));
      expect(policy.receiverAdvertisedWindow, greaterThanOrEqualTo(128));
      expect(policy.ackBatchChunkThreshold, greaterThan(1));
      expect(policy.batchesAcks, isTrue);
      expect(policy.maximumInFlightBytes, greaterThanOrEqualTo(128 * 1024));
    },
  );

  test('payload budget leaves room for fixed header and auth tag', () {
    expect(
      DataTransferTuningPolicy.maxPayloadBytesFor(),
      DataTransferTuningPolicy.safeUdpPayloadBytes -
          DataTransferTuningPolicy.fixedHeaderBytes -
          DataTransferTuningPolicy.defaultAuthTagBytes,
    );
    expect(
      DataTransferTuningPolicy.maxPayloadBytesFor(ackBitmapWords: 4),
      DataTransferTuningPolicy.maxPayloadBytesFor() - 16,
    );
  });

  test('validation catches per-chunk ACK and impossible window settings', () {
    const policy = DataTransferTuningPolicy(
      initialWindowSize: 8,
      maximumWindowSize: 4,
      receiverAdvertisedWindow: 4,
      windowUpdateChunkInterval: 1,
      ackBatchChunkThreshold: 1,
      maxRetransmissions: 6,
      maxNackIndexesPerPacket: 0,
      ackBatchInterval: Duration(milliseconds: 4),
      metricLogInterval: Duration(milliseconds: 700),
    );

    expect(
      policy.validate(),
      containsAll([
        'maximum_window_below_initial',
        'receiver_window_below_initial',
        'ack_batch_threshold_per_chunk',
        'window_update_interval_per_chunk',
        'nack_indexes_below_ack_batch',
      ]),
    );
  });
}
