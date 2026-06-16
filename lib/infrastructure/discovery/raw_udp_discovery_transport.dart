import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/domain/discovery/discovery_receive_decision.dart';
import 'package:sponzey_file_sharing/domain/network/discovery_target.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_inventory.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_packet.dart';
import 'package:sponzey_file_sharing/infrastructure/discovery/discovery_transport.dart';
import 'package:sponzey_file_sharing/infrastructure/network/dart_io_network_interface_inventory.dart';

class RawUdpDiscoveryTransport
    implements DiscoveryTransport, DiscoveryTransportDiagnostics {
  RawUdpDiscoveryTransport({
    required AppLogger logger,
    NetworkInterfaceInventory? networkInterfaceInventory,
  }) : _logger = logger,
       _networkInterfaceInventory =
           networkInterfaceInventory ?? const DartIoNetworkInterfaceInventory();

  static final InternetAddress _broadcastAddress = InternetAddress(
    '255.255.255.255',
  );
  static final InternetAddress _multicastGroup = InternetAddress(
    '239.255.42.99',
  );

  final AppLogger _logger;
  final NetworkInterfaceInventory _networkInterfaceInventory;
  final StreamController<DiscoveryDatagram> _packetsController =
      StreamController<DiscoveryDatagram>.broadcast();

  RawDatagramSocket? _receiveSocket;
  RawDatagramSocket? _sendSocket;
  StreamSubscription<RawSocketEvent>? _receiveSubscription;
  final Map<String, RawDatagramSocket> _sendSocketsByLocalAddress = {};
  List<DiscoveryTarget> _broadcastTargets = const [];
  int? _preferredPort;
  bool _receivePortFallback = false;
  String? _lastError;
  int _lastBroadcastAttemptCount = 0;
  int _lastBroadcastSuccessCount = 0;
  int _lastBroadcastFailureCount = 0;
  List<String> _lastBroadcastAttemptPreview = const [];
  List<String> _discoveryTargetSkipPreview = const [];
  String? _lastReceiveDecisionCode;
  int _malformedPacketCount = 0;

  @override
  Stream<DiscoveryDatagram> get packets => _packetsController.stream;

  @override
  DiscoveryTransportSnapshot snapshot() {
    final receivePort = _receiveSocket?.port;
    final sendPort = _sendSocket?.port;
    final mode = receivePort == null
        ? (sendPort == null ? 'stopped' : 'sender-only')
        : (_receivePortFallback ? 'fallback-receive' : 'receive-send');
    return DiscoveryTransportSnapshot(
      mode: mode,
      preferredPort: _preferredPort ?? 0,
      receivePort: receivePort,
      sendPort: sendPort,
      receivePortFallback: _receivePortFallback,
      lastError: _lastError,
      broadcastTargets: _broadcastTargets
          .map((target) => '${target.localAddress}->${target.address}')
          .toList(growable: false),
      lastBroadcastAttemptCount: _lastBroadcastAttemptCount,
      lastBroadcastSuccessCount: _lastBroadcastSuccessCount,
      lastBroadcastFailureCount: _lastBroadcastFailureCount,
      lastBroadcastAttemptPreview: _lastBroadcastAttemptPreview,
      discoveryTargetSkipPreview: _discoveryTargetSkipPreview,
      lastReceiveDecisionCode: _lastReceiveDecisionCode,
      malformedPacketCount: _malformedPacketCount,
    );
  }

  @override
  Future<void> start({required int port}) async {
    if (_sendSocket != null || _receiveSocket != null) {
      return;
    }
    _preferredPort = port;
    _receivePortFallback = false;
    _lastError = null;

    final interfaceScan = await _resolveInterfaceScan();
    final preferredInterfaces = interfaceScan.selected;
    final preferredInterfaceIds = preferredInterfaces
        .map((interface) => interface.id.stableId)
        .toSet();
    final targetPlan = _buildBroadcastTargetPlan(
      interfaces: preferredInterfaces,
      port: port,
    );
    _broadcastTargets = targetPlan.targets;
    _discoveryTargetSkipPreview = targetPlan.skipped
        .take(32)
        .map((decision) => decision.label)
        .toList(growable: false);
    _logger.info(
      AppLogCategory.discovery,
      'Discovery transport start requested. preferredPort=$port '
      'scannedInterfaces=${interfaceScan.all.length} '
      'selectedInterfaces=${preferredInterfaces.length}',
    );
    _logger.info(
      AppLogCategory.discovery,
      'Discovery interface scan details '
      '${_allInterfacePreview(interfaceScan.all).join(' | ')}',
    );
    _logger.info(
      AppLogCategory.discovery,
      'Discovery selected interfaces '
      '${_interfacePreview(preferredInterfaces).join(' | ')}',
    );
    if (_broadcastTargets.isEmpty) {
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery broadcast target plan is empty. '
        'No active ethernet/bridge/wifi IPv4 interface was selected.',
      );
    } else {
      _logger.info(
        AppLogCategory.discovery,
        'Discovery broadcast target plan count=${_broadcastTargets.length} '
        'targets=${_targetPreview(_broadcastTargets, limit: 32).join(' | ')}',
      );
    }
    if (_discoveryTargetSkipPreview.isNotEmpty) {
      _logger.info(
        AppLogCategory.discovery,
        'Discovery broadcast target skip plan '
        '${_discoveryTargetSkipPreview.join(' | ')}',
      );
    }

    RawDatagramSocket? receiveSocket;
    try {
      receiveSocket = await _bindSocket(port);
      _logger.info(
        AppLogCategory.discovery,
        'Discovery receive socket bound address=${receiveSocket.address.address} '
        'port=${receiveSocket.port} preferredPort=$port fallback=false',
      );
    } catch (error, stackTrace) {
      if (!_isAddressInUse(error)) {
        rethrow;
      }
      _lastError = error.toString();
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery receive bind failed on UDP $port, trying fallback receive port',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        receiveSocket = await _bindSocket(0);
        _receivePortFallback = true;
        _logger.warning(
          AppLogCategory.discovery,
          'Discovery receive socket bound to fallback port '
          '${receiveSocket.port}. Peers must learn this port from outgoing '
          'DISCOVER packets before they can reply directly.',
        );
      } catch (fallbackError, fallbackStackTrace) {
        _lastError = fallbackError.toString();
        _logger.warning(
          AppLogCategory.discovery,
          'Discovery fallback receive bind failed, switching to sender-only mode',
          error: fallbackError,
          stackTrace: fallbackStackTrace,
        );
      }
    }

    if (receiveSocket != null) {
      receiveSocket.readEventsEnabled = true;
      await _joinMulticastGroups(receiveSocket, preferredInterfaceIds);
      _receiveSocket = receiveSocket;
      _receiveSubscription = receiveSocket.listen(_handleSocketEvent);
    }

    final sendSocket = await _bindSocket(0);
    sendSocket.readEventsEnabled = false;
    _sendSocket = sendSocket;
    _logger.info(
      AppLogCategory.discovery,
      'Discovery wildcard send socket bound address=${sendSocket.address.address} '
      'port=${sendSocket.port}',
    );
    await _initializeInterfaceSendSockets();

    if (receiveSocket != null) {
      _logger.info(
        AppLogCategory.discovery,
        'Discovery transport listening on UDP ${receiveSocket.port} '
        '(preferred $port) with broadcast targets: '
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
    final attemptPreview = <String>[];
    var attemptCount = 0;
    var successCount = 0;
    var failureCount = 0;

    if (_broadcastTargets.isEmpty) {
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery broadcast skipped because target list is empty. '
        'packet=${_packetSummary(packet)} preferredPort=$port',
      );
    }

    void attemptSend({
      required String sender,
      required RawDatagramSocket selectedSocket,
      required DiscoveryTarget target,
    }) {
      attemptCount += 1;
      final result = _sendDatagram(
        selectedSocket,
        payload,
        InternetAddress(target.address),
        port,
      );
      final endpoint =
          '$sender ${target.localAddress}->${target.address}:$port ${target.type.name}';
      if (result.success) {
        successCount += 1;
        _logger.debug(
          AppLogCategory.discovery,
          'Discovery broadcast send OK $endpoint bytes=${result.bytesSent} '
          'packet=${_packetSummary(packet)}',
        );
        if (attemptPreview.length < 12) {
          attemptPreview.add('$endpoint OK ${result.bytesSent}B');
        }
        return;
      }
      failureCount += 1;
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery broadcast send FAIL $endpoint '
        'error=${result.errorMessage ?? '-'} packet=${_packetSummary(packet)}',
      );
      if (attemptPreview.length < 12) {
        attemptPreview.add('$endpoint FAIL ${result.errorMessage}');
      }
    }

    for (final target in _broadcastTargets) {
      final destinationKey = '${target.address}:$port';
      if (receiveSocket != null &&
          receiveSocketDestinationsSent.add(destinationKey)) {
        attemptSend(
          sender: 'rx-any',
          selectedSocket: receiveSocket,
          target: target,
        );
      }

      final targetSocket =
          _sendSocketsByLocalAddress[target.localAddress] ?? socket;
      attemptSend(
        sender: 'tx-${target.interfaceId.name}',
        selectedSocket: targetSocket,
        target: target,
      );

      if (!identical(targetSocket, socket) &&
          wildcardDestinationsSent.add(destinationKey)) {
        attemptSend(sender: 'tx-any', selectedSocket: socket, target: target);
      }
    }

    _lastBroadcastAttemptCount = attemptCount;
    _lastBroadcastSuccessCount = successCount;
    _lastBroadcastFailureCount = failureCount;
    _lastBroadcastAttemptPreview = attemptPreview;
    if (failureCount > 0) {
      _lastError = 'broadcast send failures $failureCount/$attemptCount';
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery broadcast completed with $failureCount failed send '
        'attempt(s) out of $attemptCount. packet=${_packetSummary(packet)} '
        'preview=${attemptPreview.join(' | ')}',
      );
    } else {
      _lastError = null;
      _logger.debug(
        AppLogCategory.discovery,
        'Discovery broadcast completed with $successCount successful send '
        'attempt(s). packet=${_packetSummary(packet)} '
        'preview=${attemptPreview.join(' | ')}',
      );
    }
  }

  @override
  Future<void> sendUnicast(
    DiscoveryPacket packet, {
    required InternetAddress address,
    required int port,
  }) async {
    final socket = _requireSendSocket();
    final payload = packet.encode();
    try {
      final sent = socket.send(payload, address, port);
      if (sent == 0) {
        _lastError =
            'unicast send returned 0 bytes to ${address.address}:$port';
        _logger.warning(
          AppLogCategory.discovery,
          'Discovery unicast send returned 0 bytes. '
          'target=${address.address}:$port packet=${_packetSummary(packet)}',
        );
        return;
      }
      _logger.debug(
        AppLogCategory.discovery,
        'Discovery unicast sent target=${address.address}:$port bytes=$sent '
        'packet=${_packetSummary(packet)}',
      );
    } catch (error, stackTrace) {
      _lastError = error.toString();
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery unicast send failed. target=${address.address}:$port '
        'packet=${_packetSummary(packet)}',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
    _preferredPort = null;
    _receivePortFallback = false;
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
      _logger.debug(
        AppLogCategory.discovery,
        'Discovery datagram received from '
        '${current.address.address}:${current.port} bytes=${current.data.length}',
      );
      try {
        final packet = DiscoveryPacket.decode(current.data);
        _lastReceiveDecisionCode = DiscoveryReceiveDecisionCode.accepted.name;
        _logger.debug(
          AppLogCategory.discovery,
          'Discovery datagram decoded from '
          '${current.address.address}:${current.port} '
          'packet=${_packetSummary(packet)}',
        );
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
          'Ignored malformed discovery datagram from '
          '${current.address.address}:${current.port} '
          'bytes=${current.data.length}',
          error: error,
          stackTrace: stackTrace,
        );
        _malformedPacketCount += 1;
        _lastReceiveDecisionCode = DiscoveryReceiveDecisionCode.malformed.name;
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

  Future<_DiscoveryInterfaceScan> _resolveInterfaceScan() async {
    final snapshots = await _networkInterfaceInventory.scan();
    return _DiscoveryInterfaceScan(
      all: snapshots,
      selected: selectPreferredInterfaces(snapshots),
    );
  }

  DiscoveryTargetPlan _buildBroadcastTargetPlan({
    required List<NetworkInterfaceSnapshot> interfaces,
    required int port,
  }) {
    return const DiscoveryTargetBuilder().buildPlan(
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
        _logger.info(
          AppLogCategory.discovery,
          'Discovery interface send socket bound local=$localAddress '
          'port=${socket.port}',
        );
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
        .where((interface) => discoveryInterfaceDecision(interface).isSelected)
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

  static DiscoveryInterfaceDecision discoveryInterfaceDecision(
    NetworkInterfaceSnapshot interface,
  ) {
    if (interface.isLoopback) {
      return const DiscoveryInterfaceDecision.excluded('loopback');
    }
    if (!interface.isUp) {
      return const DiscoveryInterfaceDecision.excluded('interface-down');
    }
    if (interface.activeIpv4Addresses.isEmpty) {
      return const DiscoveryInterfaceDecision.excluded('no-active-lan-ipv4');
    }
    if (!_isDefaultDiscoveryInterface(interface)) {
      return DiscoveryInterfaceDecision.excluded(
        'type-${interface.typeHint.name}',
      );
    }
    return const DiscoveryInterfaceDecision.selected();
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

  _DiscoverySendResult _sendDatagram(
    RawDatagramSocket socket,
    List<int> payload,
    InternetAddress address,
    int port,
  ) {
    try {
      final sent = socket.send(payload, address, port);
      if (sent == 0) {
        _logger.warning(
          AppLogCategory.discovery,
          'Discovery datagram send returned 0 bytes for ${address.address}:$port',
        );
        return const _DiscoverySendResult.failure('0 bytes sent');
      }
      return _DiscoverySendResult.success(sent);
    } catch (error, stackTrace) {
      _logger.warning(
        AppLogCategory.discovery,
        'Discovery datagram send failed for ${address.address}:$port',
        error: error,
        stackTrace: stackTrace,
      );
      return _DiscoverySendResult.failure(error.toString());
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
        _logger.info(
          AppLogCategory.discovery,
          'Discovery socket bind attempt address=${bindAddress.address} '
          'port=$port reuseAddress=${options.reuseAddress} '
          'reusePort=${options.reusePort}',
        );
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

  static List<DiscoverySocketBindOptions> bindOptionsFor({
    required DiscoverySocketPlatform platform,
  }) {
    switch (platform) {
      case DiscoverySocketPlatform.windows:
        return const [
          DiscoverySocketBindOptions(reuseAddress: false, reusePort: false),
          DiscoverySocketBindOptions(reuseAddress: true, reusePort: false),
        ];
      case DiscoverySocketPlatform.posix:
        return const [
          DiscoverySocketBindOptions(reuseAddress: true, reusePort: true),
          DiscoverySocketBindOptions(reuseAddress: true, reusePort: false),
          DiscoverySocketBindOptions(reuseAddress: false, reusePort: false),
        ];
    }
  }

  static List<DiscoverySocketBindOptions> _bindOptionsForCurrentPlatform() {
    return bindOptionsFor(
      platform: Platform.isWindows
          ? DiscoverySocketPlatform.windows
          : DiscoverySocketPlatform.posix,
    );
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

  static List<String> _interfacePreview(
    Iterable<NetworkInterfaceSnapshot> interfaces, {
    int limit = 24,
  }) {
    return interfaces
        .take(limit)
        .map((interface) {
          final addresses = interface.activeIpv4Addresses
              .map((address) {
                final prefix = address.prefixLength == null
                    ? ''
                    : '/${address.prefixLength}';
                final broadcast = address.broadcastAddress == null
                    ? ''
                    : ' bcast=${address.broadcastAddress}';
                return '${address.address}$prefix$broadcast';
              })
              .join(',');
          return '${interface.id.stableId} type=${interface.typeHint.name} '
              'up=${interface.isUp} multicast=${interface.supportsMulticast} '
              'ipv4=[$addresses]';
        })
        .toList(growable: false);
  }

  static List<String> _allInterfacePreview(
    Iterable<NetworkInterfaceSnapshot> interfaces, {
    int limit = 64,
  }) {
    return interfaces
        .take(limit)
        .map((interface) {
          final addresses = interface.addresses
              .map((address) {
                final prefix = address.prefixLength == null
                    ? ''
                    : '/${address.prefixLength}';
                final flags = [
                  address.family.name,
                  if (address.isPrivate) 'private',
                  if (address.isLinkLocal) 'linkLocal',
                  if (address.isLoopback) 'loopback',
                ].join(',');
                return '${address.address}$prefix($flags)';
              })
              .join(',');
          final decision = discoveryInterfaceDecision(interface);
          return '${interface.id.stableId} decision=${decision.label} '
              'type=${interface.typeHint.name} up=${interface.isUp} '
              'loopback=${interface.isLoopback} '
              'multicast=${interface.supportsMulticast} '
              'addresses=[$addresses]';
        })
        .toList(growable: false);
  }

  static List<String> _targetPreview(
    Iterable<DiscoveryTarget> targets, {
    int limit = 24,
  }) {
    return targets
        .take(limit)
        .map((target) {
          return '${target.interfaceId.stableId} '
              '${target.localAddress}->${target.address}:${target.port} '
              '${target.type.name}';
        })
        .toList(growable: false);
  }

  static String _packetSummary(DiscoveryPacket packet) {
    return 'type=${packet.type.wireName} user=${packet.userId} '
        'device=${packet.deviceId} instance=${_short(packet.instanceId)} '
        'group=${_short(packet.discoveryGroupTag)} '
        'discoveryPort=${packet.discoveryPort ?? '-'} '
        'controlPort=${packet.controlPort ?? packet.port} '
        'dataPort=${packet.dataPort ?? '-'} msg=${_short(packet.messageId)}';
  }

  static String _short(String value, {int max = 12}) {
    if (value.isEmpty) {
      return '-';
    }
    return value.length <= max ? value : value.substring(0, max);
  }
}

class _DiscoverySendResult {
  const _DiscoverySendResult._({
    required this.success,
    required this.bytesSent,
    this.errorMessage,
  });

  const _DiscoverySendResult.success(int bytesSent)
    : this._(success: true, bytesSent: bytesSent);

  const _DiscoverySendResult.failure(String errorMessage)
    : this._(success: false, bytesSent: 0, errorMessage: errorMessage);

  final bool success;
  final int bytesSent;
  final String? errorMessage;
}

class DiscoveryInterfaceDecision {
  const DiscoveryInterfaceDecision._({
    required this.isSelected,
    required this.reason,
  });

  const DiscoveryInterfaceDecision.selected()
    : this._(isSelected: true, reason: 'selected');

  const DiscoveryInterfaceDecision.excluded(String reason)
    : this._(isSelected: false, reason: reason);

  final bool isSelected;
  final String reason;

  String get label => isSelected ? 'selected' : 'excluded:$reason';
}

class _DiscoveryInterfaceScan {
  const _DiscoveryInterfaceScan({required this.all, required this.selected});

  final List<NetworkInterfaceSnapshot> all;
  final List<NetworkInterfaceSnapshot> selected;
}

enum DiscoverySocketPlatform { windows, posix }

class DiscoverySocketBindOptions {
  const DiscoverySocketBindOptions({
    required this.reuseAddress,
    required this.reusePort,
  });

  final bool reuseAddress;
  final bool reusePort;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiscoverySocketBindOptions &&
            other.reuseAddress == reuseAddress &&
            other.reusePort == reusePort;
  }

  @override
  int get hashCode => Object.hash(reuseAddress, reusePort);
}
