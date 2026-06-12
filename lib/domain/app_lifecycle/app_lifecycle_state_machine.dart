import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

enum AppLifecycleStatus {
  initial,
  loadingConfig,
  initializingStorage,
  bindingPorts,
  networkReady,
  requiresLogin,
  authenticated,
  running,
  shuttingDown,
  stopped,
  failed,
}

enum AppLifecycleEvent {
  loadConfigRequested,
  configLoaded,
  storageInitialized,
  portsBound,
  portBindingFailed,
  loginRequired,
  authenticated,
  runRequested,
  transferCommandRequested,
  shutdownRequested,
  shutdownCompleted,
  failed,
}

class AppLifecycleStateMachine
    implements StateMachine<AppLifecycleStatus, AppLifecycleEvent> {
  const AppLifecycleStateMachine();

  @override
  TransitionResult<AppLifecycleStatus> transition(
    AppLifecycleStatus state,
    AppLifecycleEvent event,
  ) {
    if (event == AppLifecycleEvent.failed) {
      return TransitionResult.transitioned(AppLifecycleStatus.failed);
    }

    if (event == AppLifecycleEvent.transferCommandRequested) {
      if (state == AppLifecycleStatus.running) {
        return TransitionResult.noOp(state);
      }
      return TransitionResult.failure(
        state,
        issue: const TransitionIssue(
          code: 'transfer_not_allowed',
          message: 'Transfer commands require the app to be running.',
        ),
      );
    }

    switch ((state, event)) {
      case (AppLifecycleStatus.initial, AppLifecycleEvent.loadConfigRequested):
        return TransitionResult.transitioned(
          AppLifecycleStatus.loadingConfig,
          effects: const [TransitionEffect('loadConfig')],
        );
      case (AppLifecycleStatus.loadingConfig, AppLifecycleEvent.configLoaded):
        return TransitionResult.transitioned(
          AppLifecycleStatus.initializingStorage,
          effects: const [TransitionEffect('initializeStorage')],
        );
      case (
        AppLifecycleStatus.initializingStorage,
        AppLifecycleEvent.storageInitialized,
      ):
        return TransitionResult.transitioned(
          AppLifecycleStatus.bindingPorts,
          effects: const [TransitionEffect('bindPorts')],
        );
      case (AppLifecycleStatus.bindingPorts, AppLifecycleEvent.portsBound):
        return TransitionResult.transitioned(AppLifecycleStatus.networkReady);
      case (
        AppLifecycleStatus.bindingPorts,
        AppLifecycleEvent.portBindingFailed,
      ):
        return TransitionResult.failure(
          AppLifecycleStatus.failed,
          issue: const TransitionIssue(
            code: 'port_binding_failed',
            message: 'The app cannot run until required UDP ports are bound.',
          ),
        );
      case (AppLifecycleStatus.networkReady, AppLifecycleEvent.loginRequired):
        return TransitionResult.transitioned(AppLifecycleStatus.requiresLogin);
      case (AppLifecycleStatus.requiresLogin, AppLifecycleEvent.authenticated):
        return TransitionResult.transitioned(AppLifecycleStatus.authenticated);
      case (AppLifecycleStatus.authenticated, AppLifecycleEvent.runRequested):
        return TransitionResult.transitioned(AppLifecycleStatus.running);
      case (AppLifecycleStatus.running, AppLifecycleEvent.shutdownRequested):
        return TransitionResult.transitioned(
          AppLifecycleStatus.shuttingDown,
          effects: const [
            TransitionEffect('sendDiscoveryGoodbye'),
            TransitionEffect('cancelActiveTransfers'),
          ],
        );
      case (
        AppLifecycleStatus.shuttingDown,
        AppLifecycleEvent.shutdownCompleted,
      ):
        return TransitionResult.transitioned(AppLifecycleStatus.stopped);
      default:
        return TransitionResult.warning(
          state,
          issue: TransitionIssue(
            code: 'invalid_app_lifecycle_transition',
            message: 'Cannot apply $event while app lifecycle is $state.',
          ),
        );
    }
  }
}
