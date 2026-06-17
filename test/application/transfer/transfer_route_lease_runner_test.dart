import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_route_lease_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_route_lease_state_machine.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

void main() {
  group('TransferRouteLeaseRunner', () {
    test('requestProbe transitions and delegates probeRoute', () async {
      final executor = _RecordingRouteExecutor();
      final runner = TransferRouteLeaseRunner(executor: executor);

      final result = await runner.requestProbe();

      expect(result.state, TransferRouteLeaseState.probing);
      expect(result.disposition, TransitionDisposition.transitioned);
      expect(runner.state, TransferRouteLeaseState.probing);
      expect(executor.calls, ['probeRoute']);
    });

    test('markProbeSucceeded delegates bindRouteLease', () async {
      final executor = _RecordingRouteExecutor();
      final runner = TransferRouteLeaseRunner(executor: executor);

      await runner.requestProbe();
      executor.calls.clear();
      final result = await runner.markProbeSucceeded();

      expect(result.state, TransferRouteLeaseState.verified);
      expect(runner.isUsableForTransfer, isTrue);
      expect(executor.calls, ['bindRouteLease']);
    });

    test('markProbeFailed delegates rejectRouteLease', () async {
      final executor = _RecordingRouteExecutor();
      final runner = TransferRouteLeaseRunner(executor: executor);

      await runner.requestProbe();
      executor.calls.clear();
      final result = await runner.markProbeFailed();

      expect(result.state, TransferRouteLeaseState.rejected);
      expect(runner.isUsableForTransfer, isFalse);
      expect(executor.calls, ['rejectRouteLease']);
    });

    test('markExpired delegates notifyRouteExpired', () async {
      final executor = _RecordingRouteExecutor();
      final runner = TransferRouteLeaseRunner(
        initialState: TransferRouteLeaseState.verified,
        executor: executor,
      );

      final result = await runner.markExpired();

      expect(result.state, TransferRouteLeaseState.expired);
      expect(runner.isUsableForTransfer, isFalse);
      expect(executor.calls, ['notifyRouteExpired']);
    });

    test('terminal no-op does not execute effects', () async {
      final executor = _RecordingRouteExecutor();
      final runner = TransferRouteLeaseRunner(
        initialState: TransferRouteLeaseState.rejected,
        executor: executor,
      );

      final result = await runner.requestProbe();

      expect(result.disposition, TransitionDisposition.warning);
      expect(result.state, TransferRouteLeaseState.rejected);
      expect(runner.state, TransferRouteLeaseState.rejected);
      expect(executor.calls, isEmpty);
    });
  });
}

class _RecordingRouteExecutor implements TransferRouteLeaseEffectExecutor {
  final List<String> calls = [];

  @override
  Future<void> bindRouteLease() async {
    calls.add('bindRouteLease');
  }

  @override
  Future<void> notifyRouteExpired() async {
    calls.add('notifyRouteExpired');
  }

  @override
  Future<void> probeRoute() async {
    calls.add('probeRoute');
  }

  @override
  Future<void> rejectRouteLease() async {
    calls.add('rejectRouteLease');
  }
}
