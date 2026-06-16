import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/core/errors/app_exception.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/state_machine/state_machine.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/application/network/network_diagnostics_provider.dart';
import 'package:sponzey_file_sharing/application/network/peer_path_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/auth_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/jwt_token_service.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/shared_verifier_service.dart';
import 'package:sponzey_file_sharing/infrastructure/control/control_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';

import 'auth_controller.dart';

typedef AuthNow = DateTime Function();

class PeerAuthState {
  const PeerAuthState({
    required this.sessions,
    this.localPort,
    this.errorMessage,
    this.isListening = false,
    this.isLoading = false,
  });

  const PeerAuthState.initial()
    : sessions = const {},
      localPort = null,
      errorMessage = null,
      isListening = false,
      isLoading = true;

  final Map<String, PeerAuthSession> sessions;
  final int? localPort;
  final String? errorMessage;
  final bool isListening;
  final bool isLoading;

  PeerAuthState copyWith({
    Map<String, PeerAuthSession>? sessions,
    int? localPort,
    String? errorMessage,
    bool? isListening,
    bool? isLoading,
    bool clearError = false,
  }) {
    return PeerAuthState(
      sessions: sessions ?? this.sessions,
      localPort: localPort ?? this.localPort,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isListening: isListening ?? this.isListening,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PeerAuthController extends Notifier<PeerAuthState> {
  bool _didInitialize = false;
  bool _isStarting = false;
  final Random _random = Random.secure();
  final PeerAuthSessionStateMachine _authStateMachine =
      const PeerAuthSessionStateMachine();
  StreamSubscription<ControlDatagram>? _packetSubscription;
  LocalDeviceIdentity? _localIdentity;
  final Map<String, _HandshakeContext> _contexts = {};
  final Map<String, Timer> _timeouts = {};
  final Set<String> _usedJtis = {};

  @override
  PeerAuthState build() {
    ref.onDispose(() {
      unawaited(_dispose());
    });
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && !_isStarting && _packetSubscription == null) {
        unawaited(_initialize());
      }

      if (!next.isAuthenticated && _packetSubscription != null) {
        unawaited(_stop(clearSessions: true));
      }
    });

    if (!_didInitialize) {
      _didInitialize = true;
      unawaited(_initialize());
    }

    return const PeerAuthState.initial();
  }

  Future<void> saveAllowedPeer({
    required String userId,
    required String label,
    required String sharedPassword,
  }) async {
    state = state.copyWith(
      errorMessage: '허용 사용자 등록은 사용하지 않습니다. 연결 요청만 오면 인증됩니다.',
    );
  }

  Future<void> removeAllowedPeer(String userId) async {
    state = state.copyWith(
      errorMessage: '허용 사용자 등록은 사용하지 않습니다. 연결 요청만 오면 인증됩니다.',
    );
  }

  Future<void> startHandshake(
    PeerNode peer, {
    PeerConnectionPath? selectedPath,
    bool restartAuthenticatedSession = false,
  }) async {
    final existingSession = state.sessions[peer.id];
    if (existingSession?.isAuthenticated == true &&
        !restartAuthenticatedSession) {
      return;
    }
    if (restartAuthenticatedSession) {
      _cancelContextsForPeer(peer.id);
    }
    if (_contexts.values.any((context) => context.peerId == peer.id)) {
      return;
    }

    if (!_canAuthenticate()) {
      state = state.copyWith(errorMessage: '로그인 세션이 준비되지 않았습니다.');
      return;
    }

    await ensureListening();

    final user = _currentUser();
    final localIdentity = _localIdentity;
    if (user == null || localIdentity == null) {
      state = state.copyWith(errorMessage: '로컬 인증 엔진이 준비되지 않았습니다.');
      return;
    }

    final sessionId = _randomHex(12);
    final context = _HandshakeContext(
      sessionId: sessionId,
      peerId: peer.id,
      peerUserId: peer.userId,
      peerDisplayName: peer.displayName,
      peerAddress: peer.address,
      peerPort: peer.port,
      selectedPathId: selectedPath?.pathId,
      selectedCandidateId: selectedPath?.candidate.candidateId,
      selectedLocalEndpoint: selectedPath?.controlEndpoint,
      initiatedByMe: true,
    );
    _contexts[sessionId] = context;
    if (selectedPath != null) {
      _selectPathForAuth(selectedPath);
    }
    _cancelTimeout(sessionId);
    _timeouts[sessionId] = Timer(
      ref.read(appConfigProvider).authHandshakeTimeout,
      () => _onHandshakeTimeout(sessionId),
    );

    final initialSession = PeerAuthSession(
      sessionId: sessionId,
      peerId: peer.id,
      peerUserId: peer.userId,
      peerDisplayName: peer.displayName,
      peerAddress: peer.address,
      peerPort: peer.port,
      status: PeerAuthStatus.idle,
      updatedAt: _now(),
    );
    _upsertSession(
      peer.id,
      _transitionAuthSession(
        initialSession,
        PeerAuthEvent.connectStarted,
        message: '상대 피어와 경로를 협상하는 중입니다.',
      ),
    );

    try {
      await _send(
        AuthPacket(
          type: AuthPacketType.connectRequest,
          protocolVersion: ref.read(appConfigProvider).protocolVersion,
          sessionId: sessionId,
          fromUserId: user.userId,
          fromDeviceId: localIdentity.deviceId,
          fromInstanceId: localIdentity.instanceId,
          fromDisplayName: user.displayName,
          sentAtEpochMs: _now().millisecondsSinceEpoch,
        ),
        address: InternetAddress(
          selectedPath?.candidate.remoteAddress ?? peer.address,
        ),
        port: selectedPath?.candidate.remotePort ?? peer.port,
        localEndpoint: selectedPath?.controlEndpoint,
      );
    } on ControlTransportBindException catch (error) {
      _contexts.remove(sessionId);
      _cancelTimeout(sessionId);
      _failSelectedPath(context, reasonCode: error.reasonCode);
      _upsertSession(
        peer.id,
        _requireSession(peer.id).copyWith(
          status: PeerAuthStatus.failed,
          message: error.reasonCode,
          updatedAt: _now(),
        ),
      );
    }
  }

