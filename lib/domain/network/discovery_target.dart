import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

enum DiscoveryTargetType { limitedBroadcast, directedBroadcast, multicast }

enum DiscoveryTargetSkipReason {
  interfaceDown,
  loopbackReservedForLocalRegistry,
  unsupportedInterfaceType,
  noBroadcastIpv4,
  unsupportedAddressFamily,
  loopbackAddress,
  linkLocalAddress,
  malformedBroadcastAddress,
  multicastUnsupported,
}

class DiscoveryTarget {
  const DiscoveryTarget({
    required this.interfaceId,
    required this.localAddress,
    required this.address,
    required this.port,
    required this.type,
  });

  final NetworkInterfaceId interfaceId;
  final String localAddress;
  final String address;
  final int port;
  final DiscoveryTargetType type;

  String get dedupeKey {
    return '${interfaceId.stableId}|$localAddress|$address|$port|${type.name}';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiscoveryTarget &&
            other.interfaceId == interfaceId &&
            other.localAddress == localAddress &&
            other.address == address &&
            other.port == port &&
            other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(interfaceId, localAddress, address, port, type);
  }
}

class DiscoveryTargetDecision {
  const DiscoveryTargetDecision({
    required this.interfaceId,
    required this.reason,
    this.localAddress,
  });

  final NetworkInterfaceId interfaceId;
  final DiscoveryTargetSkipReason reason;
  final String? localAddress;

  String get label {
    final address = localAddress == null ? '' : ' address=$localAddress';
    return '${interfaceId.stableId} skipped=${reason.name}$address';
  }
}

class DiscoveryTargetPlan {
  const DiscoveryTargetPlan({required this.targets, required this.skipped});

  final List<DiscoveryTarget> targets;
  final List<DiscoveryTargetDecision> skipped;

  bool get hasSelectedInterface => targets.isNotEmpty;
}

class Ipv4SubnetCalculator {
  const Ipv4SubnetCalculator();

  String? broadcastAddress({
    required String address,
    int? prefixLength,
    String? netmask,
    int fallbackPrefixLength = 24,
  }) {
    final ip = _parseIpv4(address);
    if (ip == null || _isLoopback(ip) || _isLinkLocal(ip)) {
      return null;
    }

    final prefix = prefixLength ?? _prefixLengthFromNetmask(netmask);
    final effectivePrefix = prefix ?? fallbackPrefixLength;
    if (effectivePrefix < 0 || effectivePrefix > 30) {
      return null;
    }

    final ipInt = _toInt(ip);
    final mask = (0xffffffff << (32 - effectivePrefix)) & 0xffffffff;
    final broadcast = (ipInt & mask) | (~mask & 0xffffffff);
    final result = _fromInt(broadcast);
    if (result == '255.255.255.255') {
      return null;
    }
    return result;
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

  static bool _isLinkLocal(List<int> octets) {
    return octets[0] == 169 && octets[1] == 254;
  }

  static bool _isLoopback(List<int> octets) => octets[0] == 127;

  static int _toInt(List<int> octets) {
    return (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];
  }

  static String _fromInt(int value) {
    return [
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ].join('.');
  }
}

class DiscoveryTargetBuilder {
  const DiscoveryTargetBuilder({
    this.subnetCalculator = const Ipv4SubnetCalculator(),
    this.limitedBroadcastAddress = '255.255.255.255',
    this.multicastAddress = '239.255.42.99',
    this.fallbackPrefixLength = 24,
  });

  final Ipv4SubnetCalculator subnetCalculator;
  final String limitedBroadcastAddress;
  final String multicastAddress;
  final int fallbackPrefixLength;

  List<DiscoveryTarget> build({
    required Iterable<NetworkInterfaceSnapshot> interfaces,
    required int port,
  }) {
    return buildPlan(interfaces: interfaces, port: port).targets;
  }

