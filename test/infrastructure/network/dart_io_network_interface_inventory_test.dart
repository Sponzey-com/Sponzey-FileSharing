import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/network/dart_io_network_interface_inventory.dart';

void main() {
  test('classifies common desktop interface names', () {
    final fixtures = <String, InterfaceTypeHint>{
      'en0': InterfaceTypeHint.ethernet,
      'eth0': InterfaceTypeHint.ethernet,
      'Ethernet 2': InterfaceTypeHint.ethernet,
      'bridge100': InterfaceTypeHint.bridge,
      'br0': InterfaceTypeHint.bridge,
      'Thunderbolt Bridge': InterfaceTypeHint.bridge,
      'vEthernet (Default Switch)': InterfaceTypeHint.bridge,
      'docker0': InterfaceTypeHint.virtual,
      'br-123456': InterfaceTypeHint.virtual,
      'veth1234': InterfaceTypeHint.virtual,
      'utun4': InterfaceTypeHint.vpn,
      'tun0': InterfaceTypeHint.vpn,
      'tap0': InterfaceTypeHint.vpn,
      'wlan0': InterfaceTypeHint.wifi,
      'Wi-Fi': InterfaceTypeHint.wifi,
      'AirPort': InterfaceTypeHint.wifi,
      'p2p0': InterfaceTypeHint.unknown,
    };

    for (final entry in fixtures.entries) {
      expect(
        DartIoNetworkInterfaceInventory.classifyInterfaceName(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('does not require VM vendor names for discovery classification', () {
    final vendorNames = [
      'Parallels Shared Networking Adapter',
      'VirtualBox Host-Only Adapter',
      'Hyper-V Virtual Adapter',
      'vmnet8',
      'vboxnet0',
      'vnic0',
    ];

    for (final name in vendorNames) {
      expect(
        DartIoNetworkInterfaceInventory.classifyInterfaceName(name),
        InterfaceTypeHint.unknown,
        reason: name,
      );
    }
  });

  test('classifies loopback only when the interface is known loopback', () {
    expect(
      DartIoNetworkInterfaceInventory.classifyInterfaceName(
        'lo0',
        isLoopback: true,
      ),
      InterfaceTypeHint.loopback,
    );
    expect(
      DartIoNetworkInterfaceInventory.classifyInterfaceName(
        'Loopback Pseudo-Interface 1',
        isLoopback: true,
      ),
      InterfaceTypeHint.loopback,
    );
  });
}
