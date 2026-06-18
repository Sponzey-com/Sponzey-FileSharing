import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';

class TcpDataHelloExpectationResolution {
  const TcpDataHelloExpectationResolution({
    required this.accepted,
    this.expectation,
    this.issueCode,
  });

  final bool accepted;
  final TcpDataSessionHandshakeExpectation? expectation;
  final String? issueCode;

  const TcpDataHelloExpectationResolution.accepted(this.expectation)
    : accepted = true,
      issueCode = null;

  const TcpDataHelloExpectationResolution.rejected({required this.issueCode})
    : accepted = false,
      expectation = null;
}

abstract interface class TcpDataHelloExpectationResolverPort {
  TcpDataHelloExpectationResolution resolve(TcpDataReceivedHello received);
}
