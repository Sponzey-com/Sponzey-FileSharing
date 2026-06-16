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
import 'package:sponzey_file_sharing/application/transfer/transfer_diagnostics_ring_buffer.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_endpoint_resolver.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_rtt_estimator.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_tuning_policy.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_protocol.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_job_state_machine.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_route_snapshot.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_platform_directories.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/transfer_history_repository.dart';
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

  bool _didInitialize = false;
  final Random _random = Random.secure();
  StreamSubscription<ControlDatagram>? _packetSubscription;
  StreamSubscription<DataFrameDatagram>? _dataFrameSubscription;
  LocalDeviceIdentity? _localIdentity;
  final Map<String, _OutgoingTransferContext> _outgoingTransfers = {};
  final Map<String, _IncomingTransferContext> _incomingTransfers = {};
  final Map<String, String> _transferIdByFrameKey = {};
  final Map<String, DateTime> _lastMetricLoggedAt = {};
  final Map<String, TransferDiagnosticsRingBuffer> _diagnosticFrameTraces = {};

  @override
  TransferState build() {
    ref.onDispose(() {
      unawaited(_dispose());
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

    final outgoing = _outgoingTransfers.remove(transferId);
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
      _transferIdByFrameKey.remove(_frameKey(outgoing.transferIdBytes));
      await outgoing.dispose();
    }

    final incoming = _incomingTransfers.remove(transferId);
    if (incoming != null) {
      await incoming.closeWriter();
      _transferIdByFrameKey.remove(_frameKey(incoming.transferIdBytes));
      await ref
          .read(transferFileServiceProvider)
          .discardDraft(incoming.tempFilePath);
    }

    _lastMetricLoggedAt.remove(transferId);
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

  Future<void> sendFile({
    required String peerId,
    required String filePath,
  }) async {
    state = state.copyWith(clearError: true, clearInfo: true);

    try {
      final session = _requireAuthenticatedSession(peerId);
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
      final targetAddress = InternetAddress(routeSnapshot.controlRemoteAddress);
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
      _outgoingTransfers[transferId] = context;
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.transferControl,
            'Starting outgoing transfer ${_safeTransfer(transferId)} '
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
    } on AppException catch (error) {
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
      state = state.copyWith(
        isListening: false,
        isLoading: false,
        errorMessage: '전송 엔진을 시작하지 못했습니다.',
      );
    }
  }

  Future<void> _handlePacket(ControlDatagram datagram) async {
    final packet = datagram.packet;
    switch (packet.type) {
      case AuthPacketType.transferInit:
        await _onTransferInit(packet, datagram);
      case AuthPacketType.transferInitAck:
        _onTransferInitAck(packet, datagram);
      case AuthPacketType.transferChunk:
        await _onTransferChunk(packet, datagram);
      case AuthPacketType.transferChunkAck:
        _onTransferChunkAck(packet);
      case AuthPacketType.transferChunkNack:
        _onTransferChunkNack(packet);
      case AuthPacketType.transferWindowUpdate:
        _onTransferWindowUpdate(packet);
      case AuthPacketType.transferComplete:
        await _onTransferComplete(packet, datagram);
      case AuthPacketType.transferCompleteAck:
        await _onTransferCompleteAck(packet, datagram);
      case AuthPacketType.connectRequest:
      case AuthPacketType.authChallenge:
      case AuthPacketType.authToken:
      case AuthPacketType.authTokenAck:
      case AuthPacketType.authAccept:
      case AuthPacketType.authReject:
        return;
    }
  }

  Future<void> _handleDataFrame(DataFrameDatagram datagram) async {
    final frame = datagram.frame;
    final transferId = _transferIdByFrameKey[_frameKey(frame.transferIdBytes)];
    if (transferId == null) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferData,
            'Dropped data frame for unknown transfer type=${frame.type.name} '
            'from=${datagram.address.address}:${datagram.port}',
          );
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

    switch (frame.type) {
      case DataFrameType.dataStart:
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
      case DataFrameType.dataChunk:
        await _onDataChunk(transferId, datagram);
        return;
      case DataFrameType.dataAck:
        _onDataAck(transferId, datagram);
        return;
      case DataFrameType.dataNack:
        _onDataNack(transferId, datagram);
        return;
      case DataFrameType.dataWindowUpdate:
        _onDataWindowUpdate(transferId, datagram);
        return;
      case DataFrameType.dataFinish:
        await _onDataFinish(transferId, datagram);
        return;
      case DataFrameType.dataAbort:
        await _failIncomingTransfer(transferId, '상대 노드가 전송을 취소했습니다.');
        return;
    }
  }

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
        _outgoingTransfers.remove(transferId);
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
      _transferIdByFrameKey[_frameKey(context.transferIdBytes)] = transferId;
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
      _lastMetricLoggedAt.remove(transferId);
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
      final current = _outgoingTransfers.remove(transferId);
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

      if (!context.allChunksAcked.isCompleted &&
          context.acknowledgedChunks.length ==
              context.preparedFile.chunkCount &&
          context.inFlightChunks.isEmpty) {
        context.allChunksAcked.complete();
      }
    } finally {
      context.isPumpActive = false;
    }
  }

  int? _nextChunkForSend(_OutgoingTransferContext context) {
    final retransmit = context.nextQueuedRetransmission();
    if (retransmit != null &&
        !context.acknowledgedChunks.contains(retransmit) &&
        !context.inFlightChunks.contains(retransmit)) {
      return retransmit;
    }

    final remoteLimit =
        context.remoteWindowStart + max(1, context.advertisedWindowSize);
    while (context.nextChunkToSend < context.preparedFile.chunkCount) {
      final index = context.nextChunkToSend;
      if (index >= remoteLimit) {
        return null;
      }
      context.nextChunkToSend += 1;
      if (context.acknowledgedChunks.contains(index) ||
          context.inFlightChunks.contains(index)) {
        continue;
      }
      return index;
    }
    return null;
  }

  Future<bool> _sendChunk(
    String transferId,
    _OutgoingTransferContext context,
    int chunkIndex, {
    required bool isRetransmission,
  }) async {
    final nextAttempts =
        (context.retransmissionAttempts[chunkIndex] ?? 0) +
        (isRetransmission ? 1 : 0);
    _ensureRouteLeaseStillActive(context);
    if (nextAttempts > _maxRetransmissions) {
      throw AppException(
        code: 'transfer_retry_exhausted',
        message: 'chunk $chunkIndex 재전송 한도를 초과했습니다.',
      );
    }

    if (isRetransmission) {
      context.retryCount += 1;
      context.windowSize = max(1, context.windowSize ~/ 2);
      context.retransmissionAttempts[chunkIndex] = nextAttempts;
      context.hasRetransmitted.add(chunkIndex);
    }

    final bytes = await context.reader.readAt(
      chunkSize: context.preparedFile.chunkSize,
      chunkIndex: chunkIndex,
    );
    if (!isRetransmission && chunkIndex == context.nextDigestChunk) {
      context.outgoingDigest.add(bytes);
      context.nextDigestChunk += 1;
    }
    final now = _now();
    context.inFlightChunks.add(chunkIndex);
    context.sentAtByChunk[chunkIndex] = now;
    try {
      final remoteAddress = context.remoteDataAddress;
      final remotePort = context.remoteDataPort;
      if (remoteAddress == null || remotePort == null) {
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
        address: remoteAddress,
        port: remotePort,
      );
    } on AppException catch (error, stackTrace) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      if (!_isRetryableDataFrameSendFailure(error)) {
        rethrow;
      }
      final attemptsAfterFailure = max(
        nextAttempts,
        (context.retransmissionAttempts[chunkIndex] ?? 0) + 1,
      );
      if (attemptsAfterFailure > _maxRetransmissions) {
        throw AppException(
          code: 'transfer_retry_exhausted',
          message: 'chunk $chunkIndex 재전송 한도를 초과했습니다.',
        );
      }
      if (!isRetransmission) {
        context.retryCount += 1;
        context.windowSize = max(1, context.windowSize ~/ 2);
      }
      context.retransmissionAttempts[chunkIndex] = attemptsAfterFailure;
      context.hasRetransmitted.add(chunkIndex);
      context.queueRetransmission(chunkIndex);
      context.scheduleBackpressureRetry(
        _sendBackpressureRetryDelay,
        () => unawaited(_pumpOutgoingWindow(transferId, context)),
      );
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Data chunk send failed; queued retry '
            'transfer=${_safeTransfer(transferId)} chunk=$chunkIndex '
            'attempt=$attemptsAfterFailure window=${context.windowSize}',
            error: error,
            stackTrace: stackTrace,
          );
      _updateOutgoingMetrics(
        transferId,
        context,
        message: 'data chunk $chunkIndex 송신 실패, 재전송 대기 중',
        important: true,
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
      message: isRetransmission
          ? 'chunk $chunkIndex 재전송 중'
          : 'window ${context.windowSize} 기준으로 전송 중',
    );
    return true;
  }

  bool _isRetryableDataFrameSendFailure(AppException error) {
    return error.code == 'sendFailed' ||
        error.code == 'partialSend' ||
        error.code == 'data_frame_send_failed';
  }

  void _onRetransmissionScan(String transferId) {
    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }
    context.retransmissionScanTimer = null;
    if (context.inFlightChunks.isEmpty) {
      return;
    }

    final now = _now();
    final timeout = context.rttEstimator.currentTimeout;
    final timedOutChunks = <int>[];
    for (final chunkIndex in context.inFlightChunks.toList(growable: false)) {
      if (context.acknowledgedChunks.contains(chunkIndex)) {
        context.inFlightChunks.remove(chunkIndex);
        context.sentAtByChunk.remove(chunkIndex);
        continue;
      }
      final sentAt = context.sentAtByChunk[chunkIndex];
      if (sentAt == null || now.difference(sentAt) < timeout) {
        continue;
      }
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      context.queueRetransmission(chunkIndex);
      timedOutChunks.add(chunkIndex);
    }

    if (timedOutChunks.isNotEmpty) {
      context.rttEstimator.noteTimeoutBackoff();
      context.windowSize = max(1, context.windowSize ~/ 2);
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Retransmission scan timed out ${timedOutChunks.length} chunks '
            'on transfer ${_safeTransfer(transferId)}',
          );
      _updateOutgoingMetrics(
        transferId,
        context,
        message: 'timeout ${timedOutChunks.length} chunks, 재전송 대기 중',
        important: true,
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
    final transferId = packet.transferId;
    final fileName = packet.transferFileName;
    final fileSize = packet.transferFileSize;
    final sha256 = packet.transferSha256;
    final chunkCount = packet.transferChunkCount;
    if (transferId == null ||
        fileName == null ||
        fileSize == null ||
        chunkCount == null) {
      return;
    }

    final packetPeerId = _peerIdFromPacket(packet);
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
    if (peerId != packetPeerId) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'Resolved TRANSFER_INIT peer alias '
            'packetPeer=$packetPeerId sessionPeer=$peerId '
            'session=${_safeSession(session.sessionId)} '
            'source=${datagram.address.address}:${datagram.port}',
          );
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
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferControl,
            'Preparing incoming transfer storage '
            'transfer=${_safeTransfer(transferId)} peer=$peerId '
            'file=${_safeFileNameForLog(fileName)} size=$fileSize '
            'chunks=$chunkCount',
          );
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
      _transferIdByFrameKey[_frameKey(transferIdBytes)] = transferId;
      _incomingTransfers[transferId] = _IncomingTransferContext(
        sessionId: packet.sessionId,
        peerId: peerId,
        peerDisplayName: packet.fromDisplayName ?? packet.fromUserId,
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
          peerDisplayName: packet.fromDisplayName ?? packet.fromUserId,
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
        acceptedChunkSize: packet.transferAcceptedChunkSize ?? _dataChunkSize,
        acceptedWindowSize: _receiverAdvertisedWindow,
        receiverBufferBudget: _receiverAdvertisedWindow * _dataChunkSize,
        dataAuthContextId: packet.transferDataAuthContextId,
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

  void _onTransferInitAck(AuthPacket packet, ControlDatagram datagram) {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _outgoingTransfers[transferId];
    if (context == null || context.initAck.isCompleted) {
      return;
    }
    ref
        .read(appLoggerProvider)
        .info(
          AppLogCategory.transferControl,
          'Received TRANSFER_INIT_ACK ${_safeTransfer(transferId)} '
          'from=${datagram.address.address}:${datagram.port} '
          'accepted=${packet.transferAccepted ?? false}',
        );
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

    final context = _incomingTransfers[transferId];
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
        windowSize: _receiverWindowSize(context),
        localEndpoint: datagram.localEndpoint,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: '중복 chunk $chunkIndex 수신',
        important: true,
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
        final missingIndexes = _missingIndexesUntil(
          context,
          chunkIndex,
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
    final context = _incomingTransfers[transferId];
    if (context == null) {
      return;
    }
    context.lastDataAddress = datagram.address;
    context.lastDataPort = datagram.port;

    if (chunkIndex >= context.expectedChunkCount) {
      await _sendDataNackSafely(
        context,
        chunkIndexes: [context.nextExpectedChunk],
        address: datagram.address,
        port: datagram.port,
      );
      return;
    }

    if (context.acknowledgedChunks.contains(chunkIndex)) {
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
        important: true,
      );
      return;
    }

    try {
      final bytes = frame.payload;
      context.acknowledgedChunks.add(chunkIndex);
      context.acknowledgedBytes += bytes.length;

      if (chunkIndex == context.nextExpectedChunk) {
        await _appendIncomingChunk(context, bytes);
        context.nextExpectedChunk += 1;
        await _flushBufferedChunks(context);
      } else {
        context.bufferedChunks[chunkIndex] = bytes;
        final missingIndexes = _missingIndexesUntil(
          context,
          chunkIndex,
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
      }

      await _queueDataAck(
        context,
        chunkIndex: chunkIndex,
        address: datagram.address,
        port: datagram.port,
        flushImmediately:
            context.pendingAckChunks.length + 1 >= _ackBatchChunkThreshold ||
            context.nextExpectedChunk >= context.expectedChunkCount,
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
    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }
    final chunkIndexes =
        _chunkIndexesFromAckFrame(datagram.frame)
            .where(
              (index) => index >= 0 && index < context.preparedFile.chunkCount,
            )
            .toList(growable: false)
          ..sort();
    if (chunkIndexes.isEmpty) {
      return;
    }
    var newlyAckedCount = 0;
    var newlyAckedBytes = 0;
    for (final chunkIndex in chunkIndexes) {
      if (context.acknowledgedChunks.contains(chunkIndex)) {
        context.duplicateAckCount += 1;
        continue;
      }
      context.acknowledgedChunks.add(chunkIndex);
      context.inFlightChunks.remove(chunkIndex);
      final sentAt = context.sentAtByChunk.remove(chunkIndex);
      final retransmissions = context.retransmissionAttempts[chunkIndex] ?? 0;
      if (sentAt != null && retransmissions == 0) {
        context.rttEstimator.recordSample(_now().difference(sentAt));
      }
      newlyAckedCount += 1;
      newlyAckedBytes += _chunkByteLength(context.preparedFile, chunkIndex);
    }
    if (newlyAckedCount == 0) {
      return;
    }
    context.windowSize =
        const DataTransferTuningPolicy(
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
        ).windowAfterAck(
          currentWindow: context.windowSize,
          maximumWindow: _maximumWindowSize,
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
          'DATA_ACK ${chunkIndexes.first}-${chunkIndexes.last} '
          'count=$newlyAckedCount 수신',
    );
    if (!context.allChunksAcked.isCompleted &&
        context.acknowledgedChunks.length == context.preparedFile.chunkCount &&
        context.inFlightChunks.isEmpty) {
      context.allChunksAcked.complete();
    } else {
      unawaited(_pumpOutgoingWindow(transferId, context));
    }
  }

  void _onDataNack(String transferId, DataFrameDatagram datagram) {
    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }
    context.windowSize = max(1, context.windowSize ~/ 2);
    final chunkIndexes = <int>{datagram.frame.chunkIndex};
    for (
      var wordIndex = 0;
      wordIndex < datagram.frame.ackBitmapWords.length;
      wordIndex += 1
    ) {
      final word = datagram.frame.ackBitmapWords[wordIndex];
      for (var bit = 0; bit < 32; bit += 1) {
        if ((word & (1 << bit)) != 0) {
          chunkIndexes.add(datagram.frame.ackBase + wordIndex * 32 + bit);
        }
      }
    }
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
      message: 'DATA_NACK ${chunkIndexes.join(', ')} 수신',
      important: true,
    );
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  void _onDataWindowUpdate(String transferId, DataFrameDatagram datagram) {
    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }
    context.remoteWindowStart = datagram.frame.windowStart;
    context.advertisedWindowSize = max(1, datagram.frame.windowSize);
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  Future<void> _onDataFinish(
    String transferId,
    DataFrameDatagram datagram,
  ) async {
    final context = _incomingTransfers[transferId];
    if (context == null) {
      return;
    }
    if (context.nextExpectedChunk != context.expectedChunkCount ||
        context.bufferedChunks.isNotEmpty) {
      final missingIndexes = _remainingMissingIndexes(
        context,
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
      _updateIncomingMetrics(
        transferId,
        context,
        message: '누락 data chunk 재전송을 기다리는 중입니다.',
        important: true,
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
      _incomingTransfers.remove(transferId);
      _transferIdByFrameKey.remove(_frameKey(context.transferIdBytes));
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
          windowSize: _receiverWindowSize(context),
        ),
      );
      _lastMetricLoggedAt.remove(transferId);
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
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Incoming data transfer finalize rejected '
            'transfer=${_safeTransfer(transferId)} peer=${context.peerId} '
            'code=${error.code}',
          );
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: context.controlAddress,
        port: context.controlPort,
        accepted: false,
        message: error.message,
        localEndpoint: context.controlLocalEndpoint,
      );
      await _failIncomingTransfer(transferId, error.message);
    } catch (error, stackTrace) {
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
        message: '수신 파일을 완료하지 못했습니다.',
        localEndpoint: context.controlLocalEndpoint,
      );
      await _failIncomingTransfer(transferId, '수신 파일을 완료하지 못했습니다.');
    }
  }

  void _onTransferChunkAck(AuthPacket packet) {
    final transferId = packet.transferId;
    final chunkIndex = packet.transferChunkIndex;
    if (transferId == null || chunkIndex == null) {
      return;
    }

    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }

    if (context.acknowledgedChunks.contains(chunkIndex)) {
      context.duplicateAckCount += 1;
      _updateOutgoingMetrics(
        transferId,
        context,
        message: '중복 ACK $chunkIndex 수신',
        important: true,
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
    if (context.windowSize < _maximumWindowSize) {
      context.windowSize += 1;
    }
    context.acknowledgedBytes += _chunkByteLength(
      context.preparedFile,
      chunkIndex,
    );
    context.cancelRetransmissionScanIfIdle();
    _updateOutgoingMetrics(transferId, context, message: 'ACK $chunkIndex 수신');
    if (!context.allChunksAcked.isCompleted &&
        context.acknowledgedChunks.length == context.preparedFile.chunkCount &&
        context.inFlightChunks.isEmpty) {
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

    final context = _outgoingTransfers[transferId];
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

    context.windowSize = max(1, context.windowSize ~/ 2);
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
      important: true,
    );
    unawaited(_pumpOutgoingWindow(transferId, context));
  }

  void _onTransferWindowUpdate(AuthPacket packet) {
    final transferId = packet.transferId;
    if (transferId == null) {
      return;
    }

    final context = _outgoingTransfers[transferId];
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

    final context = _incomingTransfers[transferId];
    if (context == null) {
      return;
    }

    if (context.nextExpectedChunk != context.expectedChunkCount ||
        context.bufferedChunks.isNotEmpty) {
      final missingIndexes = _remainingMissingIndexes(
        context,
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
      await _sendWindowUpdate(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        windowStart: context.nextExpectedChunk,
        windowSize: _receiverWindowSize(context),
        localEndpoint: datagram.localEndpoint,
      );
      _updateIncomingMetrics(
        transferId,
        context,
        message: '누락 chunk 재전송을 기다리는 중입니다.',
        important: true,
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
      _incomingTransfers.remove(transferId);
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
          windowSize: _receiverWindowSize(context),
        ),
      );
      _lastMetricLoggedAt.remove(transferId);
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
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferControl,
            'Incoming transfer finalize rejected '
            'transfer=${_safeTransfer(transferId)} peer=${context.peerId} '
            'code=${error.code}',
          );
      await _sendTransferCompleteAck(
        sessionId: context.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: error.message,
        localEndpoint: datagram.localEndpoint,
      );
      await _failIncomingTransfer(transferId, error.message);
    } catch (error, stackTrace) {
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
        message: '수신 파일을 완료하지 못했습니다.',
        localEndpoint: datagram.localEndpoint,
      );
      await _failIncomingTransfer(transferId, '수신 파일을 완료하지 못했습니다.');
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

    final context = _outgoingTransfers[transferId];
    if (context == null || context.completeAck.isCompleted) {
      return;
    }
    ref
        .read(appLoggerProvider)
        .info(
          AppLogCategory.transferControl,
          'Received TRANSFER_COMPLETE_ACK ${_safeTransfer(transferId)} '
          'from=${datagram.address.address}:${datagram.port} '
          'accepted=${packet.transferAccepted ?? false}',
        );
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
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Data ACK flush failed; queued retry '
            'peer=${context.peerId} chunks=${chunkIndexes.length}',
            error: error,
            stackTrace: stackTrace,
          );
    });
  }

  void _scheduleDataAckRetry(_IncomingTransferContext context) {
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
    final compactIndexes = chunkIndexes.toSet().toList(growable: false)..sort();
    if (compactIndexes.isEmpty) {
      return Future.value();
    }
    return _sendDataFrame(
      _incomingDataFrame(
        context,
        type: DataFrameType.dataAck,
        sequence: context.nextSequence(),
        chunkIndex: compactIndexes.first,
        windowStart: context.nextExpectedChunk,
        windowSize: _receiverWindowSize(context),
        ackBase: compactIndexes.first,
        ackBitmapWords: _bitmapWordsFor(compactIndexes),
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
    final compactIndexes = chunkIndexes.toSet().toList(growable: false)..sort();
    if (compactIndexes.isEmpty) {
      return Future.value();
    }
    return _sendDataFrame(
      _incomingDataFrame(
        context,
        type: DataFrameType.dataNack,
        sequence: context.nextSequence(),
        chunkIndex: compactIndexes.first,
        ackBase: compactIndexes.first,
        ackBitmapWords: _bitmapWordsFor(compactIndexes),
        windowStart: context.nextExpectedChunk,
        windowSize: _receiverWindowSize(context),
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
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.transferData,
            'Data NACK send failed; sender retransmission timeout remains '
            'available peer=${context.peerId} chunks=${chunkIndexes.length}',
            error: error,
            stackTrace: stackTrace,
          );
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
    final reason = switch (error) {
      AppException(:final message) => message,
      FileSystemException(:final message) when message.isNotEmpty => message,
      StateError(:final message) => message,
      _ => error.runtimeType.toString(),
    };
    return '수신 data chunk 를 저장하지 못했습니다. '
        '저장 경로 또는 임시 파일 권한을 확인해 주세요. '
        '원인: $reason';
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
    final receiverWindowSize = _receiverWindowSize(context);
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

  List<int> _missingIndexesUntil(
    _IncomingTransferContext context,
    int highestReceivedIndex, {
    required int limit,
  }) {
    final indexes = <int>[];
    for (
      var index = context.nextExpectedChunk;
      index < highestReceivedIndex && indexes.length < limit;
      index += 1
    ) {
      if (!context.acknowledgedChunks.contains(index)) {
        indexes.add(index);
      }
    }
    return indexes;
  }

  List<int> _remainingMissingIndexes(
    _IncomingTransferContext context, {
    required int limit,
  }) {
    final indexes = <int>[];
    for (
      var index = context.nextExpectedChunk;
      index < context.expectedChunkCount && indexes.length < limit;
      index += 1
    ) {
      if (!context.acknowledgedChunks.contains(index)) {
        indexes.add(index);
      }
    }
    return indexes;
  }

  Set<int> _chunkIndexesFromAckFrame(DataFrame frame) {
    final chunkIndexes = <int>{frame.chunkIndex};
    for (
      var wordIndex = 0;
      wordIndex < frame.ackBitmapWords.length;
      wordIndex += 1
    ) {
      final word = frame.ackBitmapWords[wordIndex];
      for (var bit = 0; bit < 32; bit += 1) {
        if ((word & (1 << bit)) != 0) {
          chunkIndexes.add(frame.ackBase + wordIndex * 32 + bit);
        }
      }
    }
    return chunkIndexes;
  }

  int _receiverWindowSize(_IncomingTransferContext context) {
    return max(1, _receiverAdvertisedWindow - context.bufferedChunks.length);
  }

  Future<void> _failIncomingTransfer(String transferId, String message) async {
    final context = _incomingTransfers.remove(transferId);
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
    final context = _outgoingTransfers[transferId];
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
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferData,
            'Ignored incoming writer cleanup failure',
            error: error,
            stackTrace: stackTrace,
          );
    }
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(transferFileServiceProvider)
          .discardDraft(draft.tempFilePath);
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.transferData,
            'Ignored incoming draft cleanup failure',
            error: error,
            stackTrace: stackTrace,
          );
    }
  }

  PeerAuthSession? _authenticatedSessionForTransferInit(
    AuthPacket packet,
    ControlDatagram datagram, {
    required String packetPeerId,
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
          'Rejected TRANSFER_INIT because authenticated session was not found '
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

  int _chunkByteLength(PreparedTransferMetadata file, int chunkIndex) {
    final start = chunkIndex * file.chunkSize;
    final remaining = file.fileSize - start;
    return remaining > file.chunkSize ? file.chunkSize : remaining;
  }

  void _updateOutgoingMetrics(
    String transferId,
    _OutgoingTransferContext context, {
    required String message,
    bool important = false,
  }) {
    final throughput = _throughputBytesPerSec(
      transferredBytes: context.acknowledgedBytes,
      startedAt: context.startedAt,
    );
    final lossRate = _lossRateFor(context);
    _updateJob(
      transferId,
      (job) => job.copyWith(
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
    _logMetricSummary(
      transferId,
      message:
          'outgoing ${context.acknowledgedChunks.length}/${context.preparedFile.chunkCount} '
          'window=${context.windowSize} retry=${context.retryCount} '
          'loss=${(lossRate * 100).toStringAsFixed(1)}% '
          'rate=${throughput.toStringAsFixed(0)}B/s '
          'rtt=${context.rttEstimator.smoothedRttMs?.toStringAsFixed(0) ?? '-'}ms '
          'note=$message',
      important: important,
    );
  }

  void _updateIncomingMetrics(
    String transferId,
    _IncomingTransferContext context, {
    required String message,
    bool important = false,
  }) {
    final throughput = _throughputBytesPerSec(
      transferredBytes: context.writtenBytes,
      startedAt: context.startedAt,
    );
    _updateJob(
      transferId,
      (job) => job.copyWith(
        status: TransferJobStatus.receiving,
        bytesTransferred: context.writtenBytes,
        completedChunks: context.nextExpectedChunk,
        duplicateCount: context.duplicateChunks,
        throughputBytesPerSec: throughput,
        windowSize: _receiverWindowSize(context),
        updatedAt: _now(),
        message: message,
      ),
    );
    _logMetricSummary(
      transferId,
      message:
          'incoming written=${context.nextExpectedChunk}/${context.expectedChunkCount} '
          'acked=${context.acknowledgedChunks.length}/${context.expectedChunkCount} '
          'route=${context.routeSnapshot.routeLeaseId} '
          'buffered=${context.bufferedChunks.length} dup=${context.duplicateChunks} '
          'rate=${throughput.toStringAsFixed(0)}B/s '
          'window=${_receiverWindowSize(context)} note=$message',
      important: important,
    );
  }

  void _scheduleMissingDataNackRetry(
    String transferId,
    _IncomingTransferContext context,
  ) {
    if (context.bufferedChunks.isEmpty ||
        context.missingNackRetryTimer != null) {
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
    if (_incomingTransfers[transferId] != context ||
        context.bufferedChunks.isEmpty) {
      return;
    }
    final address = context.lastDataAddress;
    final port = context.lastDataPort;
    if (address == null || port == null) {
      return;
    }
    final missingIndexes = _remainingMissingIndexes(
      context,
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

  void _logMetricSummary(
    String transferId, {
    required String message,
    required bool important,
  }) {
    final now = _now();
    final lastLoggedAt = _lastMetricLoggedAt[transferId];
    if (!important &&
        lastLoggedAt != null &&
        now.difference(lastLoggedAt) < _metricLogInterval) {
      return;
    }
    _lastMetricLoggedAt[transferId] = now;
    ref.read(appLoggerProvider).debug(AppLogCategory.transferData, message);
  }

  double _lossRateFor(_OutgoingTransferContext context) {
    final denominator = context.acknowledgedChunks.length + context.retryCount;
    if (denominator <= 0) {
      return 0;
    }
    return context.retryCount / denominator;
  }

  double _throughputBytesPerSec({
    required int transferredBytes,
    required DateTime startedAt,
  }) {
    final elapsedMs = _now().difference(startedAt).inMilliseconds;
    if (elapsedMs <= 0 || transferredBytes <= 0) {
      return 0;
    }
    return transferredBytes / (elapsedMs / 1000);
  }

  void _upsertJob(TransferJob nextJob) {
    final jobs = [
      for (final job in state.jobs)
        if (job.id != nextJob.id) job,
      nextJob,
    ]..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    state = state.copyWith(jobs: jobs, clearError: true);
    ref
        .read(messageBusProvider)
        .publish(
          TransferSessionAppEvent(
            eventId: _eventId('transfer-${nextJob.status.name}'),
            occurredAt: _now(),
            correlationId: nextJob.transferId,
            source: 'TransferController',
            severity:
                nextJob.status == TransferJobStatus.failed ||
                    nextJob.status == TransferJobStatus.rejected
                ? AppEventSeverity.product
                : AppEventSeverity.debug,
            eventType: 'transfer${nextJob.status.name}',
            transferId: nextJob.transferId,
            jobId: nextJob.id,
            peerId: nextJob.peerId,
            reasonCode:
                nextJob.status == TransferJobStatus.failed ||
                    nextJob.status == TransferJobStatus.rejected
                ? nextJob.message
                : null,
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
    TransferJob? currentJob;
    for (final job in state.jobs) {
      if (job.id == transferId) {
        currentJob = job;
        break;
      }
    }
    if (currentJob == null) {
      return;
    }
    _upsertJob(update(currentJob));
  }

  void _markRejected(String transferId, String message) {
    _lastMetricLoggedAt.remove(transferId);
    _updateJob(
      transferId,
      (job) => job.copyWith(
        status: TransferJobStatus.rejected,
        updatedAt: _now(),
        message: message,
      ),
    );
    state = state.copyWith(errorMessage: message);
  }

  void _markFailed(String transferId, String message) {
    _lastMetricLoggedAt.remove(transferId);
    _updateJob(
      transferId,
      (job) => job.copyWith(
        status: TransferJobStatus.failed,
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
    final message =
        'Sending ${packet.type.wireName} ${_safeTransfer(packet.transferId)} '
        'to ${address.address}:$port '
        'local=${_endpointLabel(localEndpoint)} '
        'session=${_safeSession(packet.sessionId)}';
    final logger = ref.read(appLoggerProvider);
    if (_isHighVolumeTransferPacket(packet.type)) {
      logger.debug(AppLogCategory.transferControl, message);
    } else {
      logger.info(AppLogCategory.transferControl, message);
    }
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
    final transferId = _transferIdByFrameKey[_frameKey(frame.transferIdBytes)];
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
      TransferFrameTrace(
        occurredAt: _now(),
        direction: direction,
        frameType: frame.type.name,
        sequence: frame.sequence,
        chunkIndex: frame.chunkIndex,
        ackBase: frame.ackBase,
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
    return DataFrame(
      version: DataFrameCodec.version,
      type: type,
      flags: 0,
      sessionHash: context.authContext.sessionHash,
      transferIdBytes: context.transferIdBytes,
      sequence: sequence,
      chunkIndex: chunkIndex,
      windowStart: windowStart ?? context.remoteWindowStart,
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
    return DataFrame(
      version: DataFrameCodec.version,
      type: type,
      flags: 0,
      sessionHash: context.sessionHash,
      transferIdBytes: context.transferIdBytes,
      sequence: sequence,
      chunkIndex: chunkIndex,
      windowStart: windowStart ?? context.nextExpectedChunk,
      windowSize: windowSize ?? _receiverWindowSize(context),
      ackBase: ackBase,
      ackBitmapWords: ackBitmapWords,
      payload: payload,
    );
  }

  List<int> _bitmapWordsFor(List<int> chunkIndexes) {
    if (chunkIndexes.isEmpty) {
      return const [];
    }
    final base = chunkIndexes.first;
    var maxOffset = 0;
    for (final index in chunkIndexes) {
      final offset = index - base;
      if (offset > maxOffset) {
        maxOffset = offset;
      }
    }
    final words = List<int>.filled(maxOffset ~/ 32 + 1, 0);
    for (final index in chunkIndexes) {
      final offset = index - base;
      words[offset ~/ 32] |= 1 << (offset % 32);
    }
    return words;
  }

  String _frameKey(Uint8List transferIdBytes) =>
      base64Url.encode(transferIdBytes);

  bool _isHighVolumeTransferPacket(AuthPacketType type) {
    return type == AuthPacketType.transferChunk ||
        type == AuthPacketType.transferChunkAck ||
        type == AuthPacketType.transferWindowUpdate;
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
    if (path.controlEndpoint.localAddress.trim().isEmpty ||
        path.candidate.remoteAddress.trim().isEmpty ||
        path.candidate.remotePort <= 0) {
      throw const AppException(
        code: 'transfer_active_route_invalid',
        message: '연결 경로의 endpoint 정보가 올바르지 않습니다.',
      );
    }
    if (_isLoopbackAddress(path.candidate.remoteAddress) &&
        !_isLoopbackAddress(session.peerAddress)) {
      throw const AppException(
        code: 'transfer_loopback_route_mismatch',
        message: '외부 피어 전송에는 loopback 경로를 사용할 수 없습니다.',
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
    mutations.select(observedPath);
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
    final candidates = <PeerRouteCandidate>[
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
    final observedCandidate = candidates.isEmpty
        ? _upsertObservedIncomingTransferCandidate(
            peerId: peerId,
            datagram: datagram,
            currentPath: currentPath,
          )
        : _upsertReachableIncomingTransferCandidate(candidates.first);
    return PeerPathSelectionPolicy()
        .select(candidates: [observedCandidate], selectedAt: _now())
        ?.path;
  }

  bool _matchesIncomingTransferRoute(
    PeerRouteCandidate candidate,
    ControlDatagram datagram,
  ) {
    if (candidate.remoteAddress != datagram.address.address ||
        candidate.remotePort != datagram.port) {
      return false;
    }
    final localEndpoint = datagram.localEndpoint;
    if (localEndpoint == null || localEndpoint.isWildcardBind) {
      return true;
    }
    return candidate.localAddress == localEndpoint.localAddress ||
        candidate.bindMode == UdpInterfaceBindMode.any;
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
    if (_sameAddress(
      remoteAddress.address,
      routeSnapshot.controlRemoteAddress,
    )) {
      return;
    }
    throw AppException(
      code: 'transfer_route_mismatch',
      message:
          'Data endpoint가 검증된 연결 경로와 다릅니다. '
          'route=${routeSnapshot.controlRemoteAddress}, '
          'data=${remoteAddress.address}',
    );
  }

  void _validateDataBindEndpoint({
    required TransferRouteSnapshot routeSnapshot,
    required UdpInterfaceEndpoint dataEndpoint,
  }) {
    if (dataEndpoint.isWildcardBind ||
        _isWildcardAddress(dataEndpoint.localAddress)) {
      return;
    }
    if (_sameAddress(
      dataEndpoint.localAddress,
      routeSnapshot.controlLocalAddress,
    )) {
      return;
    }
    throw AppException(
      code: 'transfer_data_bind_mismatch',
      message:
          'Data socket local address가 검증된 연결 경로와 다릅니다. '
          'route=${routeSnapshot.controlLocalAddress}, '
          'data=${dataEndpoint.localAddress}',
    );
  }

  bool _sameAddress(String left, String right) {
    return left.trim().toLowerCase() == right.trim().toLowerCase();
  }

  bool _isWildcardAddress(String address) {
    final normalized = address.trim().toLowerCase();
    return normalized == '0.0.0.0' ||
        normalized == '::' ||
        normalized == '0:0:0:0:0:0:0:0';
  }

  void _ensureRouteLeaseStillActive(_OutgoingTransferContext context) {
    final current = ref
        .read(peerPathRegistryProvider)
        .selectedForPeer(context.session.peerId);
    if (current?.pathId == context.routeSnapshot.routeLeaseId &&
        current?.status == PeerPathStatus.active) {
      return;
    }
    throw AppException(
      code: 'transfer_route_lease_expired',
      message:
          '전송 중 연결 경로가 만료되어 전송을 중단했습니다. '
          'route=${context.routeSnapshot.routeLeaseId}',
    );
  }

  bool _isLoopbackAddress(String address) {
    final normalized = address.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '::1' ||
        normalized.startsWith('127.');
  }

  String _endpointLabel(UdpInterfaceEndpoint? endpoint) {
    if (endpoint == null) {
      return 'any';
    }
    return '${endpoint.localAddress}:${endpoint.port}/${endpoint.bindMode.name}';
  }

  String _safeSession(String sessionId) {
    return sessionId.length <= 8 ? sessionId : sessionId.substring(0, 8);
  }

  String _safeTransfer(String? transferId) {
    if (transferId == null || transferId.isEmpty) {
      return '-';
    }
    return transferId.length <= 8 ? transferId : transferId.substring(0, 8);
  }

  String _safeFileNameForLog(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    final posixBase = trimmed.split('/').last;
    final basename = posixBase.split('\\').last;
    if (basename.length <= 80) {
      return basename;
    }
    return '${basename.substring(0, 77)}...';
  }

  DateTime _now() => ref.read(transferNowProvider)();

  String _eventId(String prefix) => '$prefix-${_now().microsecondsSinceEpoch}';

  String _currentUserId() {
    final user = ref.read(authControllerProvider).currentUser;
    if (user == null) {
      throw const AppException(
        code: 'transfer_no_session',
        message: '로그인 세션이 없어 전송할 수 없습니다.',
      );
    }
    return user.userId;
  }

  String _currentDisplayName() {
    final user = ref.read(authControllerProvider).currentUser;
    return user?.displayName ?? _currentUserId();
  }

  String _currentDeviceId() {
    final deviceId = _localIdentity?.deviceId;
    if (deviceId == null || deviceId.trim().isEmpty) {
      throw const AppException(
        code: 'transfer_local_device_missing',
        message: '로컬 장치 식별 정보를 찾지 못했습니다.',
      );
    }
    return deviceId;
  }

  String _currentInstanceId() {
    final instanceId = _localIdentity?.instanceId;
    if (instanceId == null || instanceId.trim().isEmpty) {
      throw const AppException(
        code: 'transfer_local_instance_missing',
        message: '로컬 실행 인스턴스 식별 정보를 찾지 못했습니다.',
      );
    }
    return instanceId;
  }

  String _peerIdFromPacket(AuthPacket packet) {
    final instanceId = packet.fromInstanceId;
    return '${packet.fromUserId}@${instanceId == null || instanceId.isEmpty ? packet.fromDeviceId : instanceId}';
  }

  String _randomHex(int bytes) {
    return List<int>.generate(
      bytes,
      (_) => _random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _dispose() async {
    await _packetSubscription?.cancel();
    await _dataFrameSubscription?.cancel();
    for (final context in _outgoingTransfers.values) {
      await context.dispose();
    }
    for (final context in _incomingTransfers.values) {
      await context.closeWriter();
    }
    _outgoingTransfers.clear();
    _incomingTransfers.clear();
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
