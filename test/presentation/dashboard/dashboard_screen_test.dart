import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_overview_provider.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/presentation/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('recent peers show stable authenticated address without port', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final peer = _peer(address: '127.0.0.1', port: 38401);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(
            _DashboardDiscoveryController.new,
          ),
          discoveryOverviewProvider.overrideWith(
            (ref) => DiscoveryOverview(
              peers: [peer],
              onlineCount: 1,
              staleCount: 0,
              offlineCount: 0,
              incompatibleCount: 0,
            ),
          ),
          peerAuthControllerProvider.overrideWith(
            _DashboardPeerAuthController.new,
          ),
          transferJobsProvider.overrideWith((ref) => const []),
          activeTransferJobsProvider.overrideWith((ref) => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Recent Peers'), findsOneWidget);
    expect(find.textContaining('10.211.55.3'), findsOneWidget);
    expect(find.textContaining('127.0.0.1'), findsNothing);
    expect(find.textContaining(':38401'), findsNothing);
  });
}

class _DashboardDiscoveryController extends DiscoveryController {
  @override
  DiscoveryState build() {
    return DiscoveryState(
      peers: [_peer(address: '127.0.0.1', port: 38401)],
      isLoading: false,
      isRunning: true,
      currentPairingUserId: 'admin',
      currentDiscoveryGroupTagPreview: 'abc123',
    );
  }
}

class _DashboardPeerAuthController extends PeerAuthController {
  @override
  PeerAuthState build() {
    return PeerAuthState(
      sessions: {
        _peerId: PeerAuthSession(
          sessionId: 'session-1',
          peerId: _peerId,
          peerUserId: 'admin',
          peerDisplayName: 'admin',
          peerAddress: '10.211.55.3',
          peerPort: 38401,
          status: PeerAuthStatus.authenticated,
          updatedAt: DateTime.utc(2026),
        ),
      },
      isListening: true,
      isLoading: false,
    );
  }
}

const _peerId = 'admin@instance-peer';

PeerNode _peer({required String address, required int port}) {
  return PeerNode(
    deviceId: 'device-peer',
    instanceId: 'instance-peer',
    userId: 'admin',
    displayName: 'admin',
    deviceName: 'Windows VM',
    osType: 'windows',
    protocolVersion: '1.0',
    lastSeenAt: DateTime.utc(2026),
    address: address,
    port: port,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}
