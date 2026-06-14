import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_rtt_estimator.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/app_storage_path_provider.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/settings_repository.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer/transfer_file_service.dart';

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
  static const int _chunkSize = 8 * 1024;
  static const Duration _initAckTimeout = Duration(seconds: 10);
  static const Duration _completeAckTimeout = Duration(seconds: 10);
  static const int _initialWindowSize = 4;
  static const int _maximumWindowSize = 24;
  static const int _receiverAdvertisedWindow = 24;
  static const int _maxRetransmissions = 6;
  static const int _maxNackIndexesPerPacket = 8;
  static const Duration _metricLogInterval = Duration(milliseconds: 700);

  bool _didInitialize = false;
  final Random _random = Random.secure();
  StreamSubscription<ControlDatagram>? _packetSubscription;
  LocalDeviceIdentity? _localIdentity;
  final Map<String, _OutgoingTransferContext> _outgoingTransfers = {};
  final Map<String, _IncomingTransferContext> _incomingTransfers = {};
  final Map<String, DateTime> _lastMetricLoggedAt = {};

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

  Future<void> sendFile({
    required String peerId,
    required String filePath,
  }) async {
    state = state.copyWith(clearError: true, clearInfo: true);

    try {
      final session = _requireAuthenticatedSession(peerId);
      final preparedFile = await ref
          .read(transferFileServiceProvider)
          .prepareOutgoingFile(filePath, chunkSize: _chunkSize);
      final transferId = _randomHex(12);
      final now = _now();
      final targetAddress = InternetAddress(session.peerAddress);
      final targetPort = session.peerPort;
      final controlEndpoint = _activeControlEndpointForPeer(peerId);
      final context = _OutgoingTransferContext(
        session: session,
        preparedFile: preparedFile,
        startedAt: now,
        windowSize: _initialWindowSize,
        remoteWindowStart: 0,
        advertisedWindowSize: _receiverAdvertisedWindow,
        rttEstimator: TransferRttEstimator(),
        controlEndpoint: controlEndpoint,
      );
      _outgoingTransfers[transferId] = context;
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.transferControl,
            'Starting outgoing transfer ${_safeTransfer(transferId)} '
            'peer=$peerId target=${targetAddress.address}:$targetPort '
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
          transferSha256: preparedFile.sha256,
          transferChunkCount: preparedFile.chunkCount,
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
        _onTransferCompleteAck(packet, datagram);
      case AuthPacketType.connectRequest:
      case AuthPacketType.authChallenge:
      case AuthPacketType.authToken:
      case AuthPacketType.authTokenAck:
      case AuthPacketType.authAccept:
      case AuthPacketType.authReject:
        return;
    }
  }

  Future<void> _runOutgoingTransfer(
    String transferId,
    _OutgoingTransferContext context,
  ) async {
    try {
      final initAck = await context.initAck.future.timeout(_initAckTimeout);
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
          message: 'ACK/NACK 기반 전송 세션을 시작합니다.',
          windowSize: context.windowSize,
        ),
      );

      await _pumpOutgoingWindow(transferId, context);
      await context.allChunksAcked.future;

      _updateJob(
        transferId,
        (job) => job.copyWith(
          status: TransferJobStatus.verifying,
          updatedAt: _now(),
          message: '모든 chunk ACK 를 수신했습니다. 완료 확인을 기다립니다.',
        ),
      );
      await _send(
        AuthPacket(
          type: AuthPacketType.transferComplete,
          protocolVersion: ref.read(appConfigProvider).protocolVersion,
          sessionId: context.session.sessionId,
          fromUserId: _currentUserId(),
          fromDeviceId: _currentDeviceId(),
          fromInstanceId: _currentInstanceId(),
          fromDisplayName: _currentDisplayName(),
          transferId: transferId,
          transferChunkCount: context.preparedFile.chunkCount,
          transferFileSize: context.preparedFile.fileSize,
          transferSha256: context.preparedFile.sha256,
          sentAtEpochMs: _now().millisecondsSinceEpoch,
        ),
        address: InternetAddress(context.session.peerAddress),
        port: context.session.peerPort,
        localEndpoint: context.controlEndpoint,
      );

      final completeAck = await context.completeAck.future.timeout(
        _completeAckTimeout,
      );
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
      current?.dispose();
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
        await _sendChunk(
          transferId,
          context,
          nextChunkIndex,
          isRetransmission: isRetransmission,
        );
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

  Future<void> _sendChunk(
    String transferId,
    _OutgoingTransferContext context,
    int chunkIndex, {
    required bool isRetransmission,
  }) async {
    final nextAttempts =
        (context.retransmissionAttempts[chunkIndex] ?? 0) +
        (isRetransmission ? 1 : 0);
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

    final bytes = await ref
        .read(transferFileServiceProvider)
        .readChunkAt(
          context.preparedFile.filePath,
          chunkSize: context.preparedFile.chunkSize,
          chunkIndex: chunkIndex,
        );
    final now = _now();
    context.inFlightChunks.add(chunkIndex);
    context.sentAtByChunk[chunkIndex] = now;
    context.scheduleTimer(
      chunkIndex,
      context.rttEstimator.currentTimeout,
      () => _onChunkTimeout(transferId, chunkIndex),
    );
    try {
      await _send(
        AuthPacket(
          type: AuthPacketType.transferChunk,
          protocolVersion: ref.read(appConfigProvider).protocolVersion,
          sessionId: context.session.sessionId,
          fromUserId: _currentUserId(),
          fromDeviceId: _currentDeviceId(),
          fromInstanceId: _currentInstanceId(),
          fromDisplayName: _currentDisplayName(),
          transferId: transferId,
          transferChunkIndex: chunkIndex,
          transferChunkDataBase64: base64Encode(bytes),
          sentAtEpochMs: now.millisecondsSinceEpoch,
        ),
        address: InternetAddress(context.session.peerAddress),
        port: context.session.peerPort,
        localEndpoint: context.controlEndpoint,
      );
    } catch (_) {
      context.inFlightChunks.remove(chunkIndex);
      context.sentAtByChunk.remove(chunkIndex);
      context.cancelTimer(chunkIndex);
      rethrow;
    }
    _updateOutgoingMetrics(
      transferId,
      context,
      message: isRetransmission
          ? 'chunk $chunkIndex 재전송 중'
          : 'window ${context.windowSize} 기준으로 전송 중',
    );
  }

  void _onChunkTimeout(String transferId, int chunkIndex) {
    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }
    if (context.acknowledgedChunks.contains(chunkIndex)) {
      context.inFlightChunks.remove(chunkIndex);
      context.cancelTimer(chunkIndex);
      return;
    }

    context.inFlightChunks.remove(chunkIndex);
    context.rttEstimator.noteTimeoutBackoff();
    context.windowSize = max(1, context.windowSize ~/ 2);
    context.queueRetransmission(chunkIndex);
    ref
        .read(appLoggerProvider)
        .warning(
          AppLogCategory.transferData,
          'Chunk timeout on transfer $transferId index $chunkIndex',
        );
    _updateOutgoingMetrics(
      transferId,
      context,
      message: 'chunk $chunkIndex timeout, 재전송 대기 중',
      important: true,
    );
    unawaited(_pumpOutgoingWindow(transferId, context));
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
        sha256 == null ||
        chunkCount == null) {
      return;
    }

    final peerId = _peerIdFromPacket(packet);
    ref
        .read(appLoggerProvider)
        .info(
          AppLogCategory.transferControl,
          'Received TRANSFER_INIT ${_safeTransfer(transferId)} '
          'peer=$peerId source=${datagram.address.address}:${datagram.port} '
          'local=${_endpointLabel(datagram.localEndpoint)} '
          'file=$fileName size=$fileSize chunks=$chunkCount',
        );
    final session = ref.read(peerAuthSessionByPeerIdProvider(peerId));
    if (session == null || !session.isAuthenticated) {
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

    try {
      final settings = await _loadSettings();
      final draft = await ref
          .read(transferFileServiceProvider)
          .createIncomingDraft(transferId: transferId, fileName: fileName);
      final now = _now();
      _incomingTransfers[transferId] = _IncomingTransferContext(
        sessionId: packet.sessionId,
        peerId: peerId,
        peerDisplayName: packet.fromDisplayName ?? packet.fromUserId,
        tempFilePath: draft.tempFilePath,
        fileName: fileName,
        fileSize: fileSize,
        expectedSha256: sha256,
        expectedChunkCount: chunkCount,
        saveDirectory: settings.defaultSavePath,
        startedAt: now,
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
        ),
      );

      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: true,
        savePath: settings.defaultSavePath,
        localEndpoint: datagram.localEndpoint,
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
      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: error.message,
        localEndpoint: datagram.localEndpoint,
      );
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .error(
            AppLogCategory.transferControl,
            'Failed to prepare incoming transfer',
            error: error,
            stackTrace: stackTrace,
          );
      await _sendTransferInitAck(
        sessionId: packet.sessionId,
        transferId: transferId,
        address: datagram.address,
        port: datagram.port,
        accepted: false,
        message: '수신 임시 파일을 준비하지 못했습니다.',
        localEndpoint: datagram.localEndpoint,
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
        await ref
            .read(transferFileServiceProvider)
            .appendChunk(tempFilePath: context.tempFilePath, bytes: bytes);
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
    context.cancelTimer(chunkIndex);
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
      context.cancelTimer(chunkIndex);
      context.queueRetransmission(chunkIndex);
    }
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

      if (context.acknowledgedChunks.length != context.expectedChunkCount) {
        throw const AppException(
          code: 'transfer_chunk_count_mismatch',
          message: '수신한 chunk 수가 예상과 다릅니다.',
        );
      }
      if (context.acknowledgedBytes != context.fileSize) {
        throw const AppException(
          code: 'transfer_size_mismatch',
          message: '수신한 파일 크기가 예상과 다릅니다.',
        );
      }

      final actualSha256 = await ref
          .read(transferFileServiceProvider)
          .computeSha256(context.tempFilePath);
      if (actualSha256 != context.expectedSha256) {
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
            transferredBytes: context.acknowledgedBytes,
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

  void _onTransferCompleteAck(AuthPacket packet, ControlDatagram datagram) {
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
  }

  Future<void> _sendTransferInitAck({
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
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: localEndpoint,
    );
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
        return;
      }
      await ref
          .read(transferFileServiceProvider)
          .appendChunk(tempFilePath: context.tempFilePath, bytes: bytes);
      context.nextExpectedChunk += 1;
    }
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

  int _receiverWindowSize(_IncomingTransferContext context) {
    return max(1, _receiverAdvertisedWindow - context.bufferedChunks.length);
  }

  Future<void> _failIncomingTransfer(String transferId, String message) async {
    final context = _incomingTransfers.remove(transferId);
    if (context != null) {
      await ref
          .read(transferFileServiceProvider)
          .discardDraft(context.tempFilePath);
    }
    _markFailed(transferId, message);
  }

  Future<void> _failOutgoingTransfer(String transferId, String message) async {
    final context = _outgoingTransfers[transferId];
    if (context == null || context.hasFailed) {
      return;
    }
    context.hasFailed = true;
    context.dispose();
    if (!context.allChunksAcked.isCompleted) {
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

  Future<AppSettings> _loadSettings() async {
    final defaultSavePath = await ref
        .read(appStoragePathProvider)
        .getDefaultReceivePath();
    return ref
        .read(settingsRepositoryProvider)
        .loadOrCreate(defaultSavePath: defaultSavePath);
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

  int _chunkByteLength(PreparedTransferFile file, int chunkIndex) {
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
      transferredBytes: context.acknowledgedBytes,
      startedAt: context.startedAt,
    );
    _updateJob(
      transferId,
      (job) => job.copyWith(
        status: TransferJobStatus.receiving,
        bytesTransferred: context.acknowledgedBytes,
        completedChunks: context.acknowledgedChunks.length,
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
          'incoming ${context.acknowledgedChunks.length}/${context.expectedChunkCount} '
          'buffered=${context.bufferedChunks.length} dup=${context.duplicateChunks} '
          'rate=${throughput.toStringAsFixed(0)}B/s '
          'window=${_receiverWindowSize(context)} note=$message',
      important: important,
    );
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
    if (packet.type != AuthPacketType.transferChunk) {
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.transferControl,
            'Sending ${packet.type.wireName} ${_safeTransfer(packet.transferId)} '
            'to ${address.address}:$port '
            'local=${_endpointLabel(localEndpoint)} '
            'session=${_safeSession(packet.sessionId)}',
          );
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

  UdpInterfaceEndpoint? _activeControlEndpointForPeer(String peerId) {
    final path = ref.read(peerPathRegistryProvider).selectedForPeer(peerId);
    if (path == null || path.status != PeerPathStatus.active) {
      return null;
    }
    return path.controlEndpoint;
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
    for (final context in _outgoingTransfers.values) {
      context.dispose();
    }
    _outgoingTransfers.clear();
    _incomingTransfers.clear();
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
    this.controlEndpoint,
  });

  final PeerAuthSession session;
  final PreparedTransferFile preparedFile;
  final DateTime startedAt;
  final TransferRttEstimator rttEstimator;
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
  final Map<int, Timer> retransmissionTimers = <int, Timer>{};
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
  bool hasFailed = false;
  bool isPumpActive = false;

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

  void scheduleTimer(
    int chunkIndex,
    Duration timeout,
    void Function() onTimeout,
  ) {
    cancelTimer(chunkIndex);
    retransmissionTimers[chunkIndex] = Timer(timeout, onTimeout);
  }

  void cancelTimer(int chunkIndex) {
    retransmissionTimers.remove(chunkIndex)?.cancel();
  }

  void dispose() {
    for (final timer in retransmissionTimers.values) {
      timer.cancel();
    }
    retransmissionTimers.clear();
    queuedRetransmissions.clear();
    queuedRetransmissionSet.clear();
  }
}

class _IncomingTransferContext {
  _IncomingTransferContext({
    required this.sessionId,
    required this.peerId,
    required this.peerDisplayName,
    required this.tempFilePath,
    required this.fileName,
    required this.fileSize,
    required this.expectedSha256,
    required this.expectedChunkCount,
    required this.saveDirectory,
    required this.startedAt,
  });

  final String sessionId;
  final String peerId;
  final String peerDisplayName;
  final String tempFilePath;
  final String fileName;
  final int fileSize;
  final String expectedSha256;
  final int expectedChunkCount;
  final String saveDirectory;
  final DateTime startedAt;
  final Set<int> acknowledgedChunks = <int>{};
  final Map<int, List<int>> bufferedChunks = <int, List<int>>{};
  int nextExpectedChunk = 0;
  int acknowledgedBytes = 0;
  int duplicateChunks = 0;
}

class _TransferInitAckResult {
  const _TransferInitAckResult({
    required this.accepted,
    this.message,
    this.savePath,
  });

  final bool accepted;
  final String? message;
  final String? savePath;
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
