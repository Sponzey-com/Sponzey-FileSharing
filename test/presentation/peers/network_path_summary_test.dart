import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/presentation/peers/network_path_summary.dart';

void main() {
  testWidgets('shows product fallback when no candidates exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: NetworkPathSummary(peerId: 'peer-a')),
      ),
    );

    expect(find.text('연결 경로 정보 없음'), findsOneWidget);
  });

  testWidgets('shows debug diagnostics without sensitive values', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peerRouteCandidateStoreProvider.overrideWith((ref) => [_candidate()]),
        ],
        child: const MaterialApp(
          home: NetworkPathSummary(peerId: 'peer-a', debug: true),
        ),
      ),
    );

    expect(find.textContaining('candidates=1'), findsOneWidget);
    expect(find.textContaining('type=unknown'), findsOneWidget);
    expect(find.textContaining('rtt=12'), findsOneWidget);
    expect(find.textContaining('password'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('keeps long debug rows constrained without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 240);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          peerRouteCandidateStoreProvider.overrideWith(
            (ref) => [_candidate(interfaceName: 'very-long-interface-name')],
          ),
        ],
        child: const MaterialApp(
          home: SizedBox(
            width: 160,
            child: NetworkPathSummary(peerId: 'peer-a', debug: true),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('very-long-interface-name'), findsOneWidget);
  });
}

PeerRouteCandidate _candidate({String interfaceName = 'en0'}) {
  return PeerRouteCandidate.create(
    peerId: 'peer-a',
    remoteAddress: '10.0.1.20',
    remotePort: 38401,
    localInterfaceId: NetworkInterfaceId(name: interfaceName, index: 1),
    localAddress: '10.0.1.10',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    rttMs: 12,
  );
}
