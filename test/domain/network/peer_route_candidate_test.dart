import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

void main() {
  test('keeps same peer candidates on different interfaces separately', () {
    final collection = PeerRouteCandidateCollection();
    final now = DateTime.utc(2026);

    collection.upsert(
      _candidate(
        interfaceId: const NetworkInterfaceId(name: 'en0', index: 1),
        localAddress: '10.0.1.10',
        remoteAddress: '10.0.1.20',
        seenAt: now,
      ),
    );
    collection.upsert(
      _candidate(
        interfaceId: const NetworkInterfaceId(name: 'en1', index: 2),
        localAddress: '192.168.1.10',
        remoteAddress: '192.168.1.20',
        seenAt: now,
      ),
    );

    expect(collection.candidatesForPeer('user@device'), hasLength(2));
  });

  test(
    'keeps same interface candidates with different local addresses separately',
    () {
      final collection = PeerRouteCandidateCollection();
      final now = DateTime.utc(2026);
      const interfaceId = NetworkInterfaceId(name: 'en0', index: 1);

      collection.upsert(
        _candidate(
          interfaceId: interfaceId,
          localAddress: '10.0.1.10',
          remoteAddress: '10.0.1.20',
          seenAt: now,
        ),
      );
      collection.upsert(
        _candidate(
          interfaceId: interfaceId,
          localAddress: '10.0.1.11',
          remoteAddress: '10.0.1.20',
          seenAt: now,
        ),
      );

      expect(collection.candidatesForPeer('user@device'), hasLength(2));
    },
  );

  test('represents unknown fallback candidates with any bind mode', () {
    final candidate = PeerRouteCandidate.create(
      peerId: 'user@device',
      remoteAddress: '10.0.1.20',
      remotePort: 38401,
      localInterfaceId: const NetworkInterfaceId(
        name: 'unknown',
        index: -1,
        stableId: 'unknown',
      ),
      localAddress: '0.0.0.0',
      discoveredBy: RouteCandidateDiscoverySource.broadcast,
      seenAt: DateTime.utc(2026),
      bindMode: UdpInterfaceBindMode.any,
    );

    expect(candidate.bindMode, UdpInterfaceBindMode.any);
    expect(candidate.localAddress, '0.0.0.0');
  });

  test('updates duplicate candidate lastSeenAt', () {
    final collection = PeerRouteCandidateCollection();
    final first = DateTime.utc(2026);
    final second = first.add(const Duration(seconds: 5));
    const interfaceId = NetworkInterfaceId(name: 'en0', index: 1);

    collection.upsert(
      _candidate(
        interfaceId: interfaceId,
        localAddress: '10.0.1.10',
        remoteAddress: '10.0.1.20',
        seenAt: first,
      ),
    );
    final updated = collection.upsert(
      _candidate(
        interfaceId: interfaceId,
        localAddress: '10.0.1.10',
        remoteAddress: '10.0.1.20',
        seenAt: second,
        rttMs: 12,
      ),
    );

    expect(collection.all, hasLength(1));
    expect(updated.firstSeenAt, first);
    expect(updated.lastSeenAt, second);
    expect(updated.rttMs, 12);
  });

  test('expires old candidates and removes them from active selection', () {
    final collection = PeerRouteCandidateCollection([
      _candidate(
        interfaceId: const NetworkInterfaceId(name: 'en0', index: 1),
        localAddress: '10.0.1.10',
        remoteAddress: '10.0.1.20',
        seenAt: DateTime.utc(2026),
      ),
    ]);

    final expired = collection.expireOlderThan(
      now: DateTime.utc(2026, 1, 1, 0, 1),
      ttl: const Duration(seconds: 30),
    );

    expect(expired, hasLength(1));
    expect(collection.selectableForPeer('user@device'), isEmpty);
  });

  test('marks incompatible candidates as non-selectable', () {
    final candidate = _candidate(
      interfaceId: const NetworkInterfaceId(name: 'en0', index: 1),
      localAddress: '10.0.1.10',
      remoteAddress: '10.0.1.20',
      seenAt: DateTime.utc(2026),
      compatible: false,
    );

    expect(candidate.status, RouteCandidateStatus.incompatible);
    expect(candidate.isSelectable, isFalse);
  });
}

PeerRouteCandidate _candidate({
  required NetworkInterfaceId interfaceId,
  required String localAddress,
  required String remoteAddress,
  required DateTime seenAt,
  int? rttMs,
  bool compatible = true,
  UdpInterfaceBindMode bindMode = UdpInterfaceBindMode.specificAddress,
}) {
  return PeerRouteCandidate.create(
    peerId: 'user@device',
    remoteAddress: remoteAddress,
    remotePort: 38401,
    localInterfaceId: interfaceId,
    localAddress: localAddress,
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: seenAt,
    rttMs: rttMs,
    compatible: compatible,
    bindMode: bindMode,
  );
}
