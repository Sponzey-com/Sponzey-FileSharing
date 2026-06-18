import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/incoming_transfer_session_runner.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_accepted_session_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_channel_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatch_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_hello_expectation_resolver.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_inbound_listener_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_outbound_channel_open_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_promotion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_registry_promotion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_metadata_frame_prepare_port.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_effect_executor.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_transfer_frame_context_store.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_outgoing_connected_channel_lookup_command.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_transfer_send_use_case.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_metadata_frame_prepare_adapter.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_incoming_transfer_writer_session_prepare_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_peer_file_send_command.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart';

final tcpDataConnectorProvider = Provider<TcpDataConnectorPort>((ref) {
  return RawTcpDataConnector(logger: ref.watch(appLoggerProvider));
});

final tcpDataListenerProvider = Provider<TcpDataListenerPort>((ref) {
  return RawTcpDataListener(logger: ref.watch(appLoggerProvider));
});

final tcpDataChannelSessionRegistryProvider =
    Provider<DataChannelSessionRegistry>((ref) {
      return InMemoryDataChannelSessionRegistry(mode: DataChannelMode.tcp);
    });

final tcpIncomingTransferRunnerRegistryProvider =
    Provider<TransferSessionRegistry<IncomingTransferSessionRunner>>((ref) {
      return TransferSessionRegistry<IncomingTransferSessionRunner>(
        direction: TransferDirection.incoming,
      );
    });

final tcpIncomingTransferPayloadWriterSessionRegistryProvider =
    Provider<TcpIncomingTransferPayloadWriterSessionRegistry>((ref) {
      return InMemoryTcpIncomingTransferPayloadWriterSessionRegistry();
    });

final tcpIncomingTransferFrameContextStoreProvider =
    Provider<TcpIncomingTransferFrameContextStore>((ref) {
      return InMemoryTcpIncomingTransferFrameContextStore();
    });

final tcpIncomingTransferPayloadWriterPortProvider =
    Provider<TcpIncomingTransferPayloadWriterPort>((ref) {
      return TcpIncomingTransferPayloadWriterAdapter(
        registry: ref.watch(
          tcpIncomingTransferPayloadWriterSessionRegistryProvider,
        ),
        fileService: ref.watch(transferFileServiceProvider),
      );
    });

final tcpIncomingMetadataFramePreparePortProvider =
    Provider.family<TcpIncomingMetadataFramePreparePort, String>((
      ref,
      destinationDirectory,
    ) {
      return TcpIncomingMetadataFramePrepareAdapter(
        codec: const TcpIncomingTransferMetadataCodec(),
        prepareCommand: TcpIncomingTransferWriterSessionPrepareCommand(
          registry: ref.watch(
            tcpIncomingTransferPayloadWriterSessionRegistryProvider,
          ),
          fileService: ref.watch(transferFileServiceProvider),
        ),
        destinationDirectory: destinationDirectory,
      );
    });

final tcpIncomingStreamFramePipelineCommandProvider =
    Provider.family<TcpIncomingStreamFramePipelineCommand, String>((
      ref,
      destinationDirectory,
    ) {
      return TcpIncomingStreamFramePipelineCommand(
        dispatchCommand: const TcpDataStreamFrameDispatchCommand(
          contextCommand: TcpDataStreamFrameChannelContextCommand(),
          dispatcher: TcpDataStreamFrameDispatcher(),
        ),
        stageCommand: const TcpIncomingTransferFrameContextStageCommand(),
        runnerAdapter: const TcpIncomingStreamFrameRunnerAdapter(),
        payloadWriter: ref.watch(tcpIncomingTransferPayloadWriterPortProvider),
        metadataPreparePort: ref.watch(
          tcpIncomingMetadataFramePreparePortProvider(destinationDirectory),
        ),
      );
    });

final tcpIncomingStreamFrameEventCoordinatorProvider =
    Provider.family<TcpIncomingStreamFrameEventCoordinator, String>((
      ref,
      destinationDirectory,
    ) {
      return TcpIncomingStreamFrameEventCoordinator(
        dataChannelRegistry: ref.watch(tcpDataChannelSessionRegistryProvider),
        incomingRunnerRegistry: ref.watch(
          tcpIncomingTransferRunnerRegistryProvider,
        ),
        frameContextStore: ref.watch(
          tcpIncomingTransferFrameContextStoreProvider,
        ),
        pipeline: ref.watch(
          tcpIncomingStreamFramePipelineCommandProvider(destinationDirectory),
        ),
      );
    });

final tcpDataHelloExpectationResolverProvider =
    Provider<TcpDataHelloExpectationResolverPort>((ref) {
      final config = ref.watch(appConfigProvider);
      return _PeerAuthTcpDataHelloExpectationResolver(
        ref: ref,
        protocolVersion: _protocolMajor(config.protocolVersion),
        dataProtocolVersion: 1,
      );
    });

