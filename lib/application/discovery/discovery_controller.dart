import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_sorting.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/infrastructure/auth/shared_verifier_service.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/platform/local_device_identity_service.dart';
import 'package:sponzey_file_sharing/infrastructure/repositories/peer_repository.dart';

typedef Now = DateTime Function();

class DiscoveryState {
  const DiscoveryState({
    required this.peers,
    this.errorMessage,
    this.isLoading = false,
    this.isRunning = false,
    this.lastBroadcastAt,
    this.currentPairingUserId,
    this.currentPairingProofPreview,
    this.receivedPacketCount = 0,
    this.localRegistryEntryCount = 0,
    this.lastPacketAt,
    this.lastDecision,
  });

  const DiscoveryState.initial()
    : peers = const [],
      errorMessage = null,
      isLoading = true,
      isRunning = false,
      lastBroadcastAt = null,
      currentPairingUserId = null,
      currentPairingProofPreview = null,
      receivedPacketCount = 0,
      localRegistryEntryCount = 0,
      lastPacketAt = null,
      lastDecision = null;

  final List<PeerNode> peers;
  final String? errorMessage;
  final bool isLoading;
  final bool isRunning;
  final DateTime? lastBroadcastAt;
  final String? currentPairingUserId;
  final String? currentPairingProofPreview;
  final int receivedPacketCount;
  final int localRegistryEntryCount;
  final DateTime? lastPacketAt;
  final String? lastDecision;

  DiscoveryState copyWith({
    List<PeerNode>? peers,
    String? errorMessage,
    bool? isLoading,
    bool? isRunning,
    DateTime? lastBroadcastAt,
    String? currentPairingUserId,
    String? currentPairingProofPreview,
    int? receivedPacketCount,
    int? localRegistryEntryCount,
    DateTime? lastPacketAt,
    String? lastDecision,
    bool clearError = false,
    bool clearLastDecision = false,
  }) {
    return DiscoveryState(
      peers: peers ?? this.peers,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isRunning: isRunning ?? this.isRunning,
      lastBroadcastAt: lastBroadcastAt ?? this.lastBroadcastAt,
      currentPairingUserId: currentPairingUserId ?? this.currentPairingUserId,
      currentPairingProofPreview:
          currentPairingProofPreview ?? this.currentPairingProofPreview,
      receivedPacketCount: receivedPacketCount ?? this.receivedPacketCount,
      localRegistryEntryCount:
          localRegistryEntryCount ?? this.localRegistryEntryCount,
      lastPacketAt: lastPacketAt ?? this.lastPacketAt,
      lastDecision: clearLastDecision
          ? null
          : lastDecision ?? this.lastDecision,
    );
  }
}

class DiscoveryController extends Notifier<DiscoveryState> {
  bool _didInitialize = false;
  bool _isStarting = false;
  StreamSubscription<DiscoveryDatagram>? _packetSubscription;
  Timer? _broadcastTimer;
  Timer? _presenceTimer;
  LocalDeviceIdentity? _localIdentity;
  LocalInstanceRegistry? _localInstanceRegistry;
  int? _localAuthPort;
  final Map<String, DateTime> _lastAutoHandshakeAt = {};

  @override
  DiscoveryState build() {
    ref.onDispose(() {
      unawaited(_dispose());
    });
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated &&
          !_isStarting &&
          _packetSubscription == null &&
          _broadcastTimer == null) {
        unawaited(_initialize());
      }

