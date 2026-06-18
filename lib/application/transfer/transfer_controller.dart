import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/data_channel_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_active_route_validation_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_control_packet_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_endpoint_resolver.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_bind_endpoint_route_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_key_formatter.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_key_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_route_context_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_diagnostics_ring_buffer.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_endpoint_label_formatter.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_event_id_formatter.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_frame_trace_mapper.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_ack_retry_schedule_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_data_chunk_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_data_finish_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_chunk_write_failure_mapper.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_finalize_failure_mapper.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_missing_chunks_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_route_match_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_window_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_init_receive_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_identity_selection_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_event_factory.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_list_upsert_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_metrics_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_terminal_status_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_job_update_lookup_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_log_safe_formatter.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_metric_calculation_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_ack_bitmap_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_ack_indexes_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_chunk_byte_length_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_chunk_metric_message_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_completion_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_data_ack_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_data_nack_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_data_endpoint_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_digest_advance_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_next_chunk_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_retransmission_scan_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_route_lease_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_retryable_send_failure_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_remote_data_endpoint_route_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_send_failure_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_window_reduction_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_window_growth_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_window_update_command.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_random_hex_formatter.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_rtt_estimator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_transfer_send_use_case.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_incoming_stream_frame_event_coordinator.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_channel_ports.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_session_handshake_command.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_identity.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_tuning_policy.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_protocol.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_peer_session_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_job_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_route_snapshot.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/transfer_history_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/tcp_transfer_pipeline_providers.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/streaming_digest.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame_codec.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_transport.dart';

import 'transfer_data_auth_context.dart';

typedef TransferNow = DateTime Function();

class TransferState {
  const TransferState({
    required this.jobs,
    this.errorMessage,
    this.infoMessage,
    this.isListening = false,
    this.isLoading = false,
    this.draftPeerId,
  });

  const TransferState.initial()
    : jobs = const [],
      errorMessage = null,
      infoMessage = null,
      isListening = false,
      isLoading = true,
      draftPeerId = null;

  final List<TransferJob> jobs;
  final String? errorMessage;
  final String? infoMessage;
  final bool isListening;
  final bool isLoading;
  final String? draftPeerId;

  TransferState copyWith({
    List<TransferJob>? jobs,
    String? errorMessage,
    String? infoMessage,
    bool? isListening,
    bool? isLoading,
    String? draftPeerId,
    bool clearError = false,
    bool clearInfo = false,
    bool clearDraftPeerId = false,
  }) {
    return TransferState(
      jobs: jobs ?? this.jobs,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
      isListening: isListening ?? this.isListening,
      isLoading: isLoading ?? this.isLoading,
      draftPeerId: clearDraftPeerId ? null : draftPeerId ?? this.draftPeerId,
    );
  }
}

class TransferController extends Notifier<TransferState> {
  static const Duration _initAckTimeout = Duration(seconds: 10);
  static const Duration _completeAckTimeout = Duration(seconds: 10);
  static const int _initialWindowSize =
      DataTransferTuningPolicy.defaultInitialWindowSize;
  static const int _maximumWindowSize =
      DataTransferTuningPolicy.defaultMaximumWindowSize;
  static const int _receiverAdvertisedWindow =
      DataTransferTuningPolicy.defaultReceiverAdvertisedWindow;
  static const int _windowUpdateChunkInterval =
      DataTransferTuningPolicy.defaultWindowUpdateChunkInterval;
  static const int _ackBatchChunkThreshold =
      DataTransferTuningPolicy.defaultAckBatchChunkThreshold;
  static const int _maxWindowGrowthPerAck =
      DataTransferTuningPolicy.defaultMaxWindowGrowthPerAck;
  static const int _maxRetransmissions =
      DataTransferTuningPolicy.defaultMaxRetransmissions;
  static const int _maxNackIndexesPerPacket =
      DataTransferTuningPolicy.defaultMaxNackIndexesPerPacket;
  static const int _diagnosticFrameTraceCapacity = 128;
  static const Duration _ackBatchInterval =
      DataTransferTuningPolicy.defaultAckBatchInterval;
  static const Duration _metricLogInterval =
      DataTransferTuningPolicy.defaultMetricLogInterval;
  static const Duration _sendBackpressureRetryDelay = Duration(milliseconds: 8);
  static const Duration _outOfOrderNackRepeatInterval = Duration(
    milliseconds: 120,
  );
  static final int _dataChunkSize =
      DataTransferTuningPolicy.defaults.maxPayloadBytes;
  static const TransferJobStateMachine _jobStateMachine =
      TransferJobStateMachine();
  static const TransferControlPacketDispatcher _controlPacketDispatcher =
      TransferControlPacketDispatcher();
  static const TransferDataFrameDispatcher _dataFrameDispatcher =
      TransferDataFrameDispatcher();

  bool _didInitialize = false;
  final Random _random = Random.secure();
  StreamSubscription<ControlDatagram>? _packetSubscription;
  StreamSubscription<DataFrameDatagram>? _dataFrameSubscription;
  StreamSubscription<TcpIncomingStreamFrameEventCoordinatorResult>?
  _tcpIncomingResultSubscription;
  TcpIncomingListenerSubscriptionPort? _tcpIncomingSubscription;
  TcpDataListenerPort? _tcpDataListener;
  TcpDataConnectorPort? _tcpDataConnector;
  TcpDataListenerBinding? _tcpDataListenerBinding;
  LocalDeviceIdentity? _localIdentity;
  final Set<String> _offeredTcpDataPeers = {};
  final TransferSessionRegistry<_OutgoingTransferContext>
  _outgoingSessionRegistry = TransferSessionRegistry<_OutgoingTransferContext>(
    direction: TransferDirection.outgoing,
  );
  final TransferSessionRegistry<_IncomingTransferContext>
  _incomingSessionRegistry = TransferSessionRegistry<_IncomingTransferContext>(
    direction: TransferDirection.incoming,
  );
  final Map<String, _OutgoingTransferContext> _outgoingTransfers = {};
  final Map<String, _IncomingTransferContext> _incomingTransfers = {};
  final TransferDataFrameKeyRegistry _frameKeyRegistry =
      TransferDataFrameKeyRegistry();
  final Map<String, TransferDiagnosticsRingBuffer> _diagnosticFrameTraces = {};

  @override
  TransferState build() {
    ref.onDispose(() {
      unawaited(_dispose());
    });
    ref.listen<PeerAuthState>(peerAuthControllerProvider, (previous, next) {
      for (final session in next.sessions.values) {
        if (!session.isAuthenticated) {
          continue;
        }
        final wasAuthenticated =
            previous?.sessions[session.peerId]?.isAuthenticated == true;
        if (!wasAuthenticated) {
          unawaited(_sendTcpDataChannelOffer(session));
        }
      }
    });
    ref.listen<int>(peerPathRegistryRevisionProvider, (previous, next) {
      unawaited(_sendTcpDataChannelOffersToAuthenticatedPeers());
    });

    if (!_didInitialize) {
      _didInitialize = true;
      unawaited(_initialize());
    }

    return const TransferState.initial();
  }

  void setDraftPeerId(String? peerId) {
    state = state.copyWith(
      draftPeerId: peerId,
      clearDraftPeerId: peerId == null,
    );
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  Future<void> cancelTransfer(String transferId) async {
    TransferJob? job;
    for (final current in state.jobs) {
      if (current.id == transferId) {
        job = current;
        break;
      }
    }
    if (job == null) {
      return;
    }
    final transition = _jobStateMachine.transition(
      job.status,
      TransferJobEvent.cancelRequested,
    );
    if (!transition.didTransition) {
      return;
    }

    final outgoing = _removeOutgoingTransfer(transferId);
    if (outgoing != null) {
      outgoing.hasFailed = true;
      if (!outgoing.initAck.isCompleted) {
        outgoing.initAck.complete(
          _TransferInitAckResult(
            accepted: false,
            sourceAddress: outgoing.session.peerAddress,
            message: '전송이 취소되었습니다.',
          ),
        );
      }
      unawaited(outgoing.allChunksAcked.future.catchError((Object _) {}));
      if (!outgoing.allChunksAcked.isCompleted) {
        outgoing.allChunksAcked.completeError(
          const AppException(
            code: 'transfer_cancelled',
            message: '전송이 취소되었습니다.',
          ),
        );
      }
      if (!outgoing.completeAck.isCompleted) {
        outgoing.completeAck.complete(
          const _TransferCompleteAckResult(
            accepted: false,
            message: '전송이 취소되었습니다.',
          ),
        );
      }
      await outgoing.dispose();
    }

    final incoming = _removeIncomingTransfer(transferId);
    if (incoming != null) {
      await incoming.closeWriter();
      await ref
          .read(transferFileServiceProvider)
          .discardDraft(incoming.tempFilePath);
    }

    _updateJob(
      transferId,
      (currentJob) => currentJob.copyWith(
        status: transition.state,
        updatedAt: _now(),
        message: '전송이 취소되었습니다.',
      ),
    );
    state = state.copyWith(infoMessage: '전송을 취소했습니다.');
  }

  List<TransferFrameTrace> diagnosticFrameSnapshot(String transferId) {
    return _diagnosticFrameTraces[transferId]?.snapshot() ?? const [];
  }

  // Legacy UDP outgoing path is intentionally retained until the dedicated
  // removal task migrates or deletes old UDP-data controller tests.
  // ignore: unused_element
  void _registerOutgoingTransfer(
    String transferId,
    _OutgoingTransferContext context,
  ) {
    final result = _outgoingSessionRegistry.register(
      _outgoingSessionKey(transferId, context),
      context,
    );
    if (!result.registered) {
      throw AppException(
        code: result.issueCode ?? 'transfer_session_register_failed',
        message: '송신 전송 세션을 등록하지 못했습니다.',
      );
    }
    _outgoingTransfers[transferId] = context;
  }

  void _registerIncomingTransfer(
    String transferId,
    _IncomingTransferContext context,
  ) {
    final result = _incomingSessionRegistry.register(
      _incomingSessionKey(transferId, context),
      context,
    );
    if (!result.registered) {
      throw AppException(
        code: result.issueCode ?? 'transfer_session_register_failed',
        message: '수신 전송 세션을 등록하지 못했습니다.',
      );
    }
    _incomingTransfers[transferId] = context;
    _registerFrameKey(
      direction: TransferDirection.incoming,
      transferId: transferId,
      transferIdBytes: context.transferIdBytes,
    );
  }

  _OutgoingTransferContext? _lookupOutgoingTransfer(String transferId) {
    final context = _outgoingTransfers[transferId];
    if (context == null) {
      return null;
    }
    return _outgoingSessionRegistry.lookup(
      _outgoingSessionKey(transferId, context),
    );
  }

  _IncomingTransferContext? _lookupIncomingTransfer(String transferId) {
    final context = _incomingTransfers[transferId];
    if (context == null) {
      return null;
    }
    return _incomingSessionRegistry.lookup(
      _incomingSessionKey(transferId, context),
    );
  }

  _OutgoingTransferContext? _removeOutgoingTransfer(String transferId) {
    final context = _outgoingTransfers.remove(transferId);
    if (context == null) {
      return null;
    }
    _outgoingSessionRegistry.remove(_outgoingSessionKey(transferId, context));
    _removeFrameKey(
      direction: TransferDirection.outgoing,
      transferId: transferId,
      transferIdBytes: context.transferIdBytes,
    );
    return context;
  }

  _IncomingTransferContext? _removeIncomingTransfer(String transferId) {
    final context = _incomingTransfers.remove(transferId);
    if (context == null) {
      return null;
    }
    _incomingSessionRegistry.remove(_incomingSessionKey(transferId, context));
    _removeFrameKey(
      direction: TransferDirection.incoming,
      transferId: transferId,
      transferIdBytes: context.transferIdBytes,
    );
    return context;
  }

  TransferSessionKey _outgoingSessionKey(
    String transferId,
    _OutgoingTransferContext context,
  ) {
    return TransferSessionKey(
      direction: TransferDirection.outgoing,
      transferId: transferId,
      peerId: context.session.peerId,
      authSessionId: context.session.sessionId,
    );
  }

  TransferSessionKey _incomingSessionKey(
    String transferId,
    _IncomingTransferContext context,
  ) {
    return TransferSessionKey(
      direction: TransferDirection.incoming,
      transferId: transferId,
      peerId: context.peerId,
      authSessionId: context.sessionId,
    );
  }

  Future<void> sendFile({
    required String peerId,
    required String filePath,
  }) async {
    state = state.copyWith(clearError: true, clearInfo: true);
    String? pendingTcpTransferId;

    try {
      final session = _requireAuthenticatedSession(peerId);
      final tcpTransferId = _randomHex(12);
      pendingTcpTransferId = tcpTransferId;
      DateTime? tcpStartedAt;
      Future<TcpTransferSendUseCaseResult> sendOverTcp() {
        return ref
            .read(tcpTransferSendUseCaseProvider)
            .send(
              TcpTransferSendUseCaseInput(
                peerId: peerId,
                authSessionId: session.sessionId,
                transferId: tcpTransferId,
                filePath: filePath,
                chunkSize: _dataChunkSize,
                onPrepared: (metadata) {
                  final now = _now();
                  tcpStartedAt = now;
                  _upsertJob(
                    TransferJob(
                      id: tcpTransferId,
                      transferId: tcpTransferId,
                      direction: TransferDirection.outgoing,
                      peerId: peerId,
                      peerDisplayName: session.peerDisplayName,
                      fileName: metadata.fileName,
                      fileSize: metadata.fileSize,
                      bytesTransferred: 0,
                      totalChunks: metadata.chunkCount,
                      completedChunks: 0,
                      status: TransferJobStatus.sending,
                      createdAt: now,
                      updatedAt: now,
                      localFilePath: metadata.filePath,
                      message: 'TCP data channel 전송 중',
                      dataCapability: DataTransferCapability.tcpDataStreamV1,
                    ),
                  );
                },
                onProgress: (progress) {
                  _updateJob(tcpTransferId, (job) {
                    final now = _now();
                    final startedAt = tcpStartedAt ?? job.createdAt;
                    final elapsedMs = max(
                      1,
                      now.difference(startedAt).inMilliseconds,
                    );
                    return job.copyWith(
                      status: TransferJobStatus.sending,
                      bytesTransferred: min(job.fileSize, progress.bytesSent),
                      completedChunks: min(
                        job.totalChunks,
                        progress.completedChunks,
                      ),
                      throughputBytesPerSec:
                          progress.bytesSent * 1000 / elapsedMs,
                      updatedAt: now,
                      message: 'TCP data channel 전송 중',
                    );
                  });
                },
              ),
            );
      }

      var tcpSendResult = await sendOverTcp();
      if (!tcpSendResult.sent &&
          _tcpSendFailureInvalidatesOutboundChannel(tcpSendResult.issueCode)) {
        _removeOutboundTcpDataSession(session);
      }
      if (!tcpSendResult.sent &&
          !ref.read(appConfigProvider).allowLegacyUdpDataFallback &&
          _tcpSendFailureCanNegotiateOutboundChannel(tcpSendResult.issueCode)) {
        final negotiated = await _requestAndWaitForOutboundTcpDataChannel(
          session,
        );
        if (negotiated) {
          tcpSendResult = await sendOverTcp();
          if (!tcpSendResult.sent &&
              _tcpSendFailureInvalidatesOutboundChannel(
                tcpSendResult.issueCode,
              )) {
            _removeOutboundTcpDataSession(session);
          }
        }
      }
      if (tcpSendResult.sent) {
        final now = _now();
        _upsertJob(
          TransferJob(
            id: tcpTransferId,
            transferId: tcpTransferId,
            direction: TransferDirection.outgoing,
            peerId: peerId,
            peerDisplayName: session.peerDisplayName,
            fileName: tcpSendResult.fileName ?? filePath.split('/').last,
            fileSize: tcpSendResult.fileSize,
            bytesTransferred: tcpSendResult.bytesSent > 0
                ? tcpSendResult.bytesSent
                : tcpSendResult.fileSize,
            totalChunks: tcpSendResult.chunkCount,
            completedChunks: tcpSendResult.chunkCount,
            status: TransferJobStatus.completed,
            createdAt: now,
            updatedAt: now,
            localFilePath: tcpSendResult.filePath ?? filePath,
            message: 'TCP data channel 전송 완료',
            dataCapability: DataTransferCapability.tcpDataStreamV1,
          ),
        );
        setDraftPeerId(peerId);
        state = state.copyWith(
          infoMessage:
              '파일 전송이 완료되었습니다: ${tcpSendResult.fileName ?? filePath.split('/').last}',
          clearError: true,
        );
        return;
      }
      if (ref.read(appConfigProvider).allowLegacyUdpDataFallback) {
        _removeJob(tcpTransferId);
        final activeRoute = _requireActiveTransferRoute(
          peerId: peerId,
          session: session,
        );
        final routeSnapshot = _snapshotFromActiveRoute(activeRoute);
        final fileService = ref.read(transferFileServiceProvider);
        final preparedFile = await fileService.prepareOutgoingMetadata(
          filePath,
          chunkSize: _dataChunkSize,
        );
        final reader = await fileService.openOutgoingReader(
          preparedFile.filePath,
        );
        final transferId = _randomHex(12);
        final now = _now();
        final targetAddress = InternetAddress(
          routeSnapshot.controlRemoteAddress,
        );
        final targetPort = routeSnapshot.controlRemotePort;
        final controlEndpoint = activeRoute.controlEndpoint;
        final authContext = TransferDataAuthContext.derive(
          sessionId: session.sessionId,
          localNodeId: _currentInstanceId(),
          remoteNodeId: session.peerId,
          transferId: transferId,
          selectedPathId: activeRoute.pathId,
          nonce: _randomHex(12),
        );
        final context = _OutgoingTransferContext(
          session: session,
          preparedFile: preparedFile,
          startedAt: now,
          windowSize: _initialWindowSize,
          remoteWindowStart: 0,
          advertisedWindowSize: _receiverAdvertisedWindow,
          rttEstimator: TransferRttEstimator(),
          controlEndpoint: controlEndpoint,
          reader: reader,
          authContext: authContext,
          transferId: transferId,
          routeSnapshot: routeSnapshot,
        );
        _registerOutgoingTransfer(transferId, context);
        ref
            .read(appLoggerProvider)
            .info(
              AppLogCategory.transferControl,
              'Starting legacy UDP outgoing transfer '
              '${_safeTransfer(transferId)} '
              'peer=$peerId route=${routeSnapshot.routeLeaseId} '
              'session=${_safeSession(session.sessionId)} '
              'target=${targetAddress.address}:$targetPort '
              'local=${_endpointLabel(controlEndpoint)} '
              'file=${preparedFile.fileName} size=${preparedFile.fileSize} '
              'chunks=${preparedFile.chunkCount}',
            );
        _upsertJob(
          TransferJob(
            id: transferId,
            transferId: transferId,
            direction: TransferDirection.outgoing,
            peerId: peerId,
            peerDisplayName: session.peerDisplayName,
            fileName: preparedFile.fileName,
            fileSize: preparedFile.fileSize,
            bytesTransferred: 0,
            totalChunks: preparedFile.chunkCount,
            completedChunks: 0,
            status: TransferJobStatus.preparing,
            createdAt: now,
            updatedAt: now,
            localFilePath: preparedFile.filePath,
            windowSize: context.windowSize,
            routeSnapshot: routeSnapshot,
            dataCapability: DataTransferCapability.udpDataBinaryV1,
          ),
        );

        await _send(
          AuthPacket(
            type: AuthPacketType.transferInit,
            protocolVersion: ref.read(appConfigProvider).protocolVersion,
            sessionId: session.sessionId,
            fromUserId: _currentUserId(),
            fromDeviceId: _currentDeviceId(),
            fromInstanceId: _currentInstanceId(),
            fromDisplayName: _currentDisplayName(),
            transferId: transferId,
            transferFileName: preparedFile.fileName,
            transferFileSize: preparedFile.fileSize,
            transferChunkCount: preparedFile.chunkCount,
            transferAcceptedChunkSize: preparedFile.chunkSize,
            transferCapabilities: const ['udpDataBinaryV1'],
            transferDataProtocol: DataTransferCapability.udpDataBinaryV1.name,
            transferDataAuthContextId: authContext.keyId,
            sentAtEpochMs: now.millisecondsSinceEpoch,
          ),
          address: targetAddress,
          port: targetPort,
          localEndpoint: controlEndpoint,
        );

        _updateJob(
          transferId,
          (job) => job.copyWith(
            status: TransferJobStatus.awaitingAcceptance,
            updatedAt: _now(),
            message: '수신 노드의 저장 준비를 기다리는 중입니다.',
          ),
        );
        setDraftPeerId(peerId);
        unawaited(_runOutgoingTransfer(transferId, context));
        return;
      }
      final now = _now();
      final failureMessage = tcpSendResult.message ?? 'TCP 파일 전송을 시작하지 못했습니다.';
      _upsertJob(
        TransferJobTerminalStatusCommand.failed(
          TransferJob(
            id: tcpTransferId,
            transferId: tcpTransferId,
            direction: TransferDirection.outgoing,
            peerId: peerId,
            peerDisplayName: session.peerDisplayName,
            fileName: tcpSendResult.fileName ?? filePath.split('/').last,
            fileSize: tcpSendResult.fileSize,
            bytesTransferred: min(
              tcpSendResult.bytesSent,
              tcpSendResult.fileSize,
            ),
            totalChunks: tcpSendResult.chunkCount,
            completedChunks: min(
              tcpSendResult.chunkCount,
              tcpSendResult.framesSent > 0 ? tcpSendResult.framesSent - 1 : 0,
            ),
            status: TransferJobStatus.preparing,
            createdAt: now,
            updatedAt: now,
            localFilePath: tcpSendResult.filePath ?? filePath,
            dataCapability: DataTransferCapability.tcpDataStreamV1,
          ),
          updatedAt: now,
          message: failureMessage,
        ),
      );
      state = state.copyWith(errorMessage: failureMessage, clearInfo: true);
      return;
    } on AppException catch (error) {
      if (pendingTcpTransferId != null) {
        _markFailed(pendingTcpTransferId, error.message);
      }
      state = state.copyWith(errorMessage: error.message);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferControl,
            'Failed to start outgoing transfer',
            error: error,
            stackTrace: stackTrace,
          );
      if (pendingTcpTransferId != null) {
        _markFailed(pendingTcpTransferId, '파일 전송을 시작하지 못했습니다.');
      }
      state = state.copyWith(errorMessage: '파일 전송을 시작하지 못했습니다.');
    }
  }

