import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_inventory.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

final networkInterfaceInventoryProvider = Provider<NetworkInterfaceInventory>(
  (ref) => const DartIoNetworkInterfaceInventory(),
);

class DartIoNetworkInterfaceInventory implements NetworkInterfaceInventory {
  const DartIoNetworkInterfaceInventory({this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Future<List<NetworkInterfaceSnapshot>> scan() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: true,
      includeLinkLocal: true,
      type: InternetAddressType.any,
    );

    return [
      for (final interface in interfaces)
        NetworkInterfaceSnapshot(
          id: NetworkInterfaceId(
            name: interface.name,
            index: interface.index,
            displayName: interface.name,
          ),
          name: interface.name,
          displayName: interface.name,
          typeHint: _typeHintFor(interface),
          isUp: interface.addresses.isNotEmpty,
          supportsMulticast: !_isLoopback(interface),
          isLoopback: _isLoopback(interface),
          addresses: interface.addresses
              .map(_mapAddress)
              .whereType<InterfaceAddress>()
              .toList(growable: false),
          capturedAt: clock(),
          metadata: {
            'addressCount': interface.addresses.length.toString(),
            'prefixSource': 'unavailable:darto_network_interface',
          },
        ),
    ];
  }

  static InterfaceAddress? _mapAddress(InternetAddress address) {
    if (address.type == InternetAddressType.IPv4) {
      return InterfaceAddress.ipv4(address: address.address);
    }
    if (address.type == InternetAddressType.IPv6) {
      return InterfaceAddress.ipv6(address: address.address);
    }
    return null;
  }

  static InterfaceTypeHint _typeHintFor(NetworkInterface interface) {
    return classifyInterfaceName(
      interface.name,
      isLoopback: _isLoopback(interface),
    );
  }

  static bool _isLoopback(NetworkInterface interface) {
    final name = interface.name.toLowerCase();
    if (name == 'lo' || name.startsWith('lo') || name.contains('loopback')) {
      return true;
    }
    return interface.addresses.any((address) => address.isLoopback);
  }

  static InterfaceTypeHint classifyInterfaceName(
    String interfaceName, {
    bool isLoopback = false,
  }) {
    final name = interfaceName.toLowerCase();
    if (isLoopback) {
      return InterfaceTypeHint.loopback;
    }
    if (name.contains('utun') || name.contains('tun') || name.contains('tap')) {
      return InterfaceTypeHint.vpn;
    }
    if (_isContainerVirtualInterfaceName(name)) {
      return InterfaceTypeHint.virtual;
    }
    if (name.contains('bridge') || name.startsWith('br')) {
      return InterfaceTypeHint.bridge;
    }
    if (_isGenericVirtualBridgeInterfaceName(name)) {
      return InterfaceTypeHint.bridge;
    }
    if (name.contains('wlan') ||
        name.contains('wifi') ||
        name.contains('wi-fi') ||
        name.contains('airport')) {
      return InterfaceTypeHint.wifi;
    }
    if (name.startsWith('en') || name.startsWith('eth')) {
      return InterfaceTypeHint.ethernet;
    }
    return InterfaceTypeHint.unknown;
  }

  static bool _isContainerVirtualInterfaceName(String name) {
    return name.contains('docker') ||
        (name.startsWith('veth') && !name.startsWith('vethernet')) ||
        name.startsWith('br-') ||
        name.startsWith('cni') ||
        name.contains('podman') ||
        name.contains('flannel') ||
        name.startsWith('cali');
  }

  static bool _isGenericVirtualBridgeInterfaceName(String name) {
    return name.startsWith('vethernet');
  }
}