      if (!next.isAuthenticated &&
          (_packetSubscription != null || _broadcastTimer != null)) {
        unawaited(_stop(clearPeers: true));
      }
    });

    if (!_didInitialize) {
      _didInitialize = true;
      unawaited(_initialize());
    }

    return const DiscoveryState.initial();
  }

  Future<void> refreshPresence() async {
    final updated = await _mergeLocalRegistryPeers(state.peers);
    if (!ref.mounted) {
      return;
    }
    ref.read(peerAuthControllerProvider.notifier).syncPeerPresence(updated);
    if (!_samePeerCollection(state.peers, updated)) {
      state = state.copyWith(peers: updated, clearError: true);
    }
    await _autoHandshakePeers(updated);
  }

  @visibleForTesting
  Future<void> broadcastNow() async {
    final packet = await _buildLocalPacket(DiscoveryPacketType.discover);
    if (packet == null) {
      return;
    }

    final config = ref.read(appConfigProvider);
    await ref
        .read(discoveryTransportProvider)
        .sendBroadcast(packet, port: config.discoveryPort);
    await _localInstanceRegistry?.publish(
      LocalInstancePresence(
        userId: packet.userId,
        pairingProof: packet.pairingProof,
        instanceId: packet.instanceId,
        displayName: packet.displayName,
        deviceId: packet.deviceId,
        deviceName: packet.deviceName,
        osType: packet.osType,
        protocolVersion: packet.protocolVersion,
        port: packet.port,
        receiveAvailable: packet.receiveAvailable,
        seenAtEpochMs: packet.sentAtEpochMs,
      ),
    );

    ref
        .read(appLoggerProvider)
        .debug(AppLogCategory.discovery, 'Sent DISCOVER broadcast');

    state = state.copyWith(
      lastBroadcastAt: _now(),
      isRunning: true,
      isLoading: false,
      clearError: true,
    );
    await refreshPresence();
  }

  Future<void> _initialize() async {
    if (_isStarting) {
      return;
    }

    final logger = ref.read(appLoggerProvider);
    _isStarting = true;
    var initStage = 'begin';
    String? currentPairingUserId;
    String? currentPairingProofPreview;

    try {
      initStage = 'auth-state';
      final authState = ref.read(authControllerProvider);
      final user = authState.currentUser;
      currentPairingUserId = user?.userId;
      currentPairingProofPreview = _pairingProofPreview(_currentPairingProof());
      if (!authState.isAuthenticated || user == null) {
        state = const DiscoveryState(
          peers: <PeerNode>[],
          isLoading: false,
          isRunning: false,
        );
        return;
      }

      initStage = 'local-identity';
      _localIdentity = await ref
          .read(localDeviceIdentityServiceProvider)
          .load();
      if (!ref.mounted) {
        return;
      }
      initStage = 'peer-auth-ready';
      _localAuthPort = await ref
          .read(peerAuthControllerProvider.notifier)
          .ensureListening();
      if (!ref.mounted) {
        return;
      }
      initStage = 'local-registry';
      _localInstanceRegistry = ref.read(localInstanceRegistryProvider);
      initStage = 'transport-provider';
      final transport = ref.read(discoveryTransportProvider);
      final config = ref.read(appConfigProvider);
      initStage = 'cached-peers';
      final cachedPeers = await ref
          .read(peerRepositoryProvider)
          .loadCachedPeers();
      if (!ref.mounted) {
        return;
      }
      final scopedPeers = _filterCachedPeersForCurrentUser(cachedPeers);

      state = DiscoveryState(
        peers: _applyPresence(scopedPeers),
        isLoading: false,
        isRunning: true,
        currentPairingUserId: currentPairingUserId,
        currentPairingProofPreview: currentPairingProofPreview,
        lastDecision: 'init: cached peers loaded ${scopedPeers.length}',
      );

      initStage = 'transport-start';
      await transport.start(port: config.discoveryPort);
      if (!ref.mounted) {
        return;
      }
      initStage = 'packet-subscription';
      _packetSubscription = transport.packets.listen((datagram) {
        unawaited(_handlePacket(datagram));
      });
      initStage = 'timers';
      _broadcastTimer = Timer.periodic(config.discoveryBroadcastInterval, (_) {
        unawaited(broadcastNow());
      });
      _presenceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(refreshPresence());
      });

      initStage = 'first-broadcast';
      await broadcastNow();
      if (!ref.mounted) {
        return;
      }
      initStage = 'first-refresh';
      await refreshPresence();
      if (!ref.mounted) {
        return;
      }
      initStage = 'running';
      logger.info(
        AppLogCategory.discovery,
        'Discovery engine started on UDP ${config.discoveryPort}',
      );
    } catch (error, stackTrace) {
      logger.error(
        AppLogCategory.discovery,
        'Failed to initialize discovery engine',
        error: error,
        stackTrace: stackTrace,
      );
      state = DiscoveryState(
        peers: const <PeerNode>[],
        isLoading: false,
        isRunning: false,
        currentPairingUserId: currentPairingUserId,
        currentPairingProofPreview: currentPairingProofPreview,
        errorMessage:
            '디스커버리 엔진을 시작하지 못했습니다. [$initStage] ${error.runtimeType}: $error',
        lastDecision: 'init failed at $initStage: ${error.runtimeType}: $error',
      );
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _handlePacket(DiscoveryDatagram datagram) async {
    final logger = ref.read(appLoggerProvider);
    final packet = datagram.packet;
    final localIdentity = _localIdentity;
    if (localIdentity == null) {
      return;
    }

    if (packet.instanceId == localIdentity.instanceId ||
        packet.deviceId == localIdentity.deviceId) {
      state = state.copyWith(
        receivedPacketCount: state.receivedPacketCount + 1,
        lastPacketAt: _now(),
        lastDecision:
            'self packet ignored: ${packet.instanceId}/${packet.deviceId}',
      );
      return;
    }
    if (!_matchesCurrentPairingGroup(packet)) {
      state = state.copyWith(
        receivedPacketCount: state.receivedPacketCount + 1,
        lastPacketAt: _now(),
        lastDecision:
            'ignored packet: ${packet.userId}@${packet.deviceId} pairing mismatch',
      );
      return;
    }

    final peer = _peerFromPacket(packet, datagram.address);
    final nextPeers = _mergePeer(state.peers, peer);
    state = state.copyWith(
      peers: nextPeers,
      clearError: true,
      receivedPacketCount: state.receivedPacketCount + 1,
      lastPacketAt: _now(),
      lastDecision: 'accepted peer: ${peer.id} ${peer.address}:${peer.port}',
    );
    await ref.read(peerRepositoryProvider).upsert(peer);
    ref
        .read(messageBusProvider)
        .publish(
          DiscoveryAppEvent(
            eventId: _eventId('discovery-peer-seen'),
            occurredAt: _now(),
            correlationId: packet.messageId.isEmpty
                ? peer.id
                : packet.messageId,
            source: 'DiscoveryController',
            severity: AppEventSeverity.debug,
            eventType: 'discoveryPeerSeen',
            peerId: peer.id,
            messageId: packet.messageId.isEmpty ? null : packet.messageId,
          ),
        );
    ref
        .read(peerAuthControllerProvider.notifier)
        .syncDiscoveredPeer(peer, message: 'Discovery에서 피어를 발견했습니다.');
    await _maybeAutoHandshake(peer);

    logger.debug(
      AppLogCategory.discovery,
      'Received ${packet.type.wireName} from ${peer.id} (${peer.address})',
    );

    if (packet.type == DiscoveryPacketType.discover) {
      final ackPacket = await _buildLocalPacket(
        DiscoveryPacketType.discoverAck,
      );
      if (ackPacket != null) {
        await ref
            .read(discoveryTransportProvider)
            .sendUnicast(
              ackPacket,
              address: datagram.address,
              port: datagram.port,
            );
      }
    }
  }

  Future<DiscoveryPacket?> _buildLocalPacket(DiscoveryPacketType type) async {
    final localIdentity = _localIdentity;
    final user = _currentUser();
    if (localIdentity == null || user == null) {
      return null;
    }

    final config = ref.read(appConfigProvider);
    final pairingProof = _currentPairingProof();
    if (pairingProof == null) {
      return null;
    }
    return DiscoveryPacket(
      type: type,
      protocolVersion: config.protocolVersion,
      userId: user.userId,
      pairingProof: pairingProof,
      instanceId: localIdentity.instanceId,
      displayName: user.displayName,
      deviceId: localIdentity.deviceId,
      deviceName: user.deviceName,
      osType: localIdentity.osType,
      port: _localAuthPort ?? ref.read(localAuthPortProvider),
      controlPort: config.controlPort,
      dataPort: config.dataPort,
      dataPortRange: config.dataPortRange.ports,
      capabilities: const ['discovery', 'control', 'data'],
      receiveAvailable: true,
      sentAtEpochMs: _now().millisecondsSinceEpoch,
    );
  }

  List<PeerNode> _mergePeer(List<PeerNode> peers, PeerNode incomingPeer) {
    final updated = <PeerNode>[
      for (final peer in peers)
        if (peer.deviceId != incomingPeer.deviceId) peer,
      incomingPeer,
    ];
    return sortPeers(updated, sortMode: PeerSortMode.recent);
  }

  PeerNode _peerFromPacket(DiscoveryPacket packet, InternetAddress address) {
    final seenAt = DateTime.fromMillisecondsSinceEpoch(packet.sentAtEpochMs);
    return PeerNode(
      deviceId: packet.deviceId,
      userId: packet.userId,
      displayName: packet.displayName,
      deviceName: packet.deviceName,
      osType: packet.osType,
      protocolVersion: packet.protocolVersion,
      lastSeenAt: seenAt,
      address: address.address,
      port: packet.controlPort ?? packet.port,
      receiveAvailable: packet.receiveAvailable,
      presence: resolvePeerPresence(
        protocolVersion: packet.protocolVersion,
        config: ref.read(appConfigProvider),
        lastSeenAt: seenAt,
        now: _now(),
      ),
    );
  }

  List<PeerNode> _applyPresence(List<PeerNode> peers) {
    final config = ref.read(appConfigProvider);
    final now = _now();
    return sortPeers([
      for (final peer in peers)
        peer.copyWith(
          presence: resolvePeerPresence(
            protocolVersion: peer.protocolVersion,
            config: config,
            lastSeenAt: peer.lastSeenAt,
            now: now,
          ),
        ),
    ], sortMode: PeerSortMode.recent);
  }

  Future<List<PeerNode>> _mergeLocalRegistryPeers(List<PeerNode> peers) async {
    final localIdentity = _localIdentity;
    if (localIdentity == null) {
      return _applyPresence(peers);
    }

    final config = ref.read(appConfigProvider);
    final entries =
        await _localInstanceRegistry?.listActive(
          now: _now(),
          maxAge: config.discoveryOfflineAfter,
        ) ??
        const <LocalInstancePresence>[];
    if (!ref.mounted) {
      return peers;
    }

    var merged = peers;
    for (final entry in entries) {
      if (entry.instanceId == localIdentity.instanceId ||
          entry.deviceId == localIdentity.deviceId) {
        continue;
      }
      if (!_matchesCurrentPairingGroupEntry(entry)) {
        continue;
      }

      final seenAt = DateTime.fromMillisecondsSinceEpoch(entry.seenAtEpochMs);
      final peer = PeerNode(
        deviceId: entry.deviceId,
        userId: entry.userId,
        displayName: entry.displayName,
        deviceName: entry.deviceName,
        osType: entry.osType,
        protocolVersion: entry.protocolVersion,
        lastSeenAt: seenAt,
        address: InternetAddress.loopbackIPv4.address,
        port: entry.port,
        receiveAvailable: entry.receiveAvailable,
        presence: resolvePeerPresence(
          protocolVersion: entry.protocolVersion,
          config: config,
          lastSeenAt: seenAt,
          now: _now(),
        ),
      );
      merged = _mergePeer(merged, peer);
      if (!ref.mounted) {
        return _applyPresence(merged);
      }
      ref
          .read(peerAuthControllerProvider.notifier)
          .syncDiscoveredPeer(peer, message: 'Local discovery에서 피어를 발견했습니다.');
      await _maybeAutoHandshake(peer);
      if (!ref.mounted) {
        return _applyPresence(merged);
      }
    }

    state = state.copyWith(
      localRegistryEntryCount: entries.length,
      currentPairingUserId: _currentUser()?.userId,
      currentPairingProofPreview: _pairingProofPreview(_currentPairingProof()),
    );

    return _applyPresence(merged);
  }

  UserAccount? _currentUser() => ref.read(authControllerProvider).currentUser;

  String? _currentPairingProof() {
    final authState = ref.read(authControllerProvider);
    final user = authState.currentUser;
    final password = authState.sessionPassword;
    if (!authState.isAuthenticated ||
        user == null ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return ref
        .read(sharedVerifierServiceProvider)
        .deriveVerifierBase64(userId: user.userId, password: password);
  }

  String? _pairingProofPreview(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final safeLength = value.length < 12 ? value.length : 12;
    return value.substring(0, safeLength);
  }

  bool _matchesCurrentPairingGroup(DiscoveryPacket packet) {
    final user = _currentUser();
    final pairingProof = _currentPairingProof();
    if (user == null || pairingProof == null) {
      return false;
    }
    return packet.userId == user.userId && packet.pairingProof == pairingProof;
  }

  bool _matchesCurrentPairingGroupEntry(LocalInstancePresence entry) {
    final user = _currentUser();
    final pairingProof = _currentPairingProof();
    if (user == null || pairingProof == null) {
      return false;
    }
    return entry.userId == user.userId && entry.pairingProof == pairingProof;
  }

  List<PeerNode> _filterCachedPeersForCurrentUser(List<PeerNode> peers) {
    final user = _currentUser();
    if (user == null) {
      return const <PeerNode>[];
    }
    return peers
        .where((peer) => peer.userId == user.userId)
        .toList(growable: false);
  }

  DateTime _now() => ref.read(nowProvider)();

  String _eventId(String prefix) => '$prefix-${_now().microsecondsSinceEpoch}';

  Future<void> _autoHandshakePeers(List<PeerNode> peers) async {
    for (final peer in peers) {
      await _maybeAutoHandshake(peer);
    }
  }

  Future<void> _maybeAutoHandshake(PeerNode peer) async {
    if (!peer.isCompatible || peer.presence != PeerPresence.online) {
      return;
    }

    final session = ref.read(peerAuthSessionByPeerIdProvider(peer.id));
    if (session?.isAuthenticated == true) {
      return;
    }
    switch (session?.status) {
      case PeerAuthStatus.connecting:
      case PeerAuthStatus.challengeIssued:
      case PeerAuthStatus.tokenSent:
      case PeerAuthStatus.verifying:
        return;
      case null:
      case PeerAuthStatus.idle:
      case PeerAuthStatus.authenticated:
      case PeerAuthStatus.rejected:
      case PeerAuthStatus.failed:
        break;
    }

    final now = _now();
    final cooldown = ref.read(appConfigProvider).discoveryBroadcastInterval;
    final lastAttemptAt = _lastAutoHandshakeAt[peer.id];
    if (lastAttemptAt != null && now.difference(lastAttemptAt) < cooldown) {
      return;
    }

    _lastAutoHandshakeAt[peer.id] = now;
    ref
        .read(appLoggerProvider)
        .debug(
          AppLogCategory.discovery,
          'Auto-starting peer handshake for ${peer.id} ${peer.address}:${peer.port}',
        );
    await ref.read(peerAuthControllerProvider.notifier).startHandshake(peer);
  }

  Future<void> _dispose() async {
    await _stop(clearPeers: false);
  }

  Future<void> _stop({required bool clearPeers}) async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    await _packetSubscription?.cancel();
    _packetSubscription = null;
    final localIdentity = _localIdentity;
    if (localIdentity != null) {
      await _localInstanceRegistry?.remove(localIdentity.deviceId);
    }
    _localIdentity = null;
    _localAuthPort = null;
    _lastAutoHandshakeAt.clear();

    if (clearPeers) {
      state = state.copyWith(
        peers: const [],
        isRunning: false,
        isLoading: false,
        clearError: true,
      );
    }
  }
}

PeerPresence resolvePeerPresence({
  required String protocolVersion,
  required AppConfig config,
  required DateTime lastSeenAt,
  required DateTime now,
}) {
  if (protocolVersion != config.protocolVersion) {
    return PeerPresence.incompatible;
  }

  final age = now.difference(lastSeenAt);
  if (age >= config.discoveryOfflineAfter) {
    return PeerPresence.offline;
  }
  if (age >= config.discoveryStaleAfter) {
    return PeerPresence.stale;
  }
  return PeerPresence.online;
}

final nowProvider = Provider<Now>((ref) => DateTime.now);

final discoveryControllerProvider =
    NotifierProvider<DiscoveryController, DiscoveryState>(
      DiscoveryController.new,
    );

bool _samePeerCollection(List<PeerNode> left, List<PeerNode> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    final current = left[index];
    final next = right[index];
    if (current.deviceId != next.deviceId ||
        current.presence != next.presence ||
        current.lastSeenAt != next.lastSeenAt ||
        current.address != next.address ||
        current.port != next.port ||
        current.receiveAvailable != next.receiveAvailable ||
        current.protocolVersion != next.protocolVersion) {
      return false;
    }
  }

  return true;
}
