import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/app/app.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/core/errors/error_presenter.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';

void main() {
  testWidgets('renders login screen and navigates into shell', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1024);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.production()),
          appLoggerProvider.overrideWithValue(
            const ConsoleAppLogger(minimumLevel: AppLogLevel.debug),
          ),
          errorPresenterProvider.overrideWithValue(ErrorPresenter()),
          authControllerProvider.overrideWith(TestAuthController.new),
          localDeviceIdentityServiceProvider.overrideWithValue(
            const _WidgetLocalDeviceIdentityService(),
          ),
          localAuthPortProvider.overrideWithValue(38401),
          discoveryTransportProvider.overrideWithValue(
            _WidgetDiscoveryTransport(),
          ),
          nowProvider.overrideWithValue(() => DateTime(2026, 4, 9, 12, 0, 0)),
        ],
        child: const SponzeyFileSharingApp(),
      ),
    );

    expect(find.text('로그인'), findsAtLeastNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, '로그인'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(find.text('Queue Snapshot'), findsOneWidget);
  });
}

class TestAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> signIn({
    required String userId,
    required String password,
  }) async {
    state = AuthState(
      status: AuthStatus.authenticated,
      currentUser: UserAccount(
        userId: userId,
        displayName: 'Widget Test User',
        deviceName: 'Widget Test Device',
      ),
      sessionPassword: password,
    );
  }
}

class _WidgetLocalDeviceIdentityService implements LocalDeviceIdentityService {
  const _WidgetLocalDeviceIdentityService();

  @override
  Future<LocalDeviceIdentity> load() async {
    return const LocalDeviceIdentity(
      deviceId: 'widget-device',
      instanceId: 'widget-instance',
      osType: 'macos',
    );
  }
}

class _WidgetDiscoveryTransport implements DiscoveryTransport {
  @override
  Future<void> close() async {}

  @override
  Stream<DiscoveryDatagram> get packets => const Stream.empty();

  @override
  Future<void> sendBroadcast(
    DiscoveryPacket packet, {
    required int port,
  }) async {}

  @override
  Future<void> sendUnicast(
    DiscoveryPacket packet, {
    required address,
    required int port,
  }) async {}

  @override
  Future<void> start({required int port}) async {}
}
