import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/network/connectable_interface_policy.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

void main() {
  test('prioritizes physical ethernet over bridge, wifi, and unknown', () {
    final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
      remoteAddress: '192.168.10.20',
      interfaces: [
        _snapshot(
          name: 'wlan0',
          index: 3,
          typeHint: InterfaceTypeHint.wifi,
          address: InterfaceAddress.ipv4(
            address: '192.168.10.13',
            prefixLength: 24,
          ),
        ),
        _snapshot(
          name: 'bridge100',
          index: 2,
          typeHint: InterfaceTypeHint.bridge,
          address: InterfaceAddress.ipv4(
            address: '192.168.10.12',
            prefixLength: 24,
          ),
        ),
        _snapshot(
          name: 'en0',
          index: 1,
          typeHint: InterfaceTypeHint.ethernet,
          address: InterfaceAddress.ipv4(
            address: '192.168.10.11',
            prefixLength: 24,
          ),
        ),
        _snapshot(
          name: 'p2p0',
          index: 4,
          typeHint: InterfaceTypeHint.unknown,
          address: InterfaceAddress.ipv4(
            address: '192.168.10.14',
            prefixLength: 24,
          ),
        ),
      ],
    );

    expect(candidates, hasLength(4));
    expect(candidates.map((candidate) => candidate.interfaceId.name), [
      'en0',
      'bridge100',
      'wlan0',
      'p2p0',
    ]);
    expect(candidates.first.priority, ConnectableInterfacePriority.primary);
  });

  test('keeps usb, thunderbolt ethernet, and internal bridge candidates', () {
    final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
      remoteAddress: '10.10.1.20',
      interfaces: [
        _snapshot(
          name: 'USB 10/100 LAN',
          index: 1,
          typeHint: InterfaceTypeHint.ethernet,
          address: InterfaceAddress.ipv4(
            address: '10.10.1.11',
            prefixLength: 24,
          ),
        ),
        _snapshot(
          name: 'Thunderbolt Ethernet',
          index: 2,
          typeHint: InterfaceTypeHint.ethernet,
          address: InterfaceAddress.ipv4(
            address: '10.10.1.12',
            prefixLength: 24,
          ),
        ),
        _snapshot(
          name: 'br0',
          index: 3,
          typeHint: InterfaceTypeHint.bridge,
          address: InterfaceAddress.ipv4(
            address: '10.10.1.13',
            prefixLength: 24,
          ),
        ),
      ],
    );

    expect(candidates.map((candidate) => candidate.interfaceId.name), [
      'Thunderbolt Ethernet',
      'USB 10/100 LAN',
      'br0',
    ]);
  });

  test(
    'excludes vpn tunnel container virtual link-local loopback and ipv6-only',
    () {
      final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
        remoteAddress: '10.10.1.20',
        interfaces: [
          _snapshot(
            name: 'utun4',
            index: 1,
            typeHint: InterfaceTypeHint.vpn,
            address: InterfaceAddress.ipv4(
              address: '10.10.1.11',
              prefixLength: 24,
            ),
          ),
          _snapshot(
            name: 'docker0',
            index: 2,
            typeHint: InterfaceTypeHint.virtual,
            address: InterfaceAddress.ipv4(
              address: '10.10.1.12',
              prefixLength: 24,
            ),
          ),
          _snapshot(
            name: 'en0',
            index: 3,
            typeHint: InterfaceTypeHint.ethernet,
            address: InterfaceAddress.ipv4(address: '169.254.1.5'),
          ),
          _snapshot(
            name: 'lo0',
            index: 4,
            typeHint: InterfaceTypeHint.loopback,
            address: InterfaceAddress.ipv4(address: '127.0.0.1'),
            isLoopback: true,
          ),
          _snapshot(
            name: 'en1',
            index: 5,
            typeHint: InterfaceTypeHint.ethernet,
            address: InterfaceAddress.ipv6(address: 'fe80::1'),
          ),
        ],
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.bindMode, UdpInterfaceBindMode.any);
      expect(candidates.single.localAddress, '0.0.0.0');
    },
  );

  test(
    'keeps virtual machine bridge candidates for Parallels and VM hosts',
    () {
      final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
        remoteAddress: '10.211.55.20',
        interfaces: [
          _snapshot(
            name: 'bridge100',
            index: 1,
            typeHint: InterfaceTypeHint.bridge,
            address: InterfaceAddress.ipv4(
              address: '10.211.55.2',
              prefixLength: 24,
            ),
          ),
          _snapshot(
            name: 'vmnet8',
            index: 2,
            typeHint: InterfaceTypeHint.bridge,
            address: InterfaceAddress.ipv4(
              address: '10.211.55.3',
              prefixLength: 24,
            ),
          ),
        ],
      );

      expect(candidates.map((candidate) => candidate.interfaceId.name), [
        'bridge100',
        'vmnet8',
      ]);
      expect(
        candidates.every(
          (candidate) =>
              candidate.priority == ConnectableInterfacePriority.secondary,
        ),
        isTrue,
      );
    },
  );

  test(
    'matches remote address to every local interface in the same subnet',
    () {
      final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
        remoteAddress: '192.168.10.20',
        interfaces: [
          _snapshot(
            name: 'en0',
            index: 1,
            typeHint: InterfaceTypeHint.ethernet,
            address: InterfaceAddress.ipv4(
              address: '192.168.10.5',
              prefixLength: 24,
            ),
          ),
          _snapshot(
            name: 'en1',
            index: 2,
            typeHint: InterfaceTypeHint.ethernet,
            address: InterfaceAddress.ipv4(
              address: '192.168.10.6',
              prefixLength: 24,
            ),
          ),
          _snapshot(
            name: 'en2',
            index: 3,
            typeHint: InterfaceTypeHint.ethernet,
            address: InterfaceAddress.ipv4(
              address: '10.0.0.5',
              prefixLength: 24,
            ),
          ),
        ],
      );

      expect(candidates.map((candidate) => candidate.localAddress), [
        '192.168.10.5',
        '192.168.10.6',
      ]);
    },
  );

  test('uses fallback prefix when prefix metadata is unavailable', () {
    final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
      remoteAddress: '172.16.4.20',
      interfaces: [
        _snapshot(
          name: 'en0',
          index: 1,
          typeHint: InterfaceTypeHint.ethernet,
          address: InterfaceAddress.ipv4(address: '172.16.4.5'),
        ),
      ],
    );

    expect(candidates.single.localAddress, '172.16.4.5');
    expect(candidates.single.bindMode, UdpInterfaceBindMode.specificAddress);
  });

  test('creates any-bind unknown fallback when no LAN candidate exists', () {
    final candidates = const ConnectableInterfacePolicy().candidatesForRemote(
      remoteAddress: '192.168.50.20',
      interfaces: const [],
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.interfaceId.stableId, 'unknown');
    expect(candidates.single.localAddress, '0.0.0.0');
    expect(candidates.single.bindMode, UdpInterfaceBindMode.any);
    expect(candidates.single.priority, ConnectableInterfacePriority.anyBind);
  });
}

NetworkInterfaceSnapshot _snapshot({
  required String name,
  required int index,
  required InterfaceTypeHint typeHint,
  required InterfaceAddress address,
  bool isLoopback = false,
}) {
  return NetworkInterfaceSnapshot(
    id: NetworkInterfaceId(name: name, index: index),
    name: name,
    displayName: name,
    typeHint: typeHint,
    isUp: true,
    supportsMulticast: true,
    isLoopback: isLoopback,
    addresses: [address],
    capturedAt: DateTime.utc(2026),
  );
}
