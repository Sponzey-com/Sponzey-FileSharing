import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

abstract class NetworkInterfaceInventory {
  Future<List<NetworkInterfaceSnapshot>> scan();
}

class FakeNetworkInterfaceInventory implements NetworkInterfaceInventory {
  FakeNetworkInterfaceInventory(this._snapshots);

  final List<NetworkInterfaceSnapshot> _snapshots;

  @override
  Future<List<NetworkInterfaceSnapshot>> scan() async => _snapshots;
}