  DiscoveryTargetPlan buildPlan({
    required Iterable<NetworkInterfaceSnapshot> interfaces,
    required int port,
  }) {
    final targets = <String, DiscoveryTarget>{};
    final skipped = <DiscoveryTargetDecision>[];
    for (final interface in interfaces) {
      if (!interface.isUp) {
        skipped.add(
          DiscoveryTargetDecision(
            interfaceId: interface.id,
            reason: DiscoveryTargetSkipReason.interfaceDown,
          ),
        );
        continue;
      }
      if (interface.isLoopback ||
          interface.typeHint == InterfaceTypeHint.loopback) {
        skipped.add(
          DiscoveryTargetDecision(
            interfaceId: interface.id,
            reason: DiscoveryTargetSkipReason.loopbackReservedForLocalRegistry,
          ),
        );
        continue;
      }
      if (!_isSupportedInterfaceType(interface.typeHint)) {
        skipped.add(
          DiscoveryTargetDecision(
            interfaceId: interface.id,
            reason: DiscoveryTargetSkipReason.unsupportedInterfaceType,
          ),
        );
        continue;
      }

      var targetCountBefore = targets.length;
      for (final address in interface.addresses) {
        if (!address.isIpv4) {
          skipped.add(
            DiscoveryTargetDecision(
              interfaceId: interface.id,
              localAddress: address.address,
              reason: DiscoveryTargetSkipReason.unsupportedAddressFamily,
            ),
          );
          continue;
        }
        if (address.isLoopback) {
          skipped.add(
            DiscoveryTargetDecision(
              interfaceId: interface.id,
              localAddress: address.address,
              reason: DiscoveryTargetSkipReason.loopbackAddress,
            ),
          );
          continue;
        }
        if (address.isLinkLocal) {
          skipped.add(
            DiscoveryTargetDecision(
              interfaceId: interface.id,
              localAddress: address.address,
              reason: DiscoveryTargetSkipReason.linkLocalAddress,
            ),
          );
          continue;
        }
        _add(
          targets,
          DiscoveryTarget(
            interfaceId: interface.id,
            localAddress: address.address,
            address: limitedBroadcastAddress,
            port: port,
            type: DiscoveryTargetType.limitedBroadcast,
          ),
        );

        final explicitBroadcast = address.broadcastAddress;
        var directed = explicitBroadcast == null
            ? null
            : _validDirectedBroadcastOrNull(explicitBroadcast);
        if (explicitBroadcast != null && directed == null) {
          skipped.add(
            DiscoveryTargetDecision(
              interfaceId: interface.id,
              localAddress: address.address,
              reason: DiscoveryTargetSkipReason.malformedBroadcastAddress,
            ),
          );
        }
        directed ??= subnetCalculator.broadcastAddress(
          address: address.address,
          prefixLength: address.prefixLength,
          netmask: address.netmask,
          fallbackPrefixLength: fallbackPrefixLength,
        );
        if (directed != null && directed != limitedBroadcastAddress) {
          _add(
            targets,
            DiscoveryTarget(
              interfaceId: interface.id,
              localAddress: address.address,
              address: directed,
              port: port,
              type: DiscoveryTargetType.directedBroadcast,
            ),
          );
        }

        if (interface.supportsMulticast) {
          _add(
            targets,
            DiscoveryTarget(
              interfaceId: interface.id,
              localAddress: address.address,
              address: multicastAddress,
              port: port,
              type: DiscoveryTargetType.multicast,
            ),
          );
        } else {
          skipped.add(
            DiscoveryTargetDecision(
              interfaceId: interface.id,
              localAddress: address.address,
              reason: DiscoveryTargetSkipReason.multicastUnsupported,
            ),
          );
        }
      }
      if (targets.length == targetCountBefore) {
        skipped.add(
          DiscoveryTargetDecision(
            interfaceId: interface.id,
            reason: DiscoveryTargetSkipReason.noBroadcastIpv4,
          ),
        );
      }
    }
    final targetList = targets.values.toList(growable: false)
      ..sort((a, b) => a.dedupeKey.compareTo(b.dedupeKey));
    return DiscoveryTargetPlan(
      targets: targetList,
      skipped: List.unmodifiable(skipped),
    );
  }

  static void _add(
    Map<String, DiscoveryTarget> targets,
    DiscoveryTarget target,
  ) {
    targets[target.dedupeKey] = target;
  }

  static bool _isSupportedInterfaceType(InterfaceTypeHint typeHint) {
    switch (typeHint) {
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

  static String? _validDirectedBroadcastOrNull(String value) {
    final octets = Ipv4SubnetCalculator._parseIpv4(value);
    if (octets == null ||
        Ipv4SubnetCalculator._isLoopback(octets) ||
        Ipv4SubnetCalculator._isLinkLocal(octets)) {
      return null;
    }
    return value == '255.255.255.255' ? null : value;
  }
}
