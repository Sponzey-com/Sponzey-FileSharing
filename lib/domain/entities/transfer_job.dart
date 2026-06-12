enum TransferDirection { outgoing, incoming }

enum TransferJobStatus {
  preparing,
  awaitingAcceptance,
  sending,
  receiving,
  verifying,
  completed,
  rejected,
  failed,
}

class TransferJob {
  const TransferJob({
    required this.id,
    required this.transferId,
    required this.direction,
    required this.peerId,
    required this.peerDisplayName,
    required this.fileName,
    required this.fileSize,
    required this.bytesTransferred,
    required this.totalChunks,
    required this.completedChunks,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.windowSize = 1,
    this.retryCount = 0,
    this.duplicateCount = 0,
    this.lossRate = 0,
    this.throughputBytesPerSec = 0,
    this.rttMs,
    this.localFilePath,
    this.destinationPath,
    this.message,
  });

  final String id;
  final String transferId;
  final TransferDirection direction;
  final String peerId;
  final String peerDisplayName;
  final String fileName;
  final int fileSize;
  final int bytesTransferred;
  final int totalChunks;
  final int completedChunks;
  final TransferJobStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int windowSize;
  final int retryCount;
  final int duplicateCount;
  final double lossRate;
  final double throughputBytesPerSec;
  final double? rttMs;
  final String? localFilePath;
  final String? destinationPath;
  final String? message;

  double get progress {
    if (fileSize <= 0) {
      return status == TransferJobStatus.completed ? 1 : 0;
    }
    final raw = bytesTransferred / fileSize;
    if (raw < 0) {
      return 0;
    }
    if (raw > 1) {
      return 1;
    }
    return raw;
  }

  String get title => fileName;

  Duration? get estimatedRemaining {
    if (throughputBytesPerSec <= 0 || bytesTransferred >= fileSize) {
      return null;
    }
    final remainingBytes = fileSize - bytesTransferred;
    return Duration(
      milliseconds: (remainingBytes / throughputBytesPerSec * 1000).round(),
    );
  }

  String get statusLabel {
    switch (status) {
      case TransferJobStatus.preparing:
        return '준비 중';
      case TransferJobStatus.awaitingAcceptance:
        return '수신 대기';
      case TransferJobStatus.sending:
        return '전송 중';
      case TransferJobStatus.receiving:
        return '수신 중';
      case TransferJobStatus.verifying:
        return '검증 중';
      case TransferJobStatus.completed:
        return '완료';
      case TransferJobStatus.rejected:
        return '거절됨';
      case TransferJobStatus.failed:
        return '실패';
    }
  }

  bool get isTerminal {
    return status == TransferJobStatus.completed ||
        status == TransferJobStatus.rejected ||
        status == TransferJobStatus.failed;
  }

  TransferJob copyWith({
    String? id,
    String? transferId,
    TransferDirection? direction,
    String? peerId,
    String? peerDisplayName,
    String? fileName,
    int? fileSize,
    int? bytesTransferred,
    int? totalChunks,
    int? completedChunks,
    TransferJobStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? windowSize,
    int? retryCount,
    int? duplicateCount,
    double? lossRate,
    double? throughputBytesPerSec,
    double? rttMs,
    String? localFilePath,
    String? destinationPath,
    String? message,
    bool clearLocalFilePath = false,
    bool clearDestinationPath = false,
    bool clearMessage = false,
  }) {
    return TransferJob(
      id: id ?? this.id,
      transferId: transferId ?? this.transferId,
      direction: direction ?? this.direction,
      peerId: peerId ?? this.peerId,
      peerDisplayName: peerDisplayName ?? this.peerDisplayName,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalChunks: totalChunks ?? this.totalChunks,
      completedChunks: completedChunks ?? this.completedChunks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      windowSize: windowSize ?? this.windowSize,
      retryCount: retryCount ?? this.retryCount,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      lossRate: lossRate ?? this.lossRate,
      throughputBytesPerSec:
          throughputBytesPerSec ?? this.throughputBytesPerSec,
      rttMs: rttMs ?? this.rttMs,
      localFilePath: clearLocalFilePath
          ? null
          : localFilePath ?? this.localFilePath,
      destinationPath: clearDestinationPath
          ? null
          : destinationPath ?? this.destinationPath,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
