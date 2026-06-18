import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';

class TcpIncomingStreamFrameRunnerResult {
  const TcpIncomingStreamFrameRunnerResult({
    required this.applied,
    required this.state,
    this.issueCode,
  });

  final bool applied;
  final IncomingTransferSessionState state;
  final String? issueCode;
}

class TcpIncomingStreamFrameRunnerAdapter {
  const TcpIncomingStreamFrameRunnerAdapter();

  Future<TcpIncomingStreamFrameRunnerResult> apply({
    required TcpDataStreamFrameDispatchDecision decision,
    required IncomingTransferSessionRunner runner,
  }) async {
    if (!decision.allowed || decision.route == null) {
      return TcpIncomingStreamFrameRunnerResult(
        applied: false,
        state: runner.state,
        issueCode: decision.issueCode,
      );
    }

    final transition = switch (decision.route!) {
      TcpDataStreamFrameRoute.metadata => await runner.receiveDataStart(),
      TcpDataStreamFrameRoute.chunk => await runner.receiveChunk(),
      TcpDataStreamFrameRoute.complete => await _complete(runner),
      TcpDataStreamFrameRoute.cancel || TcpDataStreamFrameRoute.error =>
        await runner.dispatch(IncomingTransferSessionEvent.dataAbortReceived),
    };

    return TcpIncomingStreamFrameRunnerResult(
      applied: transition.didTransition,
      state: transition.state,
      issueCode: transition.issue?.code,
    );
  }

  Future<TransitionResult<IncomingTransferSessionState>> _complete(
    IncomingTransferSessionRunner runner,
  ) async {
    var transition = await runner.receiveDataFinish();
    if (!transition.didTransition ||
        transition.state != IncomingTransferSessionState.verifying) {
      return transition;
    }
    transition = await runner.markDigestVerified();
    if (!transition.didTransition ||
        transition.state != IncomingTransferSessionState.finalizing) {
      return transition;
    }
    return runner.markFinalizeCompleted();
  }
}
