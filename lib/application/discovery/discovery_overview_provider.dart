import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';

class DiscoveryOverview {
  const DiscoveryOverview({
    required this.peers,
    required this.onlineCount,
    required this.staleCount,
    required this.offlineCount,
    required this.incompatibleCount,
  });

  final List<PeerNode> peers;
  final int onlineCount;
  final int staleCount;
  final int offlineCount;
  final int incompatibleCount;
}

final discoveryOverviewProvider = Provider<DiscoveryOverview>((ref) {
  final peers = ref.watch(peerNodesProvider);
  return DiscoveryOverview(
    peers: peers,
    onlineCount: peers
        .where((peer) => peer.presence == PeerPresence.online)
        .length,
    staleCount: peers
        .where((peer) => peer.presence == PeerPresence.stale)
        .length,
    offlineCount: peers
        .where((peer) => peer.presence == PeerPresence.offline)
        .length,
    incompatibleCount: peers
        .where((peer) => peer.presence == PeerPresence.incompatible)
        .length,
  );
});

final peerNodesProvider = Provider<List<PeerNode>>((ref) {
  return ref.watch(discoveryControllerProvider).peers;
});
