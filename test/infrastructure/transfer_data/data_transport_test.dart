import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_port_bind_policy.dart';

void main() {
  test('data port bind policy uses first range port', () {
    final selected = const DataPortBindPolicy().selectFirstAvailable(
      range: const UdpPortRange(start: 50000, end: 50002),
      canBind: (_) => true,
    );

    expect(selected, 50000);
  });

  test('data port bind policy retries next port when first is unavailable', () {
    final selected = const DataPortBindPolicy().selectFirstAvailable(
      range: const UdpPortRange(start: 50000, end: 50002),
      canBind: (port) => port != 50000,
    );

    expect(selected, 50001);
  });

  test('data port bind policy fails when range is exhausted', () {
    expect(
      () => const DataPortBindPolicy().selectFirstAvailable(
        range: const UdpPortRange(start: 50000, end: 50001),
        canBind: (_) => false,
      ),
      throwsStateError,
    );
  });
}
