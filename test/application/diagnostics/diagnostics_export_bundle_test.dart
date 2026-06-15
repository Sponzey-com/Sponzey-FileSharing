import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/application/auth/peer_auth_controller.dart';
import 'package:sponzey_file_sharing/application/diagnostics/diagnostics_export_bundle.dart';
import 'package:sponzey_file_sharing/application/discovery/discovery_controller.dart';
import 'package:sponzey_file_sharing/application/settings/settings_controller.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_controller.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/entities/app_settings.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_auth_session.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/entities/user_account.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_connection_path.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_route_snapshot.dart';

void main() {
  test('builds redacted product, debug, environment and development sections', () {
    final now = DateTime.utc(2026, 6, 15, 1, 2, 3);
    final candidate = _candidate(status: RouteCandidateStatus.expired);
    final activePath = PeerConnectionPath.fromCandidate(
      candidate: _candidate(),
      selectedAt: now,
      selectionReason: PeerPathSelectionReason.sameSubnet,
      dataPort: 38410,
    ).copyWith(status: PeerPathStatus.active);
    final bundle = DiagnosticsExportBundleBuilder().build(
      DiagnosticsExportInput(
        generatedAt: now,
        appName: 'Sponzey FileSharing',
        protocolVersion: '1.0',
        operatingSystem: 'macos',
        logLevel: AppLogLevel.debug,
        logFilePath: '/Users/dongwooshin/Library/Logs/private.log',
        authState: const AuthState(
          status: AuthStatus.authenticated,
          currentUser: UserAccount(
            userId: 'admin',
            displayName: 'admin',
            deviceName: 'mac',
          ),
          sessionPassword: 'plain-password',
        ),
        peerAuthState: PeerAuthState(
          sessions: {
            'peer-a': PeerAuthSession(
              sessionId: 'session-id-with-secret-key',
              peerId: 'peer-a',
              peerUserId: 'admin',
              peerDisplayName: 'admin',
              peerAddress: '10.0.1.20',
              peerPort: 38401,
              status: PeerAuthStatus.authenticated,
              updatedAt: now,
              message:
                  'token=aaaaaaaabbbbbbbb.ccccccccdddddddd.eeeeeeeeffffffff',
            ),
          },
          isListening: true,
          localPort: 38401,
        ),
        discoveryState: const DiscoveryState(
          peers: [],
          isRunning: true,
          receivedPacketCount: 4,
          discoveryBroadcastAttemptCount: 7,
          discoveryMalformedPacketCount: 2,
          lastDecisionCode: 'ignoredSelf',
          discoveryLastReceiveDecisionCode: 'groupMismatch',
        ),
        transferState: TransferState(
          jobs: [
            _job(
              status: TransferJobStatus.failed,
              message:
                  'route_probe_failed at /Users/dongwooshin/Downloads/file.zip',
            ),
          ],
        ),
        settingsState: SettingsState(
          settings: const AppSettings(
            defaultSavePath: '/Users/dongwooshin/Downloads/Sponzey FileSharing',
            autoReceiveEnabled: true,
            receivePolicy: ReceivePolicy.autoReceiveAll,
            logLevel: AppLogLevel.debug,
          ),
          errorMessage: 'sessionKey=do-not-export',
        ),
        routeCandidates: [candidate],
        activePaths: [activePath],
      ),
    );

    final jsonText = const JsonEncoder.withIndent('  ').convert(
      bundle.toJson(),
    );

    expect(bundle.toJson(), containsPair('product', isA<Map<String, Object?>>()));
    expect(bundle.toJson(), containsPair('debug', isA<Map<String, Object?>>()));
    expect(
      bundle.toJson(),
      containsPair('environment', isA<Map<String, Object?>>()),
    );
    expect(
      bundle.toJson(),
      containsPair('development', isA<Map<String, Object?>>()),
    );
    expect(jsonText, contains('peer-a'));
    expect(jsonText, contains('routeLeaseId'));
    expect(jsonText, contains('ROUTE_PROBE_FAILED'));
    expect(jsonText, contains('ignoredSelf'));
    expect(jsonText, contains('groupMismatch'));
    expect(jsonText, contains('stale'));
    expect(jsonText, contains('routeProbeFailure'));
    expect(jsonText, contains('packetDetailsExcluded'));
    expect(jsonText, isNot(contains('plain-password')));
    expect(jsonText, isNot(contains('session-key-value')));
    expect(jsonText, isNot(contains('do-not-export')));
    expect(jsonText, isNot(contains('aaaaaaaabbbbbbbb.ccccccccdddddddd')));
    expect(jsonText, isNot(contains('/Users/dongwooshin')));
    expect(jsonText, contains('.../file.zip'));
  });

  test('packet decision summary distinguishes route decisions', () {
    final now = DateTime.utc(2026);
    final summary = PacketDecisionSummary.fromSnapshots(
      discoveryState: const DiscoveryState(
        peers: [],
        receivedPacketCount: 3,
        discoveryBroadcastAttemptCount: 5,
        discoveryMalformedPacketCount: 1,
        lastDecisionCode: 'groupMismatch',
        discoveryLastReceiveDecisionCode: 'ignoredSelf',
      ),
      routeCandidates: [
        _candidate(status: RouteCandidateStatus.expired),
        _candidate(status: RouteCandidateStatus.failed),
      ],
      activePaths: [
        PeerConnectionPath.fromCandidate(
          candidate: _candidate(),
          selectedAt: now,
          selectionReason: PeerPathSelectionReason.sameSubnet,
        ).copyWith(status: PeerPathStatus.active),
      ],
    );

    expect(summary.sent, 5);
    expect(summary.received, 3);
    expect(summary.ignoredSelf, 1);
    expect(summary.groupMismatch, 1);
    expect(summary.malformed, 1);
    expect(summary.stale, 1);
    expect(summary.routePromoted, 1);
    expect(summary.routeProbeFailure, 1);
  });
}

PeerRouteCandidate _candidate({
  RouteCandidateStatus status = RouteCandidateStatus.reachable,
}) {
  return PeerRouteCandidate.create(
    peerId: 'peer-a',
    remoteAddress: '10.0.1.20',
    remotePort: 38401,
    localInterfaceId: const NetworkInterfaceId(
      name: 'en0',
      index: 1,
      stableId: 'en0',
    ),
    localAddress: '10.0.1.10',
    discoveredBy: RouteCandidateDiscoverySource.broadcast,
    seenAt: DateTime.utc(2026),
    status: status,
    score: 100,
    localInterfaceTypeHint: InterfaceTypeHint.ethernet,
  );
}

TransferJob _job({
  required TransferJobStatus status,
  required String message,
}) {
  return TransferJob(
    id: 'job-a',
    transferId: 'transfer-a',
    direction: TransferDirection.outgoing,
    peerId: 'peer-a',
    peerDisplayName: 'admin',
    fileName: 'file.zip',
    fileSize: 1024,
    bytesTransferred: 0,
    totalChunks: 1,
    completedChunks: 0,
    status: status,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    localFilePath: '/Users/dongwooshin/Downloads/file.zip',
    message: message,
    routeSnapshot: const TransferRouteSnapshot(
      routeLeaseId: 'path:peer-a|en0',
      peerId: 'peer-a',
      controlLocalAddress: '10.0.1.10',
      controlRemoteAddress: '10.0.1.20',
      controlRemotePort: 38401,
      localInterfaceId: 'en0',
      dataLocalAddress: '10.0.1.10',
      dataRemoteAddress: '10.0.1.20',
      dataRemotePort: 38410,
    ),
  );
}
