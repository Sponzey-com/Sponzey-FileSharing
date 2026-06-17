import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';

class TransferInitReceiveCommand {
  const TransferInitReceiveCommand({
    required this.sessionId,
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.sha256,
    required this.chunkCount,
    required this.packetPeerId,
    required this.peerDisplayName,
    required this.acceptedChunkSize,
    required this.dataAuthContextId,
  });

  final String sessionId;
  final String transferId;
  final String fileName;
  final int fileSize;
  final String? sha256;
  final int chunkCount;
  final String packetPeerId;
  final String peerDisplayName;
  final int? acceptedChunkSize;
  final String? dataAuthContextId;

  static TransferInitReceiveCommandResult fromPacket(AuthPacket packet) {
    final transferId = packet.transferId;
    final fileName = packet.transferFileName;
    final fileSize = packet.transferFileSize;
    final chunkCount = packet.transferChunkCount;
    if (transferId == null ||
        fileName == null ||
        fileSize == null ||
        chunkCount == null) {
      return const TransferInitReceiveCommandResult.invalid(
        issueCode: 'missing_transfer_init_fields',
      );
    }

    final instanceId = packet.fromInstanceId;
    final peerNodeId = instanceId == null || instanceId.isEmpty
        ? packet.fromDeviceId
        : instanceId;
    return TransferInitReceiveCommandResult.valid(
      TransferInitReceiveCommand(
        sessionId: packet.sessionId,
        transferId: transferId,
        fileName: fileName,
        fileSize: fileSize,
        sha256: packet.transferSha256,
        chunkCount: chunkCount,
        packetPeerId: '${packet.fromUserId}@$peerNodeId',
        peerDisplayName: packet.fromDisplayName ?? packet.fromUserId,
        acceptedChunkSize: packet.transferAcceptedChunkSize,
        dataAuthContextId: packet.transferDataAuthContextId,
      ),
    );
  }
}

class TransferInitReceiveCommandResult {
  const TransferInitReceiveCommandResult.valid(this.command) : issueCode = null;

  const TransferInitReceiveCommandResult.invalid({required this.issueCode})
    : command = null;

  final TransferInitReceiveCommand? command;
  final String? issueCode;

  bool get isValid => command != null;
}
