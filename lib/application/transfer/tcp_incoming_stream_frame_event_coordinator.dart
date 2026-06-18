import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_metadata_frame_prepare_port.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';

class TcpIncomingStreamFrameEventCoordinatorResult {
  const TcpIncomingStreamFrameEventCoordinatorResult({
    required this.applied,
    this.peerId,
    this.authSessionId,
    this.transferId,
    this.route,
    this.payloadBytes = 0,
    this.metadata,
    this.state,
    this.issueCode,
  });

  final bool applied;
  final String? peerId;
  final String? authSessionId;
  final String? transferId;
  final TcpDataStreamFrameRoute? route;
  final int payloadBytes;
  final TcpIncomingMetadataProjection? metadata;
  final IncomingTransferSessionState? state;
  final String? issueCode;
}

class TcpIncomingStreamFrameEventCoordinator {
  const TcpIncomingStreamFrameEventCoordinator({
    required this.dataChannelRegistry,
    required this.incomingRunnerRegistry,
    required this.frameContextStore,
    required this.pipeline,
  });

  final DataChannelSessionRegistry dataChannelRegistry;
  final TransferSessionRegistry<IncomingTransferSessionRunner>
  incomingRunnerRegistry;
  final TcpIncomingTransferFrameContextStore frameContextStore;
  final TcpIncomingStreamFramePipelineCommand pipeline;

  Future<TcpIncomingStreamFrameEventCoordinatorResult> handleFrame(
    TcpDataReceivedStreamFrame received,
  ) async {
    final result = await pipeline.handle(
      dataChannelRegistry: dataChannelRegistry,
      incomingRunnerRegistry: incomingRunnerRegistry,
      frameContextStore: frameContextStore,
      received: received,
    );
    return TcpIncomingStreamFrameEventCoordinatorResult(
      applied: result.applied,
      peerId: result.peerId,
      authSessionId: result.authSessionId,
      transferId: result.transferId,
      route: result.route,
      payloadBytes: result.payloadBytes,
      metadata: result.metadata,
      state: result.state,
      issueCode: result.issueCode,
    );
  }

  TcpIncomingStreamFrameEventCoordinatorResult handleFrameError(
    TcpDataReceivedStreamFrameError error,
  ) {
    return TcpIncomingStreamFrameEventCoordinatorResult(
      applied: false,
      issueCode: error.issueCode,
    );
  }
}
