import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';

class DataPortBindPolicy {
  const DataPortBindPolicy();

  int selectFirstAvailable({
    required UdpPortRange range,
    required bool Function(int port) canBind,
  }) {
    for (final port in range.ports) {
      if (canBind(port)) {
        return port;
      }
    }
    throw StateError('No data ports available in ${range.start}-${range.end}.');
  }
}
