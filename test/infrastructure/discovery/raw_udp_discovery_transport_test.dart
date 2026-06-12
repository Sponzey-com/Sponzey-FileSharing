import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  test('prefers usable ethernet interfaces over wifi and virtual adapters', () {
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
        name: 'vEthernet',
        index: 6,
        typeHint: InterfaceTypeHint.virtual,
        address: InterfaceAddress.ipv4(address: '172.20.0.1'),
      ),
    ]);

    expect(selected, hasLength(1));
    expect(selected.single.name, 'Ethernet');
  });
}

NetworkInterfaceSnapshot _snapshot({
  required String name,
  required int index,
  required InterfaceTypeHint typeHint,
  required InterfaceAddress address,
}) {
  return NetworkInterfaceSnapshot(
    id: NetworkInterfaceId(name: name, index: index),
    name: name,
    typeHint: typeHint,
    isUp: true,
    supportsMulticast: true,
    isLoopback: false,
    addresses: [address],
    capturedAt: DateTime.utc(2026),
  );
}
