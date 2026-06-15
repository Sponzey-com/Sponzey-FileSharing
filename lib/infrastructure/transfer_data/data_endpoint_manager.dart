import 'dart:async';
import 'dart:io';

import 'package:sponzey_file_sharing/core/logger/app_log_category.dart';
import 'package:sponzey_file_sharing/core/logger/app_logger.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

class DataSocketLease {
  DataSocketLease({
    required this.localEndpoint,
    required this.socket,
    required this.ownerId,
  });

  final UdpInterfaceEndpoint localEndpoint;
  final RawDatagramSocket socket;
  final String ownerId;
  bool _closed = false;

  bool get isClosed => _closed;

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    socket.close();
  }
}

class DataEndpointManager {
  DataEndpointManager({
    required AppLogger logger,
    DataSocketBindOptions? bindOptions,
  }) : _logger = logger,
       _bindOptions = bindOptions ?? DataSocketBindOptions.currentPlatform();

  final AppLogger _logger;
  final DataSocketBindOptions _bindOptions;
  final Map<String, DataSocketLease> _leases = <String, DataSocketLease>{};

  Future<DataSocketLease> bind({
    required UdpInterfaceEndpoint localEndpoint,
    required UdpPortRange portRange,
    required String ownerId,
  }) async {
    Object? lastError;
    for (final port in portRange.ports) {
      try {
        final endpoint = UdpInterfaceEndpoint(
          role: UdpPortRole.data,
          interfaceId: localEndpoint.interfaceId,
          localAddress: localEndpoint.localAddress,
          port: port,
          bindMode: localEndpoint.bindMode,
          reuseAddress: _bindOptions.reuseAddress,
          reusePort: _bindOptions.reusePort,
        );
        final socket = await RawDatagramSocket.bind(
          InternetAddress(endpoint.localAddress),
          endpoint.port,
          reuseAddress: endpoint.reuseAddress,
          reusePort: endpoint.reusePort,
        );
        socket.readEventsEnabled = true;
        socket.writeEventsEnabled = false;
        final lease = DataSocketLease(
          localEndpoint: endpoint,
          socket: socket,
          ownerId: ownerId,
        );
        _leases[_leaseKey(endpoint)] = lease;
        _logger.info(
          AppLogCategory.transferData,
          'Data endpoint lease bound ${endpoint.localAddress}:${endpoint.port} owner=$ownerId',
        );
        return lease;
      } on Object catch (error) {
        lastError = error;
        if (!_isAddressInUse(error)) {
          break;
        }
      }
    }
    throw StateError(
      'Failed to bind data endpoint ${localEndpoint.localAddress} '
      'in ${portRange.start}-${portRange.end}: $lastError',
    );
  }

  Future<void> closeAll() async {
    final leases = _leases.values.toList(growable: false);
    _leases.clear();
    for (final lease in leases) {
      await lease.close();
    }
  }

  String _leaseKey(UdpInterfaceEndpoint endpoint) {
    return '${endpoint.localAddress}:${endpoint.port}';
  }

  bool _isAddressInUse(Object error) {
    final message = error.toString().toLowerCase();
    if (error is SocketException) {
      final code = error.osError?.errorCode;
      return code == 48 ||
          code == 98 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    if (error is OSError) {
      final code = error.errorCode;
      return code == 48 ||
          code == 98 ||
          code == 10048 ||
          message.contains('address already in use');
    }
    return message.contains('address already in use');
  }
}

class DataSocketBindOptions {
  const DataSocketBindOptions({
    required this.reuseAddress,
    required this.reusePort,
  });

  final bool reuseAddress;
  final bool reusePort;

  factory DataSocketBindOptions.currentPlatform() {
    return DataSocketBindOptions(reuseAddress: false, reusePort: false);
  }
}

class DataSessionDispatcher<T> {
  final Map<String, T> _sessions = <String, T>{};

  void register({required String transferId, required T session}) {
    _sessions[transferId] = session;
  }

  T? lookup(String transferId) => _sessions[transferId];

  T? unregister(String transferId) => _sessions.remove(transferId);

  bool contains(String transferId) => _sessions.containsKey(transferId);
}
