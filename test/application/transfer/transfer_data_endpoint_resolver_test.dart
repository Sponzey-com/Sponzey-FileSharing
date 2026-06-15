import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_endpoint_resolver.dart';
import 'package:sponzey_file_sharing/core/network/udp_port_config.dart';
import 'package:sponzey_file_sharing/domain/network/network_interface_models.dart';

void main() {
  test('wildcard data bind does not advertise the sender address', () {
    final dataEndpoint = UdpInterfaceEndpoint(
      role: UdpPortRole.data,
      localAddress: '0.0.0.0',
      port: 38410,
      bindMode: UdpInterfaceBindMode.any,
    );

    expect(
      TransferDataEndpointResolver.advertisedReceiverAddress(
        dataEndpoint: dataEndpoint,
      ),
      isNull,
    );
  });

  test('wildcard data bind ignores selected local control address', () {
    final dataEndpoint = UdpInterfaceEndpoint(
      role: UdpPortRole.data,
      localAddress: '0.0.0.0',
      port: 38410,
      bindMode: UdpInterfaceBindMode.any,
    );

    expect(
      TransferDataEndpointResolver.advertisedReceiverAddress(
        dataEndpoint: dataEndpoint,
      ),
      isNull,
    );
  });

  test(
    'sender falls back to control ack source for missing or wildcard address',
    () {
      expect(
        TransferDataEndpointResolver.senderRemoteAddress(
          advertisedAddress: null,
          controlAckSourceAddress: '10.211.55.2',
        ),
        '10.211.55.2',
      );
      expect(
        TransferDataEndpointResolver.senderRemoteAddress(
          advertisedAddress: '0.0.0.0',
          controlAckSourceAddress: '10.211.55.2',
        ),
        '10.211.55.2',
      );
    },
  );

  test('sender rejects loopback advertised address for remote ack source', () {
    expect(
      TransferDataEndpointResolver.senderRemoteAddress(
        advertisedAddress: '127.0.0.1',
        controlAckSourceAddress: '10.211.55.2',
      ),
      '10.211.55.2',
    );
  });
}
