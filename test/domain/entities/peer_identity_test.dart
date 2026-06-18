import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/entities/peer_identity.dart';

void main() {
  group('PeerIdentity', () {
    test('uses runtime instance id as live peer identity', () {
      final identity = PeerIdentity.resolve(
        userId: 'admin',
        instanceId: 'instance-a',
        deviceId: 'device-a',
      );

      expect(identity.id, 'admin@instance-a');
      expect(identity.usesLegacyDeviceFallback, isFalse);
    });

    test('keeps the same peer id for the same instance across endpoints', () {
      final first = PeerIdentity.resolve(
        userId: 'admin',
        instanceId: 'instance-a',
        deviceId: 'device-a',
      );
      final second = PeerIdentity.resolve(
        userId: 'admin',
        instanceId: 'instance-a',
        deviceId: 'device-a-renamed',
      );

      expect(second.id, first.id);
    });

    test(
      'separates different instances even when the device id is the same',
      () {
        final first = PeerIdentity.resolve(
          userId: 'admin',
          instanceId: 'instance-a',
          deviceId: 'device-a',
        );
        final second = PeerIdentity.resolve(
          userId: 'admin',
          instanceId: 'instance-b',
          deviceId: 'device-a',
        );

        expect(second.id, isNot(first.id));
        expect(second.id, 'admin@instance-b');
      },
    );

    test('uses device id only for legacy inputs without an instance id', () {
      final identity = PeerIdentity.resolve(
        userId: 'admin',
        instanceId: null,
        deviceId: 'device-a',
      );

      expect(identity.id, 'admin@device-a');
      expect(identity.usesLegacyDeviceFallback, isTrue);
    });

    test('rejects an empty user id', () {
      expect(
        () => PeerIdentity.resolve(
          userId: ' ',
          instanceId: 'instance-a',
          deviceId: 'device-a',
        ),
        throwsArgumentError,
      );
    });

    test('rejects inputs without an instance id or legacy device id', () {
      expect(
        () => PeerIdentity.resolve(
          userId: 'admin',
          instanceId: ' ',
          deviceId: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}
