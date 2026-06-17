import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_session_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferSessionKey', () {
    test('uses direction as part of identity', () {
      const outgoing = TransferSessionKey(
        direction: TransferDirection.outgoing,
        transferId: 'transfer-1',
        peerId: 'team@peer-a',
        authSessionId: 'auth-1',
      );
      const incoming = TransferSessionKey(
        direction: TransferDirection.incoming,
        transferId: 'transfer-1',
        peerId: 'team@peer-a',
        authSessionId: 'auth-1',
      );

      expect(outgoing, isNot(incoming));
      expect(outgoing.hashCode, isNot(incoming.hashCode));
    });
  });

  group('TransferSessionRegistry', () {
    test(
      'keeps outgoing and incoming sessions with same transfer id separate',
      () {
        const outgoingKey = TransferSessionKey(
          direction: TransferDirection.outgoing,
          transferId: 'shared-transfer',
          peerId: 'team@peer-a',
          authSessionId: 'auth-1',
        );
        const incomingKey = TransferSessionKey(
          direction: TransferDirection.incoming,
          transferId: 'shared-transfer',
          peerId: 'team@peer-a',
          authSessionId: 'auth-1',
        );
        final outgoing = TransferSessionRegistry<String>(
          direction: TransferDirection.outgoing,
        );
        final incoming = TransferSessionRegistry<String>(
          direction: TransferDirection.incoming,
        );

        expect(
          outgoing.register(outgoingKey, 'send-session').registered,
          isTrue,
        );
        expect(
          incoming.register(incomingKey, 'receive-session').registered,
          isTrue,
        );

        expect(outgoing.lookup(outgoingKey), 'send-session');
        expect(incoming.lookup(incomingKey), 'receive-session');

        expect(outgoing.remove(outgoingKey), 'send-session');
        expect(outgoing.lookup(outgoingKey), isNull);
        expect(incoming.lookup(incomingKey), 'receive-session');
      },
    );

    test('rejects wrong-direction registration', () {
      const incomingKey = TransferSessionKey(
        direction: TransferDirection.incoming,
        transferId: 'transfer-1',
        peerId: 'team@peer-a',
        authSessionId: 'auth-1',
      );
      final outgoing = TransferSessionRegistry<String>(
        direction: TransferDirection.outgoing,
      );

      final result = outgoing.register(incomingKey, 'wrong-session');

      expect(result.registered, isFalse);
      expect(result.issueCode, 'wrong_transfer_session_direction');
      expect(outgoing.lookup(incomingKey), isNull);
    });

    test('marks closing and removed entries without reviving late packets', () {
      const key = TransferSessionKey(
        direction: TransferDirection.outgoing,
        transferId: 'transfer-1',
        peerId: 'team@peer-a',
        authSessionId: 'auth-1',
      );
      final registry = TransferSessionRegistry<String>(
        direction: TransferDirection.outgoing,
      );
      registry.register(key, 'send-session');

      expect(
        registry.markClosing(key).status,
        TransferSessionEntryStatus.closing,
      );
      expect(registry.lookup(key), isNull);

      expect(registry.remove(key), 'send-session');
      expect(registry.statusOf(key), TransferSessionEntryStatus.removed);
      expect(registry.lookup(key), isNull);

      final duplicateLateRegistration = registry.register(key, 'late-session');
      expect(duplicateLateRegistration.registered, isFalse);
      expect(duplicateLateRegistration.issueCode, 'removed_transfer_session');
      expect(registry.lookup(key), isNull);
    });
  });
}
