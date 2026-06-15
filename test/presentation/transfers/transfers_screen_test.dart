import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/presentation/transfers/transfers_screen.dart';

void main() {
  testWidgets('does not show retry action for non-retryable transfer failure', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transferControllerProvider.overrideWith(_TransfersFakeController.new),
          authenticatedTransferPeersProvider.overrideWith((ref) => const []),
          peerAuthControllerProvider.overrideWith(_PeerAuthFakeController.new),
          settingsControllerProvider.overrideWith(_SettingsFakeController.new),
        ],
        child: const MaterialApp(home: Scaffold(body: TransfersScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Transfer Queue'), findsOneWidget);
    expect(find.text('demo.txt'), findsOneWidget);
    expect(find.text('재시도'), findsNothing);
    expect(find.textContaining('수신 파일 검증에 실패'), findsOneWidget);
  });
}

class _TransfersFakeController extends TransferController {
  @override
  TransferState build() {
    final now = DateTime.utc(2026, 1, 1, 12);
    return TransferState(
      jobs: [
        TransferJob(
          id: 'job-1',
          transferId: 'transfer-1',
          direction: TransferDirection.outgoing,
          peerId: 'peer-1',
          peerDisplayName: 'peer',
          fileName: 'demo.txt',
          fileSize: 12,
          bytesTransferred: 0,
          totalChunks: 1,
          completedChunks: 0,
          status: TransferJobStatus.failed,
          createdAt: now,
          updatedAt: now,
          localFilePath: '/tmp/demo.txt',
          message: '파일 해시가 일치하지 않습니다.',
        ),
      ],
      isLoading: false,
      isListening: true,
    );
  }
}

class _PeerAuthFakeController extends PeerAuthController {
  @override
  PeerAuthState build() {
    return const PeerAuthState(
      sessions: {},
      isListening: true,
      isLoading: false,
    );
  }
}

class _SettingsFakeController extends SettingsController {
  @override
  SettingsState build() {
    return const SettingsState(
      settings: AppSettings(
        defaultSavePath: '/tmp/Sponzey',
        autoReceiveEnabled: true,
        receivePolicy: ReceivePolicy.autoReceiveAll,
        logLevel: AppLogLevel.error,
      ),
      isLoading: false,
    );
  }
}
