import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_overview_provider.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

final transferJobsProvider = Provider<List<TransferJob>>((ref) {
  return ref.watch(transferControllerProvider).jobs;
});

final activeTransferJobsProvider = Provider<List<TransferJob>>((ref) {
  return ref
      .watch(transferJobsProvider)
      .where((job) => !job.isTerminal)
      .toList(growable: false);
});

final transferHistoryJobsProvider = Provider<List<TransferJob>>((ref) {
  return ref
      .watch(transferJobsProvider)
      .where((job) => job.isTerminal)
      .toList(growable: false);
});

final authenticatedTransferPeersProvider = Provider<List<PeerNode>>((ref) {
  final sessions = ref.watch(peerAuthControllerProvider).sessions;
  final peersById = {
    for (final peer in ref.watch(discoveryOverviewProvider).peers)
      peer.id: peer,
  };

  return sessions.values
      .where((session) => session.isAuthenticated)
      .map((session) => peersById[session.peerId])
      .whereType<PeerNode>()
      .where(
        (peer) => peer.presence == PeerPresence.online && peer.isCompatible,
      )
      .map(
        (peer) => peer.copyWith(
          address: sessions[peer.id]!.peerAddress,
          port: sessions[peer.id]!.peerPort,
          presence: PeerPresence.online,
        ),
      )
      .toList(growable: false);
});
