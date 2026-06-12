import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/app_lifecycle/app_lifecycle_state_machine.dart';

void main() {
  const machine = AppLifecycleStateMachine();

  test('follows the normal startup transition path', () {
    var state = AppLifecycleStatus.initial;

    var result = machine.transition(
      state,
      AppLifecycleEvent.loadConfigRequested,
    );
    expect(result.state, AppLifecycleStatus.loadingConfig);
    expect(result.effects.map((effect) => effect.name), contains('loadConfig'));

    state = result.state;
    result = machine.transition(state, AppLifecycleEvent.configLoaded);
    expect(result.state, AppLifecycleStatus.initializingStorage);

    state = result.state;
    result = machine.transition(state, AppLifecycleEvent.storageInitialized);
    expect(result.state, AppLifecycleStatus.bindingPorts);

    state = result.state;
    result = machine.transition(state, AppLifecycleEvent.portsBound);
    expect(result.state, AppLifecycleStatus.networkReady);

    state = result.state;
    result = machine.transition(state, AppLifecycleEvent.loginRequired);
    expect(result.state, AppLifecycleStatus.requiresLogin);

    state = result.state;
    result = machine.transition(state, AppLifecycleEvent.authenticated);
    expect(result.state, AppLifecycleStatus.authenticated);

    state = result.state;
    result = machine.transition(state, AppLifecycleEvent.runRequested);
    expect(result.state, AppLifecycleStatus.running);
  });

  test('does not enter running when port binding fails', () {
    final result = machine.transition(
      AppLifecycleStatus.bindingPorts,
      AppLifecycleEvent.portBindingFailed,
    );

    expect(result.state, AppLifecycleStatus.failed);
    expect(result.disposition, TransitionDisposition.failure);
    expect(result.issue?.code, 'port_binding_failed');
  });

  test('rejects transfer commands before the app is running', () {
    final result = machine.transition(
      AppLifecycleStatus.requiresLogin,
      AppLifecycleEvent.transferCommandRequested,
    );

    expect(result.isFailure, isTrue);
    expect(result.issue?.code, 'transfer_not_allowed');
  });

  test('shutdown requests emit cleanup effects', () {
    final result = machine.transition(
      AppLifecycleStatus.running,
      AppLifecycleEvent.shutdownRequested,
    );

    expect(result.state, AppLifecycleStatus.shuttingDown);
    expect(
      result.effects.map((effect) => effect.name),
      containsAll(['sendDiscoveryGoodbye', 'cancelActiveTransfers']),
    );
  });
}
