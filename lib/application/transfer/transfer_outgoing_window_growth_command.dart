import 'package:sponzey_file_sharing/domain/transfer/data_transfer_tuning_policy.dart';

class TransferOutgoingWindowGrowthCommand {
  const TransferOutgoingWindowGrowthCommand._();

  static int afterDataAck({
    required DataTransferTuningPolicy tuningPolicy,
    required int currentWindowSize,
    required int maximumWindowSize,
    required int newlyAckedChunks,
  }) {
    return tuningPolicy.windowAfterAck(
      currentWindow: currentWindowSize,
      maximumWindow: maximumWindowSize,
      newlyAckedChunks: newlyAckedChunks,
    );
  }

  static int afterLegacyAck({
    required int currentWindowSize,
    required int maximumWindowSize,
  }) {
    if (currentWindowSize >= maximumWindowSize) {
      return currentWindowSize;
    }
    return currentWindowSize + 1;
  }
}
