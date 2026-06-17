class TransferOutgoingChunkMetricMessageCommand {
  const TransferOutgoingChunkMetricMessageCommand._();

  static String retryQueued({required int chunkIndex}) {
    return 'data chunk $chunkIndex 송신 실패, 재전송 대기 중';
  }

  static String retryExhausted({required int chunkIndex}) {
    return 'chunk $chunkIndex 재전송 한도를 초과했습니다.';
  }

  static String timeoutQueued({required int chunkCount}) {
    return 'timeout $chunkCount chunks, 재전송 대기 중';
  }

  static String sent({
    required int chunkIndex,
    required bool isRetransmission,
    required int windowSize,
  }) {
    return isRetransmission
        ? 'chunk $chunkIndex 재전송 중'
        : 'window $windowSize 기준으로 전송 중';
  }
}
