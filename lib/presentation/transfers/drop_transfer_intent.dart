import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';

class DropTransferIntent {
  const DropTransferIntent({required this.peerId, required this.filePaths});

  final String peerId;
  final List<String> filePaths;
}

class DropTransferResolution {
  const DropTransferResolution._({this.intent, this.message});

  factory DropTransferResolution.ready(DropTransferIntent intent) {
    return DropTransferResolution._(intent: intent);
  }

  factory DropTransferResolution.rejected(String message) {
    return DropTransferResolution._(message: message);
  }

  factory DropTransferResolution.ignored() {
    return const DropTransferResolution._();
  }

  final DropTransferIntent? intent;
  final String? message;
}

DropTransferResolution resolveDroppedTransfer({
  required List<String> droppedPaths,
  required List<PeerNode> peers,
  required String? selectedPeerId,
  required bool Function(String path) isFile,
}) {
  if (droppedPaths.isEmpty) {
    return DropTransferResolution.ignored();
  }
  if (peers.isEmpty) {
    return DropTransferResolution.rejected('연결된 피어가 없어 전송할 수 없습니다.');
  }

  final filePaths = droppedPaths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  if (filePaths.isEmpty) {
    return DropTransferResolution.ignored();
  }

  String? invalidPath;
  for (final path in filePaths) {
    if (!isFile(path)) {
      invalidPath = path;
      break;
    }
  }
  if (invalidPath != null) {
    return DropTransferResolution.rejected('디렉터리가 아니라 파일만 드롭해 주세요.');
  }

  final peerId =
      selectedPeerId != null && peers.any((peer) => peer.id == selectedPeerId)
      ? selectedPeerId
      : peers.first.id;
  return DropTransferResolution.ready(
    DropTransferIntent(peerId: peerId, filePaths: filePaths),
  );
}
