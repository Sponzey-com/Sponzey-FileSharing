import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
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
    final peerId = '${packet.userId}@${packet.deviceId}';
    final compatible = packet.protocolVersion == currentProtocolVersion;
    final candidate = PeerRouteCandidate.create(
      peerId: peerId,
      remoteAddress: remoteAddress,
      remotePort: packet.controlPort ?? packet.port,
      localInterfaceId: localInterfaceId ?? _interfaceIdFromPacket(packet),
      localAddress: localAddress ?? packet.sourceAddress ?? '0.0.0.0',
      discoveredBy: discoveredBy,
      seenAt: receivedAt,
      compatible: compatible,
      receiveAvailable: packet.receiveAvailable,
    );
    final merged = collection.upsert(candidate);
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
