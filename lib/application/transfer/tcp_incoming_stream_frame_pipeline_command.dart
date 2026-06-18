import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_state_machine.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_metadata_frame_prepare_port.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_effect_executor.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

class TcpIncomingStreamFramePipelineResult {
  const TcpIncomingStreamFramePipelineResult({
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

class TcpIncomingStreamFramePipelineCommand {
  const TcpIncomingStreamFramePipelineCommand({
    required this.dispatchCommand,
    required this.stageCommand,
    required this.runnerAdapter,
    this.metadataPreparePort =
        const PassthroughTcpIncomingMetadataFramePreparePort(),
    this.payloadWriter,
  });

  final TcpDataStreamFrameDispatchCommand dispatchCommand;
  final TcpIncomingTransferFrameContextStageCommand stageCommand;
  final TcpIncomingStreamFrameRunnerAdapter runnerAdapter;
  final TcpIncomingMetadataFramePreparePort metadataPreparePort;
  final TcpIncomingTransferPayloadWriterPort? payloadWriter;

  Future<TcpIncomingStreamFramePipelineResult> handle({
    required DataChannelSessionRegistry dataChannelRegistry,
    required TransferSessionRegistry<IncomingTransferSessionRunner>
    incomingRunnerRegistry,
    required TcpIncomingTransferFrameContextStore frameContextStore,
    required TcpDataReceivedStreamFrame received,
  }) async {
    final decision = dispatchCommand.decide(
      registry: dataChannelRegistry,
      received: received,
    );
    if (!decision.allowed) {
      return TcpIncomingStreamFramePipelineResult(
        applied: false,
        route: decision.route,
        transferId: decision.transferId,
        issueCode: decision.issueCode,
      );
    }

    final runnerKey = TransferSessionKey(
      direction: TransferDirection.incoming,
      transferId: decision.transferId!,
      peerId: decision.peerId!,
      authSessionId: decision.authSessionId!,
    );
    var runner = incomingRunnerRegistry.lookup(runnerKey);
    if (runner == null) {
      if (decision.route != TcpDataStreamFrameRoute.metadata) {
        return TcpIncomingStreamFramePipelineResult(
          applied: false,
          peerId: decision.peerId,
          authSessionId: decision.authSessionId,
          transferId: decision.transferId,
          route: decision.route,
          payloadBytes: decision.frame?.payload.length ?? 0,
          issueCode: 'missing_tcp_incoming_transfer_runner',
        );
      }
    }

    final stage = stageCommand.stage(
      store: frameContextStore,
      decision: decision,
    );
    if (!stage.staged) {
      return TcpIncomingStreamFramePipelineResult(
        applied: false,
        peerId: decision.peerId,
        authSessionId: decision.authSessionId,
        transferId: decision.transferId,
        route: decision.route,
        payloadBytes: decision.frame?.payload.length ?? 0,
        state: runner?.state,
        issueCode: stage.issueCode,
      );
    }

    TcpIncomingMetadataProjection? metadata;
    if (decision.route == TcpDataStreamFrameRoute.metadata) {
      final prepareResult = await metadataPreparePort.prepare(
        key: stage.key!,
        payload: decision.frame!.payload,
      );
      if (!prepareResult.prepared) {
        return TcpIncomingStreamFramePipelineResult(
          applied: false,
          peerId: decision.peerId,
          authSessionId: decision.authSessionId,
          transferId: decision.transferId,
          route: decision.route,
          payloadBytes: decision.frame?.payload.length ?? 0,
          state: runner?.state,
          issueCode: prepareResult.issueCode,
        );
      }
      metadata = prepareResult.metadata;
      runner ??= _createAndRegisterRunner(
        incomingRunnerRegistry: incomingRunnerRegistry,
        runnerKey: runnerKey,
        frameContextStore: frameContextStore,
        stageKey: stage.key!,
      );
      if (runner == null) {
        return const TcpIncomingStreamFramePipelineResult(
          applied: false,
          issueCode: 'missing_tcp_incoming_transfer_runner_factory',
        );
      }
    }

    final activeRunner = runner;
    if (activeRunner == null) {
      return TcpIncomingStreamFramePipelineResult(
        applied: false,
        peerId: decision.peerId,
        authSessionId: decision.authSessionId,
        transferId: decision.transferId,
        route: decision.route,
        payloadBytes: decision.frame?.payload.length ?? 0,
        issueCode: 'missing_tcp_incoming_transfer_runner',
      );
    }
    final TcpIncomingStreamFrameRunnerResult result;
    try {
      result = await runnerAdapter.apply(
        decision: decision,
        runner: activeRunner,
      );
    } on AppException catch (error) {
      return TcpIncomingStreamFramePipelineResult(
        applied: false,
        peerId: decision.peerId,
        authSessionId: decision.authSessionId,
        transferId: decision.transferId,
        route: decision.route,
        payloadBytes: decision.frame?.payload.length ?? 0,
        metadata: metadata,
        state: activeRunner.state,
        issueCode: error.code,
      );
    } catch (_) {
      return TcpIncomingStreamFramePipelineResult(
        applied: false,
        peerId: decision.peerId,
        authSessionId: decision.authSessionId,
        transferId: decision.transferId,
        route: decision.route,
        payloadBytes: decision.frame?.payload.length ?? 0,
        metadata: metadata,
        state: activeRunner.state,
        issueCode: 'tcp_incoming_frame_pipeline_failed',
      );
    }
    return TcpIncomingStreamFramePipelineResult(
      applied: result.applied,
      peerId: decision.peerId,
      authSessionId: decision.authSessionId,
      transferId: decision.transferId,
      route: decision.route,
      payloadBytes: decision.frame?.payload.length ?? 0,
      metadata: metadata,
      state: result.state,
      issueCode: result.issueCode,
    );
  }

  IncomingTransferSessionRunner? _createAndRegisterRunner({
    required TransferSessionRegistry<IncomingTransferSessionRunner>
    incomingRunnerRegistry,
    required TransferSessionKey runnerKey,
    required TcpIncomingTransferFrameContextStore frameContextStore,
    required TcpIncomingTransferFrameContextKey stageKey,
  }) {
    final writer = payloadWriter;
    if (writer == null) {
      return null;
    }
    final runner = IncomingTransferSessionRunner(
      executor: TcpIncomingTransferEffectExecutor(
        key: stageKey,
        frameContextStore: frameContextStore,
        writer: writer,
      ),
      initialState: IncomingTransferSessionState.readyForData,
    );
    incomingRunnerRegistry.register(runnerKey, runner);
    return runner;
  }
}