  Future<int?> ensureListening() async {
    if (_packetSubscription == null && !_isStarting) {
      await _initialize();
    }

    for (var i = 0; i < 50; i += 1) {
      final current = state;
      if (current.isListening && current.localPort != null) {
        return current.localPort;
      }
      if (!_isStarting) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    return state.localPort;
  }

  void syncDiscoveredPeer(PeerNode peer, {String? message}) {
    final existing = state.sessions[peer.id];
    if (existing?.isAuthenticated == true) {
      if (existing!.peerAddress != peer.address ||
          existing.peerPort != peer.port) {
        ref
            .read(appLoggerProvider)
            .debug(
              AppLogCategory.auth,
              'Preserved authenticated peer route for ${peer.id}: '
              '${existing.peerAddress}:${existing.peerPort}; '
              'ignored discovery endpoint ${peer.address}:${peer.port}',
            );
      }
      _upsertSession(
        peer.id,
        existing.copyWith(
          peerUserId: peer.userId,
          peerDisplayName: peer.displayName,
          updatedAt: _now(),
          message: message,
        ),
      );
      return;
    }

    if (existing != null && _isHandshakeInProgress(existing.status)) {
      if (existing.peerAddress != peer.address ||
          existing.peerPort != peer.port) {
        ref
            .read(appLoggerProvider)
            .debug(
              AppLogCategory.auth,
              'Preserved in-progress peer handshake route for ${peer.id}: '
              '${existing.peerAddress}:${existing.peerPort}; '
              'ignored discovery endpoint ${peer.address}:${peer.port}',
            );
      }
      _upsertSession(
        peer.id,
        existing.copyWith(
          peerUserId: peer.userId,
          peerDisplayName: peer.displayName,
          updatedAt: _now(),
        ),
      );
      return;
    }

    if (existing != null &&
        existing.peerAddress == peer.address &&
        existing.peerPort == peer.port &&
        existing.peerDisplayName == peer.displayName &&
        existing.status != PeerAuthStatus.failed &&
        existing.status != PeerAuthStatus.rejected &&
        (message == null || existing.message == message)) {
      return;
    }

    _upsertSession(
      peer.id,
      PeerAuthSession(
        sessionId: existing?.sessionId.isNotEmpty == true
            ? existing!.sessionId
            : _randomHex(12),
        peerId: peer.id,
        peerUserId: peer.userId,
        peerDisplayName: peer.displayName,
        peerAddress: peer.address,
        peerPort: peer.port,
        status: existing?.status == PeerAuthStatus.authenticated
            ? PeerAuthStatus.authenticated
            : PeerAuthStatus.idle,
        message: message,
        updatedAt: _now(),
      ),
    );
  }

  void failInProgressHandshakeForPeer({
    required String peerId,
    required String reasonCode,
    bool markCandidateFailed = true,
  }) {
    final matchingContexts = _contexts.values
        .where((context) => context.peerId == peerId)
        .toList(growable: false);
    for (final context in matchingContexts) {
      _contexts.remove(context.sessionId);
      _cancelTimeout(context.sessionId);
      _failSelectedPath(
        context,
        reasonCode: reasonCode,
        markCandidateFailed: markCandidateFailed,
      );
    }

    final session = state.sessions[peerId];
    if (session == null || !_isHandshakeInProgress(session.status)) {
      return;
    }
    _upsertSession(
      peerId,
      session.copyWith(
        status: PeerAuthStatus.failed,
        message: reasonCode,
        updatedAt: _now(),
      ),
    );
  }

  void syncPeerPresence(List<PeerNode> peers) {
    final peersById = {for (final peer in peers) peer.id: peer};
    final nextSessions = <String, PeerAuthSession>{};

    for (final entry in state.sessions.entries) {
      final peer = peersById[entry.key];
      if (peer == null) {
        if (_isHandshakeInProgress(entry.value.status)) {
          nextSessions[entry.key] = entry.value.copyWith(updatedAt: _now());
          continue;
        }
        _clearPeerPathAndContexts(entry.key);
        continue;
      }

      if (peer.presence == PeerPresence.offline ||
          peer.presence == PeerPresence.incompatible) {
        _clearPeerPathAndContexts(entry.key);
        continue;
      }

      if (peer.presence == PeerPresence.stale) {
        if (_isHandshakeInProgress(entry.value.status)) {
          nextSessions[entry.key] = entry.value.copyWith(updatedAt: _now());
          continue;
        }
        _clearPeerPathAndContexts(entry.key);
        nextSessions[entry.key] = entry.value.copyWith(
          status: PeerAuthStatus.idle,
          peerAddress: peer.address,
          peerPort: peer.port,
          updatedAt: _now(),
          message: '피어 응답을 다시 기다리는 중입니다.',
        );
        continue;
      }

      if (entry.value.isAuthenticated) {
        if (entry.value.peerAddress != peer.address ||
            entry.value.peerPort != peer.port) {
          ref
              .read(appLoggerProvider)
              .debug(
                AppLogCategory.auth,
                'Preserved authenticated peer route for ${entry.key}: '
                '${entry.value.peerAddress}:${entry.value.peerPort}; '
                'ignored presence endpoint ${peer.address}:${peer.port}',
              );
        }
        nextSessions[entry.key] = entry.value.copyWith(updatedAt: _now());
        continue;
      }

      nextSessions[entry.key] = entry.value.copyWith(
        peerAddress: peer.address,
        peerPort: peer.port,
        updatedAt: _now(),
      );
    }

    if (_sameSessionMap(state.sessions, nextSessions)) {
      return;
    }

    state = state.copyWith(sessions: nextSessions, clearError: true);
  }

  Future<void> _initialize() async {
    if (_isStarting) {
      return;
    }

    final logger = ref.read(appLoggerProvider);
    _isStarting = true;
    try {
      if (!_canAuthenticate()) {
        state = const PeerAuthState(
          sessions: <String, PeerAuthSession>{},
          isLoading: false,
          isListening: false,
        );
        return;
      }

      _localIdentity = await ref
          .read(localDeviceIdentityServiceProvider)
          .load();

      final localPort = await ref
          .read(controlTransportProvider)
          .start(preferredPort: ref.read(appConfigProvider).authPort);
      _packetSubscription = ref.read(controlTransportProvider).packets.listen((
        datagram,
      ) {
        unawaited(_handleDatagram(datagram));
      });

      state = PeerAuthState(
        sessions: state.sessions,
        localPort: localPort,
        isListening: true,
        isLoading: false,
      );
      logger.info(
        AppLogCategory.auth,
        'Peer auth controller started on UDP $localPort',
      );
    } catch (error, stackTrace) {
      logger.error(
        AppLogCategory.auth,
        'Failed to initialize peer auth controller',
        error: error,
        stackTrace: stackTrace,
      );
      state = PeerAuthState(
        sessions: state.sessions,
        localPort: state.localPort,
        isLoading: false,
        isListening: false,
        errorMessage: '인증 엔진을 시작하지 못했습니다.',
      );
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _handleDatagram(ControlDatagram datagram) async {
    final packet = datagram.packet;
    switch (packet.type) {
      case AuthPacketType.connectRequest:
        await _onConnectRequest(packet, datagram);
      case AuthPacketType.authChallenge:
        await _onAuthChallenge(packet, datagram);
      case AuthPacketType.authToken:
        await _onAuthToken(packet, datagram);
      case AuthPacketType.authTokenAck:
        await _onAuthTokenAck(packet, datagram);
      case AuthPacketType.authAccept:
        await _onAuthAccept(packet, datagram);
      case AuthPacketType.authReject:
        await _onAuthReject(packet);
      case AuthPacketType.transferInit:
      case AuthPacketType.transferInitAck:
      case AuthPacketType.transferChunk:
      case AuthPacketType.transferChunkAck:
      case AuthPacketType.transferChunkNack:
      case AuthPacketType.transferWindowUpdate:
      case AuthPacketType.transferComplete:
      case AuthPacketType.transferCompleteAck:
        return;
    }
  }

  Future<void> _onConnectRequest(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final user = _currentUser();
    final localIdentity = _localIdentity;
    if (user == null || localIdentity == null) {
      return;
    }

    if (_isPacketFromLocalIdentity(packet, localIdentity)) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.auth,
            'Ignored self connect request session=${_safeSession(packet.sessionId)}',
          );
      return;
    }

    final peerId = _peerIdFromPacket(packet);
    final existingSession = state.sessions[peerId];
    final selectedAuthenticatedPath = existingSession?.isAuthenticated == true
        ? _selectedPathForPeer(peerId)
        : null;
    final preserveAuthenticatedSession =
        existingSession?.isAuthenticated == true &&
        selectedAuthenticatedPath?.status == PeerPathStatus.active;
    if (existingSession?.isAuthenticated == true) {
      if (preserveAuthenticatedSession) {
        ref
            .read(appLoggerProvider)
            .debug(
              AppLogCategory.auth,
              'Answered connect request for authenticated peer route refresh '
              'without downgrading session peer=$peerId '
              'session=${_safeSession(packet.sessionId)} '
              'pathStatus=${selectedAuthenticatedPath!.status.name}',
            );
      } else {
        ref
            .read(appLoggerProvider)
            .debug(
              AppLogCategory.auth,
              'Accepted connect request for authenticated peer route refresh '
              'peer=$peerId session=${_safeSession(packet.sessionId)} '
              'pathStatus=${selectedAuthenticatedPath?.status.name ?? 'missing'}',
            );
      }
    }

    final duplicateContext = _contexts[packet.sessionId];
    if (duplicateContext != null) {
      await _sendChallenge(duplicateContext, address: datagram.address);
      return;
    }

    final inProgressForPeer = _inProgressContextForPeer(peerId);
    if (inProgressForPeer != null) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.auth,
            'Ignored parallel connect request for $peerId '
            'current=${_safeSession(inProgressForPeer.sessionId)} '
            'incoming=${_safeSession(packet.sessionId)}',
          );
      return;
    }

