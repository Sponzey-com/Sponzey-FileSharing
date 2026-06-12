import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/connectable_interface_policy.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';

class PeerRouteCandidateProjection {
  PeerRouteCandidateProjection({
    PeerRouteCandidateCollection? collection,
    this.unknownInterfaceId = const NetworkInterfaceId(
      name: 'unknown',
      index: -1,
      stableId: 'unknown',
    ),
  }) : collection = collection ?? PeerRouteCandidateCollection();

  final PeerRouteCandidateCollection collection;
  final NetworkInterfaceId unknownInterfaceId;
  final Map<String, PeerNode> _representativePeers = {};

  List<PeerRouteCandidate> get candidates => collection.all;

  List<PeerNode> get peers {
    return _representativePeers.values.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  PeerRouteCandidate ingestDiscoveryPacket({
    required DiscoveryPacket packet,
    required String remoteAddress,
    required int remotePort,
    required DateTime receivedAt,
    required String currentProtocolVersion,
    NetworkInterfaceId? localInterfaceId,
    String? localAddress,
    RouteCandidateDiscoverySource discoveredBy =
        RouteCandidateDiscoverySource.broadcast,
  }) {
    final inferredLocalCandidate = _candidateFromPacket(
      packet: packet,
      localInterfaceId: localInterfaceId,
      localAddress: localAddress,
    );
    return ingestDiscoveryPacketCandidates(
      packet: packet,
      remoteAddress: remoteAddress,
      remotePort: remotePort,
      receivedAt: receivedAt,
      currentProtocolVersion: currentProtocolVersion,
      localCandidates: [inferredLocalCandidate],
      discoveredBy: discoveredBy,
    ).single;
  }

  List<PeerRouteCandidate> ingestDiscoveryPacketCandidates({
    required DiscoveryPacket packet,
    required String remoteAddress,
    required int remotePort,
    required DateTime receivedAt,
    required String currentProtocolVersion,
    required Iterable<ConnectableInterfaceCandidate> localCandidates,
    RouteCandidateDiscoverySource discoveredBy =
        RouteCandidateDiscoverySource.broadcast,
  }) {
    final peerId = '${packet.userId}@${packet.deviceId}';
    final compatible = packet.protocolVersion == currentProtocolVersion;
    final effectiveLocalCandidates = localCandidates.isEmpty
        ? [_unknownAnyBindCandidate()]
        : localCandidates;
    final merged = <PeerRouteCandidate>[];
    for (final localCandidate in effectiveLocalCandidates) {
      final candidate = PeerRouteCandidate.create(
        peerId: peerId,
        remoteAddress: remoteAddress,
        remotePort: packet.controlPort ?? packet.port,
        localInterfaceId: localCandidate.interfaceId,
        localAddress: localCandidate.localAddress,
        discoveredBy: discoveredBy,
        seenAt: receivedAt,
        score: localCandidate.score,
        localInterfaceTypeHint: localCandidate.typeHint,
        bindMode: localCandidate.bindMode,
        compatible: compatible,
        receiveAvailable: packet.receiveAvailable,
      );
      merged.add(collection.upsert(candidate));
    }
    _representativePeers[peerId] = _peerFromPacket(
      packet,
      remoteAddress: remoteAddress,
      remotePort: remotePort,
      receivedAt: receivedAt,
      compatible: compatible,
    );
    return merged;
  }

  PeerRouteCandidate ingestLocalRegistry({
    required LocalInstancePresence presence,
    required DateTime now,
  }) {
    final peerId = '${presence.userId}@${presence.deviceId}';
    final candidate = PeerRouteCandidate.create(
      peerId: peerId,
      remoteAddress: '127.0.0.1',
      remotePort: presence.port,
      localInterfaceId: const NetworkInterfaceId(
        name: 'loopback',
        index: 0,
        stableId: 'loopback',
      ),
      localAddress: '127.0.0.1',
      discoveredBy: RouteCandidateDiscoverySource.localRegistry,
      seenAt: now,
      localInterfaceTypeHint: InterfaceTypeHint.loopback,
      bindMode: UdpInterfaceBindMode.specificAddress,
      receiveAvailable: presence.receiveAvailable,
    );
    final merged = collection.upsert(candidate);
    _representativePeers[peerId] = PeerNode(
      deviceId: presence.deviceId,
      userId: presence.userId,
      displayName: presence.displayName,
      deviceName: presence.deviceName,
      osType: presence.osType,
      protocolVersion: presence.protocolVersion,
      lastSeenAt: now,
      address: '127.0.0.1',
      port: presence.port,
      receiveAvailable: presence.receiveAvailable,
      presence: PeerPresence.online,
    );
    return merged;
  }

  List<PeerRouteCandidate> expire({
    required DateTime now,
    required Duration ttl,
  }) {
    return collection.expireOlderThan(now: now, ttl: ttl);
  }

  NetworkInterfaceId _interfaceIdFromPacket(DiscoveryPacket packet) {
    final sourceInterfaceId = packet.sourceInterfaceId;
    if (sourceInterfaceId == null) {
      return unknownInterfaceId;
    }
    return NetworkInterfaceId(
      name: packet.sourceInterfaceHint ?? sourceInterfaceId,
      index: -1,
      stableId: sourceInterfaceId,
    );
  }

  ConnectableInterfaceCandidate _candidateFromPacket({
    required DiscoveryPacket packet,
    NetworkInterfaceId? localInterfaceId,
    String? localAddress,
  }) {
    final effectiveLocalAddress =
        localAddress ?? packet.sourceAddress ?? '0.0.0.0';
    final bindMode = effectiveLocalAddress == '0.0.0.0'
        ? UdpInterfaceBindMode.any
        : UdpInterfaceBindMode.specificAddress;
    final interfaceId = localInterfaceId ?? _interfaceIdFromPacket(packet);
    return ConnectableInterfaceCandidate(
      interfaceId: interfaceId,
      localAddress: effectiveLocalAddress,
      typeHint: _typeHintFromPacket(packet, localInterfaceId),
      priority: bindMode == UdpInterfaceBindMode.any
          ? ConnectableInterfacePriority.anyBind
          : ConnectableInterfacePriority.fallback,
      bindMode: bindMode,
      score: bindMode == UdpInterfaceBindMode.any ? 0 : 1000,
    );
  }

  ConnectableInterfaceCandidate _unknownAnyBindCandidate() {
    return ConnectableInterfaceCandidate(
      interfaceId: unknownInterfaceId,
      localAddress: '0.0.0.0',
      typeHint: InterfaceTypeHint.unknown,
      priority: ConnectableInterfacePriority.anyBind,
      bindMode: UdpInterfaceBindMode.any,
      score: 0,
    );
  }

  InterfaceTypeHint _typeHintFromPacket(
    DiscoveryPacket packet,
    NetworkInterfaceId? explicitInterfaceId,
  ) {
    if (explicitInterfaceId != null) {
      return InterfaceTypeHint.unknown;
    }
    switch (packet.sourceInterfaceHint?.toLowerCase()) {
      case 'ethernet':
        return InterfaceTypeHint.ethernet;
      case 'wifi':
        return InterfaceTypeHint.wifi;
      case 'bridge':
        return InterfaceTypeHint.bridge;
      case 'vpn':
        return InterfaceTypeHint.vpn;
      case 'virtual':
        return InterfaceTypeHint.virtual;
      case 'loopback':
        return InterfaceTypeHint.loopback;
      default:
        return InterfaceTypeHint.unknown;
    }
  }

  static PeerNode _peerFromPacket(
    DiscoveryPacket packet, {
    required String remoteAddress,
    required int remotePort,
    required DateTime receivedAt,
    required bool compatible,
  }) {
    return PeerNode(
      deviceId: packet.deviceId,
      userId: packet.userId,
      displayName: packet.displayName,
      deviceName: packet.deviceName,
      osType: packet.osType,
      protocolVersion: packet.protocolVersion,
      lastSeenAt: receivedAt,
      address: remoteAddress,
      port: packet.controlPort ?? remotePort,
      receiveAvailable: packet.receiveAvailable,
      presence: compatible ? PeerPresence.online : PeerPresence.incompatible,
    );
  }
}

final peerRouteCandidateProjectionProvider =
    NotifierProvider<
      PeerRouteCandidateProjectionNotifier,
      List<PeerRouteCandidate>
    >(PeerRouteCandidateProjectionNotifier.new);

class PeerRouteCandidateProjectionNotifier
    extends Notifier<List<PeerRouteCandidate>> {
  late final PeerRouteCandidateProjection _projection;

  @override
  List<PeerRouteCandidate> build() {
    _projection = PeerRouteCandidateProjection();
    return _projection.candidates;
  }

  List<PeerRouteCandidate> ingestDiscoveryPacketCandidates({
    required DiscoveryPacket packet,
    required String remoteAddress,
    required int remotePort,
    required DateTime receivedAt,
    required String currentProtocolVersion,
    required Iterable<ConnectableInterfaceCandidate> localCandidates,
    RouteCandidateDiscoverySource discoveredBy =
        RouteCandidateDiscoverySource.broadcast,
  }) {
    final candidates = _projection.ingestDiscoveryPacketCandidates(
      packet: packet,
      remoteAddress: remoteAddress,
      remotePort: remotePort,
      receivedAt: receivedAt,
      currentProtocolVersion: currentProtocolVersion,
      localCandidates: localCandidates,
      discoveredBy: discoveredBy,
    );
    state = _projection.candidates;
    return candidates;
  }

  PeerRouteCandidate ingestLocalRegistry({
    required LocalInstancePresence presence,
    required DateTime now,
  }) {
    final candidate = _projection.ingestLocalRegistry(
      presence: presence,
      now: now,
    );
    state = _projection.candidates;
    return candidate;
  }

  List<PeerRouteCandidate> expire({
    required DateTime now,
    required Duration ttl,
  }) {
    final expired = _projection.expire(now: now, ttl: ttl);
    if (expired.isNotEmpty) {
      state = _projection.candidates;
    }
    return expired;
  }

  PeerRouteCandidate upsertCandidate(PeerRouteCandidate candidate) {
    final merged = _projection.collection.upsert(candidate);
    state = _projection.candidates;
    return merged;
  }

  PeerRouteCandidate? markCandidateFailed({
    required String candidateId,
    required DateTime now,
  }) {
    final current = _projection.candidates
        .where((candidate) => candidate.candidateId == candidateId)
        .firstOrNull;
    if (current == null) {
      return null;
    }
    final failed = current.copyWith(
      lastSeenAt: now,
      failureCount: current.failureCount + 1,
      status: RouteCandidateStatus.failed,
    );
    final merged = _projection.collection.upsert(failed);
    state = _projection.candidates;
    return merged;
  }
}
