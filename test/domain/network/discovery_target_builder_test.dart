import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/network/discovery_target.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

void main() {
  group('Ipv4SubnetCalculator', () {
    const calculator = Ipv4SubnetCalculator();

    test('calculates /24, /16, and /20 directed broadcasts', () {
      expect(
        calculator.broadcastAddress(address: '192.168.10.23', prefixLength: 24),
        '192.168.10.255',
      );
      expect(
        calculator.broadcastAddress(address: '10.20.30.40', prefixLength: 16),
        '10.20.255.255',
      );
      expect(
        calculator.broadcastAddress(address: '172.16.5.7', prefixLength: 20),
        '172.16.15.255',
      );
    });

    test(
      'uses netmask and conservative fallback when prefix is unavailable',
      () {
        expect(
          calculator.broadcastAddress(
            address: '10.1.2.3',
            netmask: '255.255.0.0',
          ),
          '10.1.255.255',
        );
        expect(calculator.broadcastAddress(address: '10.1.2.3'), '10.1.2.255');
      },
    );

    test(
      'does not create directed broadcast for /31, /32, link-local, loopback',
      () {
        expect(
          calculator.broadcastAddress(address: '10.0.0.1', prefixLength: 31),
          isNull,
        );
        expect(
          calculator.broadcastAddress(address: '10.0.0.1', prefixLength: 32),
          isNull,
        );
        expect(calculator.broadcastAddress(address: '169.254.1.1'), isNull);
        expect(calculator.broadcastAddress(address: '127.0.0.1'), isNull);
      },
    );
  });

  group('DiscoveryTargetBuilder', () {
    test('returns target plan with explicit skip reasons', () {
      final plan = const DiscoveryTargetBuilder().buildPlan(
        interfaces: [
          _snapshot(
            name: 'en0',
            index: 1,
            address: InterfaceAddress.ipv4(address: '192.168.10.23'),
          ),
          _snapshot(
            name: 'lo0',
            index: 2,
            address: InterfaceAddress.ipv4(address: '127.0.0.1'),
            typeHint: InterfaceTypeHint.loopback,
            isLoopback: true,
          ),
          _snapshot(
            name: 'en1',
            index: 3,
            address: InterfaceAddress.ipv4(address: '169.254.10.20'),
          ),
          _snapshot(
            name: 'utun4',
            index: 4,
            address: InterfaceAddress.ipv4(address: '10.8.0.2'),
            typeHint: InterfaceTypeHint.vpn,
          ),
          _snapshot(
            name: 'en2',
            index: 5,
            address: InterfaceAddress.ipv6(address: 'fe80::1'),
          ),
        ],
        port: 38400,
      );

      expect(plan.targets, isNotEmpty);
      expect(
        plan.skipped.map((decision) => decision.reason),
        containsAll([
          DiscoveryTargetSkipReason.loopbackReservedForLocalRegistry,
          DiscoveryTargetSkipReason.linkLocalAddress,
          DiscoveryTargetSkipReason.unsupportedInterfaceType,
          DiscoveryTargetSkipReason.unsupportedAddressFamily,
        ]),
      );
      expect(plan.hasSelectedInterface, isTrue);
    });

    test('does not create loopback targets by default', () {
      final plan = const DiscoveryTargetBuilder().buildPlan(
        interfaces: [
          _snapshot(
            name: 'lo0',
            index: 1,
            address: InterfaceAddress.ipv4(address: '127.0.0.1'),
            typeHint: InterfaceTypeHint.loopback,
            isLoopback: true,
          ),
        ],
        port: 38400,
      );

      expect(plan.targets, isEmpty);
      expect(
        plan.skipped.single.reason,
        DiscoveryTargetSkipReason.loopbackReservedForLocalRegistry,
      );
    });

    test('builds per-interface limited, directed, and multicast targets', () {
      final targets = const DiscoveryTargetBuilder().build(
        interfaces: [
          _snapshot(
            name: 'en0',
            index: 1,
            address: InterfaceAddress.ipv4(
              address: '192.168.10.23',
              prefixLength: 24,
            ),
          ),
          _snapshot(
            name: 'en1',
            index: 2,
            address: InterfaceAddress.ipv4(
              address: '10.20.30.40',
              prefixLength: 16,
            ),
          ),
        ],
        port: 38400,
      );

      expect(targets, hasLength(6));
      expect(
        targets.where(
          (target) => target.type == DiscoveryTargetType.limitedBroadcast,
        ),
        hasLength(2),
      );
      expect(
        targets.map((target) => target.address),
        contains('10.20.255.255'),
      );
      expect(targets.map((target) => target.interfaceId.stableId).toSet(), {
        'en0#1',
        'en1#2',
      });
    });

    test('excludes multicast on unsupported interfaces', () {
      final targets = const DiscoveryTargetBuilder().build(
        interfaces: [
          _snapshot(
            name: 'utun0',
            index: 9,
            address: InterfaceAddress.ipv4(
              address: '10.8.0.2',
              prefixLength: 24,
            ),
            supportsMulticast: false,
          ),
        ],
        port: 38400,
      );

      expect(
        targets.any((target) => target.type == DiscoveryTargetType.multicast),
        isFalse,
      );
    });

    test('keeps interface identity when target addresses overlap', () {
      final targets = const DiscoveryTargetBuilder().build(
        interfaces: [
          _snapshot(
            name: 'en0',
            index: 1,
            address: InterfaceAddress.ipv4(address: '10.0.1.10'),
          ),
          _snapshot(
            name: 'en1',
            index: 2,
            address: InterfaceAddress.ipv4(address: '10.0.1.11'),
          ),
        ],
        port: 38400,
      );

      final limitedTargets = targets
          .where((target) => target.address == '255.255.255.255')
          .toList(growable: false);
      expect(limitedTargets, hasLength(2));
      expect(
        limitedTargets.map((target) => target.interfaceId.stableId).toSet(),
        {'en0#1', 'en1#2'},
      );
    });
  });
}

NetworkInterfaceSnapshot _snapshot({
  required String name,
  required int index,
  required InterfaceAddress address,
  InterfaceTypeHint typeHint = InterfaceTypeHint.ethernet,
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
