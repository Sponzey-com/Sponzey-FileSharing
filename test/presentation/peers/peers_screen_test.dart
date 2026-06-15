import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_overview_provider.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/presentation/peers/peers_screen.dart';

void main() {
  testWidgets(
    'peer cards stay constrained with long names and product-safe network details',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(480, 720);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final peer = _peer();
      final candidate = _candidate(peer.id);
      final activePath = PeerConnectionPath.fromCandidate(
        candidate: candidate,
        selectedAt: DateTime.utc(2026),
        selectionReason: PeerPathSelectionReason.sameSubnet,
      ).copyWith(status: PeerPathStatus.active);
      final registry = PeerPathRegistry()..select(activePath);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryControllerProvider.overrideWith(
              _PeersScreenDiscoveryController.new,
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
            peerAuthSessionByPeerIdProvider(peer.id).overrideWith(
              (ref) => _session(peer, status: PeerAuthStatus.authenticated),
            ),
            peerRouteCandidateStoreProvider.overrideWith((ref) => [candidate]),
            peerPathRegistryProvider.overrideWithValue(registry),
          ],
          child: const MaterialApp(home: Scaffold(body: PeersScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('연결됨'), findsOneWidget);
      expect(find.text('파일 보내기'), findsOneWidget);
      expect(find.textContaining('10.20.30.'), findsNothing);
      expect(
        find.textContaining('very-long-ethernet-interface-name'),
        findsNothing,
      );
      expect(find.textContaining('token'), findsNothing);
      expect(find.textContaining('password'), findsNothing);
    },
  );

  testWidgets('authenticated peer waits for active path before enabling send', (
    tester,
  ) async {
    final peer = _peer();
    final candidate = _candidate(peer.id);
    final authenticatingPath = PeerConnectionPath.fromCandidate(
      candidate: candidate,
      selectedAt: DateTime.utc(2026),
      selectionReason: PeerPathSelectionReason.sameSubnet,
    ).copyWith(status: PeerPathStatus.authenticating);
    final registry = PeerPathRegistry()..select(authenticatingPath);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(
            _PeersScreenDiscoveryController.new,
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
          peerAuthSessionByPeerIdProvider(peer.id).overrideWith(
            (ref) => _session(peer, status: PeerAuthStatus.authenticated),
          ),
          peerRouteCandidateStoreProvider.overrideWith((ref) => [candidate]),
          peerPathRegistryProvider.overrideWithValue(registry),
        ],
        child: const MaterialApp(home: Scaffold(body: PeersScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('경로 확인 중'), findsOneWidget);
    expect(find.text('자동 연결 대기 중'), findsOneWidget);
    final sendButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '자동 연결 대기 중'),
    );
    expect(sendButton.onPressed, isNull);
  });
}

class _PeersScreenDiscoveryController extends DiscoveryController {
  @override
  DiscoveryState build() {
    return DiscoveryState(
      peers: [_peer()],
      isLoading: false,
      isRunning: true,
      currentPairingUserId: 'team',
      currentDiscoveryGroupTagPreview: 'abc123',
    );
  }
}

PeerNode _peer() {
  return PeerNode(
    deviceId: 'device-b',
    userId: 'team',
    displayName:
        'Very Long Peer Display Name That Must Be Ellipsized In Product UI',
    deviceName:
        'Very-Long-Host-Name-That-Should-Not-Overflow-The-Peer-Card.local',
    osType: 'macos',
    protocolVersion: '1.0',
    lastSeenAt: DateTime.utc(2026),
    address: '10.20.30.40',
    port: 38401,
    receiveAvailable: true,
    presence: PeerPresence.online,
  );
}

PeerAuthSession _session(PeerNode peer, {required PeerAuthStatus status}) {
  return PeerAuthSession(
    sessionId: 'session-a',
    peerId: peer.id,
    peerUserId: peer.userId,
    peerDisplayName: peer.displayName,
    peerAddress: peer.address,
    peerPort: peer.port,
    status: status,
    updatedAt: DateTime.utc(2026),
  );
}

PeerRouteCandidate _candidate(String peerId) {
  return PeerRouteCandidate.create(
    peerId: peerId,
    remoteAddress: '10.20.30.40',
    remotePort: 38401,
    localInterfaceId: const NetworkInterfaceId(
      name: 'very-long-ethernet-interface-name',
      index: 77,
    ),
    localAddress: '10.20.30.5',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    score: 1200,
    localInterfaceTypeHint: InterfaceTypeHint.ethernet,
  );
}
