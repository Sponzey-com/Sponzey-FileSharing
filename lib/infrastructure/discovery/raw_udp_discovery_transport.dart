import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/network/discovery_target.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/network/dart_io_network_interface_inventory.dart';

class RawUdpDiscoveryTransport implements DiscoveryTransport {
  RawUdpDiscoveryTransport({required AppLogger logger}) : _logger = logger;

  static final InternetAddress _broadcastAddress = InternetAddress(
    '255.255.255.255',
  );
  static final InternetAddress _multicastGroup = InternetAddress(
    '239.255.42.99',
  );

  final AppLogger _logger;
  final StreamController<DiscoveryDatagram> _packetsController =
      StreamController<DiscoveryDatagram>.broadcast();

  RawDatagramSocket? _receiveSocket;
  RawDatagramSocket? _sendSocket;
  StreamSubscription<RawSocketEvent>? _receiveSubscription;
  final Map<String, RawDatagramSocket> _sendSocketsByLocalAddress = {};
  List<DiscoveryTarget> _broadcastTargets = const [];

  @override
  Stream<DiscoveryDatagram> get packets => _packetsController.stream;

  @override
  Future<void> start({required int port}) async {
    if (_sendSocket != null || _receiveSocket != null) {
      return;
    }

    final preferredInterfaces = await _resolvePreferredInterfaceSnapshots();
    final preferredInterfaceIds = preferredInterfaces
        .map((interface) => interface.id.stableId)
        .toSet();
    _broadcastTargets = _buildBroadcastTargets(
      interfaces: preferredInterfaces,
      port: port,
    );

    RawDatagramSocket? receiveSocket;
    try {
      receiveSocket = await _bindSocket(port);
      receiveSocket.readEventsEnabled = true;
      await _joinMulticastGroups(receiveSocket, preferredInterfaceIds);
      _receiveSocket = receiveSocket;
      _receiveSubscription = receiveSocket.listen(_handleSocketEvent);
    } catch (error, stackTrace) {
      if (!_isAddressInUse(error)) {
        rethrow;
      }
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery receive bind failed on UDP $port, switching to sender-only mode',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final sendSocket = await _bindSocket(0);
    sendSocket.readEventsEnabled = false;
    _sendSocket = sendSocket;
    await _initializeInterfaceSendSockets();

    if (receiveSocket != null) {
      _logger.info(
        AppLogCategory.discovery,
        'Discovery transport listening on UDP $port with broadcast targets: '
        '${_broadcastTargets.map((target) => '${target.localAddress}->${target.address}').join(', ')}',
      );
    } else {
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery transport started without receive socket. '
        'Broadcast/local registry only mode is active.',
      );
    }
  }

  @override
  Future<void> sendBroadcast(
    DiscoveryPacket packet, {
    required int port,
  }) async {
    final socket = _requireSendSocket();
    final payload = packet.encode();
    final receiveSocket = _receiveSocket;
    final receiveSocketDestinationsSent = <String>{};
    final wildcardDestinationsSent = <String>{};

    for (final target in _broadcastTargets) {
      final address = InternetAddress(target.address);
      final destinationKey = '${target.address}:$port';
      if (receiveSocket != null &&
          receiveSocketDestinationsSent.add(destinationKey)) {
        _sendDatagram(receiveSocket, payload, address, port);
      }

      final targetSocket =
          _sendSocketsByLocalAddress[target.localAddress] ?? socket;
      _sendDatagram(targetSocket, payload, address, port);

      if (!identical(targetSocket, socket) &&
          wildcardDestinationsSent.add(destinationKey)) {
        _sendDatagram(socket, payload, address, port);
      }
    }
  }

