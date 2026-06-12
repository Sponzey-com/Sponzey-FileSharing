import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

enum RouteCandidateStatus {
  fresh,
  probing,
  reachable,
  degraded,
  failed,
  expired,
  incompatible,
}

enum RouteCandidateDiscoverySource {
  broadcast,
  multicast,
  unicastProbe,
  localRegistry,
}

class PeerRouteCandidate {
  const PeerRouteCandidate({
    required this.candidateId,
    required this.peerId,
    required this.remoteAddress,
    required this.remotePort,
    required this.localInterfaceId,
    required this.localAddress,
    required this.discoveredBy,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.rttMs,
    this.failureCount = 0,
    this.score = 0,
    required this.status,
    this.localInterfaceTypeHint = InterfaceTypeHint.unknown,
    this.bindMode = UdpInterfaceBindMode.specificAddress,
    this.compatible = true,
    this.receiveAvailable = true,
  });

  factory PeerRouteCandidate.create({
    required String peerId,
    required String remoteAddress,
    required int remotePort,
    required NetworkInterfaceId localInterfaceId,
    required String localAddress,
    required RouteCandidateDiscoverySource discoveredBy,
    required DateTime seenAt,
    RouteCandidateStatus status = RouteCandidateStatus.fresh,
    int? rttMs,
    int failureCount = 0,
    int score = 0,
    InterfaceTypeHint localInterfaceTypeHint = InterfaceTypeHint.unknown,
    UdpInterfaceBindMode bindMode = UdpInterfaceBindMode.specificAddress,
    bool compatible = true,
    bool receiveAvailable = true,
  }) {
    return PeerRouteCandidate(
      candidateId: buildCandidateId(
        peerId: peerId,
        remoteAddress: remoteAddress,
        remotePort: remotePort,
        localInterfaceId: localInterfaceId,
        localAddress: localAddress,
        bindMode: bindMode,
      ),
      peerId: peerId,
      remoteAddress: remoteAddress,
      remotePort: remotePort,
      localInterfaceId: localInterfaceId,
      localAddress: localAddress,
      discoveredBy: discoveredBy,
      firstSeenAt: seenAt,
      lastSeenAt: seenAt,
      rttMs: rttMs,
      failureCount: failureCount,
      score: score,
      status: compatible ? status : RouteCandidateStatus.incompatible,
      localInterfaceTypeHint: localInterfaceTypeHint,
      bindMode: bindMode,
      compatible: compatible,
      receiveAvailable: receiveAvailable,
    );
  }

  final String candidateId;
  final String peerId;
  final String remoteAddress;
  final int remotePort;
  final NetworkInterfaceId localInterfaceId;
  final String localAddress;
  final RouteCandidateDiscoverySource discoveredBy;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int? rttMs;
  final int failureCount;
  final int score;
  final RouteCandidateStatus status;
  final InterfaceTypeHint localInterfaceTypeHint;
  final UdpInterfaceBindMode bindMode;
  final bool compatible;
  final bool receiveAvailable;

  bool get isSelectable {
    return compatible &&
        receiveAvailable &&
        status != RouteCandidateStatus.expired &&
        status != RouteCandidateStatus.failed &&
        status != RouteCandidateStatus.incompatible;
  }

  PeerRouteCandidate copyWith({
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    int? rttMs,
    int? failureCount,
    int? score,
    RouteCandidateStatus? status,
    InterfaceTypeHint? localInterfaceTypeHint,
    UdpInterfaceBindMode? bindMode,
    bool? compatible,
    bool? receiveAvailable,
  }) {
    final nextCompatible = compatible ?? this.compatible;
    final nextStatus = nextCompatible
        ? status ?? this.status
        : RouteCandidateStatus.incompatible;
    return PeerRouteCandidate(
      candidateId: candidateId,
      peerId: peerId,
      remoteAddress: remoteAddress,
      remotePort: remotePort,
      localInterfaceId: localInterfaceId,
      localAddress: localAddress,
      discoveredBy: discoveredBy,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rttMs: rttMs ?? this.rttMs,
      failureCount: failureCount ?? this.failureCount,
      score: score ?? this.score,
      status: nextStatus,
      localInterfaceTypeHint:
          localInterfaceTypeHint ?? this.localInterfaceTypeHint,
      bindMode: bindMode ?? this.bindMode,
      compatible: nextCompatible,
      receiveAvailable: receiveAvailable ?? this.receiveAvailable,
    );
  }

  static String buildCandidateId({
    required String peerId,
    required String remoteAddress,
    required int remotePort,
    required NetworkInterfaceId localInterfaceId,
    required String localAddress,
    required UdpInterfaceBindMode bindMode,
  }) {
    return '$peerId|${localInterfaceId.stableId}|$localAddress|'
        '$remoteAddress:$remotePort|${bindMode.name}';
  }
}

class PeerRouteCandidateCollection {
  PeerRouteCandidateCollection([
    Iterable<PeerRouteCandidate> initial = const [],
  ]) : _candidates = {
         for (final candidate in initial) candidate.candidateId: candidate,
       };

  final Map<String, PeerRouteCandidate> _candidates;

  List<PeerRouteCandidate> get all {
    return _candidates.values.toList(growable: false)
      ..sort((a, b) => a.candidateId.compareTo(b.candidateId));
  }

  PeerRouteCandidate upsert(PeerRouteCandidate candidate) {
    final existing = _candidates[candidate.candidateId];
    if (existing == null) {
      _candidates[candidate.candidateId] = candidate;
      return candidate;
    }

    final merged = existing.copyWith(
      lastSeenAt: candidate.lastSeenAt.isAfter(existing.lastSeenAt)
          ? candidate.lastSeenAt
          : existing.lastSeenAt,
      rttMs: candidate.rttMs,
      failureCount: candidate.failureCount,
      score: candidate.score,
      status: candidate.status,
      localInterfaceTypeHint: candidate.localInterfaceTypeHint,
      bindMode: candidate.bindMode,
      compatible: candidate.compatible,
      receiveAvailable: candidate.receiveAvailable,
    );
    _candidates[candidate.candidateId] = merged;
    return merged;
  }

  List<PeerRouteCandidate> candidatesForPeer(String peerId) {
    return all
        .where((candidate) => candidate.peerId == peerId)
        .toList(growable: false);
  }

  List<PeerRouteCandidate> selectableForPeer(String peerId) {
    return candidatesForPeer(
      peerId,
    ).where((candidate) => candidate.isSelectable).toList(growable: false);
  }

  List<PeerRouteCandidate> expireOlderThan({
    required DateTime now,
    required Duration ttl,
  }) {
    final expired = <PeerRouteCandidate>[];
    for (final entry in _candidates.entries.toList(growable: false)) {
      final candidate = entry.value;
      if (candidate.status == RouteCandidateStatus.expired) {
        continue;
      }
      if (now.difference(candidate.lastSeenAt) <= ttl) {
        continue;
      }
      final next = candidate.copyWith(status: RouteCandidateStatus.expired);
      _candidates[entry.key] = next;
      expired.add(next);
    }
    return expired;
  }
}