  Future<void> sendFiles({
    required String peerId,
    required List<String> filePaths,
  }) async {
    if (filePaths.isEmpty) {
      state = state.copyWith(errorMessage: '전송할 파일을 선택해 주세요.');
      return;
    }

    for (final filePath in filePaths) {
      await sendFile(peerId: peerId, filePath: filePath);
      if (state.errorMessage != null) {
        return;
      }
    }
  }

  Future<void> sendFileToPeers({
    required List<String> peerIds,
    required String filePath,
  }) async {
    if (peerIds.isEmpty) {
      state = state.copyWith(errorMessage: '전송할 피어를 선택해 주세요.');
      return;
    }

    for (final peerId in peerIds) {
      await sendFile(peerId: peerId, filePath: filePath);
      if (state.errorMessage != null) {
        return;
      }
    }
  }

  Future<void> _initialize() async {
    try {
      _localIdentity = await ref
          .read(localDeviceIdentityServiceProvider)
          .load();
      await ref
          .read(controlTransportProvider)
          .start(preferredPort: ref.read(appConfigProvider).authPort);
      _packetSubscription = ref.read(controlTransportProvider).packets.listen((
        datagram,
      ) {
        unawaited(_handlePacket(datagram));
      });
      _dataFrameSubscription = ref.read(dataTransportProvider).frames.listen((
        datagram,
      ) {
        unawaited(_handleDataFrame(datagram));
      });
      final tcpIncomingDirectory =
          await _loadTcpIncomingSubscriptionDirectory();
      if (tcpIncomingDirectory != null) {
        _tcpDataListener = ref.read(tcpDataListenerProvider);
        _tcpDataConnector = ref.read(tcpDataConnectorProvider);
        _tcpDataListenerBinding = await _tcpDataListener!.bind(
          const TcpDataListenerBindRequest(host: '0.0.0.0', port: 0),
        );
        _tcpIncomingSubscription = ref.read(
          tcpIncomingListenerSubscriptionProvider(tcpIncomingDirectory),
        );
        _tcpIncomingResultSubscription = _tcpIncomingSubscription!.results
            .listen(_handleTcpIncomingResult);
        await _tcpIncomingSubscription!.start();
        await _sendTcpDataChannelOffersToAuthenticatedPeers();
      }
      state = state.copyWith(
        isListening: true,
        isLoading: false,
        clearError: true,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferControl,
            'Failed to initialize transfer controller',
            error: error,
            stackTrace: stackTrace,
          );
      await _dispose();
      state = state.copyWith(
        isListening: false,
        isLoading: false,
        errorMessage: '전송 엔진을 시작하지 못했습니다.',
      );
    }
  }

  Future<void> _handlePacket(ControlDatagram datagram) async {
    final packet = datagram.packet;
    switch (_controlPacketDispatcher.routeFor(packet.type)) {
      case TransferControlPacketRoute.transferInit:
        await _onTransferInit(packet, datagram);
      case TransferControlPacketRoute.transferInitAck:
        _onTransferInitAck(packet, datagram);
      case TransferControlPacketRoute.transferChunk:
        await _onTransferChunk(packet, datagram);
      case TransferControlPacketRoute.transferChunkAck:
        _onTransferChunkAck(packet);
      case TransferControlPacketRoute.transferChunkNack:
        _onTransferChunkNack(packet);
      case TransferControlPacketRoute.transferWindowUpdate:
        _onTransferWindowUpdate(packet);
      case TransferControlPacketRoute.transferComplete:
        await _onTransferComplete(packet, datagram);
      case TransferControlPacketRoute.transferCompleteAck:
        await _onTransferCompleteAck(packet, datagram);
      case TransferControlPacketRoute.dataChannelOffer:
        await _onDataChannelOffer(packet, datagram);
      case TransferControlPacketRoute.dataChannelConnect:
        await _onDataChannelConnect(packet, datagram);
      case TransferControlPacketRoute.ignored:
        return;
    }
  }

  Future<void> _handleDataFrame(DataFrameDatagram datagram) async {
    final frame = datagram.frame;
    final route = _dataFrameDispatcher.routeFor(frame.type);
    final transferId = _transferIdForFrame(
      frame,
      direction: route.expectedDirection,
    );
    if (transferId == null) {
      return;
    }
    if (!_hasDataFrameRouteContext(transferId, route)) {
      return;
    }
    _recordFrameTrace(
      transferId: transferId,
      frame: frame,
      direction: 'in',
      endpoint: '${datagram.address.address}:${datagram.port}',
      datagramBytes: datagram.datagramBytes,
      decisionCode: 'received',
    );

    switch (route) {
      case TransferDataFrameRoute.dataStart:
        _updateJob(
          transferId,
          (job) => job.copyWith(
            status: job.direction == TransferDirection.incoming
                ? TransferJobStatus.receiving
                : job.status,
            updatedAt: _now(),
            message: 'Data channel start 를 수신했습니다.',
          ),
        );
        return;
      case TransferDataFrameRoute.dataChunk:
        await _onDataChunk(transferId, datagram);
        return;
      case TransferDataFrameRoute.dataAck:
        _onDataAck(transferId, datagram);
        return;
      case TransferDataFrameRoute.dataNack:
        _onDataNack(transferId, datagram);
        return;
      case TransferDataFrameRoute.dataWindowUpdate:
        _onDataWindowUpdate(transferId, datagram);
        return;
      case TransferDataFrameRoute.dataFinish:
        await _onDataFinish(transferId, datagram);
        return;
      case TransferDataFrameRoute.dataAbort:
        await _failIncomingTransfer(transferId, '상대 노드가 전송을 취소했습니다.');
        return;
    }
  }

  bool _hasDataFrameRouteContext(
    String transferId,
    TransferDataFrameRoute route,
  ) {
    return TransferDataFrameRouteContextCommand.allows(
      expectedDirection: route.expectedDirection,
      hasIncomingContext: _lookupIncomingTransfer(transferId) != null,
      hasOutgoingContext: _lookupOutgoingTransfer(transferId) != null,
    );
  }

  void _handleTcpIncomingResult(
    TcpIncomingStreamFrameEventCoordinatorResult result,
  ) {
    final transferId = result.transferId;
    if (transferId == null) {
      return;
    }
    if (!result.applied) {
      _markTcpIncomingIssue(transferId, result.issueCode);
      return;
    }

    switch (result.route) {
      case TcpDataStreamFrameRoute.metadata:
        _upsertTcpIncomingMetadataJob(result);
      case TcpDataStreamFrameRoute.chunk:
        _updateTcpIncomingChunkJob(result);
      case TcpDataStreamFrameRoute.complete:
        _completeTcpIncomingJob(result);
      case TcpDataStreamFrameRoute.cancel:
      case TcpDataStreamFrameRoute.error:
        _markTcpIncomingIssue(transferId, result.issueCode);
      case null:
        return;
    }
  }

  void _upsertTcpIncomingMetadataJob(
    TcpIncomingStreamFrameEventCoordinatorResult result,
  ) {
    final metadata = result.metadata;
    final peerId = result.peerId;
    if (metadata == null || peerId == null || result.transferId == null) {
      return;
    }
    final session = ref.read(peerAuthSessionByPeerIdProvider(peerId));
    final now = _now();
    _upsertJob(
      TransferJob(
        id: result.transferId!,
        transferId: result.transferId!,
        direction: TransferDirection.incoming,
        peerId: peerId,
        peerDisplayName: session?.peerDisplayName ?? peerId,
        fileName: metadata.fileName,
        fileSize: metadata.fileSize,
        bytesTransferred: 0,
        totalChunks: metadata.chunkCount,
        completedChunks: 0,
        status: TransferJobStatus.receiving,
        createdAt: now,
        updatedAt: now,
        destinationPath: metadata.destinationDirectory,
        message: 'TCP data channel 수신을 시작했습니다.',
        dataCapability: DataTransferCapability.tcpDataStreamV1,
      ),
    );
  }

  void _updateTcpIncomingChunkJob(
    TcpIncomingStreamFrameEventCoordinatorResult result,
  ) {
    final transferId = result.transferId;
    if (transferId == null) {
      return;
    }
    _updateJob(transferId, (job) {
      final bytesTransferred = min(
        job.fileSize,
        job.bytesTransferred + result.payloadBytes,
      );
      final completedChunks = min(job.totalChunks, job.completedChunks + 1);
      return job.copyWith(
        status: TransferJobStatus.receiving,
        bytesTransferred: bytesTransferred,
        completedChunks: completedChunks,
        updatedAt: _now(),
        message: 'TCP data channel 수신 중',
        throughputBytesPerSec: _throughputBytesPerSec(
          transferredBytes: bytesTransferred,
          startedAt: job.createdAt,
        ),
      );
    });
  }

  void _completeTcpIncomingJob(
    TcpIncomingStreamFrameEventCoordinatorResult result,
  ) {
    final transferId = result.transferId;
    if (transferId == null) {
      return;
    }
    _updateJob(
      transferId,
      (job) => job.copyWith(
        status: TransferJobStatus.completed,
        bytesTransferred: job.fileSize,
        completedChunks: job.totalChunks,
        updatedAt: _now(),
        message: 'TCP data channel 수신 완료',
        throughputBytesPerSec: _throughputBytesPerSec(
          transferredBytes: job.fileSize,
          startedAt: job.createdAt,
        ),
      ),
    );
  }

  void _markTcpIncomingIssue(String transferId, String? issueCode) {
    final message = issueCode == null
        ? 'TCP data channel 수신 중 오류가 발생했습니다.'
        : 'TCP data channel 수신 중 오류가 발생했습니다: $issueCode';
    final nextJob = TransferJobUpdateLookupCommand.updateById(
      jobs: state.jobs,
      jobId: transferId,
      update: (job) => TransferJobTerminalStatusCommand.failed(
        job,
        updatedAt: _now(),
        message: message,
      ),
    );
    if (nextJob != null) {
      _upsertJob(nextJob);
      return;
    }
    state = state.copyWith(errorMessage: message);
  }

  // Legacy UDP outgoing path is intentionally retained until the dedicated
  // removal task migrates or deletes old UDP-data controller tests.
  // ignore: unused_element
  Future<void> _runOutgoingTransfer(
    String transferId,
    _OutgoingTransferContext context,
  ) async {
    try {
      final initAck = await context.initAck.future.timeout(_initAckTimeout);
      if (context.hasFailed) {
        return;
      }
      if (!initAck.accepted) {
        _markRejected(transferId, initAck.message ?? '상대가 파일 수신을 거절했습니다.');
        _removeOutgoingTransfer(transferId);
        return;
      }

      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.sending,
          destinationPath: initAck.savePath,
          updatedAt: _now(),
          message: 'UDP Data Channel 전송 세션을 시작합니다.',
          windowSize: context.windowSize,
        ),
      );
      if (initAck.dataPort == null) {
        throw const AppException(
          code: 'transfer_data_endpoint_missing',
          message: '상대 노드의 data endpoint 정보가 없습니다.',
        );
      }
      context.remoteDataAddress = InternetAddress(
        TransferDataEndpointResolver.senderRemoteAddress(
          advertisedAddress: initAck.dataAddress,
          controlAckSourceAddress: initAck.sourceAddress,
        ),
      );
      context.remoteDataPort = initAck.dataPort!;
      _validateRemoteDataEndpoint(
        routeSnapshot: context.routeSnapshot,
        remoteAddress: context.remoteDataAddress!,
      );
      context.advertisedWindowSize =
          initAck.acceptedWindowSize ?? context.advertisedWindowSize;
      final senderBind = await _bindDataTransport(context.controlEndpoint);
      _validateDataBindEndpoint(
        routeSnapshot: context.routeSnapshot,
        dataEndpoint: senderBind.endpoint,
      );
      _ensureRouteLeaseStillActive(context);
      context.localDataEndpoint = senderBind.endpoint;
      context.routeSnapshot = context.routeSnapshot.copyWith(
        dataLocalAddress: senderBind.endpoint.localAddress,
        dataRemoteAddress: context.remoteDataAddress!.address,
        dataRemotePort: context.remoteDataPort!,
      );
      _updateJob(
        transferId,
        (job) => job.copyWith(routeSnapshot: context.routeSnapshot),
      );
      _registerFrameKey(
        direction: TransferDirection.outgoing,
        transferId: transferId,
        transferIdBytes: context.transferIdBytes,
      );
      await _sendDataFrame(
        _dataFrame(
          context,
          type: DataFrameType.dataStart,
          sequence: context.nextSequence(),
        ),
        address: context.remoteDataAddress!,
        port: context.remoteDataPort!,
      );

