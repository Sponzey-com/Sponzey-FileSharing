import 'dart:io';

import 'package:sponzey_file_sharing/domain/network/network_interface_inventory.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

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
    final name = interface.name.toLowerCase();
    if (_isLoopback(interface)) {
      return InterfaceTypeHint.loopback;
    }
    if (name.contains('utun') || name.contains('tun') || name.contains('tap')) {
      return InterfaceTypeHint.vpn;
    }
    if (name.contains('bridge') || name.startsWith('br')) {
      return InterfaceTypeHint.bridge;
    }
    if (name.contains('docker') ||
        name.contains('vbox') ||
        name.contains('vmnet') ||
        name.contains('veth') ||
        name.contains('hyper-v')) {
      return InterfaceTypeHint.virtual;
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

  static bool _isLoopback(NetworkInterface interface) {
    final name = interface.name.toLowerCase();
    if (name == 'lo' || name.startsWith('lo') || name.contains('loopback')) {
      return true;
    }
    return interface.addresses.any((address) => address.isLoopback);
  }
}