final tcpDataInboundListenerEventCoordinatorProvider =
    Provider<TcpDataInboundListenerEventCoordinator>((ref) {
      return TcpDataInboundListenerEventCoordinator(
        command: TcpDataInboundHandshakeCommand(
          acceptedSessionFactory: const TcpDataAcceptedSessionFactory(),
          registryPromotionCommand: TcpDataSessionRegistryPromotionCommand(
            registry: ref.watch(tcpDataChannelSessionRegistryProvider),
            promotionCommand: TcpDataSessionPromotionCommand(
              handshakeCommand: TcpDataSessionHandshakeCommand(
                proofVerifier: const _SessionBoundTcpDataProofVerifier(),
              ),
            ),
          ),
        ),
      );
    });

final tcpDataOutboundChannelOpenCommandProvider =
    Provider<TcpDataOutboundChannelOpenCommand>((ref) {
      return TcpDataOutboundChannelOpenCommand(
        connector: ref.watch(tcpDataConnectorProvider),
        registry: ref.watch(tcpDataChannelSessionRegistryProvider),
      );
    });

final tcpIncomingListenerStreamSubscriptionCoordinatorProvider =
    Provider.family<TcpIncomingListenerStreamSubscriptionCoordinator, String>((
      ref,
      destinationDirectory,
    ) {
      return TcpIncomingListenerStreamSubscriptionCoordinator(
        listener: ref.watch(tcpDataListenerProvider),
        inboundCoordinator: ref.watch(
          tcpDataInboundListenerEventCoordinatorProvider,
        ),
        helloExpectationResolver: ref.watch(
          tcpDataHelloExpectationResolverProvider,
        ),
        coordinator: ref.watch(
          tcpIncomingStreamFrameEventCoordinatorProvider(destinationDirectory),
        ),
      );
    });

final tcpIncomingListenerSubscriptionProvider =
    Provider.family<TcpIncomingListenerSubscriptionPort, String>((
      ref,
      destinationDirectory,
    ) {
      return ref.watch(
        tcpIncomingListenerStreamSubscriptionCoordinatorProvider(
          destinationDirectory,
        ),
      );
    });

final tcpOutgoingTransferStreamSendCommandProvider =
    Provider<TcpOutgoingTransferStreamSendCommand>((ref) {
      return TcpOutgoingTransferStreamSendCommand(
        fileService: ref.watch(transferFileServiceProvider),
        connector: ref.watch(tcpDataConnectorProvider),
        metadataCodec: const TcpIncomingTransferMetadataCodec(),
      );
    });

final tcpPeerFileSendCommandProvider = Provider<TcpPeerFileSendCommand>((ref) {
  return TcpPeerFileSendCommand(
    channelLookupCommand: const TcpOutgoingConnectedChannelLookupCommand(),
    sender: ref.watch(tcpOutgoingTransferStreamSendCommandProvider),
  );
});

final tcpTransferSendUseCaseProvider = Provider<TcpTransferSendUseCase>((ref) {
  return TcpTransferSendUseCase(
    fileService: ref.watch(transferFileServiceProvider),
    peerSender: ref.watch(tcpPeerFileSendCommandProvider),
    dataChannelRegistry: ref.watch(tcpDataChannelSessionRegistryProvider),
  );
});

class _PeerAuthTcpDataHelloExpectationResolver
    implements TcpDataHelloExpectationResolverPort {
  const _PeerAuthTcpDataHelloExpectationResolver({
    required this.ref,
    required this.protocolVersion,
    required this.dataProtocolVersion,
  });

  final Ref ref;
  final int protocolVersion;
  final int dataProtocolVersion;

  @override
  TcpDataHelloExpectationResolution resolve(TcpDataReceivedHello received) {
    final hello = received.hello;
    final authState = ref.read(peerAuthControllerProvider);
    final session = authState.sessions[hello.peerId];
    if (session == null || !session.isAuthenticated) {
      return const TcpDataHelloExpectationResolution.rejected(
        issueCode: 'tcp_data_hello_peer_not_authenticated',
      );
    }
    if (session.sessionId != hello.authSessionId) {
      return const TcpDataHelloExpectationResolution.rejected(
        issueCode: 'tcp_data_hello_auth_session_not_current',
      );
    }

    return TcpDataHelloExpectationResolution.accepted(
      TcpDataSessionHandshakeExpectation(
        peerId: hello.peerId,
        authSessionId: hello.authSessionId,
        protocolVersion: protocolVersion,
        dataProtocolVersion: dataProtocolVersion,
      ),
    );
  }
}

class _SessionBoundTcpDataProofVerifier implements TcpDataSessionProofVerifier {
  const _SessionBoundTcpDataProofVerifier();

  @override
  bool verify(TcpDataSessionHello hello) {
    return hello.proof == hello.authSessionId ||
        hello.proof == hello.sessionId.value;
  }
}

int _protocolMajor(String version) {
  final dotIndex = version.indexOf('.');
  final raw = dotIndex < 0 ? version : version.substring(0, dotIndex);
  return int.tryParse(raw) ?? 1;
}