  @override
  Future<void> sendUnicast(
    DiscoveryPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {
    final socket = _requireSendSocket();
    socket.send(packet.encode(), address, port);
  }

  @override
  Future<void> close() async {
    await _receiveSubscription?.cancel();
    _receiveSubscription = null;
    _receiveSocket?.close();
    _receiveSocket = null;
    _sendSocket?.close();
    _sendSocket = null;
    for (final socket in _sendSocketsByLocalAddress.values) {
      socket.close();
    }
    _sendSocketsByLocalAddress.clear();
    _broadcastTargets = const [];
    if (!_packetsController.isClosed) {
      await _packetsController.close();
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final socket = _receiveSocket;
    if (socket == null) {
      return;
    }

    Datagram? datagram;
    while ((datagram = socket.receive()) != null) {
      final current = datagram!;
      try {
        final packet = DiscoveryPacket.decode(current.data);
        _packetsController.add(
          DiscoveryDatagram(
            packet: packet,
            address: current.address,
            port: current.port,
          ),
        );
      } on FormatException catch (error, stackTrace) {
        _logger.warning(
          AppLogCategory.discovery,
          'Ignored malformed discovery datagram',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _joinMulticastGroups(
    RawDatagramSocket socket,
    Set<String> preferredInterfaceIds,
  ) async {
    _tryJoinMulticast(socket, description: 'default multicast group');

    final List<NetworkInterface> interfaces;
    try {
      interfaces = await NetworkInterface.list(
        includeLoopback: true,
        type: InternetAddressType.IPv4,
      );
    } catch (error, stackTrace) {
      _logger.warning(
        AppLogCategory.discovery,
        'Failed to list interfaces for discovery multicast join',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    for (final interface in interfaces) {
      final stableId = '${interface.name}#${interface.index}';
      if (!preferredInterfaceIds.contains(stableId)) {
        continue;
      }
      _tryJoinMulticast(
        socket,
        interface: interface,
        description: 'multicast group on ${interface.name}',
        debugOnly: true,
      );
    }
  }

  void _tryJoinMulticast(
    RawDatagramSocket socket, {
    NetworkInterface? interface,
    required String description,
    bool debugOnly = false,
  }) {
    try {
      if (interface == null) {
        socket.joinMulticast(_multicastGroup);
      } else {
        socket.joinMulticast(_multicastGroup, interface);
      }
    } catch (error, stackTrace) {
      final message =
          'Skipped discovery $description. '
          'Broadcast discovery remains active.';
      if (debugOnly || isInvalidSocketArgumentError(error)) {
        _logger.debug(
          AppLogCategory.discovery,
          message,
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
      _logger.warning(
        AppLogCategory.discovery,
        message,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<NetworkInterfaceSnapshot>>
  _resolvePreferredInterfaceSnapshots() async {
    final snapshots = await const DartIoNetworkInterfaceInventory().scan();
    return selectPreferredInterfaces(snapshots);
  }

  List<DiscoveryTarget> _buildBroadcastTargets({
    required List<NetworkInterfaceSnapshot> interfaces,
    required int port,
  }) {
    return const DiscoveryTargetBuilder().build(
      interfaces: interfaces,
      port: port,
    );
  }

  Future<void> _initializeInterfaceSendSockets() async {
    final localAddresses = _broadcastTargets
        .map((target) => target.localAddress)
        .toSet();
    for (final localAddress in localAddresses) {
      if (_sendSocketsByLocalAddress.containsKey(localAddress)) {
        continue;
      }
      try {
        final socket = await _bindSocketOnAddress(localAddress, 0);
        socket.readEventsEnabled = false;
        _sendSocketsByLocalAddress[localAddress] = socket;
      } catch (error, stackTrace) {
        _logger.warning(
          AppLogCategory.discovery,
          'Failed to bind discovery sender on $localAddress, falling back to wildcard sender',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  static List<String> broadcastTargetsForAddresses(
    Iterable<InternetAddress> addresses,
  ) {
    final candidates = <String>{};
    candidates.add(_broadcastAddress.address);
    candidates.add(_multicastGroup.address);
    for (final address in addresses) {
      final directedBroadcast = directedBroadcastFor(address);
      if (directedBroadcast != null) {
        candidates.add(directedBroadcast.address);
      }
    }
    return candidates.toList(growable: false);
  }

  static List<NetworkInterfaceSnapshot> selectPreferredInterfaces(
    Iterable<NetworkInterfaceSnapshot> interfaces,
  ) {
    final selected = interfaces
        .where((interface) => interface.activeIpv4Addresses.isNotEmpty)
        .where(_isDefaultDiscoveryInterface)
        .toList(growable: false);
    selected.sort((a, b) {
      final priorityCompare = _interfacePriority(
        a.typeHint,
      ).compareTo(_interfacePriority(b.typeHint));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.id.compareTo(b.id);
    });
    return selected;
  }

  static bool _isDefaultDiscoveryInterface(NetworkInterfaceSnapshot interface) {
    switch (interface.typeHint) {
      case InterfaceTypeHint.loopback:
      case InterfaceTypeHint.vpn:
      case InterfaceTypeHint.virtual:
        return false;
      case InterfaceTypeHint.ethernet:
      case InterfaceTypeHint.bridge:
      case InterfaceTypeHint.wifi:
      case InterfaceTypeHint.unknown:
        return true;
    }
  }

  static int _interfacePriority(InterfaceTypeHint typeHint) {
    switch (typeHint) {
      case InterfaceTypeHint.ethernet:
        return 0;
      case InterfaceTypeHint.bridge:
        return 1;
      case InterfaceTypeHint.wifi:
        return 2;
      case InterfaceTypeHint.unknown:
        return 3;
      case InterfaceTypeHint.loopback:
      case InterfaceTypeHint.vpn:
      case InterfaceTypeHint.virtual:
        return 4;
    }
  }

  static InternetAddress? directedBroadcastFor(InternetAddress address) {
    if (address.type != InternetAddressType.IPv4) {
      return null;
    }
    final candidate = const Ipv4SubnetCalculator().broadcastAddress(
      address: address.address,
    );
    if (candidate == null) {
      return null;
    }
    if (candidate == _broadcastAddress.address) {
      return null;
    }
    return InternetAddress(candidate);
  }

  RawDatagramSocket _requireSendSocket() {
    final socket = _sendSocket ?? _receiveSocket;
    if (socket == null) {
      throw StateError('Discovery transport has not been started.');
    }
    return socket;
  }

  void _sendDatagram(
    RawDatagramSocket socket,
    List<int> payload,
    InternetAddress address,
    int port,
  ) {
    final sent = socket.send(payload, address, port);
    if (sent == 0) {
      _logger.debug(
        AppLogCategory.discovery,
        'Discovery datagram send returned 0 bytes for ${address.address}:$port',
      );
    }
  }

  Future<RawDatagramSocket> _bindSocket(int port) async {
    final socket = await _bindSocketWithPlatformFallback(
      InternetAddress.anyIPv4,
      port,
    );
    socket.broadcastEnabled = true;
    _configureMulticastOptions(socket);
    socket.writeEventsEnabled = false;
    return socket;
  }

  Future<RawDatagramSocket> _bindSocketOnAddress(
    String address,
    int port,
  ) async {
    final socket = await _bindSocketWithPlatformFallback(
      InternetAddress(address),
      port,
    );
    socket.broadcastEnabled = true;
    _configureMulticastOptions(socket);
    socket.writeEventsEnabled = false;
    return socket;
  }

  void _configureMulticastOptions(RawDatagramSocket socket) {
    try {
      socket.multicastLoopback = true;
      socket.multicastHops = 1;
    } catch (error, stackTrace) {
      _logger.debug(
        AppLogCategory.discovery,
        'Skipped discovery multicast socket options. '
        'Broadcast discovery remains active.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<RawDatagramSocket> _bindSocketWithPlatformFallback(
    InternetAddress bindAddress,
    int port,
  ) async {
    final attempts = _bindOptionsForCurrentPlatform();
    Object? lastError;
    StackTrace? lastStackTrace;
    for (var index = 0; index < attempts.length; index++) {
      final options = attempts[index];
      try {
        return await RawDatagramSocket.bind(
          bindAddress,
          port,
          reuseAddress: options.reuseAddress,
          reusePort: options.reusePort,
        );
      } catch (error, stackTrace) {
        if (!isInvalidSocketArgumentError(error)) {
          rethrow;
        }
        lastError = error;
        lastStackTrace = stackTrace;
        if (index == attempts.length - 1) {
          break;
        }
        final next = attempts[index + 1];
        _logger.warning(
          AppLogCategory.discovery,
          'Retrying discovery socket bind with '
          'reuseAddress=${next.reuseAddress}, reusePort=${next.reusePort}',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  static List<_DiscoverySocketBindOptions> _bindOptionsForCurrentPlatform() {
    if (Platform.isWindows) {
      return const [
        _DiscoverySocketBindOptions(reuseAddress: false, reusePort: false),
        _DiscoverySocketBindOptions(reuseAddress: true, reusePort: false),
      ];
    }
    return const [
      _DiscoverySocketBindOptions(reuseAddress: true, reusePort: true),
      _DiscoverySocketBindOptions(reuseAddress: true, reusePort: false),
      _DiscoverySocketBindOptions(reuseAddress: false, reusePort: false),
    ];
  }

  bool _isAddressInUse(Object error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      final code = error.osError?.errorCode;
      return code == 48 ||
          code == 98 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    if (error is OSError) {
      final message = error.message.toLowerCase();
      final code = error.errorCode;
      return code == 48 ||
          code == 98 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    return error.toString().toLowerCase().contains('address already in use');
  }

  static bool isInvalidSocketArgumentError(Object error) {
    if (error is SocketException) {
      final message = error.message.toLowerCase();
      final code = error.osError?.errorCode;
      return code == 22 ||
          code == 10022 ||
          message.contains('invalid argument');
    }
    if (error is OSError) {
      final message = error.message.toLowerCase();
      final code = error.errorCode;
      return code == 22 ||
          code == 10022 ||
          message.contains('invalid argument');
    }
    return error.toString().toLowerCase().contains('invalid argument');
  }
}

class _DiscoverySocketBindOptions {
  const _DiscoverySocketBindOptions({
    required this.reuseAddress,
    required this.reusePort,
  });

  final bool reuseAddress;
  final bool reusePort;
}
