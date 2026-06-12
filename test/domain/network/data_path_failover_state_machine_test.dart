import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/network/data_path_failover_state_machine.dart';

void main() {
  test('bind failure retries the same interface data port', () {
    const machine = DataPathFailoverStateMachine();

    final result = machine.transition(
      _snapshot(),
      DataPathFailoverEvent.bindFailed,
    );

    expect(result.state.status, DataPathStatus.retryingSameInterface);
    expect(result.state.retryCount, 1);
    expect(result.effects.single.name, 'retrySameInterfaceDataPort');
  });

  test('same interface retry success resumes transfer', () {
    const machine = DataPathFailoverStateMachine();
    final state = _snapshot(status: DataPathStatus.retryingSameInterface);

    final result = machine.transition(
      state,
      DataPathFailoverEvent.sameInterfaceRetrySucceeded,
    );

    expect(result.state.status, DataPathStatus.transferring);
    expect(result.effects.single.name, 'resumeTransfer');
  });

  test(
    'same interface retry failure moves to alternate candidate failover',
    () {
      const machine = DataPathFailoverStateMachine();
      final state = _snapshot(status: DataPathStatus.retryingSameInterface);

      final result = machine.transition(
        state,
        DataPathFailoverEvent.sameInterfaceRetryFailed,
      );

      expect(result.state.status, DataPathStatus.failingOverInterface);
      expect(result.state.failoverCount, 1);
      expect(result.effects.single.name, 'selectAlternateRouteCandidate');
    },
  );

  test('alternate candidate success retransmits only missing chunks', () {
    const machine = DataPathFailoverStateMachine();
    final state = _snapshot(
      status: DataPathStatus.failingOverInterface,
      acked: {0, 1, 4},
      missing: {2, 3},
    );

    final result = machine.transition(
      state,
      DataPathFailoverEvent.alternateInterfaceSucceeded,
    );

    expect(result.state.status, DataPathStatus.transferring);
    expect(result.state.ackedChunkIndexes, {0, 1, 4});
    expect(result.state.missingChunkIndexes, {2, 3});
    expect(result.effects.single.name, 'retransmitMissingChunks');
  });

  test('alternate candidate failure fails transfer path', () {
    const machine = DataPathFailoverStateMachine();
    final state = _snapshot(status: DataPathStatus.failingOverInterface);

    final result = machine.transition(
      state,
      DataPathFailoverEvent.alternateInterfaceFailed,
    );

    expect(result.disposition, TransitionDisposition.failure);
    expect(result.state.status, DataPathStatus.failed);
  });

  test('RTT degraded publishes degraded effect', () {
    const machine = DataPathFailoverStateMachine();
    final state = _snapshot(status: DataPathStatus.transferring);

    final result = machine.transition(state, DataPathFailoverEvent.rttDegraded);

    expect(result.state.status, DataPathStatus.degraded);
    expect(result.effects.single.name, 'publishDataPathDegraded');
  });

  test('packet loss threshold requests failover path', () {
    const machine = DataPathFailoverStateMachine();
    final state = _snapshot(status: DataPathStatus.transferring);

    final result = machine.transition(
      state,
      DataPathFailoverEvent.packetLossExceeded,
    );

    expect(result.state.status, DataPathStatus.retryingSameInterface);
    expect(result.effects.single.name, 'retrySameInterfaceDataPort');
  });
}

DataPathFailoverSnapshot _snapshot({
  DataPathStatus status = DataPathStatus.binding,
  Set<int> acked = const {},
  Set<int> missing = const {},
}) {
  return DataPathFailoverSnapshot(
    transferId: 'transfer-001',
    peerId: 'peer-001',
    status: status,
    ackedChunkIndexes: acked,
    missingChunkIndexes: missing,
  );
}
