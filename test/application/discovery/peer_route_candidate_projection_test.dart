import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/discovery/peer_route_candidate_projection.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_node.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/domain/network/peer_route_candidate.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/local_instance_registry.dart';

void main() {
  test('creates tentative candidate when source hint is missing', () {
    final projection = PeerRouteCandidateProjection();

    final candidate = projection.ingestDiscoveryPacket(
      packet: _packet(),
      remoteAddress: '10.0.1.20',
      remotePort: 38400,
      receivedAt: DateTime.utc(2026),
      currentProtocolVersion: '1.0',
    );

    expect(candidate.localInterfaceId.stableId, 'unknown');
    expect(candidate.remotePort, 38401);
    expect(projection.peers, hasLength(1));
  });

  test('uses explicit local interface and keeps one representative peer', () {
    final projection = PeerRouteCandidateProjection();
    final now = DateTime.utc(2026);

    projection.ingestDiscoveryPacket(
      packet: _packet(deviceId: 'device-001'),
      remoteAddress: '10.0.1.20',
      remotePort: 38400,
      receivedAt: now,
      currentProtocolVersion: '1.0',
      localInterfaceId: const NetworkInterfaceId(name: 'en0', index: 1),
      localAddress: '10.0.1.10',
    );
    projection.ingestDiscoveryPacket(
      packet: _packet(deviceId: 'device-001'),
      remoteAddress: '192.168.1.20',
      remotePort: 38400,
      receivedAt: now,
      currentProtocolVersion: '1.0',
      localInterfaceId: const NetworkInterfaceId(name: 'en1', index: 2),
      localAddress: '192.168.1.10',
    );

    expect(projection.candidates, hasLength(2));
    expect(projection.peers, hasLength(1));
  });

  test('marks protocol mismatch peer as incompatible', () {
    final projection = PeerRouteCandidateProjection();

    projection.ingestDiscoveryPacket(
      packet: _packet(protocolVersion: '0.9'),
      remoteAddress: '10.0.1.20',
      remotePort: 38400,
      receivedAt: DateTime.utc(2026),
      currentProtocolVersion: '1.0',
    );

    expect(
      projection.candidates.single.status,
      RouteCandidateStatus.incompatible,
    );
    expect(projection.peers.single.presence, PeerPresence.incompatible);
  });

  test('turns local registry entries into loopback candidates', () {
    final projection = PeerRouteCandidateProjection();

    final candidate = projection.ingestLocalRegistry(
      presence: const LocalInstancePresence(
        userId: 'user',
        pairingProof: 'proof',
        instanceId: 'instance',
        displayName: 'Local',
        deviceId: 'device-local',
        deviceName: 'Local Mac',
        osType: 'macos',
        protocolVersion: '1.0',
        port: 38401,
        receiveAvailable: true,
        seenAtEpochMs: 1000,
      ),
      now: DateTime.utc(2026),
    );

    expect(candidate.discoveredBy, RouteCandidateDiscoverySource.localRegistry);
    expect(candidate.localInterfaceId.stableId, 'loopback');
    expect(candidate.remoteAddress, '127.0.0.1');
  });
}

DiscoveryPacket _packet({
  String protocolVersion = '1.0',
  String deviceId = 'device-001',
}) {
  return DiscoveryPacket(
    type: DiscoveryPacketType.discover,
    protocolVersion: protocolVersion,
    userId: 'user',
    pairingProof: 'proof',
    instanceId: 'instance',
    displayName: 'Peer',
    deviceId: deviceId,
    deviceName: 'Peer Mac',
    osType: 'macos',
    port: 38400,
    controlPort: 38401,
    receiveAvailable: true,
    sentAtEpochMs: 1,
  );
}
