import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/app_config.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_startup_failure_message.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_sorting.dart';
import 'package:sponzey_file_sharing/application/network/peer_connection_coordinator.dart';
import 'package:sponzey_file_sharing/core/message_bus/app_event.dart';
import 'package:sponzey_file_sharing/core/message_bus/message_bus.dart';
import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/discovery/discovery_receive_decision.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_identity.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/domain/network/connectable_interface_policy.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_group_tag_service.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/network/dart_io_network_interface_inventory.dart';
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
    String? currentDiscoveryGroupTagPreview,
    @Deprecated('Use currentDiscoveryGroupTagPreview.')
    String? currentPairingProofPreview,
    this.receivedPacketCount = 0,
    this.localRegistryEntryCount = 0,
    this.lastPacketAt,
    this.lastDecision,
    this.lastDecisionCode,
    this.discoveryTransportMode,
    this.discoveryPreferredPort,
    this.discoveryReceivePort,
    this.discoverySendPort,
    this.discoveryReceivePortFallback = false,
    this.discoveryBroadcastTargetCount = 0,
    this.discoveryBroadcastTargetPreview = const [],
    this.discoveryBroadcastAttemptCount = 0,
    this.discoveryBroadcastSuccessCount = 0,
    this.discoveryBroadcastFailureCount = 0,
    this.discoveryBroadcastAttemptPreview = const [],
    this.discoveryTargetSkipPreview = const [],
    this.discoveryLastReceiveDecisionCode,
    this.discoveryMalformedPacketCount = 0,
    this.discoveryTransportError,
  }) : currentDiscoveryGroupTagPreview =
           currentDiscoveryGroupTagPreview ?? currentPairingProofPreview;

  const DiscoveryState.initial()
    : peers = const [],
      errorMessage = null,
      isLoading = true,
      isRunning = false,
      lastBroadcastAt = null,
      currentPairingUserId = null,
      currentDiscoveryGroupTagPreview = null,
      receivedPacketCount = 0,
      localRegistryEntryCount = 0,
      lastPacketAt = null,
      lastDecision = null,
      lastDecisionCode = null,
      discoveryTransportMode = null,
      discoveryPreferredPort = null,
      discoveryReceivePort = null,
      discoverySendPort = null,
      discoveryReceivePortFallback = false,
      discoveryBroadcastTargetCount = 0,
      discoveryBroadcastTargetPreview = const [],
      discoveryBroadcastAttemptCount = 0,
      discoveryBroadcastSuccessCount = 0,
      discoveryBroadcastFailureCount = 0,
      discoveryBroadcastAttemptPreview = const [],
      discoveryTargetSkipPreview = const [],
      discoveryLastReceiveDecisionCode = null,
      discoveryMalformedPacketCount = 0,
      discoveryTransportError = null;

  final List<PeerNode> peers;
  final String? errorMessage;
  final bool isLoading;
  final bool isRunning;
  final DateTime? lastBroadcastAt;
  final String? currentPairingUserId;
  final String? currentDiscoveryGroupTagPreview;

  @Deprecated('Use currentDiscoveryGroupTagPreview.')
  String? get currentPairingProofPreview => currentDiscoveryGroupTagPreview;

  final int receivedPacketCount;
  final int localRegistryEntryCount;
  final DateTime? lastPacketAt;
  final String? lastDecision;
  final String? lastDecisionCode;
  final String? discoveryTransportMode;
  final int? discoveryPreferredPort;
  final int? discoveryReceivePort;
  final int? discoverySendPort;
  final bool discoveryReceivePortFallback;
  final int discoveryBroadcastTargetCount;
  final List<String> discoveryBroadcastTargetPreview;
  final int discoveryBroadcastAttemptCount;
  final int discoveryBroadcastSuccessCount;
  final int discoveryBroadcastFailureCount;
  final List<String> discoveryBroadcastAttemptPreview;
  final List<String> discoveryTargetSkipPreview;
  final String? discoveryLastReceiveDecisionCode;
  final int discoveryMalformedPacketCount;
  final String? discoveryTransportError;

  DiscoveryState copyWith({
    List<PeerNode>? peers,
    String? errorMessage,
    bool? isLoading,
    bool? isRunning,
    DateTime? lastBroadcastAt,
    String? currentPairingUserId,
    String? currentDiscoveryGroupTagPreview,
    @Deprecated('Use currentDiscoveryGroupTagPreview.')
    String? currentPairingProofPreview,
    int? receivedPacketCount,
    int? localRegistryEntryCount,
    DateTime? lastPacketAt,
    String? lastDecision,
    String? lastDecisionCode,
    String? discoveryTransportMode,
    int? discoveryPreferredPort,
    int? discoveryReceivePort,
    int? discoverySendPort,
    bool? discoveryReceivePortFallback,
    int? discoveryBroadcastTargetCount,
    List<String>? discoveryBroadcastTargetPreview,
    int? discoveryBroadcastAttemptCount,
    int? discoveryBroadcastSuccessCount,
    int? discoveryBroadcastFailureCount,
    List<String>? discoveryBroadcastAttemptPreview,
    List<String>? discoveryTargetSkipPreview,
    String? discoveryLastReceiveDecisionCode,
    int? discoveryMalformedPacketCount,
    String? discoveryTransportError,
    bool clearError = false,
    bool clearLastDecision = false,
    bool clearDiscoveryTransportError = false,
  }) {
    return DiscoveryState(
      peers: peers ?? this.peers,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isRunning: isRunning ?? this.isRunning,
      lastBroadcastAt: lastBroadcastAt ?? this.lastBroadcastAt,
      currentPairingUserId: currentPairingUserId ?? this.currentPairingUserId,
      currentDiscoveryGroupTagPreview:
          currentDiscoveryGroupTagPreview ??
          currentPairingProofPreview ??
          this.currentDiscoveryGroupTagPreview,
      receivedPacketCount: receivedPacketCount ?? this.receivedPacketCount,
      localRegistryEntryCount:
          localRegistryEntryCount ?? this.localRegistryEntryCount,
      lastPacketAt: lastPacketAt ?? this.lastPacketAt,
      lastDecision: clearLastDecision
          ? null
          : lastDecision ?? this.lastDecision,
      lastDecisionCode: clearLastDecision
          ? null
          : lastDecisionCode ?? this.lastDecisionCode,
      discoveryTransportMode:
          discoveryTransportMode ?? this.discoveryTransportMode,
      discoveryPreferredPort:
          discoveryPreferredPort ?? this.discoveryPreferredPort,
      discoveryReceivePort: discoveryReceivePort ?? this.discoveryReceivePort,
      discoverySendPort: discoverySendPort ?? this.discoverySendPort,
      discoveryReceivePortFallback:
          discoveryReceivePortFallback ?? this.discoveryReceivePortFallback,
      discoveryBroadcastTargetCount:
          discoveryBroadcastTargetCount ?? this.discoveryBroadcastTargetCount,
      discoveryBroadcastTargetPreview:
          discoveryBroadcastTargetPreview ??
          this.discoveryBroadcastTargetPreview,
      discoveryBroadcastAttemptCount:
          discoveryBroadcastAttemptCount ?? this.discoveryBroadcastAttemptCount,
      discoveryBroadcastSuccessCount:
          discoveryBroadcastSuccessCount ?? this.discoveryBroadcastSuccessCount,
      discoveryBroadcastFailureCount:
          discoveryBroadcastFailureCount ?? this.discoveryBroadcastFailureCount,
      discoveryBroadcastAttemptPreview:
          discoveryBroadcastAttemptPreview ??
          this.discoveryBroadcastAttemptPreview,
      discoveryTargetSkipPreview:
          discoveryTargetSkipPreview ?? this.discoveryTargetSkipPreview,
      discoveryLastReceiveDecisionCode:
          discoveryLastReceiveDecisionCode ??
          this.discoveryLastReceiveDecisionCode,
      discoveryMalformedPacketCount:
          discoveryMalformedPacketCount ?? this.discoveryMalformedPacketCount,
      discoveryTransportError: clearDiscoveryTransportError
          ? null
          : discoveryTransportError ?? this.discoveryTransportError,
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
  AppLogger? _cachedLogger;
  final Map<String, DateTime> _lastAutoHandshakeAt = {};

  @override
  DiscoveryState build() {
    _cachedLogger ??= ref.read(appLoggerProvider);
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
    _expireRouteCandidates();
    ref.read(peerAuthControllerProvider.notifier).syncPeerPresence(updated);
    if (!_samePeerCollection(state.peers, updated)) {
      state = state.copyWith(peers: updated, clearError: true);
    }
    await _autoHandshakePeers(updated);
  }

  @visibleForTesting
  Future<void> broadcastNow() async {
    final packet = await _buildLocalPacket(DiscoveryPacketType.discover);
    final logger = ref.read(appLoggerProvider);
    if (packet == null) {
      logger.warning(
        AppLogCategory.discovery,
        'Discovery broadcast skipped because local packet could not be built. '
        'authUser=${_currentUser()?.userId ?? '-'} '
        'identityLoaded=${_localIdentity != null} '
        'groupTag=${_discoveryGroupTagPreview(_currentDiscoveryGroupTag()) ?? '-'}',
      );
      return;
    }

    final config = ref.read(appConfigProvider);
    final transport = ref.read(discoveryTransportProvider);
    logger.info(
      AppLogCategory.discovery,
      'Discovery broadcast start configuredPort=${config.discoveryPort} '
      'packet=${_packetSummary(packet)}',
    );
    await ref
        .read(discoveryTransportProvider)
        .sendBroadcast(packet, port: config.discoveryPort);
    await _localInstanceRegistry?.publish(
      LocalInstancePresence(
        userId: packet.userId,
        discoveryGroupTag: packet.discoveryGroupTag,
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

    logger.info(
      AppLogCategory.discovery,
      'Discovery local registry published instance=${_short(packet.instanceId)} '
      'user=${packet.userId} controlPort=${packet.controlPort ?? packet.port} '
      'discoveryPort=${packet.discoveryPort ?? '-'}',
    );

    state = state.copyWith(
      lastBroadcastAt: _now(),
      isRunning: true,
      isLoading: false,
      clearError: true,
    );
    _applyTransportDiagnostics(transport);
    logger.info(
      AppLogCategory.discovery,
      'Discovery broadcast state applied ${_transportSnapshotSummary(transport)}',
    );
    await refreshPresence();
  }

  Future<void> _initialize() async {
    if (_isStarting) {
      return;
    }

    final logger = ref.read(appLoggerProvider);
    _cachedLogger = logger;
    _isStarting = true;
    var initStage = 'begin';
    String? currentPairingUserId;
    String? currentDiscoveryGroupTagPreview;

    try {
      initStage = 'auth-state';
      final authState = ref.read(authControllerProvider);
      final user = authState.currentUser;
      currentPairingUserId = user?.userId;
      currentDiscoveryGroupTagPreview = _discoveryGroupTagPreview(
        _currentDiscoveryGroupTag(),
      );
      if (!authState.isAuthenticated || user == null) {
        logger.info(
          AppLogCategory.discovery,
          'Discovery initialization paused. authenticated=${authState.isAuthenticated} '
          'user=${user?.userId ?? '-'}',
        );
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
      logger.info(
        AppLogCategory.discovery,
        'Discovery local identity loaded device=${_localIdentity!.deviceId} '
        'instance=${_short(_localIdentity!.instanceId)} '
        'os=${_localIdentity!.osType}',
      );
      initStage = 'peer-auth-ready';
      _localAuthPort = await ref
          .read(peerAuthControllerProvider.notifier)
          .ensureListening();
      if (!ref.mounted) {
        return;
      }
      logger.info(
        AppLogCategory.discovery,
        'Discovery peer control listener ready port=$_localAuthPort',
      );
      initStage = 'local-registry';
      _localInstanceRegistry = ref.read(localInstanceRegistryProvider);
      initStage = 'transport-provider';
      final transport = ref.read(discoveryTransportProvider);
      final config = ref.read(appConfigProvider);
      if (!ref.mounted) {
        return;
      }

      state = DiscoveryState(
        peers: const <PeerNode>[],
        isLoading: false,
        isRunning: true,
        currentPairingUserId: currentPairingUserId,
        currentDiscoveryGroupTagPreview: currentDiscoveryGroupTagPreview,
        lastDecision: 'init: live discovery only',
      );

      initStage = 'transport-start';
      logger.info(
        AppLogCategory.discovery,
        'Discovery transport start stage. discoveryPort=${config.discoveryPort} '
        'controlPort=${config.controlPort} dataPort=${config.dataPort}',
      );
      await transport.start(port: config.discoveryPort);
      if (!ref.mounted) {
        return;
      }
      _applyTransportDiagnostics(transport);
      logger.info(
        AppLogCategory.discovery,
        'Discovery transport started ${_transportSnapshotSummary(transport)}',
      );
      initStage = 'packet-subscription';
      _packetSubscription = transport.packets.listen((datagram) {
        unawaited(_handlePacket(datagram));
      });
      logger.info(
        AppLogCategory.discovery,
        'Discovery packet subscription attached',
      );
      initStage = 'timers';
      _broadcastTimer = Timer.periodic(config.discoveryBroadcastInterval, (_) {
        unawaited(broadcastNow());
      });
      _presenceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(refreshPresence());
      });
      logger.info(
        AppLogCategory.discovery,
        'Discovery timers started broadcastInterval='
        '${config.discoveryBroadcastInterval.inSeconds}s '
        'presenceInterval=1s',
      );

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
      final config = ref.read(appConfigProvider);
      final errorMessage = discoveryStartupFailureMessage(
        stage: initStage,
        error: error,
        discoveryPort: config.discoveryPort,
        controlPort: config.controlPort,
        dataPortRangeStart: config.dataPortRange.start,
        dataPortRangeEnd: config.dataPortRange.end,
      );
      logger.error(
        AppLogCategory.discovery,
        'Failed to initialize discovery engine at stage $initStage',
        error: error,
        stackTrace: stackTrace,
      );
      state = DiscoveryState(
        peers: const <PeerNode>[],
        isLoading: false,
        isRunning: false,
        currentPairingUserId: currentPairingUserId,
        currentDiscoveryGroupTagPreview: currentDiscoveryGroupTagPreview,
        errorMessage: errorMessage,
        lastDecision: discoveryStartupFailureDecision(
          stage: initStage,
          error: error,
        ),
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
      final decision = DiscoveryReceiveDecision(
        code: DiscoveryReceiveDecisionCode.localIdentityMissing,
        remoteAddress: datagram.address.address,
        remotePort: datagram.port,
        reason: 'local identity not loaded',
      );
      logger.warning(
        AppLogCategory.discovery,
        'Discovery packet ignored because local identity is not loaded. '
        'source=${datagram.address.address}:${datagram.port} '
        'packet=${_packetSummary(packet)} decision=${decision.summary}',
      );
      state = state.copyWith(
        receivedPacketCount: state.receivedPacketCount + 1,
        lastPacketAt: _now(),
        lastDecision: decision.summary,
        lastDecisionCode: decision.code.name,
      );
      return;
    }

    logger.debug(
      AppLogCategory.discovery,
      'Discovery packet handling start source=${datagram.address.address}:'
      '${datagram.port} packet=${_packetSummary(packet)} '
      'localInstance=${_short(localIdentity.instanceId)}',
    );

    if (packet.instanceId == localIdentity.instanceId) {
      final decision = DiscoveryReceiveDecision(
        code: DiscoveryReceiveDecisionCode.ignoredSelf,
        remoteAddress: datagram.address.address,
        remotePort: datagram.port,
        peerId: _peerIdFromPacket(packet),
        reason: 'same instance id',
      );
      logger.debug(
        AppLogCategory.discovery,
        'Discovery packet ignored as self packet. '
        'source=${datagram.address.address}:${datagram.port} '
        'packet=${_packetSummary(packet)} decision=${decision.summary}',
      );
      state = state.copyWith(
        receivedPacketCount: state.receivedPacketCount + 1,
        lastPacketAt: _now(),
        lastDecision: decision.summary,
        lastDecisionCode: decision.code.name,
      );
      return;
    }
    if (!_matchesCurrentPairingGroup(packet)) {
      final decision = DiscoveryReceiveDecision(
        code: DiscoveryReceiveDecisionCode.groupMismatch,
        remoteAddress: datagram.address.address,
        remotePort: datagram.port,
        peerId: _peerIdFromPacket(packet),
        reason: 'pairing group mismatch',
      );
      logger.debug(
        AppLogCategory.discovery,
        'Discovery packet ignored by group/user filter. '
        'source=${datagram.address.address}:${datagram.port} '
        'packetUser=${packet.userId} localUser=${_currentUser()?.userId ?? '-'} '
        'packetGroup=${_discoveryGroupTagPreview(packet.discoveryGroupTag) ?? '-'} '
        'localGroup=${_discoveryGroupTagPreview(_currentDiscoveryGroupTag()) ?? '-'} '
        'decision=${decision.summary}',
      );
      state = state.copyWith(
        receivedPacketCount: state.receivedPacketCount + 1,
        lastPacketAt: _now(),
        lastDecision: decision.summary,
        lastDecisionCode: decision.code.name,
      );
      return;
    }

    final receivedAt = _now();
    final peer = _peerFromPacket(
      packet,
      datagram.address,
      receivedAt: receivedAt,
    );
    final routeCandidates = await _ingestDiscoveryRouteCandidates(
      datagram: datagram,
      receivedAt: receivedAt,
    );
    if (!ref.mounted) {
      return;
    }
    final nextPeers = _mergePeer(state.peers, peer);
    final decision = DiscoveryReceiveDecision(
      code: DiscoveryReceiveDecisionCode.accepted,
      remoteAddress: datagram.address.address,
      remotePort: datagram.port,
      peerId: peer.id,
    );
    state = state.copyWith(
      peers: nextPeers,
      clearError: true,
      receivedPacketCount: state.receivedPacketCount + 1,
      lastPacketAt: receivedAt,
      lastDecision: decision.summary,
      lastDecisionCode: decision.code.name,
    );
    if (routeCandidates.isNotEmpty) {
      logger.debug(
        AppLogCategory.discovery,
        'Projected ${routeCandidates.length} route candidate(s) for ${peer.id}',
      );
    }
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
      'Discovery peer accepted peer=${peer.id} address=${peer.address}:'
      '${peer.port} presence=${peer.presence.name} packet=${_packetSummary(packet)}',
    );

    if (packet.type == DiscoveryPacketType.discover) {
      final ackPacket = await _buildLocalPacket(
        DiscoveryPacketType.discoverAck,
      );
      if (ackPacket != null) {
        final ackPort =
            packet.discoveryPort ?? ref.read(appConfigProvider).discoveryPort;
        try {
          await ref
              .read(discoveryTransportProvider)
              .sendUnicast(ackPacket, address: datagram.address, port: ackPort);
          logger.debug(
            AppLogCategory.discovery,
            'Discovery ACK sent peer=${peer.id} target='
            '${datagram.address.address}:$ackPort '
            'packet=${_packetSummary(ackPacket)}',
          );
        } catch (error, stackTrace) {
          logger.warning(
            AppLogCategory.discovery,
            'Discovery ACK send failed peer=${peer.id} target='
            '${datagram.address.address}:$ackPort',
            error: error,
            stackTrace: stackTrace,
          );
        }
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
    final discoveryGroupTag = _currentDiscoveryGroupTag();
    if (discoveryGroupTag == null) {
      return null;
    }
    return DiscoveryPacket(
      type: type,
      protocolVersion: config.protocolVersion,
      userId: user.userId,
      discoveryGroupTag: discoveryGroupTag,
      instanceId: localIdentity.instanceId,
      displayName: user.displayName,
      deviceId: localIdentity.deviceId,
      deviceName: user.deviceName,
      osType: localIdentity.osType,
      port: _localAuthPort ?? ref.read(localAuthPortProvider),
      discoveryPort: _currentDiscoveryReceivePort(),
      controlPort: _localAuthPort ?? ref.read(localAuthPortProvider),
      dataPort: config.dataPort,
      dataPortRange: config.dataPortRange.ports,
      capabilities: const ['discovery', 'control', 'data'],
      receiveAvailable: true,
      sentAtEpochMs: _now().millisecondsSinceEpoch,
    );
  }

  int _currentDiscoveryReceivePort() {
    final transport = ref.read(discoveryTransportProvider);
    if (transport is DiscoveryTransportDiagnostics) {
      return (transport as DiscoveryTransportDiagnostics)
              .snapshot()
              .receivePort ??
          ref.read(appConfigProvider).discoveryPort;
    }
    return ref.read(appConfigProvider).discoveryPort;
  }

  void _applyTransportDiagnostics(DiscoveryTransport transport) {
    if (transport is! DiscoveryTransportDiagnostics || !ref.mounted) {
      return;
    }
    final snapshot = (transport as DiscoveryTransportDiagnostics).snapshot();
    state = state.copyWith(
      discoveryTransportMode: snapshot.mode,
      discoveryPreferredPort: snapshot.preferredPort == 0
          ? null
          : snapshot.preferredPort,
      discoveryReceivePort: snapshot.receivePort,
      discoverySendPort: snapshot.sendPort,
      discoveryReceivePortFallback: snapshot.receivePortFallback,
      discoveryBroadcastTargetCount: snapshot.broadcastTargetCount,
      discoveryBroadcastTargetPreview: snapshot.broadcastTargets
          .take(8)
          .toList(),
      discoveryBroadcastAttemptCount: snapshot.lastBroadcastAttemptCount,
      discoveryBroadcastSuccessCount: snapshot.lastBroadcastSuccessCount,
      discoveryBroadcastFailureCount: snapshot.lastBroadcastFailureCount,
      discoveryBroadcastAttemptPreview: snapshot.lastBroadcastAttemptPreview
          .take(12)
          .toList(),
      discoveryTargetSkipPreview: snapshot.discoveryTargetSkipPreview
          .take(12)
          .toList(),
      discoveryLastReceiveDecisionCode: snapshot.lastReceiveDecisionCode,
      discoveryMalformedPacketCount: snapshot.malformedPacketCount,
      discoveryTransportError: snapshot.lastError,
      clearDiscoveryTransportError: snapshot.lastError == null,
    );
  }

  List<PeerNode> _mergePeer(List<PeerNode> peers, PeerNode incomingPeer) {
    final updated = <PeerNode>[
      for (final peer in peers)
        if (peer.id != incomingPeer.id) peer,
      incomingPeer,
    ];
    return sortPeers(updated, sortMode: PeerSortMode.recent);
  }

  PeerNode _peerFromPacket(
    DiscoveryPacket packet,
    InternetAddress address, {
    required DateTime receivedAt,
  }) {
    return PeerNode(
      deviceId: packet.deviceId,
      instanceId: packet.instanceId,
      userId: packet.userId,
      displayName: packet.displayName,
      deviceName: packet.deviceName,
      osType: packet.osType,
      protocolVersion: packet.protocolVersion,
      lastSeenAt: receivedAt,
      address: address.address,
      port: packet.controlPort ?? packet.port,
      receiveAvailable: packet.receiveAvailable,
      presence: resolvePeerPresence(
        protocolVersion: packet.protocolVersion,
        config: ref.read(appConfigProvider),
        lastSeenAt: receivedAt,
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
    ref
        .read(appLoggerProvider)
        .info(
          AppLogCategory.discovery,
          'Discovery local registry scan entries=${entries.length} '
          'localInstance=${_short(localIdentity.instanceId)}',
        );

    var merged = peers;
    for (final entry in entries) {
      if (entry.instanceId == localIdentity.instanceId) {
        ref
            .read(appLoggerProvider)
            .info(
              AppLogCategory.discovery,
              'Discovery local registry entry ignored as self '
              'instance=${_short(entry.instanceId)} user=${entry.userId}',
            );
        continue;
      }
      if (!_matchesCurrentPairingGroupEntry(entry)) {
        ref
            .read(appLoggerProvider)
            .info(
              AppLogCategory.discovery,
              'Discovery local registry entry ignored by group/user filter '
              'entryUser=${entry.userId} localUser=${_currentUser()?.userId ?? '-'} '
              'entryGroup=${_discoveryGroupTagPreview(entry.discoveryGroupTag) ?? '-'} '
              'localGroup=${_discoveryGroupTagPreview(_currentDiscoveryGroupTag()) ?? '-'}',
            );
        continue;
      }

      final seenAt = DateTime.fromMillisecondsSinceEpoch(entry.seenAtEpochMs);
      final peer = PeerNode(
        deviceId: entry.deviceId,
        instanceId: entry.instanceId,
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
      _ingestLocalRegistryRouteCandidate(entry);
      merged = _mergePeer(merged, peer);
      if (!ref.mounted) {
        return _applyPresence(merged);
      }
      ref
          .read(peerAuthControllerProvider.notifier)
          .syncDiscoveredPeer(peer, message: 'Local discovery에서 피어를 발견했습니다.');
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.discovery,
            'Discovery local registry peer accepted peer=${peer.id} '
            'address=${peer.address}:${peer.port}',
          );
      await _maybeAutoHandshake(peer);
      if (!ref.mounted) {
        return _applyPresence(merged);
      }
    }

    state = state.copyWith(
      localRegistryEntryCount: entries.length,
      currentPairingUserId: _currentUser()?.userId,
      currentDiscoveryGroupTagPreview: _discoveryGroupTagPreview(
        _currentDiscoveryGroupTag(),
      ),
    );

    return _applyPresence(merged);
  }

  Future<List<PeerRouteCandidate>> _ingestDiscoveryRouteCandidates({
    required DiscoveryDatagram datagram,
    required DateTime receivedAt,
  }) async {
    final packet = datagram.packet;
    final previousCandidateIds = _currentRouteCandidateIds();
    List<NetworkInterfaceSnapshot> interfaces;
    try {
      interfaces = await ref.read(networkInterfaceInventoryProvider).scan();
    } catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning(
            AppLogCategory.discovery,
            'Failed to scan network interfaces for route candidates',
            error: error,
            stackTrace: stackTrace,
          );
      interfaces = const <NetworkInterfaceSnapshot>[];
    }
    if (!ref.mounted) {
      return const <PeerRouteCandidate>[];
    }
    final localCandidates = const ConnectableInterfacePolicy()
        .candidatesForRemote(
          remoteAddress: datagram.address.address,
          interfaces: interfaces,
        );
    final candidates = ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .ingestDiscoveryPacketCandidates(
          packet: packet,
          remoteAddress: datagram.address.address,
          remotePort: datagram.port,
          receivedAt: receivedAt,
          currentProtocolVersion: ref.read(appConfigProvider).protocolVersion,
          localCandidates: localCandidates,
        );
    _publishRouteCandidateEvents(
      candidates: candidates,
      previousCandidateIds: previousCandidateIds,
      correlationId: packet.messageId.isEmpty
          ? _peerIdFromPacket(packet)
          : packet.messageId,
      foundEventType: 'PeerRouteCandidateFound',
      updatedEventType: 'PeerRouteCandidateUpdated',
    );
    return candidates;
  }

  void _ingestLocalRegistryRouteCandidate(LocalInstancePresence entry) {
    final previousCandidateIds = _currentRouteCandidateIds();
    final candidate = ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .ingestLocalRegistry(presence: entry, now: _now());
    _publishRouteCandidateEvents(
      candidates: [candidate],
      previousCandidateIds: previousCandidateIds,
      correlationId: _peerIdFromLocalRegistry(entry),
      foundEventType: 'PeerRouteCandidateFound',
      updatedEventType: 'PeerRouteCandidateUpdated',
    );
  }

  String _peerIdFromPacket(DiscoveryPacket packet) {
    return PeerIdentity.resolve(
      userId: packet.userId,
      instanceId: packet.instanceId,
      deviceId: packet.deviceId,
    ).id;
  }

  String _peerIdFromLocalRegistry(LocalInstancePresence entry) {
    return PeerIdentity.resolve(
      userId: entry.userId,
      instanceId: entry.instanceId,
      deviceId: entry.deviceId,
    ).id;
  }

  void _expireRouteCandidates() {
    final expired = ref
        .read(peerRouteCandidateProjectionProvider.notifier)
        .expire(
          now: _now(),
          ttl: ref.read(appConfigProvider).discoveryOfflineAfter,
        );
    for (final candidate in expired) {
      _publishRouteCandidateEvent(
        candidate: candidate,
        eventType: 'PeerRouteCandidateExpired',
        correlationId: candidate.peerId,
        reasonCode: 'ttlExceeded',
      );
    }
  }

  Set<String> _currentRouteCandidateIds() {
    return ref
        .read(peerRouteCandidateProjectionProvider)
        .map((candidate) => candidate.candidateId)
        .toSet();
  }

  void _publishRouteCandidateEvents({
    required Iterable<PeerRouteCandidate> candidates,
    required Set<String> previousCandidateIds,
    required String correlationId,
    required String foundEventType,
    required String updatedEventType,
  }) {
    for (final candidate in candidates) {
      _publishRouteCandidateEvent(
        candidate: candidate,
        eventType: previousCandidateIds.contains(candidate.candidateId)
            ? updatedEventType
            : foundEventType,
        correlationId: correlationId,
      );
    }
  }

  void _publishRouteCandidateEvent({
    required PeerRouteCandidate candidate,
    required String eventType,
    required String correlationId,
    String? reasonCode,
  }) {
    ref
        .read(messageBusProvider)
        .publish(
          PeerRouteCandidateAppEvent(
            eventId: _eventId(eventType),
            occurredAt: _now(),
            correlationId: correlationId,
            source: 'DiscoveryController',
            severity: AppEventSeverity.debug,
            eventType: eventType,
            peerId: candidate.peerId,
            candidateId: candidate.candidateId,
            reasonCode: reasonCode,
          ),
        );
  }

  UserAccount? _currentUser() => ref.read(authControllerProvider).currentUser;

  String? _currentDiscoveryGroupTag() {
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
        .read(discoveryGroupTagServiceProvider)
        .deriveTag(
          protocolVersion: ref.read(appConfigProvider).protocolVersion,
          userId: user.userId,
          password: password,
        );
  }

  String? _discoveryGroupTagPreview(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return ref.read(discoveryGroupTagServiceProvider).preview(value);
  }

  bool _matchesCurrentPairingGroup(DiscoveryPacket packet) {
    final user = _currentUser();
    final discoveryGroupTag = _currentDiscoveryGroupTag();
    if (user == null || discoveryGroupTag == null) {
      return false;
    }
    return packet.userId == user.userId &&
        packet.discoveryGroupTag == discoveryGroupTag;
  }

  bool _matchesCurrentPairingGroupEntry(LocalInstancePresence entry) {
    final user = _currentUser();
    final discoveryGroupTag = _currentDiscoveryGroupTag();
    if (user == null || discoveryGroupTag == null) {
      return false;
    }
    return entry.userId == user.userId &&
        entry.discoveryGroupTag == discoveryGroupTag;
  }

  DateTime _now() => ref.read(nowProvider)();

  String _eventId(String prefix) => '$prefix-${_now().microsecondsSinceEpoch}';

  String _packetSummary(DiscoveryPacket packet) {
    return 'type=${packet.type.wireName} user=${packet.userId} '
        'device=${packet.deviceId} instance=${_short(packet.instanceId)} '
        'group=${_discoveryGroupTagPreview(packet.discoveryGroupTag) ?? '-'} '
        'discoveryPort=${packet.discoveryPort ?? '-'} '
        'controlPort=${packet.controlPort ?? packet.port} '
        'dataPort=${packet.dataPort ?? '-'} '
        'source=${packet.sourceAddress ?? '-'} '
        'msg=${_short(packet.messageId)}';
  }

  String _transportSnapshotSummary(DiscoveryTransport transport) {
    if (transport is! DiscoveryTransportDiagnostics) {
      return 'transportDiagnostics=unavailable';
    }
    final snapshot = (transport as DiscoveryTransportDiagnostics).snapshot();
    return 'mode=${snapshot.mode} preferredPort=${snapshot.preferredPort} '
        'receivePort=${snapshot.receivePort ?? '-'} '
        'sendPort=${snapshot.sendPort ?? '-'} '
        'fallback=${snapshot.receivePortFallback} '
        'targetCount=${snapshot.broadcastTargetCount} '
        'attempts=${snapshot.lastBroadcastAttemptCount} '
        'success=${snapshot.lastBroadcastSuccessCount} '
        'fail=${snapshot.lastBroadcastFailureCount} '
        'error=${snapshot.lastError ?? '-'} '
        'targets=${snapshot.broadcastTargets.take(8).join(' | ')} '
        'sendPreview=${snapshot.lastBroadcastAttemptPreview.take(12).join(' | ')}';
  }

  String _short(String value, {int max = 12}) {
    if (value.isEmpty) {
      return '-';
    }
    return value.length <= max ? value : value.substring(0, max);
  }

  Future<void> _autoHandshakePeers(List<PeerNode> peers) async {
    for (final peer in peers) {
      await _maybeAutoHandshake(peer);
    }
  }

  Future<void> _maybeAutoHandshake(PeerNode peer) async {
    if (!peer.isCompatible || peer.presence != PeerPresence.online) {
      ref
          .read(appLoggerProvider)
          .info(
            AppLogCategory.discovery,
            'Auto handshake skipped peer=${peer.id} compatible=${peer.isCompatible} '
            'presence=${peer.presence.name}',
          );
      return;
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
        .info(
          AppLogCategory.discovery,
          'Auto-starting peer handshake for ${peer.id} ${peer.address}:${peer.port}',
        );
    await ref.read(peerConnectionCoordinatorProvider.notifier).connect(peer);
  }

  Future<void> _dispose() async {
    await _stop(clearPeers: false);
  }

  Future<void> _stop({required bool clearPeers}) async {
    _cachedLogger?.info(
      AppLogCategory.discovery,
      'Discovery stopping clearPeers=$clearPeers '
      'hasPacketSubscription=${_packetSubscription != null} '
      'hasBroadcastTimer=${_broadcastTimer != null}',
    );
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    await _packetSubscription?.cancel();
    _packetSubscription = null;
    final localIdentity = _localIdentity;
    if (localIdentity != null) {
      await _localInstanceRegistry?.remove(localIdentity.instanceId);
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