    final selectedPath = preserveAuthenticatedSession
        ? selectedAuthenticatedPath
        : _selectObservedPathForIncomingHandshake(
            peerId: peerId,
            datagram: datagram,
          );
    final context = _HandshakeContext(
      sessionId: packet.sessionId,
      peerId: peerId,
      peerUserId: packet.fromUserId,
      peerDisplayName: packet.fromDisplayName ?? packet.fromUserId,
      peerAddress: datagram.address.address,
      peerPort: datagram.port,
      initiatedByMe: false,
      selectedPathId: selectedPath?.pathId,
      selectedCandidateId: preserveAuthenticatedSession
          ? null
          : selectedPath?.candidate.candidateId,
      selectedLocalEndpoint: datagram.localEndpoint,
      nonce: _randomHex(16),
      preserveAuthenticatedSession: preserveAuthenticatedSession,
    );
    _contexts[packet.sessionId] = context;
    _cancelTimeout(packet.sessionId);
    _timeouts[packet.sessionId] = Timer(
      ref.read(appConfigProvider).authHandshakeTimeout,
      () => _onHandshakeTimeout(packet.sessionId),
    );
    if (!preserveAuthenticatedSession) {
      _upsertSession(
        context.peerId,
        _transitionAuthSession(
          PeerAuthSession(
            sessionId: packet.sessionId,
            peerId: context.peerId,
            peerUserId: packet.fromUserId,
            peerDisplayName: context.peerDisplayName,
            peerAddress: datagram.address.address,
            peerPort: datagram.port,
            status: PeerAuthStatus.idle,
            updatedAt: _now(),
          ),
          PeerAuthEvent.challengeIssued,
          message: '인증 challenge를 발급했습니다.',
        ),
      );
    }

