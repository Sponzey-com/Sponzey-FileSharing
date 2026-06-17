import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_incoming_route_match_command.dart';

void main() {
  group('TransferIncomingRouteMatchCommand', () {
    test('rejects remote address and port mismatch', () {
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.4',
          datagramRemotePort: 23200,
          datagramLocalAddress: null,
          datagramIsWildcardBind: false,
          candidateIsAnyBind: false,
        ),
        isFalse,
      );
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.3',
          datagramRemotePort: 23201,
          datagramLocalAddress: null,
          datagramIsWildcardBind: false,
          candidateIsAnyBind: false,
        ),
        isFalse,
      );
    });

    test('accepts remote match when local endpoint is absent or wildcard', () {
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.3',
          datagramRemotePort: 23200,
          datagramLocalAddress: null,
          datagramIsWildcardBind: false,
          candidateIsAnyBind: false,
        ),
        isTrue,
      );
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.3',
          datagramRemotePort: 23200,
          datagramLocalAddress: '0.0.0.0',
          datagramIsWildcardBind: true,
          candidateIsAnyBind: false,
        ),
        isTrue,
      );
    });

    test('accepts explicit local endpoint only on local match or any bind', () {
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.3',
          datagramRemotePort: 23200,
          candidateLocalAddress: '10.211.55.2',
          datagramLocalAddress: '10.211.55.2',
          datagramIsWildcardBind: false,
          candidateIsAnyBind: false,
        ),
        isTrue,
      );
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.3',
          datagramRemotePort: 23200,
          candidateLocalAddress: '192.168.0.236',
          datagramLocalAddress: '10.211.55.2',
          datagramIsWildcardBind: false,
          candidateIsAnyBind: true,
        ),
        isTrue,
      );
      expect(
        TransferIncomingRouteMatchCommand.matches(
          candidateRemoteAddress: '10.211.55.3',
          candidateRemotePort: 23200,
          datagramRemoteAddress: '10.211.55.3',
          datagramRemotePort: 23200,
          candidateLocalAddress: '192.168.0.236',
          datagramLocalAddress: '10.211.55.2',
          datagramIsWildcardBind: false,
          candidateIsAnyBind: false,
        ),
        isFalse,
      );
    });
  });
}
