import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/presentation/auth/login_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('login input focus and typing update button enabled state', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_RecordingAuth.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(_submitButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('login-user-id-field')));
    await tester.enterText(
      find.byKey(const ValueKey('login-user-id-field')),
      'admin',
    );
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('login-password-field')));
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'secret',
    );
    await tester.pump();

    expect(_submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('login primary action has desktop hit target and submits once', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    addTearDown(() => _resetViewport(tester));
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_RecordingAuth.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('login-user-id-field')),
      'admin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password-field')),
      'secret',
    );
    await tester.pump();

    final buttonFinder = find.byKey(const ValueKey('login-submit-button'));
    expect(tester.getSize(buttonFinder).height, greaterThanOrEqualTo(48));

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    final controller =
        container.read(authControllerProvider.notifier) as _RecordingAuth;
    expect(controller.signInCount, 1);
    expect(controller.lastUserId, 'admin');
    expect(controller.lastPassword, 'secret');
  });
}

ElevatedButton _submitButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.byKey(const ValueKey('login-submit-button')),
  );
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1024);
}

void _resetViewport(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

class _RecordingAuth extends AuthController {
  int signInCount = 0;
  String? lastUserId;
  String? lastPassword;

  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> signIn({
    required String userId,
    required String password,
  }) async {
    signInCount += 1;
    lastUserId = userId;
    lastPassword = password;
    state = AuthState(
      status: AuthStatus.authenticated,
      currentUser: UserAccount(
        userId: userId,
        displayName: userId,
        deviceName: 'Widget Test Device',
      ),
      sessionPassword: password,
    );
  }
}
