import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';

enum PeerSortMode { recent, name, status }

List<PeerNode> filterPeers(
  List<PeerNode> peers, {
  String query = '',
  PeerSortMode sortMode = PeerSortMode.recent,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = normalizedQuery.isEmpty
      ? peers
      : peers.where((peer) {
          return peer.displayName.toLowerCase().contains(normalizedQuery) ||
              peer.deviceName.toLowerCase().contains(normalizedQuery) ||
              peer.userId.toLowerCase().contains(normalizedQuery) ||
              peer.deviceId.toLowerCase().contains(normalizedQuery) ||
              peer.osType.toLowerCase().contains(normalizedQuery);
        }).toList();

  return sortPeers(filtered, sortMode: sortMode);
}

List<PeerNode> sortPeers(
  List<PeerNode> peers, {
  PeerSortMode sortMode = PeerSortMode.recent,
}) {
  final sorted = [...peers];
  sorted.sort((left, right) {
    switch (sortMode) {
      case PeerSortMode.recent:
        final byPresence = _presenceOrder(
          left.presence,
        ).compareTo(_presenceOrder(right.presence));
        if (byPresence != 0) {
          return byPresence;
        }

        final bySeen = right.lastSeenAt.compareTo(left.lastSeenAt);
        if (bySeen != 0) {
          return bySeen;
        }

        return left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        );
      case PeerSortMode.name:
        final byName = left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        );
        if (byName != 0) {
          return byName;
        }

        return left.deviceName.toLowerCase().compareTo(
          right.deviceName.toLowerCase(),
        );
      case PeerSortMode.status:
        final byPresence = _presenceOrder(
          left.presence,
        ).compareTo(_presenceOrder(right.presence));
        if (byPresence != 0) {
          return byPresence;
        }

        return left.displayName.toLowerCase().compareTo(
          right.displayName.toLowerCase(),
        );
    }
  });
  return sorted;
}

int _presenceOrder(PeerPresence presence) {
  switch (presence) {
    case PeerPresence.online:
      return 0;
    case PeerPresence.stale:
      return 1;
    case PeerPresence.offline:
      return 2;
    case PeerPresence.incompatible:
      return 3;
  }
}
