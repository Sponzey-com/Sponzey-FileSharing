import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';

class TcpDataSessionPromotionCommand {
  const TcpDataSessionPromotionCommand({required this.handshakeCommand});

  final TcpDataSessionHandshakeCommand handshakeCommand;
  final TcpDataPeerSessionStateMachine _stateMachine =
      const TcpDataPeerSessionStateMachine();

  TransitionResult<TcpDataPeerSessionSnapshot> promoteIncomingHello({
    required TcpDataPeerSessionSnapshot session,
    required TcpDataSessionHello hello,
    required TcpDataSessionHandshakeExpectation expectation,
  }) {
    if (session.status != TcpDataPeerSessionStatus.authenticating) {
      return TransitionResult.warning(
        session,
        issue: const TransitionIssue(
          code: 'tcp_data_session_not_authenticating',
          message:
              'TCP data session hello can only promote an authenticating session.',
        ),
      );
    }

    final validation = handshakeCommand.validateIncomingHello(
      hello: hello,
      expectation: expectation,
    );
    if (!validation.accepted) {
      return TransitionResult.failure(
        session.copyWith(status: TcpDataPeerSessionStatus.failed),
        issue: TransitionIssue(
          code: validation.issueCode ?? 'tcp_data_hello_rejected',
          message: 'TCP data session hello was rejected.',
        ),
      );
    }

    return _stateMachine.transition(
      session,
      TcpDataPeerSessionEvent.authSucceeded,
    );
  }
}
