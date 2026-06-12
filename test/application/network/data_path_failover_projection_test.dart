import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/network/data_path_failover_projection.dart';
import 'package:sponzey_file_sharing/domain/network/data_path_failover_state_machine.dart';

void main() {
  test('keeps 1:N transfer data path state isolated per peer', () {
    final projection = DataPathFailoverProjection()
      ..upsert(_snapshot('transfer-a', 'peer-a', DataPathStatus.transferring))
      ..upsert(_snapshot('transfer-b', 'peer-b', DataPathStatus.failed));

    expect(
      projection.byTransferId('transfer-a')!.status,
      DataPathStatus.transferring,
    );
    expect(
      projection.byTransferId('transfer-b')!.status,
      DataPathStatus.failed,
    );
    expect(projection.byPeerId('peer-a'), hasLength(1));
    expect(projection.byPeerId('peer-b'), hasLength(1));
  });
}

DataPathFailoverSnapshot _snapshot(
  String transferId,
  String peerId,
  DataPathStatus status,
) {
  return DataPathFailoverSnapshot(
    transferId: transferId,
    peerId: peerId,
    status: status,
  );
}
