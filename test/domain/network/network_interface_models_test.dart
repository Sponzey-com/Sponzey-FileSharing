import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_inventory.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

void main() {
  group('NetworkInterfaceId', () {
    test('uses stable value equality and ordering', () {
      const first = NetworkInterfaceId(name: 'en0', index: 1);
      const same = NetworkInterfaceId(name: 'en0', index: 1);
      const second = NetworkInterfaceId(name: 'en1', index: 2);

      expect(first, same);
      expect([second, first]..sort(), [first, second]);
    });
  });

  group('InterfaceAddress', () {
    test('classifies IPv4 private, link-local, and loopback addresses', () {
      final private = InterfaceAddress.ipv4(
        address: '192.168.10.23',
        prefixLength: 24,
      );
      final linkLocal = InterfaceAddress.ipv4(address: '169.254.1.10');
      final loopback = InterfaceAddress.ipv4(address: '127.0.0.1');

      expect(private.isPrivate, isTrue);
      expect(private.isLanCandidate, isTrue);
      expect(linkLocal.isLinkLocal, isTrue);
      expect(linkLocal.isLanCandidate, isFalse);
      expect(loopback.isLoopback, isTrue);
      expect(loopback.isLanCandidate, isFalse);
    });

    test(
      'preserves IPv6 but does not expose it as an active IPv4 candidate',
      () {
        final address = InterfaceAddress.ipv6(address: 'fe80::1');

        expect(address.isIpv6, isTrue);
        expect(address.isLinkLocal, isTrue);
        expect(address.isLanCandidate, isFalse);
      },
    );
  });

  test('snapshot is created without OS network interface types', () {
    final snapshot = NetworkInterfaceSnapshot(
      id: const NetworkInterfaceId(name: 'en0', index: 4),
      name: 'en0',
      typeHint: InterfaceTypeHint.ethernet,
      isUp: true,
      supportsMulticast: true,
      isLoopback: false,
      addresses: [
        InterfaceAddress.ipv4(address: '10.0.1.20', prefixLength: 24),
        InterfaceAddress.ipv6(address: 'fe80::1'),
      ],
      capturedAt: DateTime.utc(2026),
    );

    expect(snapshot.activeIpv4Addresses, hasLength(1));
    expect(snapshot.activeIpv4Addresses.single.address, '10.0.1.20');
  });

  test(
    'UDP interface endpoint represents discovery, control, and data roles',
    () {
      const interfaceId = NetworkInterfaceId(name: 'en0', index: 4);
      const discovery = UdpInterfaceEndpoint(
        role: UdpPortRole.discovery,
        interfaceId: interfaceId,
        localAddress: '10.0.1.20',
        port: 38400,
        bindMode: UdpInterfaceBindMode.specificAddress,
        reuseAddress: true,
      );
      const control = UdpInterfaceEndpoint(
        role: UdpPortRole.control,
        interfaceId: interfaceId,
        localAddress: '10.0.1.20',
        port: 38401,
        bindMode: UdpInterfaceBindMode.specificAddress,
      );
      const data = UdpInterfaceEndpoint(
        role: UdpPortRole.data,
        interfaceId: interfaceId,
        localAddress: '10.0.1.20',
        port: 38410,
        bindMode: UdpInterfaceBindMode.specificAddress,
      );

      expect(discovery.role, UdpPortRole.discovery);
      expect(control.role, UdpPortRole.control);
      expect(data.role, UdpPortRole.data);
      expect(discovery.isWildcardBind, isFalse);
    },
  );

  test(
    'fake inventory returns multiple snapshots for application tests',
    () async {
      final snapshots = [
        NetworkInterfaceSnapshot(
          id: const NetworkInterfaceId(name: 'en0', index: 1),
          name: 'en0',
          typeHint: InterfaceTypeHint.ethernet,
          isUp: true,
          supportsMulticast: true,
          isLoopback: false,
          addresses: [InterfaceAddress.ipv4(address: '10.0.1.20')],
          capturedAt: DateTime.utc(2026),
        ),
        NetworkInterfaceSnapshot(
          id: const NetworkInterfaceId(name: 'utun0', index: 2),
          name: 'utun0',
          typeHint: InterfaceTypeHint.vpn,
          isUp: true,
          supportsMulticast: false,
          isLoopback: false,
          addresses: [InterfaceAddress.ipv4(address: '10.8.0.2')],
          capturedAt: DateTime.utc(2026),
        ),
      ];

      final inventory = FakeNetworkInterfaceInventory(snapshots);

      expect(await inventory.scan(), snapshots);
    },
  );

  test(
    'loopback and link-local snapshots are excluded from LAN candidates',
    () {
      final loopback = NetworkInterfaceSnapshot(
        id: const NetworkInterfaceId(name: 'lo0', index: 1),
        name: 'lo0',
        typeHint: InterfaceTypeHint.loopback,
        isUp: true,
        supportsMulticast: false,
        isLoopback: true,
        addresses: [InterfaceAddress.ipv4(address: '127.0.0.1')],
        capturedAt: DateTime.utc(2026),
      );
      final linkLocal = NetworkInterfaceSnapshot(
        id: const NetworkInterfaceId(name: 'en0', index: 2),
        name: 'en0',
        typeHint: InterfaceTypeHint.ethernet,
        isUp: true,
        supportsMulticast: true,
        isLoopback: false,
        addresses: [InterfaceAddress.ipv4(address: '169.254.12.1')],
        capturedAt: DateTime.utc(2026),
      );

      expect(loopback.activeIpv4Addresses, isEmpty);
      expect(linkLocal.activeIpv4Addresses, isEmpty);
    },
  );
}
