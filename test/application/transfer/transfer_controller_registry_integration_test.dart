import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransferController owns direction-aware session registries', () async {
    final source = await File(
      'lib/application/transfer/transfer_controller.dart',
    ).readAsString();

    expect(
      source,
      contains('application/transfer/transfer_session_registry.dart'),
    );
    expect(
      source,
      contains('TransferSessionRegistry<_OutgoingTransferContext>'),
    );
    expect(
      source,
      contains('TransferSessionRegistry<_IncomingTransferContext>'),
    );
    expect(source, contains('_registerOutgoingTransfer'));
    expect(source, contains('_registerIncomingTransfer'));
    expect(source, contains('_lookupOutgoingTransfer'));
    expect(source, contains('_lookupIncomingTransfer'));
    expect(source, contains('_removeOutgoingTransfer'));
    expect(source, contains('_removeIncomingTransfer'));
  });
}
