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
    expect(find.textContaining('password'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });
}

PeerRouteCandidate _candidate() {
  return PeerRouteCandidate.create(
    peerId: 'peer-a',
    remoteAddress: '10.0.1.20',
    remotePort: 38401,
    localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 1),
    localAddress: '10.0.1.10',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    rttMs: 12,
  );
}
