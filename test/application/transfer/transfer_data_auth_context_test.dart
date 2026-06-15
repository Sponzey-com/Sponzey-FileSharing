import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_auth_context.dart';

void main() {
  TransferDataAuthContext contextFor({
    String transferId = 'transfer-a',
    String selectedPathId = 'path-a',
  }) {
    return TransferDataAuthContext.derive(
      sessionId: 'session-001',
      localNodeId: 'local',
      remoteNodeId: 'remote',
      transferId: transferId,
      selectedPathId: selectedPathId,
      nonce: 'nonce-001',
    );
  }

  test('derives different context per transfer id', () {
    final first = contextFor();
    final second = contextFor(transferId: 'transfer-b');

    expect(first.keyId, isNot(second.keyId));
    expect(first.sessionHash, isNot(second.sessionHash));
  });

  test('derives different context per selected path', () {
    final first = contextFor();
    final second = contextFor(selectedPathId: 'path-b');

    expect(first.keyId, isNot(second.keyId));
  });

  test('disposes key material access after transfer lifecycle ends', () {
    final context = contextFor();
    context.dispose();

    expect(() => context.authenticator, throwsStateError);
  });
}
