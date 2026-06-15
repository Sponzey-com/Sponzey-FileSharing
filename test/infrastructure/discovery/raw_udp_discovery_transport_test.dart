import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/logger/console_app_logger.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_inventory.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/raw_udp_discovery_transport.dart';

void main() {
  test('derives directed broadcast from IPv4 address', () {
    final address = InternetAddress('10.211.55.3');

    final directedBroadcast = RawUdpDiscoveryTransport.directedBroadcastFor(
      address,
    );

    expect(directedBroadcast, isNotNull);
    expect(directedBroadcast!.address, '10.211.55.255');
  });

  test('includes limited, multicast, and directed broadcast targets', () {
    final targets = RawUdpDiscoveryTransport.broadcastTargetsForAddresses([
      InternetAddress('10.211.55.3'),
    ]);

    expect(targets, contains('255.255.255.255'));
    expect(targets, contains('239.255.42.99'));
    expect(targets, contains('10.211.55.255'));
  });

  test('ignores loopback and link-local addresses for directed broadcast', () {
    expect(
      RawUdpDiscoveryTransport.directedBroadcastFor(
        InternetAddress.loopbackIPv4,
      ),
      isNull,
    );
    expect(
      RawUdpDiscoveryTransport.directedBroadcastFor(
        InternetAddress('169.254.10.20'),
      ),
      isNull,
    );
  });

  test('recognizes Windows invalid argument socket errors as recoverable', () {
    expect(
      RawUdpDiscoveryTransport.isInvalidSocketArgumentError(
        const OSError('잘못된 인수를 입력했습니다.', 10022),
      ),
      isTrue,
    );
    expect(
      RawUdpDiscoveryTransport.isInvalidSocketArgumentError(
        const OSError('Invalid argument', 22),
      ),
      isTrue,
    );
    expect(
      RawUdpDiscoveryTransport.isInvalidSocketArgumentError(
        const OSError('Access denied', 5),
      ),
      isFalse,
    );
  });

  test('discovery bind policy never enables reusePort on Windows', () {
    final windows = RawUdpDiscoveryTransport.bindOptionsFor(
      platform: DiscoverySocketPlatform.windows,
    );
    final posix = RawUdpDiscoveryTransport.bindOptionsFor(
      platform: DiscoverySocketPlatform.posix,
    );

    expect(windows, isNotEmpty);
    expect(windows.every((option) => option.reusePort == false), isTrue);
    expect(
      windows.first,
      const DiscoverySocketBindOptions(reuseAddress: false, reusePort: false),
    );
    expect(posix.first.reusePort, isTrue);
  });

  test('keeps every default connectable LAN interface for discovery', () {
    final selected = RawUdpDiscoveryTransport.selectPreferredInterfaces([
      _snapshot(
        name: 'Wi-Fi',
        index: 4,
        typeHint: InterfaceTypeHint.wifi,
        address: InterfaceAddress.ipv4(address: '192.168.0.10'),
      ),
      _snapshot(
        name: 'Ethernet',
        index: 5,
        typeHint: InterfaceTypeHint.ethernet,
        address: InterfaceAddress.ipv4(address: '10.0.0.10'),
      ),
      _snapshot(
        name: 'bridge100',
        index: 7,
        typeHint: InterfaceTypeHint.bridge,
        address: InterfaceAddress.ipv4(address: '10.0.1.10'),
      ),
      _snapshot(
        name: 'vmnet8',
        index: 6,
        typeHint: InterfaceTypeHint.bridge,
        address: InterfaceAddress.ipv4(address: '172.20.0.1'),
      ),
      _snapshot(
        name: 'docker0',
        index: 9,
        typeHint: InterfaceTypeHint.virtual,
        address: InterfaceAddress.ipv4(address: '172.21.0.1'),
      ),
      _snapshot(
        name: 'utun4',
        index: 8,
        typeHint: InterfaceTypeHint.vpn,
        address: InterfaceAddress.ipv4(address: '10.8.0.2'),
      ),
    ]);

    expect(selected.map((interface) => interface.name), [
      'Ethernet',
      'bridge100',
      'vmnet8',
      'Wi-Fi',
    ]);
  });

  test('explains discovery interface selection decisions', () {
    final ethernet = _snapshot(
      name: 'Ethernet',
      index: 1,
      typeHint: InterfaceTypeHint.ethernet,
      address: InterfaceAddress.ipv4(address: '10.0.0.10'),
    );
    final parallelsBridge = _snapshot(
      name: 'vnic0',
      index: 2,
      typeHint: InterfaceTypeHint.bridge,
      address: InterfaceAddress.ipv4(address: '10.211.55.2'),
    );
    final docker = _snapshot(
      name: 'docker0',
      index: 3,
      typeHint: InterfaceTypeHint.virtual,
      address: InterfaceAddress.ipv4(address: '172.21.0.1'),
    );
    final vpn = _snapshot(
      name: 'utun4',
      index: 4,
      typeHint: InterfaceTypeHint.vpn,
      address: InterfaceAddress.ipv4(address: '10.8.0.2'),
    );
    final loopback = _snapshot(
      name: 'lo0',
      index: 5,
      typeHint: InterfaceTypeHint.loopback,
      address: InterfaceAddress.ipv4(address: '127.0.0.1'),
      isLoopback: true,
    );
    final down = _snapshot(
      name: 'en9',
      index: 6,
      typeHint: InterfaceTypeHint.ethernet,
      address: InterfaceAddress.ipv4(address: '10.9.0.2'),
      isUp: false,
    );
    final noLanIpv4 = _snapshot(
      name: 'en10',
      index: 7,
      typeHint: InterfaceTypeHint.ethernet,
      address: InterfaceAddress.ipv6(address: 'fe80::1'),
    );

    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(ethernet).label,
      'selected',
    );
    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(
        parallelsBridge,
      ).label,
      'selected',
    );
    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(docker).label,
      'excluded:type-virtual',
    );
    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(vpn).label,
      'excluded:type-vpn',
    );
    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(loopback).label,
      'excluded:loopback',
    );
    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(down).label,
      'excluded:interface-down',
    );
    expect(
      RawUdpDiscoveryTransport.discoveryInterfaceDecision(noLanIpv4).label,
      'excluded:no-active-lan-ipv4',
    );
  });

  test(
    'falls back to a receive port when preferred port is occupied',
    () async {
      final blocker = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: false,
        reusePort: false,
      );
      final transport = RawUdpDiscoveryTransport(
        logger: const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      );
      addTearDown(() async {
        blocker.close();
        await transport.close();
      });

      await transport.start(port: blocker.port);

      final snapshot = transport.snapshot();
      expect(snapshot.mode, 'fallback-receive');
      expect(snapshot.preferredPort, blocker.port);
      expect(snapshot.receivePort, isNot(blocker.port));
      expect(snapshot.receivePortFallback, isTrue);
    },
  );

  test('records malformed receive decisions in diagnostics', () async {
    final transport = RawUdpDiscoveryTransport(
      logger: const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
    );
    final sender = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() async {
      sender.close();
      await transport.close();
    });

    await transport.start(port: 0);
    final receivePort = transport.snapshot().receivePort;
    expect(receivePort, isNotNull);

    sender.send([1, 2, 3, 4], InternetAddress.loopbackIPv4, receivePort!);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final snapshot = transport.snapshot();
    expect(snapshot.malformedPacketCount, 1);
    expect(snapshot.lastReceiveDecisionCode, 'malformed');
  });

  test('interface sender bind failure does not fail discovery start', () async {
    final transport = RawUdpDiscoveryTransport(
      logger: const ConsoleAppLogger(minimumLevel: AppLogLevel.error),
      networkInterfaceInventory: _FakeNetworkInterfaceInventory([
        _snapshot(
          name: 'ghost0',
          index: 99,
          typeHint: InterfaceTypeHint.ethernet,
          address: InterfaceAddress.ipv4(
            address: '203.0.113.10',
            prefixLength: 24,
          ),
        ),
      ]),
    );
    addTearDown(transport.close);

    await transport.start(port: 0);

    final snapshot = transport.snapshot();
    expect(snapshot.mode, 'receive-send');
    expect(snapshot.broadcastTargetCount, greaterThan(0));
  });
}

NetworkInterfaceSnapshot _snapshot({
  required String name,
  required int index,
  required InterfaceTypeHint typeHint,
  required InterfaceAddress address,
  bool isUp = true,
  bool supportsMulticast = true,
  bool isLoopback = false,
}) {
  return NetworkInterfaceSnapshot(
    id: NetworkInterfaceId(name: name, index: index),
    name: name,
    typeHint: typeHint,
    isUp: isUp,
    supportsMulticast: supportsMulticast,
    isLoopback: isLoopback,
    addresses: [address],
    capturedAt: DateTime.utc(2026),
  );
}

class _FakeNetworkInterfaceInventory implements NetworkInterfaceInventory {
  const _FakeNetworkInterfaceInventory(this.snapshots);

  final List<NetworkInterfaceSnapshot> snapshots;

  @override
  Future<List<NetworkInterfaceSnapshot>> scan() async => snapshots;
}
