class DataTransferTuningPolicy {
  const DataTransferTuningPolicy({
    required this.initialWindowSize,
    required this.maximumWindowSize,
    required this.receiverAdvertisedWindow,
    required this.windowUpdateChunkInterval,
    required this.ackBatchChunkThreshold,
    required this.maxRetransmissions,
    required this.maxNackIndexesPerPacket,
    required this.ackBatchInterval,
    required this.metricLogInterval,
  });

  static const int safeUdpPayloadBytes = 1472;
  static const int fixedHeaderBytes = 72;
  static const int defaultAuthTagBytes = 16;
  static const int defaultInitialWindowSize = 32;
  static const int defaultMaximumWindowSize = 256;
  static const int defaultReceiverAdvertisedWindow = 256;
  static const int defaultWindowUpdateChunkInterval = 16;
  static const int defaultAckBatchChunkThreshold = 16;
  static const int defaultMaxRetransmissions = 6;
  static const int defaultMaxNackIndexesPerPacket = 32;
  static const Duration defaultAckBatchInterval = Duration(milliseconds: 4);
  static const Duration defaultMetricLogInterval = Duration(milliseconds: 700);

  static const defaults = DataTransferTuningPolicy(
    initialWindowSize: defaultInitialWindowSize,
    maximumWindowSize: defaultMaximumWindowSize,
    receiverAdvertisedWindow: defaultReceiverAdvertisedWindow,
    windowUpdateChunkInterval: defaultWindowUpdateChunkInterval,
    ackBatchChunkThreshold: defaultAckBatchChunkThreshold,
    maxRetransmissions: defaultMaxRetransmissions,
    maxNackIndexesPerPacket: defaultMaxNackIndexesPerPacket,
    ackBatchInterval: defaultAckBatchInterval,
    metricLogInterval: defaultMetricLogInterval,
  );

  final int initialWindowSize;
  final int maximumWindowSize;
  final int receiverAdvertisedWindow;
  final int windowUpdateChunkInterval;
  final int ackBatchChunkThreshold;
  final int maxRetransmissions;
  final int maxNackIndexesPerPacket;
  final Duration ackBatchInterval;
  final Duration metricLogInterval;

  int get maxPayloadBytes => maxPayloadBytesFor();

  int get maximumInFlightBytes => maxPayloadBytes * maximumWindowSize;

  bool get batchesAcks => ackBatchChunkThreshold > 1;

  bool get usesSingleRetransmissionScanPolicy => maxRetransmissions > 0;

  List<String> validate() {
    final issues = <String>[];
    if (initialWindowSize < 1) {
      issues.add('initial_window_below_one');
    }
    if (maximumWindowSize < initialWindowSize) {
      issues.add('maximum_window_below_initial');
    }
    if (receiverAdvertisedWindow < initialWindowSize) {
      issues.add('receiver_window_below_initial');
    }
    if (ackBatchChunkThreshold <= 1) {
      issues.add('ack_batch_threshold_per_chunk');
    }
    if (ackBatchChunkThreshold > receiverAdvertisedWindow) {
      issues.add('ack_batch_threshold_above_receiver_window');
    }
    if (windowUpdateChunkInterval <= 1) {
      issues.add('window_update_interval_per_chunk');
    }
    if (maxNackIndexesPerPacket < ackBatchChunkThreshold) {
      issues.add('nack_indexes_below_ack_batch');
    }
    if (maxPayloadBytes <= 0) {
      issues.add('payload_budget_empty');
    }
    return issues;
  }

  static int maxPayloadBytesFor({
    int safeDatagramBytes = safeUdpPayloadBytes,
    int ackBitmapWords = 0,
    int authTagBytes = defaultAuthTagBytes,
  }) {
    final headerBytes = fixedHeaderBytes + ackBitmapWords * 4;
    final payloadBytes = safeDatagramBytes - headerBytes - authTagBytes;
    return payloadBytes < 0 ? 0 : payloadBytes;
  }
}
