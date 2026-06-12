import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';

enum IpAddressFamily { ipv4, ipv6 }

enum InterfaceTypeHint {
  ethernet,
  wifi,
  loopback,
  vpn,
  virtual,
  bridge,
  unknown,
}

enum UdpInterfaceBindMode { any, specificAddress }

class NetworkInterfaceId implements Comparable<NetworkInterfaceId> {
  const NetworkInterfaceId({
    required this.name,
    required this.index,
    String? stableId,
    this.displayName,
  }) : stableId = stableId ?? '$name#$index';

  final String name;
  final int index;
  final String stableId;
  final String? displayName;

  @override
  int compareTo(NetworkInterfaceId other) {
    final stableComparison = stableId.compareTo(other.stableId);
    if (stableComparison != 0) {
      return stableComparison;
    }
    final nameComparison = name.compareTo(other.name);
    if (nameComparison != 0) {
      return nameComparison;
    }
    return index.compareTo(other.index);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NetworkInterfaceId &&
            other.name == name &&
            other.index == index &&
            other.stableId == stableId;
  }

  @override
  int get hashCode => Object.hash(name, index, stableId);

  @override
  String toString() => stableId;
}

class InterfaceAddress {
  const InterfaceAddress({
    required this.address,
    required this.family,
    this.prefixLength,
    this.netmask,
    this.broadcastAddress,
    bool? isPrivate,
    bool? isLinkLocal,
    bool? isLoopback,
  }) : isPrivate = isPrivate ?? false,
       isLinkLocal = isLinkLocal ?? false,
       isLoopback = isLoopback ?? false;

  factory InterfaceAddress.ipv4({
    required String address,
    int? prefixLength,
    String? netmask,
    String? broadcastAddress,
  }) {
    return InterfaceAddress(
      address: address,
      family: IpAddressFamily.ipv4,
      prefixLength: prefixLength,
      netmask: netmask,
      broadcastAddress: broadcastAddress,
      isPrivate: _isPrivateIpv4(address),
      isLinkLocal: _isLinkLocalIpv4(address),
      isLoopback: _isLoopbackIpv4(address),
    );
  }

  factory InterfaceAddress.ipv6({required String address, int? prefixLength}) {
    return InterfaceAddress(
      address: address,
      family: IpAddressFamily.ipv6,
      prefixLength: prefixLength,
      isPrivate: _isPrivateIpv6(address),
      isLinkLocal: _isLinkLocalIpv6(address),
      isLoopback: address == '::1' || address == '0:0:0:0:0:0:0:1',
    );
  }

  final String address;
  final IpAddressFamily family;
  final int? prefixLength;
  final String? netmask;
  final String? broadcastAddress;
  final bool isPrivate;
  final bool isLinkLocal;
  final bool isLoopback;

  bool get isIpv4 => family == IpAddressFamily.ipv4;

  bool get isIpv6 => family == IpAddressFamily.ipv6;

  bool get isLanCandidate => isIpv4 && !isLoopback && !isLinkLocal;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InterfaceAddress &&
            other.address == address &&
            other.family == family &&
            other.prefixLength == prefixLength &&
            other.netmask == netmask &&
            other.broadcastAddress == broadcastAddress;
  }

  @override
  int get hashCode {
    return Object.hash(
      address,
      family,
      prefixLength,
      netmask,
      broadcastAddress,
    );
  }

  static bool _isPrivateIpv4(String value) {
    final octets = _parseIpv4(value);
    if (octets == null) {
      return false;
    }
    return octets[0] == 10 ||
        (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
        (octets[0] == 192 && octets[1] == 168);
  }

  static bool _isLinkLocalIpv4(String value) {
    final octets = _parseIpv4(value);
    return octets != null && octets[0] == 169 && octets[1] == 254;
  }

  static bool _isLoopbackIpv4(String value) {
    final octets = _parseIpv4(value);
    return octets != null && octets[0] == 127;
  }

  static bool _isPrivateIpv6(String value) {
    final normalized = value.toLowerCase();
    return normalized.startsWith('fc') || normalized.startsWith('fd');
  }

  static bool _isLinkLocalIpv6(String value) {
    return value.toLowerCase().startsWith('fe80');
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
}

class NetworkInterfaceSnapshot {
  const NetworkInterfaceSnapshot({
    required this.id,
    required this.name,
    this.displayName,
    required this.typeHint,
    required this.isUp,
    required this.supportsMulticast,
    required this.isLoopback,
    required this.addresses,
    required this.capturedAt,
    this.metadata = const {},
  });

  final NetworkInterfaceId id;
  final String name;
  final String? displayName;
  final InterfaceTypeHint typeHint;
  final bool isUp;
  final bool supportsMulticast;
  final bool isLoopback;
  final List<InterfaceAddress> addresses;
  final DateTime capturedAt;

  /// Debug/development diagnostics only. Do not treat interface IDs as durable
  /// persisted identifiers because OS names and indices can change.
  final Map<String, String> metadata;

  List<InterfaceAddress> get activeIpv4Addresses {
    if (!isUp || isLoopback) {
      return const [];
    }
    return addresses
        .where((address) => address.isLanCandidate)
        .toList(growable: false);
  }
}

class UdpInterfaceEndpoint {
  const UdpInterfaceEndpoint({
    required this.role,
    this.interfaceId,
    required this.localAddress,
    required this.port,
    required this.bindMode,
    this.reuseAddress = false,
    this.reusePort = false,
  });

  final UdpPortRole role;
  final NetworkInterfaceId? interfaceId;
  final String localAddress;
  final int port;
  final UdpInterfaceBindMode bindMode;
  final bool reuseAddress;
  final bool reusePort;

  bool get isWildcardBind => bindMode == UdpInterfaceBindMode.any;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UdpInterfaceEndpoint &&
            other.role == role &&
            other.interfaceId == interfaceId &&
            other.localAddress == localAddress &&
            other.port == port &&
            other.bindMode == bindMode &&
            other.reuseAddress == reuseAddress &&
            other.reusePort == reusePort;
  }

  @override
  int get hashCode {
    return Object.hash(
      role,
      interfaceId,
      localAddress,
      port,
      bindMode,
      reuseAddress,
      reusePort,
    );
  }
}
