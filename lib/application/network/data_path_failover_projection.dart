import 'package:sponzey_file_sharing/domain/network/data_path_failover_state_machine.dart';

class DataPathFailoverProjection {
  final Map<String, DataPathFailoverSnapshot> _sessionsByTransferId = {};

  void upsert(DataPathFailoverSnapshot snapshot) {
    _sessionsByTransferId[snapshot.transferId] = snapshot;
  }

  DataPathFailoverSnapshot? byTransferId(String transferId) {
    return _sessionsByTransferId[transferId];
  }

  List<DataPathFailoverSnapshot> byPeerId(String peerId) {
    return _sessionsByTransferId.values
        .where((snapshot) => snapshot.peerId == peerId)
        .toList(growable: false);
  }
}