    await _sendChallenge(context, address: datagram.address);
  }

  Future<void> _onAuthChallenge(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final context = _contexts[packet.sessionId];
    final user = _currentUser();
    final localIdentity = _localIdentity;
    final password = _currentPassword();
    final nonce = packet.nonce;
    if (context == null ||
        user == null ||
        localIdentity == null ||
        password == null ||
        nonce == null) {
      return;
    }

    try {
      context.peerAddress = datagram.address.address;
      context.peerPort = datagram.port;
      context.nonce = nonce;
      final verifier = ref
          .read(sharedVerifierServiceProvider)
          .deriveVerifierBase64(userId: user.userId, password: password);
      final signingKey = ref
          .read(sharedVerifierServiceProvider)
          .deriveSigningKey(
            verifierBase64: verifier,
            sessionId: packet.sessionId,
            nonce: nonce,
            subjectUserId: user.userId,
            peerUserId: packet.fromUserId,
          );
      final now = _now();
      final config = ref.read(appConfigProvider);
      final token = ref
          .read(jwtTokenServiceProvider)
          .createToken(
            claims: AuthJwtClaims(
              subjectUserId: user.userId,
              deviceId: localIdentity.deviceId,
              peerUserId: packet.fromUserId,
              nonce: nonce,
              issuedAtEpochSec: _epochSec(now),
              expiresAtEpochSec: _epochSec(now.add(config.authTokenLifetime)),
              jti: _randomHex(16),
              protocolVersion: config.protocolVersion,
              sessionId: packet.sessionId,
            ),
            signingKey: signingKey,
          );
      _upsertSession(
        context.peerId,
        _transitionAuthSession(
          _requireSession(context.peerId),
          PeerAuthEvent.tokenSent,
          peerAddress: datagram.address.address,
          peerPort: datagram.port,
          message: '인증 token을 전송했습니다.',
        ),
      );
      await _send(
        AuthPacket(
          type: AuthPacketType.authToken,
          protocolVersion: config.protocolVersion,
          sessionId: packet.sessionId,
          fromUserId: user.userId,
          fromDeviceId: localIdentity.deviceId,
          fromInstanceId: localIdentity.instanceId,
          fromDisplayName: user.displayName,
          token: token,
          sentAtEpochMs: now.millisecondsSinceEpoch,
        ),
        address: datagram.address,
        port: datagram.port,
        localEndpoint: context.selectedLocalEndpoint,
      );
    } on AppException catch (error) {
      await _rejectHandshake(
        context,
        address: datagram.address,
        port: datagram.port,
        reasonCode: error.code,
        message: error.message,
      );
    }
  }

  Future<void> _onAuthToken(AuthPacket packet, ControlDatagram datagram) async {
    final context = _contexts[packet.sessionId];
    final user = _currentUser();
    final localIdentity = _localIdentity;
    final password = _currentPassword();
    final token = packet.token;
    if (context == null ||
        user == null ||
        localIdentity == null ||
        password == null ||
        token == null ||
        context.nonce == null) {
      return;
    }

    if (!context.preserveAuthenticatedSession) {
      _upsertSession(
        context.peerId,
        _transitionAuthSession(
          _requireSession(context.peerId),
          PeerAuthEvent.tokenVerificationStarted,
          peerAddress: datagram.address.address,
          peerPort: datagram.port,
          message: '인증 token을 검증하는 중입니다.',
        ),
      );
    }

    try {
      final verifier = ref
          .read(sharedVerifierServiceProvider)
          .deriveVerifierBase64(userId: user.userId, password: password);
      final signingKey = ref
          .read(sharedVerifierServiceProvider)
          .deriveSigningKey(
            verifierBase64: verifier,
            sessionId: packet.sessionId,
            nonce: context.nonce!,
            subjectUserId: packet.fromUserId,
            peerUserId: user.userId,
          );
      final config = ref.read(appConfigProvider);
      final result = ref
          .read(jwtTokenServiceProvider)
          .validate(
            AuthJwtValidationRequest(
              token: token,
              signingKey: signingKey,
              expectedPeerUserId: user.userId,
              expectedNonce: context.nonce!,
              expectedProtocolVersion: config.protocolVersion,
              expectedSessionId: packet.sessionId,
              nowEpochSec: _epochSec(_now()),
              allowedClockSkewSec: config.authAllowedClockSkew.inSeconds,
              isReplayJti: _usedJtis.contains,
            ),
          );
      _usedJtis.add(result.claims.jti);
      _contexts.remove(packet.sessionId);
      _markAuthenticated(
        context,
        peerAddress: datagram.address.address,
        peerPort: datagram.port,
        message: 'JWT challenge/response 인증이 완료되었습니다.',
      );
      await _send(
        AuthPacket(
          type: AuthPacketType.authAccept,
          protocolVersion: config.protocolVersion,
          sessionId: packet.sessionId,
          fromUserId: user.userId,
          fromDeviceId: localIdentity.deviceId,
          fromInstanceId: localIdentity.instanceId,
          fromDisplayName: user.displayName,
          sentAtEpochMs: _now().millisecondsSinceEpoch,
        ),
        address: datagram.address,
        port: datagram.port,
        localEndpoint: context.selectedLocalEndpoint,
      );
    } on AppException catch (error) {
      await _rejectHandshake(
        context,
        address: datagram.address,
        port: datagram.port,
        reasonCode: error.code,
        message: error.message,
      );
    }
  }

  Future<void> _onAuthTokenAck(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {}

  Future<void> _onAuthAccept(
    AuthPacket packet,
    ControlDatagram datagram,
  ) async {
    final context = _contexts.remove(packet.sessionId);
    if (context == null) {
      return;
    }
    _markAuthenticated(
      context,
      peerAddress: datagram.address.address,
      peerPort: datagram.port,
      message: '핸드셰이크에서 상대 경로를 확인했습니다.',
    );
  }

  Future<void> _onAuthReject(AuthPacket packet) async {
    final context = _contexts.remove(packet.sessionId);
    if (context == null) {
      return;
    }
    _cancelTimeout(packet.sessionId);
    if (context.preserveAuthenticatedSession) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.auth,
            'Ignored auth reject for preserved authenticated peer '
            '${context.peerId} session=${_safeSession(packet.sessionId)}',
          );
      return;
    }
    _failSelectedPath(
      context,
      reasonCode: packet.rejectCode ?? packet.rejectMessage ?? 'authRejected',
    );
    _upsertSession(
      context.peerId,
      _transitionAuthSession(
        _requireSession(context.peerId),
        PeerAuthEvent.authRejected,
        message: packet.rejectMessage ?? '상대가 인증을 거절했습니다.',
      ),
    );
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

  Future<void> _sendChallenge(
    _HandshakeContext context, {
    required InternetAddress address,
  }) async {
    final user = _currentUser();
    final localIdentity = _localIdentity;
    final nonce = context.nonce;
    if (user == null || localIdentity == null || nonce == null) {
      return;
    }
    await _send(
      AuthPacket(
        type: AuthPacketType.authChallenge,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: context.sessionId,
        fromUserId: user.userId,
        fromDeviceId: localIdentity.deviceId,
        fromInstanceId: localIdentity.instanceId,
        fromDisplayName: user.displayName,
        nonce: nonce,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: context.peerPort,
      localEndpoint: context.selectedLocalEndpoint,
    );
  }

  String _peerIdFromPacket(AuthPacket packet) {
    final instanceId = packet.fromInstanceId;
    return '${packet.fromUserId}@${instanceId == null || instanceId.isEmpty ? packet.fromDeviceId : instanceId}';
  }

  bool _isPacketFromLocalIdentity(
    AuthPacket packet,
    LocalDeviceIdentity localIdentity,
  ) {
    final packetInstanceId = packet.fromInstanceId;
    if (packetInstanceId != null && packetInstanceId.isNotEmpty) {
      return packetInstanceId == localIdentity.instanceId;
    }
    return packet.fromDeviceId == localIdentity.deviceId;
  }

  PeerConnectionPath? _selectedPathForPeer(String peerId) {
    return ref.read(peerPathRegistryProvider).selectedForPeer(peerId);
  }

  _HandshakeContext? _inProgressContextForPeer(String peerId) {
    for (final context in _contexts.values) {
      if (context.peerId == peerId) {
        return context;
      }
    }
    return null;
  }

  PeerConnectionPath? _selectObservedPathForIncomingHandshake({
    required String peerId,
    required ControlDatagram datagram,
  }) {
    final path = _pathFromObservedCandidate(peerId: peerId, datagram: datagram);
    if (path == null) {
      return null;
    }
    _selectPathForAuth(path);
    return ref.read(peerPathRegistryProvider).selectedForPeer(peerId);
  }

  PeerConnectionPath? _pathFromObservedCandidate({
    required String peerId,
    required ControlDatagram datagram,
  }) {
    final candidates = ref
        .read(peerRouteCandidateStoreProvider)
        .where((candidate) => candidate.peerId == peerId)
        .toList(growable: false);
    final observed = candidates
        .where(
          (candidate) =>
              candidate.remoteAddress == datagram.address.address &&
              candidate.remotePort == datagram.port,
        )
        .toList(growable: false);
    final localEndpoint = datagram.localEndpoint;
    final localMatched =
        localEndpoint == null || localEndpoint.localAddress == '0.0.0.0'
        ? observed
        : observed
              .where(
                (candidate) =>
                    candidate.localAddress == localEndpoint.localAddress,
              )
              .toList(growable: false);
    final selectable = localMatched.isNotEmpty ? localMatched : observed;
    final candidate = selectable.isNotEmpty
        ? PeerPathSelectionPolicy()
              .select(candidates: selectable, selectedAt: _now())
              ?.path
              .candidate
        : _upsertObservedControlCandidate(peerId: peerId, datagram: datagram);
    if (candidate == null) {
      return null;
    }
    return PeerPathSelectionPolicy()
        .select(candidates: [candidate], selectedAt: _now())
        ?.path;
  }

  PeerRouteCandidate _upsertObservedControlCandidate({
    required String peerId,
    required ControlDatagram datagram,
  }) {
    final endpoint = datagram.localEndpoint;
    final localAddress = endpoint?.localAddress ?? '0.0.0.0';
    final interfaceId =
        endpoint?.interfaceId ??
        const NetworkInterfaceId(
          name: 'observed-control',
          index: -2,
          stableId: 'observed-control',
        );
    final bindMode = endpoint?.bindMode ?? UdpInterfaceBindMode.any;
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

  Future<void> _rejectHandshake(
    _HandshakeContext context, {
    required InternetAddress address,
    required int port,
    required String reasonCode,
    required String message,
  }) async {
    _contexts.remove(context.sessionId);
    _cancelTimeout(context.sessionId);
    if (!context.preserveAuthenticatedSession) {
      _upsertSession(
        context.peerId,
        _transitionAuthSession(
          _requireSession(context.peerId),
          PeerAuthEvent.authRejected,
          message: message,
        ),
      );
    }
    final user = _currentUser();
    final localIdentity = _localIdentity;
    if (user == null || localIdentity == null) {
      return;
    }
    await _send(
      AuthPacket(
        type: AuthPacketType.authReject,
        protocolVersion: ref.read(appConfigProvider).protocolVersion,
        sessionId: context.sessionId,
        fromUserId: user.userId,
        fromDeviceId: localIdentity.deviceId,
        fromInstanceId: localIdentity.instanceId,
        fromDisplayName: user.displayName,
        rejectCode: reasonCode,
        rejectMessage: message,
        sentAtEpochMs: _now().millisecondsSinceEpoch,
      ),
      address: address,
      port: port,
      localEndpoint: context.selectedLocalEndpoint,
    );
  }

  void _selectPathForAuth(PeerConnectionPath path) {
    final mutations = ref.read(peerPathRegistryMutationsProvider);
    mutations.select(path);
    mutations.applyEvent(peerId: path.peerId, event: PeerPathEvent.authStarted);
  }

  void _markAuthenticated(
    _HandshakeContext context, {
    String? peerAddress,
    int? peerPort,
    String? message,
  }) {
    final peerId = context.peerId;
    final session = _requireSession(peerId);
    _cancelTimeout(context.sessionId);
    _upsertSession(
      peerId,
      _transitionAuthSession(
        session,
        PeerAuthEvent.authSucceeded,
        peerAddress: peerAddress,
        peerPort: peerPort,
        message: message,
        clearMessage: message == null,
      ),
    );
    _applySelectedPathEvent(context, PeerPathEvent.authSucceeded);
  }

  void _onHandshakeTimeout(String sessionId) {
    final context = _contexts.remove(sessionId);
    if (context == null) {
      return;
    }
    _timeouts.remove(sessionId)?.cancel();
    if (context.preserveAuthenticatedSession) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.auth,
            'Preserved authenticated peer after route refresh timeout '
            'peer=${context.peerId} session=${_safeSession(sessionId)}',
          );
      return;
    }
    _failSelectedPath(context, reasonCode: 'handshakeTimeout');
    _upsertSession(
      context.peerId,
      _transitionAuthSession(
        _requireSession(context.peerId),
        PeerAuthEvent.authFailed,
        message: '피어 핸드셰이크 응답 시간이 초과되었습니다.',
      ),
    );
  }

  void _applySelectedPathEvent(
    _HandshakeContext context,
    PeerPathEvent event, {
    String? reasonCode,
  }) {
    if (context.selectedPathId == null) {
      return;
    }
    ref
        .read(peerPathRegistryMutationsProvider)
        .applyEvent(
          peerId: context.peerId,
          event: event,
          reasonCode: reasonCode,
        );
  }

  void _failSelectedPath(
    _HandshakeContext context, {
    required String reasonCode,
    bool markCandidateFailed = true,
  }) {
    if (markCandidateFailed && context.selectedCandidateId != null) {
      ref
          .read(peerRouteCandidateProjectionProvider.notifier)
          .markCandidateFailed(
            candidateId: context.selectedCandidateId!,
            now: _now(),
          );
    }
    if (context.selectedPathId == null) {
      return;
    }
    final result = ref
        .read(peerPathRegistryMutationsProvider)
        .applyEvent(
          peerId: context.peerId,
          event: PeerPathEvent.authFailed,
          reasonCode: reasonCode,
        );
    if (result == null) {
      ref
          .read(peerPathRegistryMutationsProvider)
          .markFailed(peerId: context.peerId, reasonCode: reasonCode);
    }
  }

  void _clearPeerPathAndContexts(String peerId) {
    ref.read(peerPathRegistryMutationsProvider).clear(peerId);
    _cancelContextsForPeer(peerId);
  }

  void _cancelContextsForPeer(String peerId) {
    final sessionIds = _contexts.entries
        .where((entry) => entry.value.peerId == peerId)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final sessionId in sessionIds) {
      _contexts.remove(sessionId);
      _cancelTimeout(sessionId);
    }
  }

  void _cancelTimeout(String sessionId) {
    _timeouts.remove(sessionId)?.cancel();
  }

  void _upsertSession(String peerId, PeerAuthSession nextSession) {
    final previous = state.sessions[peerId];
    state = state.copyWith(
      sessions: {...state.sessions, peerId: nextSession},
      clearError: true,
    );
    if (previous?.sessionId == nextSession.sessionId &&
        previous?.status == nextSession.status &&
        previous?.message == nextSession.message) {
      return;
    }
    ref
        .read(messageBusProvider)
        .publish(
          PeerLinkAppEvent(
            eventId: _eventId('peer-link-${nextSession.status.name}'),
            occurredAt: _now(),
            correlationId: nextSession.sessionId.isEmpty
                ? peerId
                : nextSession.sessionId,
            source: 'PeerAuthController',
            severity: nextSession.status == PeerAuthStatus.authenticated
                ? AppEventSeverity.debug
                : AppEventSeverity.product,
            eventType: 'peerLink${nextSession.status.name}',
            peerId: peerId,
            sessionId: nextSession.sessionId.isEmpty
                ? null
                : nextSession.sessionId,
            reasonCode:
                nextSession.status == PeerAuthStatus.failed ||
                    nextSession.status == PeerAuthStatus.rejected
                ? nextSession.message
                : null,
          ),
        );
  }

  PeerAuthSession _transitionAuthSession(
    PeerAuthSession session,
    PeerAuthEvent event, {
    String? peerAddress,
    int? peerPort,
    String? message,
    bool clearMessage = false,
  }) {
    final result = _authStateMachine.transition(session, event);
    if (result.disposition == TransitionDisposition.warning) {
      ref
          .read(appLoggerProvider)
          .debug(
            AppLogCategory.auth,
            'Peer auth transition warning peer=${session.peerId} '
            'session=${_safeSession(session.sessionId)} '
            'event=${event.name} status=${session.status.name} '
            'code=${result.issue?.code ?? '-'}',
          );
    }
    return result.state.copyWith(
      peerAddress: peerAddress,
      peerPort: peerPort,
      updatedAt: _now(),
      message: message,
      clearMessage: clearMessage,
    );
  }

  bool _sameSessionMap(
    Map<String, PeerAuthSession> current,
    Map<String, PeerAuthSession> next,
  ) {
    if (identical(current, next)) {
      return true;
    }
    if (current.length != next.length) {
      return false;
    }
    for (final entry in current.entries) {
      final other = next[entry.key];
      if (other == null) {
        return false;
      }
      if (entry.value.sessionId != other.sessionId ||
          entry.value.peerAddress != other.peerAddress ||
          entry.value.peerPort != other.peerPort ||
          entry.value.status != other.status ||
          entry.value.message != other.message) {
        return false;
      }
    }
    return true;
  }

  PeerAuthSession _requireSession(String peerId) {
    return state.sessions[peerId] ??
        PeerAuthSession(
          sessionId: '',
          peerId: peerId,
          peerUserId: peerId.split('@').first,
          peerDisplayName: peerId,
          peerAddress: '127.0.0.1',
          peerPort: ref.read(appConfigProvider).authPort,
          status: PeerAuthStatus.idle,
          updatedAt: _now(),
        );
  }

  UserAccount? _currentUser() => ref.read(authControllerProvider).currentUser;

  String? _currentPassword() =>
      ref.read(authControllerProvider).sessionPassword;

  DateTime _now() => ref.read(authNowProvider)();

  int _epochSec(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

  String _eventId(String prefix) => '$prefix-${_now().microsecondsSinceEpoch}';

  String _safeSession(String sessionId) {
    return sessionId.length <= 8 ? sessionId : sessionId.substring(0, 8);
  }

  bool _canAuthenticate() {
    final authState = ref.read(authControllerProvider);
    return authState.isAuthenticated && authState.currentUser != null;
  }

  bool _isHandshakeInProgress(PeerAuthStatus status) {
    switch (status) {
      case PeerAuthStatus.connecting:
      case PeerAuthStatus.challengeIssued:
      case PeerAuthStatus.tokenSent:
      case PeerAuthStatus.verifying:
        return true;
      case PeerAuthStatus.idle:
      case PeerAuthStatus.authenticated:
      case PeerAuthStatus.rejected:
      case PeerAuthStatus.failed:
        return false;
    }
  }

  String _randomHex(int bytes) {
    return List<int>.generate(
      bytes,
      (_) => _random.nextInt(256),
    ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _dispose() async {
    await _stop(clearSessions: false);
  }

  Future<void> _stop({required bool clearSessions}) async {
    for (final timer in _timeouts.values) {
      timer.cancel();
    }
    _timeouts.clear();
    _contexts.clear();
    await _packetSubscription?.cancel();
    _packetSubscription = null;
    _localIdentity = null;
    if (clearSessions) {
      state = const PeerAuthState(
        sessions: <String, PeerAuthSession>{},
        isListening: false,
        isLoading: false,
      );
    }
  }
}

class _HandshakeContext {
  _HandshakeContext({
    required this.sessionId,
    required this.peerId,
    required this.peerUserId,
    required this.peerDisplayName,
    required this.peerAddress,
    required this.peerPort,
    required this.initiatedByMe,
    this.selectedPathId,
    this.selectedCandidateId,
    this.selectedLocalEndpoint,
    this.nonce,
    this.preserveAuthenticatedSession = false,
  });

  final String sessionId;
  final String peerId;
  final String peerUserId;
  final String peerDisplayName;
  String peerAddress;
  int peerPort;
  final bool initiatedByMe;
  final String? selectedPathId;
  final String? selectedCandidateId;
  final UdpInterfaceEndpoint? selectedLocalEndpoint;
  final bool preserveAuthenticatedSession;
  String? nonce;
}

final authNowProvider = Provider<AuthNow>((ref) => DateTime.now);

final peerAuthControllerProvider =
    NotifierProvider<PeerAuthController, PeerAuthState>(PeerAuthController.new);

final localAuthPortProvider = Provider<int>((ref) {
  return ref.watch(peerAuthControllerProvider).localPort ??
      ref.watch(appConfigProvider).authPort;
});

final peerAuthSessionByPeerIdProvider =
    Provider.family<PeerAuthSession?, String>((ref, peerId) {
      return ref.watch(peerAuthControllerProvider).sessions[peerId];
    });
