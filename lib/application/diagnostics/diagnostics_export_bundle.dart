import 'dart:convert';

import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/core/diagnostics/diagnostics_redactor.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';

class DiagnosticsExportBundle {
  const DiagnosticsExportBundle({
    required this.generatedAt,
    required this.product,
    required this.debug,
    required this.environment,
    required this.development,
  });

  final DateTime generatedAt;
  final Map<String, Object?> product;
  final Map<String, Object?> debug;
  final Map<String, Object?> environment;
  final Map<String, Object?> development;

  Map<String, Object?> toJson() {
    return DiagnosticsRedactor.redactValue({
          'generatedAt': generatedAt.toIso8601String(),
          'product': product,
          'debug': debug,
          'environment': environment,
          'development': development,
        })
        as Map<String, Object?>;
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class DiagnosticsExportInput {
  const DiagnosticsExportInput({
    required this.generatedAt,
    required this.appName,
    required this.protocolVersion,
    required this.operatingSystem,
    required this.logLevel,
    required this.authState,
    required this.peerAuthState,
    required this.discoveryState,
    required this.transferState,
    required this.settingsState,
    required this.routeCandidates,
    required this.activePaths,
    this.logFilePath,
  });

  final DateTime generatedAt;
  final String appName;
  final String protocolVersion;
  final String operatingSystem;
  final AppLogLevel logLevel;
  final String? logFilePath;
  final AuthState authState;
  final PeerAuthState peerAuthState;
  final DiscoveryState discoveryState;
  final TransferState transferState;
  final SettingsState settingsState;
  final List<PeerRouteCandidate> routeCandidates;
  final List<PeerConnectionPath> activePaths;
}

class PacketDecisionSummary {
  const PacketDecisionSummary({
    required this.sent,
    required this.received,
    required this.ignoredSelf,
    required this.groupMismatch,
    required this.malformed,
    required this.stale,
    required this.routePromoted,
    required this.routeProbeFailure,
  });

  final int sent;
  final int received;
  final int ignoredSelf;
  final int groupMismatch;
  final int malformed;
  final int stale;
  final int routePromoted;
  final int routeProbeFailure;

  factory PacketDecisionSummary.fromSnapshots({
    required DiscoveryState discoveryState,
    required Iterable<PeerRouteCandidate> routeCandidates,
    required Iterable<PeerConnectionPath> activePaths,
  }) {
    final decisionCodes = [
      discoveryState.lastDecisionCode,
      discoveryState.discoveryLastReceiveDecisionCode,
    ].whereType<String>().map((code) => code.toLowerCase()).toList();
    final candidates = routeCandidates.toList(growable: false);
    final paths = activePaths.toList(growable: false);
    return PacketDecisionSummary(
      sent: discoveryState.discoveryBroadcastAttemptCount,
      received: discoveryState.receivedPacketCount,
      ignoredSelf: decisionCodes.where((code) => code == 'ignoredself').length,
      groupMismatch: decisionCodes
          .where((code) => code == 'groupmismatch')
          .length,
      malformed: discoveryState.discoveryMalformedPacketCount,
      stale: candidates
          .where((candidate) => candidate.status == RouteCandidateStatus.expired)
          .length,
      routePromoted: paths
          .where((path) => path.status == PeerPathStatus.active)
          .length,
      routeProbeFailure:
          candidates
              .where(
                (candidate) =>
                    candidate.status == RouteCandidateStatus.failed ||
                    candidate.failureCount > 0,
              )
              .length +
          paths
              .where(
                (path) =>
                    path.status == PeerPathStatus.probeFailed ||
                    path.status == PeerPathStatus.failed,
              )
              .length,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sent': sent,
      'received': received,
      'ignoredSelf': ignoredSelf,
      'groupMismatch': groupMismatch,
      'malformed': malformed,
      'stale': stale,
      'routePromoted': routePromoted,
      'routeProbeFailure': routeProbeFailure,
    };
  }
}

class DiagnosticsExportBundleBuilder {
  const DiagnosticsExportBundleBuilder();

  DiagnosticsExportBundle build(DiagnosticsExportInput input) {
    final packetSummary = PacketDecisionSummary.fromSnapshots(
      discoveryState: input.discoveryState,
      routeCandidates: input.routeCandidates,
      activePaths: input.activePaths,
    );
    final terminalJobs = input.transferState.jobs
        .where((job) => job.isTerminal || job.message != null)
        .toList(growable: false);

    return DiagnosticsExportBundle(
      generatedAt: input.generatedAt,
      product: {
        'appName': input.appName,
        'authStatus': input.authState.status.name,
        'currentUser': input.authState.currentUser?.userId ?? '-',
        'discoveryRunning': input.discoveryState.isRunning,
        'peerCount': input.discoveryState.peers.length,
        'authenticatedPeerCount': input.peerAuthState.sessions.values
            .where((session) => session.isAuthenticated)
            .length,
        'activeRouteCount': input.activePaths
            .where((path) => path.status == PeerPathStatus.active)
            .length,
        'transferCount': input.transferState.jobs.length,
        'failedTransferCount': input.transferState.jobs
            .where((job) => job.status == TransferJobStatus.failed)
            .length,
        'storageStatus': _storageStatus(input.settingsState),
      },
      debug: {
        'packetDecisionSummary': packetSummary.toJson(),
        'discovery': _discoverySnapshot(input.discoveryState),
        'routes': _routeSnapshot(input.routeCandidates, input.activePaths),
        'authSessions': input.peerAuthState.sessions.values
            .map(_authSessionSnapshot)
            .toList(growable: false),
        'transfers': input.transferState.jobs
            .map(_transferSnapshot)
            .toList(growable: false),
        'recentTransferErrors': terminalJobs
            .map(_transferErrorSnapshot)
            .toList(growable: false),
        'storage': _storageSnapshot(input.settingsState),
      },
      environment: {
        'operatingSystem': input.operatingSystem,
        'protocolVersion': input.protocolVersion,
        'logLevel': input.logLevel.name,
        'logFilePath': input.logFilePath,
      },
      development: const {
        'packetDetailsExcluded': true,
        'packetPayloadExcluded': true,
        'frameTraceExcludedByDefault': true,
      },
    );
  }

  static Map<String, Object?> _discoverySnapshot(DiscoveryState state) {
    return {
      'running': state.isRunning,
      'loading': state.isLoading,
      'error': state.errorMessage,
      'transportMode': state.discoveryTransportMode,
      'preferredPort': state.discoveryPreferredPort,
      'receivePort': state.discoveryReceivePort,
      'sendPort': state.discoverySendPort,
      'receivePortFallback': state.discoveryReceivePortFallback,
      'broadcastTargets': state.discoveryBroadcastTargetCount,
      'broadcastTargetPreview': state.discoveryBroadcastTargetPreview,
      'broadcastAttempts': state.discoveryBroadcastAttemptCount,
      'broadcastSuccess': state.discoveryBroadcastSuccessCount,
      'broadcastFailure': state.discoveryBroadcastFailureCount,
      'broadcastAttemptPreview': state.discoveryBroadcastAttemptPreview,
      'targetSkipPreview': state.discoveryTargetSkipPreview,
      'receivedPackets': state.receivedPacketCount,
      'malformedPackets': state.discoveryMalformedPacketCount,
      'lastPacketAt': state.lastPacketAt?.toIso8601String(),
      'lastDecision': state.lastDecision,
      'lastDecisionCode': state.lastDecisionCode,
      'lastReceiveDecisionCode': state.discoveryLastReceiveDecisionCode,
      'transportError': state.discoveryTransportError,
    };
  }

  static Map<String, Object?> _routeSnapshot(
    List<PeerRouteCandidate> candidates,
    List<PeerConnectionPath> activePaths,
  ) {
    final activeByPeer = {
      for (final path in activePaths) path.peerId: path,
    };
    final peerIds = <String>{
      for (final candidate in candidates) candidate.peerId,
      for (final path in activePaths) path.peerId,
    }.toList()..sort();
    return {
      'peerCount': peerIds.length,
      'candidateCount': candidates.length,
      'activeRouteCount': activePaths.length,
      'peers': [
        for (final peerId in peerIds)
          {
            'peerId': peerId,
            'activeRouteLease': activeByPeer[peerId] == null
                ? null
                : _activePathSnapshot(activeByPeer[peerId]!),
            'routeCandidates': candidates
                .where((candidate) => candidate.peerId == peerId)
                .map(_candidateSnapshot)
                .toList(growable: false),
          },
      ],
    };
  }

  static Map<String, Object?> _candidateSnapshot(
    PeerRouteCandidate candidate,
  ) {
    return {
      'candidateId': candidate.candidateId,
      'peerId': candidate.peerId,
      'localInterfaceId': candidate.localInterfaceId.stableId,
      'localAddress': candidate.localAddress,
      'remoteAddress': candidate.remoteAddress,
      'remotePort': candidate.remotePort,
      'discoveredBy': candidate.discoveredBy.name,
      'status': candidate.status.name,
      'typeHint': candidate.localInterfaceTypeHint.name,
      'bindMode': candidate.bindMode.name,
      'score': candidate.score,
      'rttMs': candidate.rttMs,
      'failureCount': candidate.failureCount,
      'compatible': candidate.compatible,
      'receiveAvailable': candidate.receiveAvailable,
      'lastSeenAt': candidate.lastSeenAt.toIso8601String(),
    };
  }

  static Map<String, Object?> _activePathSnapshot(PeerConnectionPath path) {
    return {
      'routeLeaseId': path.pathId,
      'peerId': path.peerId,
      'status': path.status.name,
      'selectionReason': path.selectionReason.name,
      'localInterfaceId': path.candidate.localInterfaceId.stableId,
      'controlLocalAddress': path.controlEndpoint.localAddress,
      'controlRemoteAddress': path.candidate.remoteAddress,
      'controlRemotePort': path.candidate.remotePort,
      'dataLocalAddress': path.dataEndpoint?.localAddress,
      'dataRemoteAddress': path.candidate.remoteAddress,
      'dataRemotePort': path.dataEndpoint?.port,
      'failureReasonCode': path.failureReasonCode,
      'rttMs': path.rttMs,
      'selectedAt': path.selectedAt.toIso8601String(),
    };
  }

  static Map<String, Object?> _authSessionSnapshot(PeerAuthSession session) {
    return {
      'sessionId': _safeId(session.sessionId),
      'peerId': session.peerId,
      'peerUserId': session.peerUserId,
      'peerDisplayName': session.peerDisplayName,
      'status': session.status.name,
      'safeClaims': {
        'subjectUserId': session.peerUserId,
        'peerAddress': session.peerAddress,
        'peerPort': session.peerPort,
      },
      'updatedAt': session.updatedAt.toIso8601String(),
      'message': session.message,
    };
  }

  static Map<String, Object?> _transferSnapshot(TransferJob job) {
    return {
      'transferId': _safeId(job.transferId),
      'peerId': job.peerId,
      'direction': job.direction.name,
      'fileName': job.fileName,
      'fileSize': job.fileSize,
      'bytesTransferred': job.bytesTransferred,
      'state': job.status.name,
      'errorCode': _errorCode(job),
      'lastError': job.message,
      'sessionId': null,
      'routeLeaseId': job.routeSnapshot?.routeLeaseId,
      'route': job.routeSnapshot == null
          ? null
          : {
              'localInterfaceId': job.routeSnapshot!.localInterfaceId,
              'controlLocalAddress': job.routeSnapshot!.controlLocalAddress,
              'controlRemoteAddress': job.routeSnapshot!.controlRemoteAddress,
              'controlRemotePort': job.routeSnapshot!.controlRemotePort,
              'dataLocalAddress': job.routeSnapshot!.dataLocalAddress,
              'dataRemoteAddress': job.routeSnapshot!.dataRemoteAddress,
              'dataRemotePort': job.routeSnapshot!.dataRemotePort,
            },
      'localFilePath': job.localFilePath,
      'destinationPath': job.destinationPath,
      'updatedAt': job.updatedAt.toIso8601String(),
    };
  }

  static Map<String, Object?> _transferErrorSnapshot(TransferJob job) {
    return {
      'transferId': _safeId(job.transferId),
      'state': job.status.name,
      'errorCode': _errorCode(job),
      'lastError': job.message,
      'routeLeaseId': job.routeSnapshot?.routeLeaseId,
    };
  }

  static String _storageStatus(SettingsState state) {
    if (state.errorMessage != null) {
      return 'error';
    }
    if (state.settings.defaultSavePath.trim().isEmpty) {
      return 'missingPath';
    }
    return 'ready';
  }

  static Map<String, Object?> _storageSnapshot(SettingsState state) {
    return {
      'savePathStatus': _storageStatus(state),
      'defaultSavePath': state.settings.defaultSavePath,
      'receivePolicy': state.settings.receivePolicy.name,
      'autoReceiveEnabled': state.settings.autoReceiveEnabled,
      'lastStorageError': state.errorMessage,
    };
  }

  static String _errorCode(TransferJob job) {
    if (job.status == TransferJobStatus.failed) {
      final message = job.message?.toLowerCase() ?? '';
      if (message.contains('route_probe_failed')) {
        return 'ROUTE_PROBE_FAILED';
      }
      if (message.contains('timeout') || message.contains('시간 초과')) {
        return 'TRANSFER_TIMEOUT';
      }
      if (message.contains('path') || message.contains('경로')) {
        return 'STORAGE_PATH_FAILED';
      }
      return 'TRANSFER_FAILED';
    }
    if (job.status == TransferJobStatus.rejected) {
      return 'TRANSFER_REJECTED';
    }
    if (job.status == TransferJobStatus.cancelled) {
      return 'TRANSFER_CANCELLED';
    }
    return 'NONE';
  }

  static String _safeId(String value) {
    if (value.length <= 12) {
      return value;
    }
    return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
  }
}
