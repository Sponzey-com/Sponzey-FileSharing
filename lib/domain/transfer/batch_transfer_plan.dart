class BatchTransferFile {
  const BatchTransferFile({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.sha256,
    required this.chunkCount,
  });

  final String fileId;
  final String fileName;
  final int fileSize;
  final String sha256;
  final int chunkCount;
}

class ChildTransferSessionPlan {
  const ChildTransferSessionPlan({
    required this.sessionId,
    required this.peerId,
    required this.files,
  });

  final String sessionId;
  final String peerId;
  final List<BatchTransferFile> files;
}

class BatchTransferPlan {
  const BatchTransferPlan({required this.jobId, required this.children});

  final String jobId;
  final List<ChildTransferSessionPlan> children;
}

class BatchTransferPlanner {
  const BatchTransferPlanner();

  BatchTransferPlan createPlan({
    required String jobId,
    required List<String> peerIds,
    required List<BatchTransferFile> files,
  }) {
    return BatchTransferPlan(
      jobId: jobId,
      children: [
        for (final peerId in peerIds)
          ChildTransferSessionPlan(
            sessionId: '$jobId::$peerId',
            peerId: peerId,
            files: List<BatchTransferFile>.unmodifiable(files),
          ),
      ],
    );
  }
}
