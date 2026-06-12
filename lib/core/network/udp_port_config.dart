enum UdpPortRole { discovery, control, data }

class UdpPortRange {
  const UdpPortRange({required this.start, required this.end})
    : assert(start > 0),
      assert(end >= start),
      assert(end <= 65535);

  final int start;
  final int end;

  bool contains(int port) => port >= start && port <= end;

  List<int> get ports => [for (var port = start; port <= end; port++) port];
}

class UdpEndpointConfig {
  const UdpEndpointConfig({required this.role, required this.port});

  final UdpPortRole role;
  final int port;
}

class DataPortAllocator {
  DataPortAllocator({required UdpPortRange range}) : _range = range;

  final UdpPortRange _range;
  final Set<int> _leasedPorts = <int>{};

  int allocate() {
    for (final port in _range.ports) {
      if (_leasedPorts.add(port)) {
        return port;
      }
    }
    throw StateError(
      'No data ports available in ${_range.start}-${_range.end}.',
    );
  }

  void release(int port) {
    if (!_range.contains(port)) {
      throw ArgumentError.value(
        port,
        'port',
        'Port is outside of the configured data port range.',
      );
    }
    _leasedPorts.remove(port);
  }

  bool isLeased(int port) => _leasedPorts.contains(port);
}
