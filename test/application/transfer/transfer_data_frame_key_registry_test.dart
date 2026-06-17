import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_key_registry.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

void main() {
  group('TransferDataFrameKeyRegistry', () {
    test(
      'keeps incoming and outgoing transfer ids separate for same frame key',
      () {
        final registry = TransferDataFrameKeyRegistry();

        registry.register(
          direction: TransferDirection.outgoing,
          frameKey: 'same-frame-key',
          transferId: 'outgoing-transfer',
        );
        registry.register(
          direction: TransferDirection.incoming,
          frameKey: 'same-frame-key',
          transferId: 'incoming-transfer',
        );

        expect(
          registry.lookup(
            direction: TransferDirection.outgoing,
            frameKey: 'same-frame-key',
          ),
          'outgoing-transfer',
        );
        expect(
          registry.lookup(
            direction: TransferDirection.incoming,
            frameKey: 'same-frame-key',
          ),
          'incoming-transfer',
        );
      },
    );

    test('removing one direction does not remove the opposite direction', () {
      final registry = TransferDataFrameKeyRegistry();

      registry.register(
        direction: TransferDirection.outgoing,
        frameKey: 'same-frame-key',
        transferId: 'outgoing-transfer',
      );
      registry.register(
        direction: TransferDirection.incoming,
        frameKey: 'same-frame-key',
        transferId: 'incoming-transfer',
      );

      registry.remove(
        direction: TransferDirection.outgoing,
        frameKey: 'same-frame-key',
        transferId: 'outgoing-transfer',
      );

      expect(
        registry.lookup(
          direction: TransferDirection.outgoing,
          frameKey: 'same-frame-key',
        ),
        isNull,
      );
      expect(
        registry.lookup(
          direction: TransferDirection.incoming,
          frameKey: 'same-frame-key',
        ),
        'incoming-transfer',
      );
    });

    test('ignores stale removal for a different transfer id', () {
      final registry = TransferDataFrameKeyRegistry();

      registry.register(
        direction: TransferDirection.outgoing,
        frameKey: 'same-frame-key',
        transferId: 'new-transfer',
      );

      registry.remove(
        direction: TransferDirection.outgoing,
        frameKey: 'same-frame-key',
        transferId: 'old-transfer',
      );

      expect(
        registry.lookup(
          direction: TransferDirection.outgoing,
          frameKey: 'same-frame-key',
        ),
        'new-transfer',
      );
    });
  });
}