      await _pumpOutgoingWindow(transferId, context);
      await context.allChunksAcked.future;
      if (context.hasFailed) {
        return;
      }

      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.verifying,
          updatedAt: _now(),
          message: '모든 data chunk ACK 를 수신했습니다. 완료 확인을 기다립니다.',
        ),
      );
      final digest = await context.closeOutgoingDigest();
      await _sendDataFrame(
        _dataFrame(
          context,
          type: DataFrameType.dataFinish,
          sequence: context.nextSequence(),
          payload: Uint8List.fromList(utf8.encode(digest)),
        ),
        address: context.remoteDataAddress!,
        port: context.remoteDataPort!,
      );

      final completeAck = await context.completeAck.future.timeout(
        _completeAckTimeout,
      );
      if (context.hasFailed) {
        return;
      }
      if (!completeAck.accepted) {
        _markFailed(transferId, completeAck.message ?? '상대가 파일 완료를 거절했습니다.');
        return;
      }

      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.completed,
          bytesTransferred: job.fileSize,
          completedChunks: job.totalChunks,
          destinationPath: completeAck.savePath ?? job.destinationPath,
          updatedAt: _now(),
          message: completeAck.message ?? '파일 전송이 완료되었습니다.',
          retryCount: context.retryCount,
          lossRate: _lossRateFor(context),
          throughputBytesPerSec: _throughputBytesPerSec(
            transferredBytes: context.acknowledgedBytes,
            startedAt: context.startedAt,
          ),
          rttMs: context.rttEstimator.smoothedRttMs,
          windowSize: context.windowSize,
        ),
      );
      state = state.copyWith(
        infoMessage: '파일 전송이 완료되었습니다: ${context.preparedFile.fileName}',
      );
    } on TimeoutException {
      await _failOutgoingTransfer(
        transferId,
        '상대 노드의 전송 응답 시간이 초과되었습니다. '
        '대상 ${context.session.peerAddress}:${context.session.peerPort} 에서 '
        'TRANSFER_INIT_ACK 를 받지 못했습니다. '
        'local=${_endpointLabel(context.controlEndpoint)}',
      );
    } on AppException catch (error) {
      await _failOutgoingTransfer(transferId, error.message);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferData,
            'Outgoing transfer failed',
            error: error,
            stackTrace: stackTrace,
          );
      await _failOutgoingTransfer(transferId, '파일 전송 중 오류가 발생했습니다: $error');
    } finally {
      final current = _removeOutgoingTransfer(transferId);
      await current?.dispose();
    }
  }

  Future<void> _pumpOutgoingWindow(
    String transferId,
    _OutgoingTransferContext context,
  ) async {
    if (context.isPumpActive || context.hasFailed) {
      return;
    }
    context.isPumpActive = true;
    try {
      while (!context.hasFailed) {
        if (context.inFlightChunks.length >= context.windowSize) {
          break;
        }

        final nextChunkIndex = _nextChunkForSend(context);
        if (nextChunkIndex == null) {
          break;
        }

        final isRetransmission = context.dequeueRetransmission(nextChunkIndex);
        final sent = await _sendChunk(
          transferId,
          context,
          nextChunkIndex,
          isRetransmission: isRetransmission,
        );
        if (!sent) {
          break;
        }
      }

      if (TransferOutgoingCompletionCommand.shouldComplete(
        isAlreadyCompleted: context.allChunksAcked.isCompleted,
        acknowledgedChunkCount: context.acknowledgedChunks.length,
        chunkCount: context.preparedFile.chunkCount,
        inFlightChunkCount: context.inFlightChunks.length,
      )) {
        context.allChunksAcked.complete();
      }
    } finally {
      context.isPumpActive = false;
    }
  }

  int? _nextChunkForSend(_OutgoingTransferContext context) {
    final decision = TransferOutgoingNextChunkCommand.decide(
      retransmissionCandidate: context.nextQueuedRetransmission(),
      nextChunkToSend: context.nextChunkToSend,
      chunkCount: context.preparedFile.chunkCount,
      remoteWindowStart: context.remoteWindowStart,
      advertisedWindowSize: context.advertisedWindowSize,
      acknowledgedChunks: context.acknowledgedChunks,
      inFlightChunks: context.inFlightChunks,
    );
    context.nextChunkToSend = decision.nextChunkToSend;
    return decision.chunkIndex;
  }

  Future<bool> _sendChunk(
    String transferId,
    _OutgoingTransferContext context,
    int chunkIndex, {
    required bool isRetransmission,
  }) async {
    final nextAttempts = TransferOutgoingSendFailureCommand.nextSendAttempt(
      currentAttempts: context.retransmissionAttempts[chunkIndex] ?? 0,
      isRetransmission: isRetransmission,
    );
    _ensureRouteLeaseStillActive(context);
    if (nextAttempts > _maxRetransmissions) {
      throw AppException(
        code: 'transfer_retry_exhausted',
        message: TransferOutgoingChunkMetricMessageCommand.retryExhausted(
          chunkIndex: chunkIndex,
        ),
      );
    }

    if (isRetransmission) {
      context.retryCount += 1;
      context.windowSize = TransferOutgoingWindowReductionCommand.reduce(
        context.windowSize,
      );
      context.retransmissionAttempts[chunkIndex] = nextAttempts;
      context.hasRetransmitted.add(chunkIndex);
    }

    final bytes = await context.reader.readAt(
      chunkSize: context.preparedFile.chunkSize,
      chunkIndex: chunkIndex,
    );
    final digestDecision = TransferOutgoingDigestAdvanceCommand.decide(
      isRetransmission: isRetransmission,
      chunkIndex: chunkIndex,
      nextDigestChunk: context.nextDigestChunk,
    );
    if (digestDecision.shouldAppendToDigest) {
      context.outgoingDigest.add(bytes);
    }
    context.nextDigestChunk = digestDecision.nextDigestChunk;
    final now = _now();
    context.inFlightChunks.add(chunkIndex);
    context.sentAtByChunk[chunkIndex] = now;
    try {
      final remoteAddress = context.remoteDataAddress;
      final remotePort = context.remoteDataPort;
      final endpointDecision = TransferOutgoingDataEndpointCommand.validate(
        address: remoteAddress?.address,
        port: remotePort,
      );
      if (!endpointDecision.isValid) {
        throw const AppException(
          code: 'transfer_data_endpoint_missing',
          message: '상대 노드의 data endpoint 정보가 없습니다.',
        );
      }
      await _sendDataFrame(
        _dataFrame(
          context,
          type: DataFrameType.dataChunk,
          sequence: context.nextSequence(),
          chunkIndex: chunkIndex,
          windowStart: context.remoteWindowStart,
          windowSize: context.windowSize,
          payload: Uint8List.fromList(bytes),
        ),
        address: InternetAddress(endpointDecision.address!),
        port: endpointDecision.port!,
      );
    } on AppException catch (error) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      if (!TransferOutgoingRetryableSendFailureCommand.isRetryable(
        error.code,
      )) {
        rethrow;
      }
      final failureDecision =
          TransferOutgoingSendFailureCommand.onRetryableFailure(
            nextAttempts: nextAttempts,
            recordedAttempts: context.retransmissionAttempts[chunkIndex] ?? 0,
            maxRetransmissions: _maxRetransmissions,
            isRetransmission: isRetransmission,
          );
      if (failureDecision.action ==
          TransferOutgoingSendFailureAction.exhausted) {
        throw AppException(
          code: 'transfer_retry_exhausted',
          message: TransferOutgoingChunkMetricMessageCommand.retryExhausted(
            chunkIndex: chunkIndex,
          ),
        );
      }
      if (failureDecision.shouldReduceWindow) {
        context.retryCount += 1;
        context.windowSize = TransferOutgoingWindowReductionCommand.reduce(
          context.windowSize,
        );
      }
      context.retransmissionAttempts[chunkIndex] =
          failureDecision.attemptsAfterFailure;
      context.hasRetransmitted.add(chunkIndex);
      context.queueRetransmission(chunkIndex);
      context.scheduleBackpressureRetry(
        _sendBackpressureRetryDelay,
        () => unawaited(_pumpOutgoingWindow(transferId, context)),
      );
      _updateOutgoingMetrics(
        transferId,
        context,
        message: TransferOutgoingChunkMetricMessageCommand.retryQueued(
          chunkIndex: chunkIndex,
        ),
      );
      return false;
    } catch (_) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      rethrow;
    }
    context.ensureRetransmissionScan(
      context.rttEstimator.currentTimeout,
      () => _onRetransmissionScan(transferId),
    );
    _updateOutgoingMetrics(
      transferId,
      context,
      message: TransferOutgoingChunkMetricMessageCommand.sent(
        chunkIndex: chunkIndex,
        isRetransmission: isRetransmission,
        windowSize: context.windowSize,
      ),
    );
    return true;
  }

  void _onRetransmissionScan(String transferId) {
    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }
    context.retransmissionScanTimer = null;
    if (context.inFlightChunks.isEmpty) {
      return;
    }

    final now = _now();
    final timeout = context.rttEstimator.currentTimeout;
    final scanDecision = TransferOutgoingRetransmissionScanCommand.scan(
      now: now,
      timeout: timeout,
      inFlightChunks: context.inFlightChunks,
      acknowledgedChunks: context.acknowledgedChunks,
      sentAtByChunk: context.sentAtByChunk,
    );
    for (final chunkIndex in scanDecision.acknowledgedInFlightIndexes) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
    }
    for (final chunkIndex in scanDecision.timedOutIndexes) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      context.queueRetransmission(chunkIndex);
    }

    if (scanDecision.timedOutIndexes.isNotEmpty) {
      context.rttEstimator.noteTimeoutBackoff();
      context.windowSize = TransferOutgoingWindowReductionCommand.reduce(
        context.windowSize,
      );
      _updateOutgoingMetrics(
        transferId,
        context,
        message: TransferOutgoingChunkMetricMessageCommand.timeoutQueued(
          chunkCount: scanDecision.timedOutIndexes.length,
        ),
      );
      unawaited(_pumpOutgoingWindow(transferId, context));
    }

    if (context.inFlightChunks.isNotEmpty) {
      context.ensureRetransmissionScan(
        context.rttEstimator.currentTimeout,
        () => _onRetransmissionScan(transferId),
      );
    }
  }

  Future<void> _onTransferInit(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final commandResult = TransferInitReceiveCommand.fromPacket(packet);
    final command = commandResult.command;
    if (command == null) {
      return;
    }
    final transferId = command.transferId;
    final fileName = command.fileName;
    final fileSize = command.fileSize;
    final sha256 = command.sha256;
    final chunkCount = command.chunkCount;

    final packetPeerId = command.packetPeerId;
    ref
        .read(appLoggerProvider)
        .info(
          AppLogCategory.transferControl,
          'Received TRANSFER_INIT ${_safeTransfer(transferId)} '
          'peer=$packetPeerId source=${datagram.address.address}:${datagram.port} '
          'local=${_endpointLabel(datagram.localEndpoint)} '
          'file=${_safeFileNameForLog(fileName)} '
          'size=$fileSize chunks=$chunkCount',
        );
    final session = _authenticatedSessionForTransferInit(
      packet,
      datagram,
      packetPeerId: packetPeerId,
    );
    final peerId = session?.peerId ?? packetPeerId;
    if (session == null) {
      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: '인증된 피어만 파일을 전송할 수 있습니다.',
        localEndpoint: datagram.localEndpoint,
      );
      return;
    }
    late final PeerConnectionPath activeRoute;
    try {
      activeRoute = _requireActiveTransferRoute(
        peerId: peerId,
        session: session,
        observedDatagram: datagram,
      );
    } on AppException catch (error) {
      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: error.message,
        localEndpoint: datagram.localEndpoint,
      );
      return;
    }
    final controlLocalEndpoint =
        datagram.localEndpoint ?? activeRoute.controlEndpoint;
    var routeSnapshot = _snapshotFromActiveRoute(activeRoute).copyWith(
      controlRemoteAddress: datagram.address.address,
      controlRemotePort: datagram.port,
    );

    IncomingTransferDraft? draft;
    IncomingDigestingTransferWriter? writer;
    var ownershipMovedToSession = false;
    try {
      final settings = await _loadIncomingSettingsForTransfer(transferId);
      final fileService = ref.read(transferFileServiceProvider);
      draft = await fileService.createIncomingDraft(
        transferId: transferId,
        fileName: fileName,
      );
      writer = await _openIncomingWriterForTransfer(
        draft.tempFilePath,
        transferId: transferId,
      );
      final dataBind = await _bindDataTransportForIncoming(
        controlLocalEndpoint,
        transferId: transferId,
      );
      _validateDataBindEndpoint(
        routeSnapshot: routeSnapshot,
        dataEndpoint: dataBind.endpoint,
      );
      routeSnapshot = routeSnapshot.copyWith(
        dataLocalAddress: dataBind.endpoint.localAddress,
        dataRemoteAddress: datagram.address.address,
      );
      final now = _now();
      final transferIdBytes = transferIdBytesFromString(transferId);
      final incomingContext = _IncomingTransferContext(
        sessionId: packet.sessionId,
        peerId: peerId,
        peerDisplayName: command.peerDisplayName,
        controlAddress: datagram.address,
        controlPort: datagram.port,
        controlLocalEndpoint: controlLocalEndpoint,
        tempFilePath: draft.tempFilePath,
        fileName: fileName,
        fileSize: fileSize,
        expectedSha256: sha256,
        expectedChunkCount: chunkCount,
        saveDirectory: settings.defaultSavePath,
        startedAt: now,
        writer: writer,
        transferIdBytes: transferIdBytes,
        sessionHash: 0,
        routeSnapshot: routeSnapshot,
      );
      _registerIncomingTransfer(transferId, incomingContext);
      ownershipMovedToSession = true;
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.transferControl,
            'Incoming transfer prepared '
            'transfer=${_safeTransfer(transferId)} peer=$peerId '
            'file=${_safeFileNameForLog(fileName)} '
            'dataLocal=${_endpointLabel(dataBind.endpoint)} '
            'dataRemote=${datagram.address.address}',
          );
      _upsertJob(
        TransferJob(
          id: transferId,
          transferId: transferId,
          direction: TransferDirection.incoming,
          peerId: peerId,
          peerDisplayName: command.peerDisplayName,
          fileName: fileName,
          fileSize: fileSize,
          bytesTransferred: 0,
          totalChunks: chunkCount,
          completedChunks: 0,
          status: TransferJobStatus.awaitingAcceptance,
          createdAt: now,
          updatedAt: now,
          destinationPath: settings.defaultSavePath,
          message: '수신 준비를 완료했습니다.',
          windowSize: _receiverAdvertisedWindow,
          routeSnapshot: routeSnapshot,
        ),
      );

      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: true,
        savePath: settings.defaultSavePath,
        dataEndpoint: dataBind.endpoint,
        dataAddress: TransferDataEndpointResolver.advertisedReceiverAddress(
          dataEndpoint: dataBind.endpoint,
        ),
        acceptedChunkSize: command.acceptedChunkSize ?? _dataChunkSize,
        acceptedWindowSize: _receiverAdvertisedWindow,
        receiverBufferBudget: _receiverAdvertisedWindow * _dataChunkSize,
        dataAuthContextId: command.dataAuthContextId,
        localEndpoint: controlLocalEndpoint,
      );
      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.receiving,
          updatedAt: _now(),
          message: 'Selective repeat 수신을 시작했습니다.',
          windowSize: _receiverAdvertisedWindow,
        ),
      );
    } on AppException catch (error) {
      if (!ownershipMovedToSession) {
        await _cleanupRejectedIncomingDraft(draft, writer);
      }
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Incoming transfer prepare rejected '
            'transfer=${_safeTransfer(transferId)} code=${error.code} '
            'peer=$peerId source=${datagram.address.address}:${datagram.port} '
            'local=${_endpointLabel(datagram.localEndpoint)}',
          );
      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: error.message,
        localEndpoint: controlLocalEndpoint,
      );
    } catch (error, stackTrace) {
      if (!ownershipMovedToSession) {
        await _cleanupRejectedIncomingDraft(draft, writer);
      }
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferControl,
            'Failed to prepare incoming transfer '
            'transfer=${_safeTransfer(transferId)} '
            'peer=$peerId source=${datagram.address.address}:${datagram.port} '
            'local=${_endpointLabel(datagram.localEndpoint)}',
            error: error,
            stackTrace: stackTrace,
          );
      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: '수신 준비 중 알 수 없는 오류가 발생했습니다. 수신 노드 로그를 확인해 주세요.',
        localEndpoint: controlLocalEndpoint,
      );
    }
  }

  Future<void> _onDataChannelOffer(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final dataSessionId = packet.dataChannelSessionId;
    final host = packet.dataChannelHost;
    final port = packet.dataChannelPort;
    if (dataSessionId == null ||
        dataSessionId.isEmpty ||
        host == null ||
        host.isEmpty ||
        port == null ||
        !TcpDataEndpoint(host: host, port: port).hasValidPort) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'Ignored invalid DATA_CHANNEL_OFFER '
            'session=${_safeSession(packet.sessionId)} '
            'source=${datagram.address.address}:${datagram.port}',
          );
      return;
    }

    final localIdentity = _localIdentity;
    if (localIdentity == null) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'Ignored DATA_CHANNEL_OFFER because local identity is missing '
            'session=${_safeSession(packet.sessionId)}',
          );
      return;
    }

    if (!ref.mounted) {
      return;
    }
    final packetPeerId = PeerIdentity.resolve(
      userId: packet.fromUserId,
      instanceId: packet.fromInstanceId,
      deviceId: packet.fromDeviceId,
    ).id;
    final session = _authenticatedSessionForControlPacket(
      packet,
      datagram,
      packetPeerId: packetPeerId,
      packetLabel: 'DATA_CHANNEL_OFFER',
    );
    if (session == null) {
      return;
    }

    final protocolVersion = _protocolMajor(
      ref.read(appConfigProvider).protocolVersion,
    );
    final localPeerId = PeerIdentity.resolve(
      userId: _currentUserId(),
      instanceId: localIdentity.instanceId,
      deviceId: localIdentity.deviceId,
    ).id;
    final result = await ref
        .read(tcpDataOutboundChannelOpenCommandProvider)
        .open(
          connectRequest: TcpDataConnectRequest(
            peerId: session.peerId,
            authSessionId: session.sessionId,
            sessionId: TcpDataSessionId(dataSessionId),
            host: host,
            port: port,
          ),
          hello: TcpDataSessionHello(
            sessionId: TcpDataSessionId(dataSessionId),
            peerId: localPeerId,
            instanceId: localIdentity.instanceId,
            authSessionId: session.sessionId,
            protocolVersion: protocolVersion,
            dataProtocolVersion: 1,
            proof: session.sessionId,
          ),
        );
    if (!ref.mounted) {
      return;
    }
    if (!result.opened &&
        result.issueCode != 'tcp_data_outbound_already_connected') {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'DATA_CHANNEL_OFFER did not open TCP channel '
            'peer=${session.peerId} issue=${result.issueCode}',
          );
    }
  }

  Future<void> _onDataChannelConnect(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final packetPeerId = PeerIdentity.resolve(
      userId: packet.fromUserId,
      instanceId: packet.fromInstanceId,
      deviceId: packet.fromDeviceId,
    ).id;
    final session = _authenticatedSessionForControlPacket(
      packet,
      datagram,
      packetPeerId: packetPeerId,
      packetLabel: 'DATA_CHANNEL_CONNECT',
    );
    if (session == null) {
      return;
    }
    await _sendTcpDataChannelOffer(session, force: true);
  }

  Future<void> _sendTcpDataChannelOffersToAuthenticatedPeers() async {
    if (!ref.mounted) {
      return;
    }
    for (final session
        in ref.read(peerAuthControllerProvider).sessions.values) {
      if (session.isAuthenticated) {
        await _sendTcpDataChannelOffer(session);
        if (!ref.mounted) {
          return;
        }
      }
    }
  }

  Future<void> _sendTcpDataChannelOffer(
    PeerAuthSession session, {
    bool force = false,
  }) async {
    if (!ref.mounted) {
      return;
    }
    final binding = _tcpDataListenerBinding;
    final localIdentity = _localIdentity;
    if (binding == null || localIdentity == null || !session.isAuthenticated) {
      return;
    }
    final offerKey = '${session.peerId}:${session.sessionId}';
    if (!force && _offeredTcpDataPeers.contains(offerKey)) {
      return;
    }
    final path = ref
        .read(peerPathRegistryProvider)
        .selectedForPeer(session.peerId);
    if (path == null) {
      return;
    }
    final advertisedHost = path.controlEndpoint.localAddress;
    if (advertisedHost.isEmpty ||
        advertisedHost == InternetAddress.anyIPv4.address ||
        advertisedHost == InternetAddress.anyIPv6.address) {
      return;
    }

    _offeredTcpDataPeers.add(offerKey);
    try {
      await _send(
        AuthPacket(
          type: AuthPacketType.dataChannelOffer,
          protocolVersion: ref.read(appConfigProvider).protocolVersion,
          sessionId: session.sessionId,
          fromUserId: _currentUserId(),
          fromDeviceId: localIdentity.deviceId,
          fromInstanceId: localIdentity.instanceId,
          fromDisplayName: _currentDisplayName(),
          sentAtEpochMs: _now().millisecondsSinceEpoch,
          dataChannelSessionId: _randomHex(12),
          dataChannelHost: advertisedHost,
          dataChannelPort: binding.port,
          dataChannelDirection: 'inbound',
        ),
        address: InternetAddress(path.candidate.remoteAddress),
        port: path.candidate.remotePort,
        localEndpoint: path.controlEndpoint,
      );
    } catch (error, stackTrace) {
      _offeredTcpDataPeers.remove(offerKey);
      if (!ref.mounted) {
        return;
      }
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'Failed to send DATA_CHANNEL_OFFER peer=${session.peerId}',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  Future<bool> _requestAndWaitForOutboundTcpDataChannel(
    PeerAuthSession session,
  ) async {
    await _requestTcpDataChannelOffer(session);
    final elapsed = Stopwatch()..start();
    while (elapsed.elapsed < const Duration(seconds: 2)) {
      if (!ref.mounted) {
        return false;
      }
      final existing = ref
          .read(tcpDataChannelSessionRegistryProvider)
          .lookup(
            DataChannelSessionKey(
              peerId: session.peerId,
              authSessionId: session.sessionId,
              direction: TcpDataChannelDirection.outbound,
            ),
          );
      if (existing?.status == TcpDataPeerSessionStatus.connected) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return false;
  }

  Future<void> _requestTcpDataChannelOffer(PeerAuthSession session) async {
    if (!ref.mounted || !session.isAuthenticated) {
      return;
    }
    final localIdentity = _localIdentity;
    if (localIdentity == null) {
      return;
    }
    final path = ref
        .read(peerPathRegistryProvider)
        .selectedForPeer(session.peerId);
    if (path == null || path.status != PeerPathStatus.active) {
      return;
    }
    try {
      await _send(
        AuthPacket(
          type: AuthPacketType.dataChannelConnect,
          protocolVersion: ref.read(appConfigProvider).protocolVersion,
          sessionId: session.sessionId,
          fromUserId: _currentUserId(),
          fromDeviceId: localIdentity.deviceId,
          fromInstanceId: localIdentity.instanceId,
          fromDisplayName: _currentDisplayName(),
          sentAtEpochMs: _now().millisecondsSinceEpoch,
        ),
        address: InternetAddress(path.candidate.remoteAddress),
        port: path.candidate.remotePort,
        localEndpoint: path.controlEndpoint,
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'Failed to send DATA_CHANNEL_CONNECT peer=${session.peerId}',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  void _onTransferInitAck(AuthPacket packet, ControlDatagram datagram) {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.initAck.isCompleted) {
      return;
    }
    context.initAck.complete(
      _TransferInitAckResult(
        accepted: packet.transferAccepted ?? false,
        message: packet.rejectMessage,
        savePath: packet.transferSavePath,
        sourceAddress: datagram.address.address,
        dataAddress: packet.transferDataAddress,
        dataPort: packet.transferDataPort,
        acceptedChunkSize: packet.transferAcceptedChunkSize,
        acceptedWindowSize: packet.transferAcceptedWindowSize,
      ),
    );
  }

  Future<void> _onTransferChunk(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final transferId = packet.transferId;
    final chunkIndex = packet.transferChunkIndex;
    final chunkDataBase64 = packet.transferChunkDataBase64;
    if (transferId == null || chunkIndex == null || chunkDataBase64 == null) {
      return;
    }

    final context = _lookupIncomingTransfer(transferId);
    if (context == null) {
      return;
    }

    if (chunkIndex >= context.expectedChunkCount) {
      await _sendChunkNack(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        chunkIndexes: [context.nextExpectedChunk],
        localEndpoint: datagram.localEndpoint,
      );
      return;
    }

    if (context.acknowledgedChunks.contains(chunkIndex)) {
      context.duplicateChunks += 1;
      await _sendChunkAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        chunkIndex: chunkIndex,
        localEndpoint: datagram.localEndpoint,
      );
      await _sendWindowUpdate(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        windowStart: context.nextExpectedChunk,
        windowSize: TransferIncomingWindowCommand.receiverWindowSize(
          advertisedWindowSize: _receiverAdvertisedWindow,
          bufferedChunkCount: context.bufferedChunks.length,
        ),
        localEndpoint: datagram.localEndpoint,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: '중복 chunk $chunkIndex 수신',
      );
      return;
    }

    try {
      final bytes = base64Decode(chunkDataBase64);
      context.acknowledgedChunks.add(chunkIndex);
      context.acknowledgedBytes += bytes.length;

      if (chunkIndex == context.nextExpectedChunk) {
        await _appendIncomingChunk(context, bytes);
        context.nextExpectedChunk += 1;
        await _flushBufferedChunks(context);
        await _sendChunkAck(
          sessionId: context.sessionId,
          transferId: transferId,
          address: datagram.address,
          port: datagram.port,
          chunkIndex: chunkIndex,
          localEndpoint: datagram.localEndpoint,
        );
      } else {
        context.bufferedChunks[chunkIndex] = bytes;
        await _sendChunkAck(
          sessionId: context.sessionId,
          transferId: transferId,
          address: datagram.address,
          port: datagram.port,
          chunkIndex: chunkIndex,
          localEndpoint: datagram.localEndpoint,
        );
        final missingIndexes =
            TransferIncomingMissingChunksCommand.untilHighestReceived(
              nextExpectedChunk: context.nextExpectedChunk,
              highestReceivedIndex: chunkIndex,
              acknowledgedChunks: context.acknowledgedChunks,
              limit: _maxNackIndexesPerPacket,
            );
        if (missingIndexes.isNotEmpty) {
          await _sendChunkNack(
            sessionId: context.sessionId,
            transferId: transferId,
            address: datagram.address,
            port: datagram.port,
            chunkIndexes: missingIndexes,
            localEndpoint: datagram.localEndpoint,
          );
        }
      }

      await _sendWindowUpdateIfNeeded(
        context,
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        localEndpoint: datagram.localEndpoint,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: chunkIndex == context.nextExpectedChunk - 1
            ? 'chunk $chunkIndex 수신'
            : 'out-of-order chunk $chunkIndex 버퍼링',
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferData,
            'Failed to process incoming chunk',
            error: error,
            stackTrace: stackTrace,
          );
      await _failIncomingTransfer(transferId, '수신 chunk 를 저장하지 못했습니다.');
    }
  }

  Future<void> _onDataChunk(
    String transferId,
    DataFrameDatagram datagram,
  ) async {
    final frame = datagram.frame;
    final chunkIndex = frame.chunkIndex;
    final context = _lookupIncomingTransfer(transferId);
    if (context == null) {
      return;
    }
    context.lastDataAddress = datagram.address;
    context.lastDataPort = datagram.port;
    final decision = TransferIncomingDataChunkCommand.decide(
      chunkIndex: chunkIndex,
      expectedChunkCount: context.expectedChunkCount,
      nextExpectedChunk: context.nextExpectedChunk,
      acknowledgedChunks: context.acknowledgedChunks,
    );

    if (decision.action == TransferIncomingDataChunkAction.rejectOutOfRange) {
      await _sendDataNackSafely(
        context,
        chunkIndexes: [decision.nackChunkIndex ?? context.nextExpectedChunk],
        address: datagram.address,
        port: datagram.port,
      );
      return;
    }

    if (decision.action == TransferIncomingDataChunkAction.ackDuplicate) {
      context.duplicateChunks += 1;
      await _queueDataAck(
        context,
        chunkIndex: chunkIndex,
        address: datagram.address,
        port: datagram.port,
        flushImmediately: true,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: '중복 data chunk $chunkIndex 수신',
      );
      return;
    }

    try {
      final bytes = frame.payload;
      context.acknowledgedChunks.add(chunkIndex);
      context.acknowledgedBytes += bytes.length;

      switch (decision.action) {
        case TransferIncomingDataChunkAction.appendInOrder:
          await _appendIncomingChunk(context, bytes);
          context.nextExpectedChunk += 1;
          await _flushBufferedChunks(context);
        case TransferIncomingDataChunkAction.bufferOutOfOrder:
          context.bufferedChunks[chunkIndex] = bytes;
          final missingIndexes =
              TransferIncomingMissingChunksCommand.untilHighestReceived(
                nextExpectedChunk: context.nextExpectedChunk,
                highestReceivedIndex: chunkIndex,
                acknowledgedChunks: context.acknowledgedChunks,
                limit: _maxNackIndexesPerPacket,
              );
          if (missingIndexes.isNotEmpty) {
            await _sendDataNackSafely(
              context,
              chunkIndexes: missingIndexes,
              address: datagram.address,
              port: datagram.port,
            );
          }
        case TransferIncomingDataChunkAction.rejectOutOfRange:
        case TransferIncomingDataChunkAction.ackDuplicate:
          return;
      }

      await _queueDataAck(
        context,
        chunkIndex: chunkIndex,
        address: datagram.address,
        port: datagram.port,
        flushImmediately:
            TransferIncomingAckRetryScheduleCommand.shouldFlushAfterAckEnqueue(
              pendingAckCountBeforeEnqueue: context.pendingAckChunks.length,
              ackBatchThreshold: _ackBatchChunkThreshold,
              nextExpectedChunk: context.nextExpectedChunk,
              expectedChunkCount: context.expectedChunkCount,
            ),
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: chunkIndex == context.nextExpectedChunk - 1
            ? 'data chunk $chunkIndex 수신'
            : 'out-of-order data chunk $chunkIndex 버퍼링',
      );
      if (context.bufferedChunks.isEmpty) {
        context.cancelMissingNackRetry();
      } else {
        _scheduleMissingDataNackRetry(transferId, context);
      }
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferData,
            'Failed to process incoming data chunk',
            error: error,
            stackTrace: stackTrace,
          );
      final message = _incomingChunkWriteFailureMessage(error);
      await _sendIncomingFailureAck(context, transferId, message);
      await _failIncomingTransfer(transferId, message);
    }
  }

  void _onDataAck(String transferId, DataFrameDatagram datagram) {
    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }
    final decision = TransferOutgoingDataAckCommand.decide(
      rawAckIndexes: TransferOutgoingAckIndexesCommand.decode(
        primaryChunkIndex: datagram.frame.chunkIndex,
        ackBase: datagram.frame.ackBase,
        ackBitmapWords: datagram.frame.ackBitmapWords,
      ),
      chunkCount: context.preparedFile.chunkCount,
      acknowledgedChunks: context.acknowledgedChunks,
    );
    if (decision.validAckIndexes.isEmpty) {
      return;
    }
    context.duplicateAckCount += decision.duplicateAckCount;
    var newlyAckedBytes = 0;
    for (final chunkIndex in decision.newlyAckedIndexes) {
      context.acknowledgedChunks.add(chunkIndex);
      context.inFlightChunks.remove(chunkIndex);
      final sentAt = context.sentAtByChunk.remove(chunkIndex);
      final retransmissions = context.retransmissionAttempts[chunkIndex] ?? 0;
      if (sentAt != null && retransmissions == 0) {
        context.rttEstimator.recordSample(_now().difference(sentAt));
      }
      newlyAckedBytes += _chunkByteLength(context.preparedFile, chunkIndex);
    }
    final newlyAckedCount = decision.newlyAckedIndexes.length;
    if (newlyAckedCount == 0) {
      return;
    }
    context.windowSize = TransferOutgoingWindowGrowthCommand.afterDataAck(
      tuningPolicy: const DataTransferTuningPolicy(
        initialWindowSize: _initialWindowSize,
        maximumWindowSize: _maximumWindowSize,
        receiverAdvertisedWindow: _receiverAdvertisedWindow,
        windowUpdateChunkInterval: _windowUpdateChunkInterval,
        ackBatchChunkThreshold: _ackBatchChunkThreshold,
        maxWindowGrowthPerAck: _maxWindowGrowthPerAck,
        maxRetransmissions: _maxRetransmissions,
        maxNackIndexesPerPacket: _maxNackIndexesPerPacket,
        ackBatchInterval: _ackBatchInterval,
        metricLogInterval: _metricLogInterval,
      ),
      currentWindowSize: context.windowSize,
      maximumWindowSize: _maximumWindowSize,
      newlyAckedChunks: newlyAckedCount,
    );
    context.remoteWindowStart = datagram.frame.windowStart;
    context.advertisedWindowSize = max(1, datagram.frame.windowSize);
    context.acknowledgedBytes += newlyAckedBytes;
    context.cancelRetransmissionScanIfIdle();
    _updateOutgoingMetrics(
      transferId,
      context,
      message:
          'DATA_ACK ${decision.validAckIndexes.first}-${decision.validAckIndexes.last} '
          'count=$newlyAckedCount 수신',
    );
    if (TransferOutgoingCompletionCommand.shouldComplete(
      isAlreadyCompleted: context.allChunksAcked.isCompleted,
      acknowledgedChunkCount: context.acknowledgedChunks.length,
      chunkCount: context.preparedFile.chunkCount,
      inFlightChunkCount: context.inFlightChunks.length,
    )) {
      context.allChunksAcked.complete();
    } else {
      unawaited(_pumpOutgoingWindow(transferId, context));
    }
  }

  void _onDataNack(String transferId, DataFrameDatagram datagram) {
    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }
    context.windowSize = TransferOutgoingWindowReductionCommand.reduce(
      context.windowSize,
    );
    final decision = TransferOutgoingDataNackCommand.decide(
      primaryChunkIndex: datagram.frame.chunkIndex,
      ackBase: datagram.frame.ackBase,
      ackBitmapWords: datagram.frame.ackBitmapWords,
      acknowledgedChunks: context.acknowledgedChunks,
    );
    for (final chunkIndex in decision.retransmissionIndexes) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      context.queueRetransmission(chunkIndex);
    }
    context.cancelRetransmissionScanIfIdle();
    _updateOutgoingMetrics(
      transferId,
      context,
      message: 'DATA_NACK ${decision.retransmissionIndexes.join(', ')} 수신',
    );
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  void _onDataWindowUpdate(String transferId, DataFrameDatagram datagram) {
    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }
    final decision = TransferOutgoingWindowUpdateCommand.decide(
      windowStart: datagram.frame.windowStart,
      windowSize: datagram.frame.windowSize,
    );
    context.remoteWindowStart = decision.remoteWindowStart;
    context.advertisedWindowSize = decision.advertisedWindowSize;
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  Future<void> _onDataFinish(
    String transferId,
    DataFrameDatagram datagram,
  ) async {
    final context = _lookupIncomingTransfer(transferId);
    if (context == null) {
      return;
    }
    final decision = TransferIncomingDataFinishCommand.decide(
      nextExpectedChunk: context.nextExpectedChunk,
      expectedChunkCount: context.expectedChunkCount,
      acknowledgedChunks: context.acknowledgedChunks,
      bufferedChunkCount: context.bufferedChunks.length,
      missingLimit: _maxNackIndexesPerPacket,
    );
    if (decision.action == TransferIncomingDataFinishAction.waitForMissing) {
      if (decision.missingIndexes.isNotEmpty) {
        await _sendDataNackSafely(
          context,
          chunkIndexes: decision.missingIndexes,
          address: datagram.address,
          port: datagram.port,
        );
      }
      _updateIncomingMetrics(
        transferId,
        context,
        message: '누락 data chunk 재전송을 기다리는 중입니다.',
      );
      return;
    }

    try {
      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.verifying,
          updatedAt: _now(),
          message: '수신 파일 streaming digest 를 검증하는 중입니다.',
        ),
      );
      final actualDigest = await context.closeWriterWithDigest();
      final expectedDigest = utf8.decode(datagram.frame.payload);
      if (actualDigest != expectedDigest) {
        throw const AppException(
          code: 'transfer_hash_mismatch',
          message: '파일 해시가 일치하지 않습니다.',
        );
      }

      final finalPath = await ref
          .read(transferFileServiceProvider)
          .finalizeIncomingFile(
            tempFilePath: context.tempFilePath,
            destinationDirectory: context.saveDirectory,
            fileName: context.fileName,
          );
      _removeIncomingTransfer(transferId);
      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.completed,
          bytesTransferred: job.fileSize,
          completedChunks: job.totalChunks,
          destinationPath: finalPath,
          updatedAt: _now(),
          message: '파일을 저장했습니다.',
          duplicateCount: context.duplicateChunks,
          throughputBytesPerSec: _throughputBytesPerSec(
            transferredBytes: context.writtenBytes,
            startedAt: context.startedAt,
          ),
          windowSize: TransferIncomingWindowCommand.receiverWindowSize(
            advertisedWindowSize: _receiverAdvertisedWindow,
            bufferedChunkCount: context.bufferedChunks.length,
          ),
        ),
      );
      state = state.copyWith(infoMessage: '파일을 수신했습니다: ${context.fileName}');
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: context.controlAddress,
        port: context.controlPort,
        accepted: true,
        savePath: finalPath,
        message: '수신 파일 검증이 완료되었습니다.',
        localEndpoint: context.controlLocalEndpoint,
      );
    } on AppException catch (error) {
      final failure = TransferIncomingFinalizeFailureMapper.map(error);
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Incoming data transfer finalize rejected '
            'transfer=${_safeTransfer(transferId)} peer=${context.peerId} '
            'code=${failure.reasonCode}',
          );
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: context.controlAddress,
        port: context.controlPort,
        accepted: false,
        message: failure.userMessage,
        localEndpoint: context.controlLocalEndpoint,
      );
      await _failIncomingTransfer(transferId, failure.userMessage);
    } catch (error, stackTrace) {
      final failure = TransferIncomingFinalizeFailureMapper.map(error);
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferData,
            'Failed to finalize incoming data transfer',
            error: error,
            stackTrace: stackTrace,
          );
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: context.controlAddress,
        port: context.controlPort,
        accepted: false,
        message: failure.userMessage,
        localEndpoint: context.controlLocalEndpoint,
      );
      await _failIncomingTransfer(transferId, failure.userMessage);
    }
  }

  void _onTransferChunkAck(AuthPacket packet) {
    final transferId = packet.transferId;
    final chunkIndex = packet.transferChunkIndex;
    if (transferId == null || chunkIndex == null) {
      return;
    }

    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }

    if (context.acknowledgedChunks.contains(chunkIndex)) {
      context.duplicateAckCount += 1;
      _updateOutgoingMetrics(
        transferId,
        context,
        message: '중복 ACK $chunkIndex 수신',
      );
      return;
    }

    context.acknowledgedChunks.add(chunkIndex);
    context.inFlightChunks.remove(chunkIndex);
    final sentAt = context.sentAtByChunk.remove(chunkIndex);
    final retransmissions = context.retransmissionAttempts[chunkIndex] ?? 0;
    if (sentAt != null && retransmissions == 0) {
      context.rttEstimator.recordSample(_now().difference(sentAt));
    }
    context.windowSize = TransferOutgoingWindowGrowthCommand.afterLegacyAck(
      currentWindowSize: context.windowSize,
      maximumWindowSize: _maximumWindowSize,
    );
    context.acknowledgedBytes += _chunkByteLength(
      context.preparedFile,
      chunkIndex,
    );
    context.cancelRetransmissionScanIfIdle();
    _updateOutgoingMetrics(transferId, context, message: 'ACK $chunkIndex 수신');
    if (TransferOutgoingCompletionCommand.shouldComplete(
      isAlreadyCompleted: context.allChunksAcked.isCompleted,
      acknowledgedChunkCount: context.acknowledgedChunks.length,
      chunkCount: context.preparedFile.chunkCount,
      inFlightChunkCount: context.inFlightChunks.length,
    )) {
      context.allChunksAcked.complete();
    } else {
      unawaited(_pumpOutgoingWindow(transferId, context));
    }
  }

  void _onTransferChunkNack(AuthPacket packet) {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }

    final chunkIndexes = {
      if (packet.transferChunkIndex != null) packet.transferChunkIndex!,
      ...?packet.transferChunkIndexes,
    }.toList(growable: false);
    if (chunkIndexes.isEmpty) {
      return;
    }

    context.windowSize = TransferOutgoingWindowReductionCommand.reduce(
      context.windowSize,
    );
    for (final chunkIndex in chunkIndexes) {
      if (context.acknowledgedChunks.contains(chunkIndex)) {
        continue;
      }
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      context.queueRetransmission(chunkIndex);
    }
    context.cancelRetransmissionScanIfIdle();
    _updateOutgoingMetrics(
      transferId,
      context,
      message: 'NACK ${chunkIndexes.join(', ')} 수신',
    );
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  void _onTransferWindowUpdate(AuthPacket packet) {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }

    if (packet.transferWindowStart != null) {
      context.remoteWindowStart = packet.transferWindowStart!;
    }
    if (packet.transferWindowSize != null) {
      context.advertisedWindowSize = max(1, packet.transferWindowSize!);
    }
    _updateOutgoingMetrics(
      transferId,
      context,
      message:
          'window update ${context.remoteWindowStart}/${context.advertisedWindowSize}',
    );
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  Future<void> _onTransferComplete(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _lookupIncomingTransfer(transferId);
    if (context == null) {
      return;
    }

    final decision = TransferIncomingDataFinishCommand.decide(
      nextExpectedChunk: context.nextExpectedChunk,
      expectedChunkCount: context.expectedChunkCount,
      acknowledgedChunks: context.acknowledgedChunks,
      bufferedChunkCount: context.bufferedChunks.length,
      missingLimit: _maxNackIndexesPerPacket,
    );
    if (decision.action == TransferIncomingDataFinishAction.waitForMissing) {
      if (decision.missingIndexes.isNotEmpty) {
        await _sendChunkNack(
          sessionId: context.sessionId,
          transferId: transferId,
          address: datagram.address,
          port: datagram.port,
          chunkIndexes: decision.missingIndexes,
          localEndpoint: datagram.localEndpoint,
        );
      }
      await _sendWindowUpdate(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        windowStart: context.nextExpectedChunk,
        windowSize: TransferIncomingWindowCommand.receiverWindowSize(
          advertisedWindowSize: _receiverAdvertisedWindow,
          bufferedChunkCount: context.bufferedChunks.length,
        ),
        localEndpoint: datagram.localEndpoint,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: '누락 chunk 재전송을 기다리는 중입니다.',
      );
      return;
    }

    try {
      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.verifying,
          updatedAt: _now(),
          message: '수신 파일 해시를 검증하는 중입니다.',
        ),
      );
      await context.closeWriter();

      if (context.acknowledgedChunks.length != context.expectedChunkCount) {
        throw const AppException(
          code: 'transfer_chunk_count_mismatch',
          message: '수신한 chunk 수가 예상과 다릅니다.',
        );
      }
      if (context.writtenBytes != context.fileSize) {
        throw const AppException(
          code: 'transfer_size_mismatch',
          message: '수신한 파일 크기가 예상과 다릅니다.',
        );
      }

      if (context.expectedSha256 != null) {
        final actualSha256 = await ref
            .read(transferFileServiceProvider)
            .computeSha256(context.tempFilePath);
        if (actualSha256 != context.expectedSha256) {
          throw const AppException(
            code: 'transfer_hash_mismatch',
            message: '파일 해시가 일치하지 않습니다.',
          );
        }
      }

      final finalPath = await ref
          .read(transferFileServiceProvider)
          .finalizeIncomingFile(
            tempFilePath: context.tempFilePath,
            destinationDirectory: context.saveDirectory,
            fileName: context.fileName,
          );
      _removeIncomingTransfer(transferId);
      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.completed,
          bytesTransferred: job.fileSize,
          completedChunks: job.totalChunks,
          destinationPath: finalPath,
          updatedAt: _now(),
          message: '파일을 저장했습니다.',
          duplicateCount: context.duplicateChunks,
          throughputBytesPerSec: _throughputBytesPerSec(
            transferredBytes: context.writtenBytes,
            startedAt: context.startedAt,
          ),
          windowSize: TransferIncomingWindowCommand.receiverWindowSize(
            advertisedWindowSize: _receiverAdvertisedWindow,
            bufferedChunkCount: context.bufferedChunks.length,
          ),
        ),
      );
      state = state.copyWith(infoMessage: '파일을 수신했습니다: ${context.fileName}');
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: true,
        savePath: finalPath,
        message: '수신 파일 검증이 완료되었습니다.',
        localEndpoint: datagram.localEndpoint,
      );
    } on AppException catch (error) {
      final failure = TransferIncomingFinalizeFailureMapper.map(error);
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Incoming transfer finalize rejected '
            'transfer=${_safeTransfer(transferId)} peer=${context.peerId} '
            'code=${failure.reasonCode}',
          );
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: failure.userMessage,
        localEndpoint: datagram.localEndpoint,
      );
      await _failIncomingTransfer(transferId, failure.userMessage);
    } catch (error, stackTrace) {
      final failure = TransferIncomingFinalizeFailureMapper.map(error);
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferData,
            'Failed to finalize incoming transfer',
            error: error,
            stackTrace: stackTrace,
          );
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: failure.userMessage,
        localEndpoint: datagram.localEndpoint,
      );
      await _failIncomingTransfer(transferId, failure.userMessage);
    }
  }

  Future<void> _onTransferCompleteAck(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _lookupOutgoingTransfer(transferId);
    if (context == null || context.completeAck.isCompleted) {
      return;
    }
    context.completeAck.complete(
      _TransferCompleteAckResult(
        accepted: packet.transferAccepted ?? false,
        message: packet.rejectMessage,
        savePath: packet.transferSavePath,
      ),
    );
    if (packet.transferAccepted != true) {
      await _failOutgoingTransfer(
        transferId,
        packet.rejectMessage ?? '상대가 파일 완료를 거절했습니다.',
      );
    }
  }

  Future<void> _sendTransferInitAck({
    required String sessionId,
    required String transferId,
    required InternetAddress address,
    required int port,
    required bool accepted,
    String? message,
    String? savePath,
    UdpInterfaceEndpoint? dataEndpoint,
    String? dataAddress,
    int? acceptedChunkSize,
    int? acceptedWindowSize,
    int? receiverBufferBudget,
    String? dataAuthContextId,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    return _send(
      AuthPacket(
        type: AuthPacketType.transferInitAck,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: sessionId,
        fromUserId: _currentUserId(),
        fromDeviceId: _currentDeviceId(),
        fromInstanceId: _currentInstanceId(),
        fromDisplayName: _currentDisplayName(),
        transferId: transferId,
        transferAccepted: accepted,
        rejectMessage: message,
        transferSavePath: savePath,
        transferDataAddress:
            dataAddress ??
            (dataEndpoint == null
                ? null
                : TransferDataEndpointResolver.advertisedReceiverAddress(
                    dataEndpoint: dataEndpoint,
                  )),
        transferDataPort: dataEndpoint?.port,
        transferAcceptedChunkSize: acceptedChunkSize,
        transferAcceptedWindowSize: acceptedWindowSize,
        transferReceiverBufferBudget: receiverBufferBudget,
        transferDataProtocol: DataTransferCapability.udpDataBinaryV1.name,
        transferCapabilities: const ['udpDataBinaryV1'],
        transferDataAuthContextId: dataAuthContextId,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: localEndpoint,
    );
  }

  Future<void> _queueDataAck(
    _IncomingTransferContext context, {
    required int chunkIndex,
    required InternetAddress address,
    required int port,
    bool flushImmediately = false,
  }) {
    context.pendingAckChunks.add(chunkIndex);
    context.pendingAckAddress = address;
    context.pendingAckPort = port;
    if (flushImmediately ||
        context.pendingAckChunks.length >= _ackBatchChunkThreshold) {
      return _flushDataAck(context);
    }
    _scheduleDataAckRetry(context);
    return Future.value();
  }

  Future<void> _flushDataAck(_IncomingTransferContext context) {
    final address = context.pendingAckAddress;
    final port = context.pendingAckPort;
    if (address == null || port == null || context.pendingAckChunks.isEmpty) {
      return Future.value();
    }
    context.ackFlushTimer?.cancel();
    context.ackFlushTimer = null;
    final chunkIndexes = context.pendingAckChunks.toList(growable: false)
      ..sort();
    context.pendingAckChunks.clear();
    return _sendDataAck(
      context,
      chunkIndexes: chunkIndexes,
      address: address,
      port: port,
    ).catchError((Object error, StackTrace stackTrace) {
      context.pendingAckChunks.addAll(chunkIndexes);
      context.pendingAckAddress = address;
      context.pendingAckPort = port;
      _scheduleDataAckRetry(context);
    });
  }

  void _scheduleDataAckRetry(_IncomingTransferContext context) {
    if (!TransferIncomingAckRetryScheduleCommand.shouldScheduleDataAckRetry(
      hasAckFlushTimer: context.ackFlushTimer != null,
    )) {
      return;
    }
    context.ackFlushTimer ??= Timer(_ackBatchInterval, () {
      context.ackFlushTimer = null;
      unawaited(_flushDataAck(context));
    });
  }

  Future<void> _sendDataAck(
    _IncomingTransferContext context, {
    required List<int> chunkIndexes,
    required InternetAddress address,
    required int port,
  }) {
    final ackBitmap = TransferOutgoingAckBitmapCommand.build(
      chunkIndexes: chunkIndexes,
    );
    if (ackBitmap.primaryChunkIndex == null || ackBitmap.ackBase == null) {
      return Future.value();
    }
    return _sendDataFrame(
      _incomingDataFrame(
        context,
        type: DataFrameType.dataAck,
        sequence: context.nextSequence(),
        chunkIndex: ackBitmap.primaryChunkIndex!,
        windowStart: context.nextExpectedChunk,
        windowSize: TransferIncomingWindowCommand.receiverWindowSize(
          advertisedWindowSize: _receiverAdvertisedWindow,
          bufferedChunkCount: context.bufferedChunks.length,
        ),
        ackBase: ackBitmap.ackBase!,
        ackBitmapWords: ackBitmap.ackBitmapWords,
      ),
      address: address,
      port: port,
    );
  }

  Future<void> _sendDataNack(
    _IncomingTransferContext context, {
    required List<int> chunkIndexes,
    required InternetAddress address,
    required int port,
  }) {
    final ackBitmap = TransferOutgoingAckBitmapCommand.build(
      chunkIndexes: chunkIndexes,
    );
    if (ackBitmap.primaryChunkIndex == null || ackBitmap.ackBase == null) {
      return Future.value();
    }
    return _sendDataFrame(
      _incomingDataFrame(
        context,
        type: DataFrameType.dataNack,
        sequence: context.nextSequence(),
        chunkIndex: ackBitmap.primaryChunkIndex!,
        ackBase: ackBitmap.ackBase!,
        ackBitmapWords: ackBitmap.ackBitmapWords,
        windowStart: context.nextExpectedChunk,
        windowSize: TransferIncomingWindowCommand.receiverWindowSize(
          advertisedWindowSize: _receiverAdvertisedWindow,
          bufferedChunkCount: context.bufferedChunks.length,
        ),
      ),
      address: address,
      port: port,
    );
  }

  Future<void> _sendDataNackSafely(
    _IncomingTransferContext context, {
    required List<int> chunkIndexes,
    required InternetAddress address,
    required int port,
  }) async {
    try {
      await _sendDataNack(
        context,
        chunkIndexes: chunkIndexes,
        address: address,
        port: port,
      );
    } catch (_) {
      return;
    }
  }

  Future<void> _sendChunkAck({
    required String sessionId,
    required String transferId,
    required InternetAddress address,
    required int port,
    required int chunkIndex,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    return _send(
      AuthPacket(
        type: AuthPacketType.transferChunkAck,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: sessionId,
        fromUserId: _currentUserId(),
        fromDeviceId: _currentDeviceId(),
        fromInstanceId: _currentInstanceId(),
        fromDisplayName: _currentDisplayName(),
        transferId: transferId,
        transferChunkIndex: chunkIndex,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: localEndpoint,
    );
  }

  Future<void> _sendChunkNack({
    required String sessionId,
    required String transferId,
    required InternetAddress address,
    required int port,
    required List<int> chunkIndexes,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    final compactIndexes = chunkIndexes.toSet().toList(growable: false)..sort();
    if (compactIndexes.isEmpty) {
      return Future.value();
    }
    return _send(
      AuthPacket(
        type: AuthPacketType.transferChunkNack,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: sessionId,
        fromUserId: _currentUserId(),
        fromDeviceId: _currentDeviceId(),
        fromInstanceId: _currentInstanceId(),
        fromDisplayName: _currentDisplayName(),
        transferId: transferId,
        transferChunkIndex: compactIndexes.first,
        transferChunkIndexes: compactIndexes,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: localEndpoint,
    );
  }

  Future<void> _sendWindowUpdate({
    required String sessionId,
    required String transferId,
    required InternetAddress address,
    required int port,
    required int windowStart,
    required int windowSize,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    return _send(
      AuthPacket(
        type: AuthPacketType.transferWindowUpdate,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: sessionId,
        fromUserId: _currentUserId(),
        fromDeviceId: _currentDeviceId(),
        fromInstanceId: _currentInstanceId(),
        fromDisplayName: _currentDisplayName(),
        transferId: transferId,
        transferWindowStart: windowStart,
        transferWindowSize: windowSize,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: localEndpoint,
    );
  }

  Future<void> _sendTransferCompleteAck({
    required String sessionId,
    required String transferId,
    required InternetAddress address,
    required int port,
    required bool accepted,
    String? message,
    String? savePath,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    return _send(
      AuthPacket(
        type: AuthPacketType.transferCompleteAck,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: sessionId,
        fromUserId: _currentUserId(),
        fromDeviceId: _currentDeviceId(),
        fromInstanceId: _currentInstanceId(),
        fromDisplayName: _currentDisplayName(),
        transferId: transferId,
        transferAccepted: accepted,
        rejectMessage: message,
        transferSavePath: savePath,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: localEndpoint,
    );
  }

  Future<void> _flushBufferedChunks(_IncomingTransferContext context) async {
    while (true) {
      final bytes = context.bufferedChunks.remove(context.nextExpectedChunk);
      if (bytes == null) {
        if (context.bufferedChunks.isEmpty) {
          context.cancelMissingNackRetry();
        }
        return;
      }
      await _appendIncomingChunk(context, bytes);
      context.nextExpectedChunk += 1;
    }
  }

  Future<void> _appendIncomingChunk(
    _IncomingTransferContext context,
    List<int> bytes,
  ) async {
    await context.writer.append(bytes);
    context.writtenBytes += bytes.length;
  }

  Future<void> _sendIncomingFailureAck(
    _IncomingTransferContext context,
    String transferId,
    String message,
  ) async {
    try {
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: context.controlAddress,
        port: context.controlPort,
        accepted: false,
        message: message,
        localEndpoint: context.controlLocalEndpoint,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Failed to notify sender about incoming transfer failure '
            'transfer=${_safeTransfer(transferId)}',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  String _incomingChunkWriteFailureMessage(Object error) {
    return TransferIncomingChunkWriteFailureMapper.messageFor(error);
  }

  Future<void> _sendWindowUpdateIfNeeded(
    _IncomingTransferContext context, {
    required String sessionId,
    required String transferId,
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
    bool force = false,
  }) {
    final nextStart = context.nextExpectedChunk;
    final movedBy = nextStart - context.lastAdvertisedWindowStart;
    final receiverWindowSize = TransferIncomingWindowCommand.receiverWindowSize(
      advertisedWindowSize: _receiverAdvertisedWindow,
      bufferedChunkCount: context.bufferedChunks.length,
    );
    if (!force &&
        movedBy < _windowUpdateChunkInterval &&
        receiverWindowSize > 1) {
      return Future.value();
    }
    context.lastAdvertisedWindowStart = nextStart;
    return _sendWindowUpdate(
      sessionId: sessionId,
      transferId: transferId,
      address: address,
      port: port,
      windowStart: nextStart,
      windowSize: receiverWindowSize,
      localEndpoint: localEndpoint,
    );
  }

  Future<void> _failIncomingTransfer(String transferId, String message) async {
    final context = _removeIncomingTransfer(transferId);
    if (context != null) {
      try {
        await context.closeWriter();
      } catch (error, stackTrace) {
        ref
            .read(appLoggerProvider)
            .warning(
              AppLogCategory.transferData,
              'Ignored incoming writer cleanup failure '
              'transfer=${_safeTransfer(transferId)}',
              error: error,
              stackTrace: stackTrace,
            );
      }
      try {
        await ref
            .read(transferFileServiceProvider)
            .discardDraft(context.tempFilePath);
      } catch (error, stackTrace) {
        ref
            .read(appLoggerProvider)
            .warning(
              AppLogCategory.storage,
              'Ignored incoming draft cleanup failure '
              'transfer=${_safeTransfer(transferId)}',
              error: error,
              stackTrace: stackTrace,
            );
      }
    }
    _markFailed(transferId, message);
  }

  Future<void> _failOutgoingTransfer(String transferId, String message) async {
    final context = _removeOutgoingTransfer(transferId);
    if (context == null || context.hasFailed) {
      return;
    }
    context.hasFailed = true;
    await context.dispose();
    if (!context.allChunksAcked.isCompleted) {
      unawaited(context.allChunksAcked.future.catchError((Object _) {}));
      context.allChunksAcked.completeError(
        AppException(code: 'transfer_failed', message: message),
      );
    }
    if (!context.completeAck.isCompleted) {
      context.completeAck.complete(
        _TransferCompleteAckResult(accepted: false, message: message),
      );
    }
    _markFailed(transferId, message);
  }

  Future<AppSettings> _loadIncomingSettingsForTransfer(
    String transferId,
  ) async {
    final repository = ref.read(settingsRepositoryProvider);
    try {
      final savedSettings = await repository.load();
      final preparedSavedSettings =
          await _prepareIncomingSettingsDirectoryOrNull(
            savedSettings,
            transferId: transferId,
            source: 'saved',
          );
      if (preparedSavedSettings != null) {
        return preparedSavedSettings;
      }
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Failed to load saved receive settings for '
            '${_safeTransfer(transferId)}. Falling back to default path.',
            error: error,
            stackTrace: stackTrace,
          );
    }

    final defaultSavePath = await _loadDefaultReceivePathForTransfer(
      transferId,
    );
    try {
      final settings = await repository.loadOrCreate(
        defaultSavePath: defaultSavePath,
      );
      final preparedSettings = await _prepareIncomingSettingsDirectoryOrNull(
        settings,
        transferId: transferId,
        source: 'default',
        fallbackSavePath: defaultSavePath,
      );
      if (preparedSettings != null) {
        return preparedSettings;
      }
      throw const AppException(
        code: 'transfer_receive_path_unavailable',
        message: '수신 저장 경로를 사용할 수 없습니다.',
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Failed to load receive settings for ${_safeTransfer(transferId)}. '
            'Falling back to default receive path.',
            error: error,
            stackTrace: stackTrace,
          );
      return _prepareIncomingSettingsDirectory(
        AppSettings.initial(),
        transferId: transferId,
        fallbackSavePath: defaultSavePath,
      );
    }
  }

  Future<String?> _loadTcpIncomingSubscriptionDirectory() async {
    const transferId = 'tcp-listener';
    final repository = ref.read(settingsRepositoryProvider);
    try {
      final savedSettings = await repository.load();
      final preparedSavedSettings =
          await _prepareIncomingSettingsDirectoryOrNull(
            savedSettings,
            transferId: transferId,
            source: 'tcp-listener-saved',
          );
      if (preparedSavedSettings != null) {
        return preparedSavedSettings.defaultSavePath;
      }
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Failed to load saved TCP incoming receive path.',
            error: error,
            stackTrace: stackTrace,
          );
    }

    try {
      final defaultSavePath = await _loadDefaultReceivePathForTransfer(
        transferId,
      );
      final preparedDefault = await _prepareIncomingSettingsDirectory(
        AppSettings.initial(),
        transferId: transferId,
        fallbackSavePath: defaultSavePath,
      );
      return preparedDefault.defaultSavePath;
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'TCP incoming listener subscription skipped because receive path '
            'is unavailable.',
            error: error,
            stackTrace: stackTrace,
          );
      return null;
    }
  }

  Future<String> _loadDefaultReceivePathForTransfer(String transferId) async {
    try {
      final defaultSavePath = await ref
          .read(appStoragePathProvider)
          .getDefaultReceivePath();
      if (defaultSavePath.trim().isNotEmpty) {
        return defaultSavePath;
      }
      throw const AppException(
        code: 'transfer_default_receive_path_empty',
        message: '기본 수신 경로가 비어 있습니다.',
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Failed to prepare default receive path for '
            '${_safeTransfer(transferId)}',
            error: error,
            stackTrace: stackTrace,
          );
      throw const AppException(
        code: 'transfer_default_receive_path_failed',
        message: '기본 수신 경로를 준비하지 못했습니다. 저장 경로 권한을 확인해 주세요.',
      );
    }
  }

  Future<AppSettings?> _prepareIncomingSettingsDirectoryOrNull(
    AppSettings? settings, {
    required String transferId,
    required String source,
    String? fallbackSavePath,
  }) async {
    if (settings == null) {
      return null;
    }
    try {
      return await _prepareIncomingSettingsDirectory(
        settings,
        transferId: transferId,
        fallbackSavePath: fallbackSavePath,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Rejected $source receive path for ${_safeTransfer(transferId)}',
            error: error,
            stackTrace: stackTrace,
          );
      return null;
    }
  }

  Future<AppSettings> _prepareIncomingSettingsDirectory(
    AppSettings settings, {
    required String transferId,
    String? fallbackSavePath,
  }) async {
    final configuredPath = settings.defaultSavePath.trim();
    if (AppPlatformDirectories.looksLikeLegacySandboxReceivePath(
      configuredPath,
    )) {
      throw AppException(
        code: 'transfer_receive_path_legacy_sandbox',
        message:
            'legacy sandbox 수신 경로는 사용하지 않습니다: ${_safeTransfer(transferId)}',
      );
    }
    final savePath = configuredPath.isEmpty
        ? fallbackSavePath?.trim()
        : configuredPath;
    if (savePath == null || savePath.isEmpty) {
      throw AppException(
        code: 'transfer_receive_path_empty',
        message: '수신 저장 경로가 비어 있습니다: ${_safeTransfer(transferId)}',
      );
    }
    final directory = Directory(savePath);
    final existingType = await FileSystemEntity.type(savePath);
    if (existingType == FileSystemEntityType.file) {
      throw AppException(
        code: 'transfer_receive_path_is_file',
        message: '수신 저장 경로가 폴더가 아닙니다: ${_safeTransfer(transferId)}',
      );
    }
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return settings.copyWith(
      defaultSavePath: directory.absolute.path,
      autoReceiveEnabled: true,
      receivePolicy: ReceivePolicy.autoReceiveAll,
    );
  }

  Future<IncomingDigestingTransferWriter> _openIncomingWriterForTransfer(
    String tempFilePath, {
    required String transferId,
  }) async {
    try {
      return await ref
          .read(transferFileServiceProvider)
          .openIncomingDigestingWriter(tempFilePath);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Failed to open incoming temp writer for '
            '${_safeTransfer(transferId)}',
            error: error,
            stackTrace: stackTrace,
          );
      throw const AppException(
        code: 'incoming_writer_open_failed',
        message: '수신 임시 파일 writer를 열지 못했습니다. 임시 저장소 권한을 확인해 주세요.',
      );
    }
  }

  Future<DataBindResult> _bindDataTransportForIncoming(
    UdpInterfaceEndpoint? localEndpoint, {
    required String transferId,
  }) async {
    try {
      return await _bindDataTransport(localEndpoint);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Failed to bind incoming data endpoint for '
            '${_safeTransfer(transferId)} local=${_endpointLabel(localEndpoint)}',
            error: error,
            stackTrace: stackTrace,
          );
      throw const AppException(
        code: 'incoming_data_bind_failed',
        message:
            '수신 Data UDP 포트를 준비하지 못했습니다. 방화벽 또는 UDP 포트 38410-38430 사용 상태를 확인해 주세요.',
      );
    }
  }

  Future<void> _cleanupRejectedIncomingDraft(
    IncomingTransferDraft? draft,
    IncomingDigestingTransferWriter? writer,
  ) async {
    try {
      await writer?.close();
    } catch (_) {
      // Cleanup is best-effort after rejecting an incoming transfer.
    }
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(transferFileServiceProvider)
          .discardDraft(draft.tempFilePath);
    } catch (_) {
      // Cleanup is best-effort after rejecting an incoming transfer.
    }
  }

  PeerAuthSession? _authenticatedSessionForTransferInit(
    AuthPacket packet,
    ControlDatagram datagram, {
    required String packetPeerId,
  }) {
    return _authenticatedSessionForControlPacket(
      packet,
      datagram,
      packetPeerId: packetPeerId,
      packetLabel: 'TRANSFER_INIT',
    );
  }

  PeerAuthSession? _authenticatedSessionForControlPacket(
    AuthPacket packet,
    ControlDatagram datagram, {
    required String packetPeerId,
    required String packetLabel,
  }) {
    final exact = ref.read(peerAuthSessionByPeerIdProvider(packetPeerId));
    if (exact?.isAuthenticated == true) {
      return exact;
    }

    final sourceAddress = datagram.address.address;
    for (final session
        in ref.read(peerAuthControllerProvider).sessions.values) {
      if (!session.isAuthenticated) {
        continue;
      }
      if (session.sessionId != packet.sessionId) {
        continue;
      }
      if (session.peerUserId != packet.fromUserId) {
        continue;
      }
      if (session.peerAddress != sourceAddress) {
        continue;
      }
      return session;
    }

    ref
        .read(appLoggerProvider)
        .warning(
          AppLogCategory.transferControl,
          'Rejected $packetLabel because authenticated session was not found '
          'packetPeer=$packetPeerId session=${_safeSession(packet.sessionId)} '
          'source=${datagram.address.address}:${datagram.port}',
        );
    return null;
  }

  PeerAuthSession _requireAuthenticatedSession(String peerId) {
    final session = ref.read(peerAuthSessionByPeerIdProvider(peerId));
    if (session == null || !session.isAuthenticated) {
      throw const AppException(
        code: 'transfer_peer_not_authenticated',
        message: '인증이 완료된 피어를 먼저 선택해 주세요.',
      );
    }
    return session;
  }

  int _protocolMajor(String version) {
    final dotIndex = version.indexOf('.');
    final raw = dotIndex < 0 ? version : version.substring(0, dotIndex);
    return int.tryParse(raw) ?? 1;
  }

  int _chunkByteLength(PreparedTransferMetadata file, int chunkIndex) {
    return TransferOutgoingChunkByteLengthCommand.calculate(
      fileSize: file.fileSize,
      chunkSize: file.chunkSize,
      chunkIndex: chunkIndex,
    );
  }

  void _updateOutgoingMetrics(
    String transferId,
    _OutgoingTransferContext context, {
    required String message,
  }) {
    final throughput = _throughputBytesPerSec(
      transferredBytes: context.acknowledgedBytes,
      startedAt: context.startedAt,
    );
    final lossRate = _lossRateFor(context);
    _updateJob(
      transferId,
      (job) => TransferJobMetricsCommand.outgoing(
        job,
        bytesTransferred: context.acknowledgedBytes,
        completedChunks: context.acknowledgedChunks.length,
        retryCount: context.retryCount,
        duplicateCount: context.duplicateAckCount,
        lossRate: lossRate,
        throughputBytesPerSec: throughput,
        rttMs: context.rttEstimator.smoothedRttMs,
        windowSize: context.windowSize,
        updatedAt: _now(),
        message: message,
      ),
    );
  }

  void _updateIncomingMetrics(
    String transferId,
    _IncomingTransferContext context, {
    required String message,
  }) {
    final throughput = _throughputBytesPerSec(
      transferredBytes: context.writtenBytes,
      startedAt: context.startedAt,
    );
    final windowSize = TransferIncomingWindowCommand.receiverWindowSize(
      advertisedWindowSize: _receiverAdvertisedWindow,
      bufferedChunkCount: context.bufferedChunks.length,
    );
    _updateJob(
      transferId,
      (job) => TransferJobMetricsCommand.incoming(
        job,
        bytesTransferred: context.writtenBytes,
        completedChunks: context.nextExpectedChunk,
        duplicateCount: context.duplicateChunks,
        throughputBytesPerSec: throughput,
        windowSize: windowSize,
        updatedAt: _now(),
        message: message,
      ),
    );
  }

  void _scheduleMissingDataNackRetry(
    String transferId,
    _IncomingTransferContext context,
  ) {
    if (!TransferIncomingAckRetryScheduleCommand.shouldScheduleMissingNackRetry(
      bufferedChunkCount: context.bufferedChunks.length,
      hasMissingNackRetryTimer: context.missingNackRetryTimer != null,
    )) {
      return;
    }
    context.missingNackRetryTimer = Timer(_outOfOrderNackRepeatInterval, () {
      context.missingNackRetryTimer = null;
      unawaited(_repeatMissingDataNack(transferId, context));
    });
  }

  Future<void> _repeatMissingDataNack(
    String transferId,
    _IncomingTransferContext context,
  ) async {
    if (_lookupIncomingTransfer(transferId) != context ||
        context.bufferedChunks.isEmpty) {
      return;
    }
    final address = context.lastDataAddress;
    final port = context.lastDataPort;
    if (address == null || port == null) {
      return;
    }
    final missingIndexes = TransferIncomingMissingChunksCommand.remaining(
      nextExpectedChunk: context.nextExpectedChunk,
      expectedChunkCount: context.expectedChunkCount,
      acknowledgedChunks: context.acknowledgedChunks,
      limit: _maxNackIndexesPerPacket,
    );
    if (missingIndexes.isNotEmpty) {
      await _sendDataNackSafely(
        context,
        chunkIndexes: missingIndexes,
        address: address,
        port: port,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message:
            'missing data chunk ${missingIndexes.first} 재전송 요청 중 '
            '(buffered=${context.bufferedChunks.length})',
      );
    }
    _scheduleMissingDataNackRetry(transferId, context);
  }

  double _lossRateFor(_OutgoingTransferContext context) {
    return TransferMetricCalculationCommand.lossRate(
      acknowledgedChunkCount: context.acknowledgedChunks.length,
      retryCount: context.retryCount,
    );
  }

  double _throughputBytesPerSec({
    required int transferredBytes,
    required DateTime startedAt,
  }) {
    return TransferMetricCalculationCommand.throughputBytesPerSec(
      transferredBytes: transferredBytes,
      startedAt: startedAt,
      now: _now(),
    );
  }

  void _upsertJob(TransferJob nextJob) {
    final jobs = TransferJobListUpsertCommand.upsert(
      currentJobs: state.jobs,
      nextJob: nextJob,
    );
    state = state.copyWith(jobs: jobs, clearError: true);
    ref
        .read(messageBusProvider)
        .publish(
          TransferJobEventFactory.sessionEvent(
            nextJob,
            eventId: _eventId('transfer-${nextJob.status.name}'),
            occurredAt: _now(),
            source: 'TransferController',
          ),
        );
    if (nextJob.isTerminal) {
      unawaited(_persistTerminalJob(nextJob));
    }
  }

  Future<void> _persistTerminalJob(TransferJob job) async {
    try {
      await ref.read(transferHistoryRepositoryProvider).saveTerminalJob(job);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.storage,
            'Failed to persist transfer history '
            'transfer=${_safeTransfer(job.transferId)} status=${job.status.name}',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  void _updateJob(
    String transferId,
    TransferJob Function(TransferJob currentJob) update,
  ) {
    final nextJob = TransferJobUpdateLookupCommand.updateById(
      jobs: state.jobs,
      jobId: transferId,
      update: update,
    );
    if (nextJob == null) {
      return;
    }
    _upsertJob(nextJob);
  }

  void _removeJob(String transferId) {
    final jobs = [
      for (final job in state.jobs)
        if (job.id != transferId) job,
    ];
    if (jobs.length == state.jobs.length) {
      return;
    }
    state = state.copyWith(jobs: jobs);
  }

  bool _tcpSendFailureCanNegotiateOutboundChannel(String? issueCode) {
    return issueCode == 'missing_tcp_outgoing_data_channel' ||
        issueCode == 'tcp_outgoing_data_channel_not_connected';
  }

  bool _tcpSendFailureInvalidatesOutboundChannel(String? issueCode) {
    return issueCode == 'tcp_outgoing_data_channel_not_connected' ||
        issueCode == 'tcp_outgoing_stream_send_failed';
  }

  void _removeOutboundTcpDataSession(PeerAuthSession session) {
    ref
        .read(tcpDataChannelSessionRegistryProvider)
        .remove(
          DataChannelSessionKey(
            peerId: session.peerId,
            authSessionId: session.sessionId,
            direction: TcpDataChannelDirection.outbound,
          ),
          allowReregister: true,
        );
  }

  void _markRejected(String transferId, String message) {
    _updateJob(
      transferId,
      (job) => TransferJobTerminalStatusCommand.rejected(
        job,
        updatedAt: _now(),
        message: message,
      ),
    );
    state = state.copyWith(errorMessage: message);
  }

  void _markFailed(String transferId, String message) {
    _updateJob(
      transferId,
      (job) => TransferJobTerminalStatusCommand.failed(
        job,
        updatedAt: _now(),
        message: message,
      ),
    );
    state = state.copyWith(errorMessage: message);
  }

  Future<void> _send(
    AuthPacket packet, {
    required InternetAddress address,
    required int port,
    UdpInterfaceEndpoint? localEndpoint,
  }) {
    return ref
        .read(controlTransportProvider)
        .send(
          packet,
          address: address,
          port: port,
          localEndpoint: localEndpoint,
        );
  }

  Future<DataBindResult> _bindDataTransport(
    UdpInterfaceEndpoint? controlEndpoint,
  ) {
    final localEndpoint = UdpInterfaceEndpoint(
      role: UdpPortRole.data,
      interfaceId: controlEndpoint?.interfaceId,
      localAddress:
          controlEndpoint?.localAddress ?? InternetAddress.anyIPv4.address,
      port: ref.read(appConfigProvider).dataPort,
      bindMode: controlEndpoint?.bindMode ?? UdpInterfaceBindMode.any,
      reuseAddress: false,
      reusePort: false,
    );
    return ref
        .read(dataTransportProvider)
        .bind(
          localEndpoint: localEndpoint,
          portRange: ref.read(appConfigProvider).dataPortRange,
        );
  }

  Future<void> _sendDataFrame(
    DataFrame frame, {
    required InternetAddress address,
    required int port,
  }) async {
    final result = await ref
        .read(dataTransportProvider)
        .sendFrame(frame, address: address, port: port);
    final transferId = _transferIdForFrame(
      frame,
      direction: _sentFrameOwnerDirection(frame.type),
    );
    if (transferId != null) {
      _recordFrameTrace(
        transferId: transferId,
        frame: frame,
        direction: 'out',
        endpoint: '${address.address}:$port',
        datagramBytes: result.bytesRequested,
        decisionCode: result.success ? 'sent' : result.reasonCode ?? 'failed',
      );
    }
    if (!result.success) {
      throw AppException(
        code: result.reasonCode ?? 'data_frame_send_failed',
        message: 'Data frame 전송에 실패했습니다.',
      );
    }
  }

  void _recordFrameTrace({
    required String transferId,
    required DataFrame frame,
    required String direction,
    required String endpoint,
    required int datagramBytes,
    required String decisionCode,
  }) {
    final buffer = _diagnosticFrameTraces.putIfAbsent(
      transferId,
      () => TransferDiagnosticsRingBuffer(
        capacity: _diagnosticFrameTraceCapacity,
      ),
    );
    buffer.add(
      TransferFrameTraceMapper.fromFrame(
        frame,
        occurredAt: _now(),
        direction: direction,
        datagramBytes: datagramBytes,
        endpoint: endpoint,
        decisionCode: decisionCode,
      ),
    );
  }

  DataFrame _dataFrame(
    _OutgoingTransferContext context, {
    required DataFrameType type,
    required int sequence,
    int chunkIndex = 0,
    int? windowStart,
    int? windowSize,
    int ackBase = 0,
    List<int> ackBitmapWords = const [],
    Uint8List? payload,
  }) {
    return TransferDataFrameFactory.outgoing(
      sessionHash: context.authContext.sessionHash,
      transferIdBytes: context.transferIdBytes,
      type: type,
      sequence: sequence,
      chunkIndex: chunkIndex,
      remoteWindowStart: context.remoteWindowStart,
      windowStart: windowStart,
      windowSize: windowSize ?? context.windowSize,
      ackBase: ackBase,
      ackBitmapWords: ackBitmapWords,
      payload: payload,
    );
  }

  DataFrame _incomingDataFrame(
    _IncomingTransferContext context, {
    required DataFrameType type,
    required int sequence,
    int chunkIndex = 0,
    int? windowStart,
    int? windowSize,
    int ackBase = 0,
    List<int> ackBitmapWords = const [],
    Uint8List? payload,
  }) {
    return TransferDataFrameFactory.incoming(
      sessionHash: context.sessionHash,
      transferIdBytes: context.transferIdBytes,
      type: type,
      sequence: sequence,
      chunkIndex: chunkIndex,
      nextExpectedChunk: context.nextExpectedChunk,
      receiverWindowSize: TransferIncomingWindowCommand.receiverWindowSize(
        advertisedWindowSize: _receiverAdvertisedWindow,
        bufferedChunkCount: context.bufferedChunks.length,
      ),
      windowStart: windowStart,
      windowSize: windowSize,
      ackBase: ackBase,
      ackBitmapWords: ackBitmapWords,
      payload: payload,
    );
  }

  String _frameKey(Uint8List transferIdBytes) =>
      TransferDataFrameKeyFormatter.format(transferIdBytes);

  void _registerFrameKey({
    required TransferDirection direction,
    required String transferId,
    required Uint8List transferIdBytes,
  }) {
    _frameKeyRegistry.register(
      direction: direction,
      frameKey: _frameKey(transferIdBytes),
      transferId: transferId,
    );
  }

  void _removeFrameKey({
    required TransferDirection direction,
    required String transferId,
    required Uint8List transferIdBytes,
  }) {
    _frameKeyRegistry.remove(
      direction: direction,
      frameKey: _frameKey(transferIdBytes),
      transferId: transferId,
    );
  }

  String? _transferIdForFrame(
    DataFrame frame, {
    required TransferDirection direction,
  }) {
    return _frameKeyRegistry.lookup(
      direction: direction,
      frameKey: _frameKey(frame.transferIdBytes),
    );
  }

  TransferDirection _sentFrameOwnerDirection(DataFrameType type) {
    final remoteExpectedDirection = _dataFrameDispatcher
        .routeFor(type)
        .expectedDirection;
    switch (remoteExpectedDirection) {
      case TransferDirection.incoming:
        return TransferDirection.outgoing;
      case TransferDirection.outgoing:
        return TransferDirection.incoming;
    }
  }

  PeerConnectionPath _requireActiveTransferRoute({
    required String peerId,
    required PeerAuthSession session,
    ControlDatagram? observedDatagram,
  }) {
    final currentPath = ref
        .read(peerPathRegistryProvider)
        .selectedForPeer(peerId);
    final path = currentPath?.status == PeerPathStatus.active
        ? currentPath
        : observedDatagram == null
        ? null
        : _recoverIncomingTransferRoute(
            peerId: peerId,
            datagram: observedDatagram,
            currentPath: currentPath,
          );
    if (path == null || path.status != PeerPathStatus.active) {
      throw const AppException(
        code: 'transfer_active_route_missing',
        message: '검증된 연결 경로가 없어 파일을 전송할 수 없습니다.',
      );
    }
    final routeDecision = TransferActiveRouteValidationCommand.validate(
      controlLocalAddress: path.controlEndpoint.localAddress,
      routeRemoteAddress: path.candidate.remoteAddress,
      routeRemotePort: path.candidate.remotePort,
      sessionPeerAddress: session.peerAddress,
    );
    if (!routeDecision.isValid) {
      throw AppException(
        code: routeDecision.code!,
        message: routeDecision.message!,
      );
    }
    return path;
  }

  PeerConnectionPath? _recoverIncomingTransferRoute({
    required String peerId,
    required ControlDatagram datagram,
    PeerConnectionPath? currentPath,
  }) {
    final observedPath = _observedIncomingTransferPath(
      peerId: peerId,
      datagram: datagram,
      currentPath: currentPath,
    );
    if (observedPath == null) {
      return null;
    }

    final mutations = ref.read(peerPathRegistryMutationsProvider);
    mutations.selectForTransferRecovery(observedPath);
    mutations.applyEvent(peerId: peerId, event: PeerPathEvent.authStarted);
    mutations.applyEvent(peerId: peerId, event: PeerPathEvent.authSucceeded);
    final activePath = ref
        .read(peerPathRegistryProvider)
        .selectedForPeer(peerId);
    if (activePath?.status != PeerPathStatus.active) {
      return null;
    }
    ref
        .read(appLoggerProvider)
        .info(
          AppLogCategory.transferControl,
          'Recovered incoming transfer route for peer=$peerId '
          'route=${activePath!.pathId} '
          'source=${datagram.address.address}:${datagram.port} '
          'local=${_endpointLabel(datagram.localEndpoint)}',
        );
    return activePath;
  }

  PeerConnectionPath? _observedIncomingTransferPath({
    required String peerId,
    required ControlDatagram datagram,
    PeerConnectionPath? currentPath,
  }) {
    final exactCandidates = <PeerRouteCandidate>[
      if (currentPath != null &&
          _matchesIncomingTransferRoute(currentPath.candidate, datagram))
        currentPath.candidate,
      ...ref
          .read(peerRouteCandidateStoreProvider)
          .where(
            (candidate) =>
                candidate.peerId == peerId &&
                _matchesIncomingTransferRoute(candidate, datagram),
          ),
    ];
    final observedCandidate = exactCandidates.isNotEmpty
        ? _upsertReachableIncomingTransferCandidate(exactCandidates.first)
        : _observedIncomingTransferCandidateFromAddressMatch(
                peerId: peerId,
                datagram: datagram,
                currentPath: currentPath,
              ) ??
              _upsertObservedIncomingTransferCandidate(
                peerId: peerId,
                datagram: datagram,
                currentPath: currentPath,
              );
    return PeerPathSelectionPolicy()
        .select(candidates: [observedCandidate], selectedAt: _now())
        ?.path;
  }

  bool _matchesIncomingTransferRoute(
    PeerRouteCandidate candidate,
    ControlDatagram datagram,
  ) {
    final localEndpoint = datagram.localEndpoint;
    return TransferIncomingRouteMatchCommand.matches(
      candidateRemoteAddress: candidate.remoteAddress,
      candidateRemotePort: candidate.remotePort,
      datagramRemoteAddress: datagram.address.address,
      datagramRemotePort: datagram.port,
      candidateLocalAddress: candidate.localAddress,
      datagramLocalAddress: localEndpoint?.localAddress,
      datagramIsWildcardBind: localEndpoint?.isWildcardBind ?? false,
      candidateIsAnyBind: candidate.bindMode == UdpInterfaceBindMode.any,
    );
  }

  PeerRouteCandidate _upsertReachableIncomingTransferCandidate(
    PeerRouteCandidate candidate,
  ) {
    return ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .upsertCandidate(
          candidate.copyWith(
            lastSeenAt: _now(),
            failureCount: 0,
            status: RouteCandidateStatus.reachable,
          ),
        );
  }

  PeerRouteCandidate? _observedIncomingTransferCandidateFromAddressMatch({
    required String peerId,
    required ControlDatagram datagram,
    PeerConnectionPath? currentPath,
  }) {
    final addressMatches = <PeerRouteCandidate>[
      if (currentPath != null &&
          currentPath.candidate.remoteAddress == datagram.address.address)
        currentPath.candidate,
      ...ref
          .read(peerRouteCandidateStoreProvider)
          .where(
            (candidate) =>
                candidate.peerId == peerId &&
                candidate.remoteAddress == datagram.address.address,
          ),
    ];
    if (addressMatches.isEmpty) {
      return null;
    }
    final localEndpoint = datagram.localEndpoint;
    final localMatched = localEndpoint == null || localEndpoint.isWildcardBind
        ? addressMatches
        : addressMatches
              .where(
                (candidate) =>
                    candidate.localAddress == localEndpoint.localAddress ||
                    candidate.bindMode == UdpInterfaceBindMode.any,
              )
              .toList(growable: false);
    final selectable = localMatched.isNotEmpty ? localMatched : addressMatches;
    final base = PeerPathSelectionPolicy()
        .select(candidates: selectable, selectedAt: _now())
        ?.path
        .candidate;
    if (base == null) {
      return null;
    }
    final candidate = PeerRouteCandidate.create(
      peerId: base.peerId,
      remoteAddress: base.remoteAddress,
      remotePort: datagram.port,
      localInterfaceId: base.localInterfaceId,
      localAddress: base.localAddress,
      discoveredBy: RouteCandidateDiscoverySource.unicastProbe,
      seenAt: _now(),
      status: RouteCandidateStatus.reachable,
      rttMs: base.rttMs,
      failureCount: 0,
      score: base.score,
      localInterfaceTypeHint: base.localInterfaceTypeHint,
      bindMode: base.bindMode,
      compatible: base.compatible,
      receiveAvailable: base.receiveAvailable,
    );
    return ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .upsertCandidate(candidate);
  }

  PeerRouteCandidate _upsertObservedIncomingTransferCandidate({
    required String peerId,
    required ControlDatagram datagram,
    PeerConnectionPath? currentPath,
  }) {
    final endpoint = datagram.localEndpoint;
    final localAddress =
        endpoint?.localAddress ??
        currentPath?.controlEndpoint.localAddress ??
        InternetAddress.anyIPv4.address;
    final interfaceId =
        endpoint?.interfaceId ??
        currentPath?.controlEndpoint.interfaceId ??
        const NetworkInterfaceId(
          name: 'observed-transfer-control',
          index: -3,
          stableId: 'observed-transfer-control',
        );
    final bindMode =
        endpoint?.bindMode ??
        currentPath?.controlEndpoint.bindMode ??
        UdpInterfaceBindMode.any;
    final candidate = PeerRouteCandidate.create(
      peerId: peerId,
      remoteAddress: datagram.address.address,
      remotePort: datagram.port,
      localInterfaceId: interfaceId,
      localAddress: localAddress,
      discoveredBy: RouteCandidateDiscoverySource.unicastProbe,
      seenAt: _now(),
      status: RouteCandidateStatus.reachable,
      localInterfaceTypeHint: localAddress.startsWith('127.')
          ? InterfaceTypeHint.loopback
          : InterfaceTypeHint.unknown,
      bindMode: bindMode,
    );
    return ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .upsertCandidate(candidate);
  }

  TransferRouteSnapshot _snapshotFromActiveRoute(PeerConnectionPath path) {
    return TransferRouteSnapshot(
      routeLeaseId: path.pathId,
      peerId: path.peerId,
      controlLocalAddress: path.controlEndpoint.localAddress,
      controlRemoteAddress: path.candidate.remoteAddress,
      controlRemotePort: path.candidate.remotePort,
      localInterfaceId: path.candidate.localInterfaceId.stableId,
      dataLocalAddress: path.dataEndpoint?.localAddress,
      dataRemoteAddress: path.candidate.remoteAddress,
      dataRemotePort: path.dataEndpoint?.port,
    );
  }

  void _validateRemoteDataEndpoint({
    required TransferRouteSnapshot routeSnapshot,
    required InternetAddress remoteAddress,
  }) {
    final decision = TransferOutgoingRemoteDataEndpointRouteCommand.validate(
      routeRemoteAddress: routeSnapshot.controlRemoteAddress,
      dataRemoteAddress: remoteAddress.address,
    );
    if (decision.isValid) {
      return;
    }
    throw AppException(
      code: 'transfer_route_mismatch',
      message: decision.message!,
    );
  }

  void _validateDataBindEndpoint({
    required TransferRouteSnapshot routeSnapshot,
    required UdpInterfaceEndpoint dataEndpoint,
  }) {
    final decision = TransferDataBindEndpointRouteCommand.validate(
      routeLocalAddress: routeSnapshot.controlLocalAddress,
      bindLocalAddress: dataEndpoint.localAddress,
      isWildcardBind: dataEndpoint.isWildcardBind,
    );
    if (decision.isValid) {
      return;
    }
    throw AppException(
      code: 'transfer_data_bind_mismatch',
      message: decision.message!,
    );
  }

  void _ensureRouteLeaseStillActive(_OutgoingTransferContext context) {
    final current = ref
        .read(peerPathRegistryProvider)
        .selectedForPeer(context.session.peerId);
    final decision = TransferOutgoingRouteLeaseCommand.validate(
      expectedRouteLeaseId: context.routeSnapshot.routeLeaseId,
      currentRouteLeaseId: current?.pathId,
      currentStatus: current?.status,
      expectedLocalInterfaceId: context.routeSnapshot.localInterfaceId,
      currentLocalInterfaceId: current?.candidate.localInterfaceId.stableId,
      expectedLocalAddress: context.routeSnapshot.controlLocalAddress,
      currentLocalAddress: current?.controlEndpoint.localAddress,
      expectedRemoteAddress: context.routeSnapshot.controlRemoteAddress,
      currentRemoteAddress: current?.candidate.remoteAddress,
    );
    if (decision.isValid) {
      return;
    }
    throw AppException(
      code: decision.reasonCode == 'routeChanged'
          ? 'transfer_route_changed'
          : 'transfer_route_lease_expired',
      message:
          '${decision.message ?? '전송 중 연결 경로를 검증하지 못했습니다.'} '
          'route=${context.routeSnapshot.routeLeaseId}',
    );
  }

  String _endpointLabel(UdpInterfaceEndpoint? endpoint) {
    return TransferEndpointLabelFormatter.format(
      localAddress: endpoint?.localAddress,
      port: endpoint?.port,
      bindModeName: endpoint?.bindMode.name,
    );
  }

  String _safeSession(String sessionId) {
    return TransferLogSafeFormatter.session(sessionId);
  }

  String _safeTransfer(String? transferId) {
    return TransferLogSafeFormatter.transfer(transferId);
  }

  String _safeFileNameForLog(String fileName) {
    return TransferLogSafeFormatter.fileName(fileName);
  }

  DateTime _now() => ref.read(transferNowProvider)();

  String _eventId(String prefix) {
    return TransferEventIdFormatter.format(prefix: prefix, now: _now());
  }

  String _currentUserId() {
    final user = ref.read(authControllerProvider).currentUser;
    return TransferIdentitySelectionCommand.requiredUserId(user?.userId);
  }

  String _currentDisplayName() {
    final user = ref.read(authControllerProvider).currentUser;
    return TransferIdentitySelectionCommand.displayName(
      displayName: user?.displayName,
      userId: _currentUserId(),
    );
  }

  String _currentDeviceId() {
    return TransferIdentitySelectionCommand.requiredDeviceId(
      _localIdentity?.deviceId,
    );
  }

  String _currentInstanceId() {
    return TransferIdentitySelectionCommand.requiredInstanceId(
      _localIdentity?.instanceId,
    );
  }

  String _randomHex(int bytes) {
    return TransferRandomHexFormatter.formatBytes(
      List<int>.generate(bytes, (_) => _random.nextInt(256)),
    );
  }

  Future<void> _dispose() async {
    await _tcpIncomingResultSubscription?.cancel();
    _tcpIncomingResultSubscription = null;
    await _packetSubscription?.cancel();
    await _dataFrameSubscription?.cancel();
    await _tcpIncomingSubscription?.stop();
    _tcpIncomingSubscription = null;
    await _tcpDataListener?.close();
    _tcpDataListener = null;
    _tcpDataListenerBinding = null;
    await _tcpDataConnector?.close();
    _tcpDataConnector = null;
    _offeredTcpDataPeers.clear();
    for (final transferId in _outgoingTransfers.keys.toList(growable: false)) {
      final context = _removeOutgoingTransfer(transferId);
      await context?.dispose();
    }
    for (final transferId in _incomingTransfers.keys.toList(growable: false)) {
      final context = _removeIncomingTransfer(transferId);
      await context?.closeWriter();
    }
    _diagnosticFrameTraces.clear();
  }
}

class _OutgoingTransferContext {
  _OutgoingTransferContext({
    required this.session,
    required this.preparedFile,
    required this.startedAt,
    required this.windowSize,
    required this.remoteWindowStart,
    required this.advertisedWindowSize,
    required this.rttEstimator,
    required this.reader,
    required this.authContext,
    required String transferId,
    required this.routeSnapshot,
    // ignore: unused_element_parameter
    this.controlEndpoint,
  }) : transferIdBytes = transferIdBytesFromString(transferId);

  final PeerAuthSession session;
  final PreparedTransferMetadata preparedFile;
  final DateTime startedAt;
  final TransferRttEstimator rttEstimator;
  final OutgoingTransferReader reader;
  final TransferDataAuthContext authContext;
  final StreamingSha256Digest outgoingDigest = StreamingSha256Digest();
  final Uint8List transferIdBytes;
  final UdpInterfaceEndpoint? controlEndpoint;
  final Completer<_TransferInitAckResult> initAck =
      Completer<_TransferInitAckResult>();
  final Completer<void> allChunksAcked = Completer<void>();
  final Completer<_TransferCompleteAckResult> completeAck =
      Completer<_TransferCompleteAckResult>();
  final Set<int> acknowledgedChunks = <int>{};
  final Set<int> inFlightChunks = <int>{};
  final Set<int> hasRetransmitted = <int>{};
  final Map<int, DateTime> sentAtByChunk = <int, DateTime>{};
  final Map<int, int> retransmissionAttempts = <int, int>{};
  final ListQueue<int> queuedRetransmissions = ListQueue<int>();
  final Set<int> queuedRetransmissionSet = <int>{};
  int nextChunkToSend = 0;
  int acknowledgedBytes = 0;
  int retryCount = 0;
  int duplicateAckCount = 0;
  int windowSize;
  int remoteWindowStart;
  int advertisedWindowSize;
  int nextDigestChunk = 0;
  int _nextSequence = 1;
  Timer? retransmissionScanTimer;
  Timer? backpressureRetryTimer;
  InternetAddress? remoteDataAddress;
  int? remoteDataPort;
  UdpInterfaceEndpoint? localDataEndpoint;
  TransferRouteSnapshot routeSnapshot;
  bool hasFailed = false;
  bool isPumpActive = false;
  bool _readerClosed = false;
  String? _finalDigest;

  int nextSequence() => _nextSequence++;

  Future<String> closeOutgoingDigest() async {
    final existing = _finalDigest;
    if (existing != null) {
      return existing;
    }
    _finalDigest = await outgoingDigest.close();
    return _finalDigest!;
  }

  void queueRetransmission(int chunkIndex) {
    if (queuedRetransmissionSet.add(chunkIndex)) {
      queuedRetransmissions.addLast(chunkIndex);
    }
  }

  int? nextQueuedRetransmission() {
    while (queuedRetransmissions.isNotEmpty) {
      final next = queuedRetransmissions.first;
      if (!queuedRetransmissionSet.contains(next)) {
        queuedRetransmissions.removeFirst();
        continue;
      }
      return next;
    }
    return null;
  }

  bool dequeueRetransmission(int chunkIndex) {
    if (!queuedRetransmissionSet.remove(chunkIndex)) {
      return false;
    }
    if (queuedRetransmissions.isNotEmpty &&
        queuedRetransmissions.first == chunkIndex) {
      queuedRetransmissions.removeFirst();
      return true;
    }
    queuedRetransmissions.remove(chunkIndex);
    return true;
  }

  void ensureRetransmissionScan(Duration delay, void Function() onTimeout) {
    if (retransmissionScanTimer != null || inFlightChunks.isEmpty) {
      return;
    }
    retransmissionScanTimer = Timer(delay, onTimeout);
  }

  void cancelRetransmissionScanIfIdle() {
    if (inFlightChunks.isNotEmpty) {
      return;
    }
    retransmissionScanTimer?.cancel();
    retransmissionScanTimer = null;
  }

  void scheduleBackpressureRetry(Duration delay, void Function() onRetry) {
    if (backpressureRetryTimer != null) {
      return;
    }
    backpressureRetryTimer = Timer(delay, () {
      backpressureRetryTimer = null;
      onRetry();
    });
  }

  Future<void> dispose() async {
    retransmissionScanTimer?.cancel();
    retransmissionScanTimer = null;
    backpressureRetryTimer?.cancel();
    backpressureRetryTimer = null;
    queuedRetransmissions.clear();
    queuedRetransmissionSet.clear();
    if (!_readerClosed) {
      _readerClosed = true;
      await reader.close();
    }
    authContext.dispose();
  }
}

class _IncomingTransferContext {
  _IncomingTransferContext({
    required this.sessionId,
    required this.peerId,
    required this.peerDisplayName,
    required this.controlAddress,
    required this.controlPort,
    required this.controlLocalEndpoint,
    required this.tempFilePath,
    required this.fileName,
    required this.fileSize,
    required this.expectedSha256,
    required this.expectedChunkCount,
    required this.saveDirectory,
    required this.startedAt,
    required this.writer,
    required this.transferIdBytes,
    required this.sessionHash,
    required this.routeSnapshot,
  });

  final String sessionId;
  final String peerId;
  final String peerDisplayName;
  final InternetAddress controlAddress;
  final int controlPort;
  final UdpInterfaceEndpoint? controlLocalEndpoint;
  final String tempFilePath;
  final String fileName;
  final int fileSize;
  final String? expectedSha256;
  final int expectedChunkCount;
  final String saveDirectory;
  final DateTime startedAt;
  final IncomingDigestingTransferWriter writer;
  final Uint8List transferIdBytes;
  final int sessionHash;
  final TransferRouteSnapshot routeSnapshot;
  final Set<int> acknowledgedChunks = <int>{};
  final Map<int, List<int>> bufferedChunks = <int, List<int>>{};
  final Set<int> pendingAckChunks = <int>{};
  int nextExpectedChunk = 0;
  int acknowledgedBytes = 0;
  int writtenBytes = 0;
  int duplicateChunks = 0;
  int lastAdvertisedWindowStart = 0;
  int _nextSequence = 1;
  bool _writerClosed = false;
  Timer? ackFlushTimer;
  Timer? missingNackRetryTimer;
  InternetAddress? pendingAckAddress;
  int? pendingAckPort;
  InternetAddress? lastDataAddress;
  int? lastDataPort;

  int nextSequence() => _nextSequence++;

  Future<void> closeWriter() async {
    ackFlushTimer?.cancel();
    ackFlushTimer = null;
    missingNackRetryTimer?.cancel();
    missingNackRetryTimer = null;
    pendingAckChunks.clear();
    if (_writerClosed) {
      return;
    }
    _writerClosed = true;
    await writer.close();
  }

  Future<String> closeWriterWithDigest() async {
    ackFlushTimer?.cancel();
    ackFlushTimer = null;
    missingNackRetryTimer?.cancel();
    missingNackRetryTimer = null;
    pendingAckChunks.clear();
    if (_writerClosed) {
      return writer.closeWithDigest();
    }
    _writerClosed = true;
    return writer.closeWithDigest();
  }

  void cancelMissingNackRetry() {
    if (bufferedChunks.isNotEmpty) {
      return;
    }
    missingNackRetryTimer?.cancel();
    missingNackRetryTimer = null;
  }
}

class _TransferInitAckResult {
  const _TransferInitAckResult({
    required this.accepted,
    required this.sourceAddress,
    this.message,
    this.savePath,
    this.dataAddress,
    this.dataPort,
    this.acceptedChunkSize,
    this.acceptedWindowSize,
  });

  final bool accepted;
  final String sourceAddress;
  final String? message;
  final String? savePath;
  final String? dataAddress;
  final int? dataPort;
  final int? acceptedChunkSize;
  final int? acceptedWindowSize;
}

class _TransferCompleteAckResult {
  const _TransferCompleteAckResult({
    required this.accepted,
    this.message,
    this.savePath,
  });

  final bool accepted;
  final String? message;
  final String? savePath;
}

final transferNowProvider = Provider<TransferNow>((ref) => DateTime.now);

final transferControllerProvider =
    NotifierProvider<TransferController, TransferState>(TransferController.new);
