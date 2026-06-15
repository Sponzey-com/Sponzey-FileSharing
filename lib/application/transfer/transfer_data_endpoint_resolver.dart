import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

final class TransferDataEndpointResolver {
  const TransferDataEndpointResolver._();

  static String? advertisedReceiverAddress({
    required UdpInterfaceEndpoint dataEndpoint,
  }) {
    if (_isUsableAddress(dataEndpoint.localAddress) &&
        !dataEndpoint.isWildcardBind) {
      return dataEndpoint.localAddress;
    }

    return null;
  }

  static String senderRemoteAddress({
    required String? advertisedAddress,
    required String controlAckSourceAddress,
  }) {
    final candidate = advertisedAddress?.trim();
    if (_isUsableAddress(candidate) &&
        !_isLoopbackMismatch(
          candidate!,
          fallbackAddress: controlAckSourceAddress,
        )) {
      return candidate;
    }
    return controlAckSourceAddress;
  }

  static bool _isUsableAddress(String? address) {
    final value = address?.trim();
    if (value == null || value.isEmpty) {
      return false;
    }
    return value != '0.0.0.0' && value != '::' && value != '0:0:0:0:0:0:0:0';
  }

  static bool _isLoopbackMismatch(
    String advertisedAddress, {
    required String fallbackAddress,
  }) {
    return _isLoopback(advertisedAddress) && !_isLoopback(fallbackAddress);
  }

  static bool _isLoopback(String address) {
    return address == '::1' ||
        address == '0:0:0:0:0:0:0:1' ||
        address.startsWith('127.');
  }
}
