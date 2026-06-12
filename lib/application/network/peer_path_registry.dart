import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';

class PeerPathRegistry {
  final Map<String, PeerConnectionPath> _pathsByPeerId = {};

  void select(PeerConnectionPath path) {
    _pathsByPeerId[path.peerId] = path;
  }

  PeerConnectionPath? selectedForPeer(String peerId) => _pathsByPeerId[peerId];

  void clear(String peerId) {
    _pathsByPeerId.remove(peerId);
  }
}

final peerPathRegistryProvider = Provider<PeerPathRegistry>((ref) {
  return PeerPathRegistry();
});
