import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_protocol.dart';

void main() {
  test('wire list preserves tcp data stream capability', () {
    final capabilities = DataTransferCapabilitySet({
      DataTransferCapability.tcpDataStreamV1,
      DataTransferCapability.udpDataBinaryV1,
    });

    final wire = capabilities.toWireList();
    final decoded = DataTransferCapabilitySet.fromWireList(wire);

    expect(wire, ['tcpDataStreamV1', 'udpDataBinaryV1']);
    expect(decoded.supports(DataTransferCapability.tcpDataStreamV1), isTrue);
    expect(decoded.supports(DataTransferCapability.udpDataBinaryV1), isTrue);
  });
}
