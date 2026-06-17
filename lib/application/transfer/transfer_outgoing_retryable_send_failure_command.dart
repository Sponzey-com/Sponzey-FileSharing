class TransferOutgoingRetryableSendFailureCommand {
  const TransferOutgoingRetryableSendFailureCommand._();

  static bool isRetryable(String code) {
    return code == 'sendFailed' ||
        code == 'partialSend' ||
        code == 'data_frame_send_failed';
  }
}
