import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TransferDataFrameKeyRegistry {
  final Map<TransferDirection, Map<String, String>> _transferIdsByDirection = {
    TransferDirection.outgoing: <String, String>{},
    TransferDirection.incoming: <String, String>{},
  };

  void register({
    required TransferDirection direction,
    required String frameKey,
    required String transferId,
  }) {
    _registryFor(direction)[frameKey] = transferId;
  }

  String? lookup({
    required TransferDirection direction,
    required String frameKey,
  }) {
    return _registryFor(direction)[frameKey];
  }

  void remove({
    required TransferDirection direction,
    required String frameKey,
    required String transferId,
  }) {
    final registry = _registryFor(direction);
    if (registry[frameKey] != transferId) {
      return;
    }
    registry.remove(frameKey);
  }

  Map<String, String> _registryFor(TransferDirection direction) {
    return _transferIdsByDirection[direction]!;
  }
}
