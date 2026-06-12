import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

enum ConnectableInterfacePriority { primary, secondary, fallback, anyBind }

class ConnectableInterfaceCandidate {
  const ConnectableInterfaceCandidate({
    required this.interfaceId,
    required this.localAddress,
    required this.typeHint,
    required this.priority,
    required this.bindMode,
    required this.score,
  });

  final NetworkInterfaceId interfaceId;
  final String localAddress;
  final InterfaceTypeHint typeHint;
  final ConnectableInterfacePriority priority;
  final UdpInterfaceBindMode bindMode;
  final int score;
}

class ConnectableInterfacePolicy {
  const ConnectableInterfacePolicy({
    this.fallbackPrefixLength = 24,
    this.unknownInterfaceId = const NetworkInterfaceId(
      name: 'unknown',
      index: -1,
      stableId: 'unknown',
    ),
  });

  final int fallbackPrefixLength;
  final NetworkInterfaceId unknownInterfaceId;

  List<ConnectableInterfaceCandidate> candidatesForRemote({
    required String remoteAddress,
    required Iterable<NetworkInterfaceSnapshot> interfaces,
  }) {
    final remote = _parseIpv4(remoteAddress);
    if (remote == null || _isLoopback(remote) || _isLinkLocal(remote)) {
      return [_unknownCandidate()];
    }

    final candidates = <ConnectableInterfaceCandidate>[];
    for (final interface in interfaces) {
      if (!_isUsableInterface(interface)) {
        continue;
      }
      for (final address in interface.activeIpv4Addresses) {
        final local = _parseIpv4(address.address);
        if (local == null) {
          continue;
        }
        final prefix =
            address.prefixLength ??
            _prefixLengthFromNetmask(address.netmask) ??
            fallbackPrefixLength;
        if (!_isSameSubnet(
          local: local,
          remote: remote,
          prefixLength: prefix,
        )) {
          continue;
        }
        candidates.add(_candidate(interface, address.address));
      }
    }

    if (candidates.isEmpty) {
      return [_unknownCandidate()];
    }

    return candidates..sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final nameCompare = a.interfaceId.name.compareTo(b.interfaceId.name);
      if (nameCompare != 0) {
        return nameCompare;
      }
      return a.localAddress.compareTo(b.localAddress);
    });
  }

  ConnectableInterfaceCandidate _candidate(
    NetworkInterfaceSnapshot interface,
    String localAddress,
  ) {
    return ConnectableInterfaceCandidate(
      interfaceId: interface.id,
      localAddress: localAddress,
      typeHint: interface.typeHint,
      priority: _priorityFor(interface.typeHint),
      bindMode: UdpInterfaceBindMode.specificAddress,
      score: _scoreFor(interface.typeHint),
    );
  }

  ConnectableInterfaceCandidate _unknownCandidate() {
    return ConnectableInterfaceCandidate(
      interfaceId: unknownInterfaceId,
      localAddress: '0.0.0.0',
      typeHint: InterfaceTypeHint.unknown,
      priority: ConnectableInterfacePriority.anyBind,
      bindMode: UdpInterfaceBindMode.any,
      score: 0,
    );
  }

  static bool _isUsableInterface(NetworkInterfaceSnapshot interface) {
    if (!interface.isUp || interface.isLoopback) {
      return false;
    }
    switch (interface.typeHint) {
      case InterfaceTypeHint.loopback:
      case InterfaceTypeHint.vpn:
      case InterfaceTypeHint.virtual:
        return false;
      case InterfaceTypeHint.ethernet:
      case InterfaceTypeHint.wifi:
      case InterfaceTypeHint.bridge:
      case InterfaceTypeHint.unknown:
        return true;
    }
  }

  static ConnectableInterfacePriority _priorityFor(InterfaceTypeHint typeHint) {
    switch (typeHint) {
      case InterfaceTypeHint.ethernet:
        return ConnectableInterfacePriority.primary;
      case InterfaceTypeHint.bridge:
        return ConnectableInterfacePriority.secondary;
      case InterfaceTypeHint.wifi:
      case InterfaceTypeHint.unknown:
        return ConnectableInterfacePriority.fallback;
      case InterfaceTypeHint.loopback:
      case InterfaceTypeHint.vpn:
      case InterfaceTypeHint.virtual:
        return ConnectableInterfacePriority.anyBind;
    }
  }

  static int _scoreFor(InterfaceTypeHint typeHint) {
    switch (typeHint) {
      case InterfaceTypeHint.ethernet:
        return 1300;
      case InterfaceTypeHint.bridge:
        return 1220;
      case InterfaceTypeHint.wifi:
        return 1110;
      case InterfaceTypeHint.unknown:
        return 1080;
      case InterfaceTypeHint.loopback:
      case InterfaceTypeHint.vpn:
      case InterfaceTypeHint.virtual:
        return 0;
    }
  }

  static bool _isSameSubnet({
    required List<int> local,
    required List<int> remote,
    required int prefixLength,
  }) {
    if (prefixLength < 0 || prefixLength > 32) {
      return false;
    }
    if (prefixLength == 0) {
      return true;
    }
    final localInt = _toInt(local);
    final remoteInt = _toInt(remote);
    final mask = (0xffffffff << (32 - prefixLength)) & 0xffffffff;
    return (localInt & mask) == (remoteInt & mask);
  }

  static int? _prefixLengthFromNetmask(String? netmask) {
    if (netmask == null || netmask.trim().isEmpty) {
      return null;
    }
    final octets = _parseIpv4(netmask);
    if (octets == null) {
      return null;
    }
    final value = _toInt(octets);
    var seenZero = false;
    var count = 0;
    for (var bit = 31; bit >= 0; bit--) {
      final isOne = (value & (1 << bit)) != 0;
      if (isOne) {
        if (seenZero) {
          return null;
        }
        count++;
      } else {
        seenZero = true;
      }
    }
    return count;
  }

  static List<int>? _parseIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) {
      return null;
    }
    final octets = <int>[];
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) {
        return null;
      }
      octets.add(octet);
    }
    return octets;
  }

  static int _toInt(List<int> octets) {
    return (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];
  }

  static bool _isLoopback(List<int> octets) => octets[0] == 127;

  static bool _isLinkLocal(List<int> octets) {
    return octets[0] == 169 && octets[1] == 254;
  }
}
