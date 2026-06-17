import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_data_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/infrastructure/transfer_data/data_frame.dart';

void main() {
  test('routes every Data frame type to a concrete action route', () {
    const dispatcher = TransferDataFrameDispatcher();

    expect(
      dispatcher.routeFor(DataFrameType.dataStart),
      TransferDataFrameRoute.dataStart,
    );
    expect(
      dispatcher.routeFor(DataFrameType.dataChunk),
      TransferDataFrameRoute.dataChunk,
    );
    expect(
      dispatcher.routeFor(DataFrameType.dataAck),
      TransferDataFrameRoute.dataAck,
    );
    expect(
      dispatcher.routeFor(DataFrameType.dataNack),
      TransferDataFrameRoute.dataNack,
    );
    expect(
      dispatcher.routeFor(DataFrameType.dataWindowUpdate),
      TransferDataFrameRoute.dataWindowUpdate,
    );
    expect(
      dispatcher.routeFor(DataFrameType.dataFinish),
      TransferDataFrameRoute.dataFinish,
    );
    expect(
      dispatcher.routeFor(DataFrameType.dataAbort),
      TransferDataFrameRoute.dataAbort,
    );
  });

  test('declares the expected transfer direction for every action route', () {
    expect(
      TransferDataFrameRoute.dataStart.expectedDirection,
      TransferDirection.incoming,
    );
    expect(
      TransferDataFrameRoute.dataChunk.expectedDirection,
      TransferDirection.incoming,
    );
    expect(
      TransferDataFrameRoute.dataAck.expectedDirection,
      TransferDirection.outgoing,
    );
    expect(
      TransferDataFrameRoute.dataNack.expectedDirection,
      TransferDirection.outgoing,
    );
    expect(
      TransferDataFrameRoute.dataWindowUpdate.expectedDirection,
      TransferDirection.outgoing,
    );
    expect(
      TransferDataFrameRoute.dataFinish.expectedDirection,
      TransferDirection.incoming,
    );
    expect(
      TransferDataFrameRoute.dataAbort.expectedDirection,
      TransferDirection.incoming,
    );
  });

  test('dispatcher stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_data_frame_dispatcher.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });

  test('TransferController does not duplicate DataFrameType switch', () async {
    final source = await File(
      'lib/application/transfer/transfer_controller.dart',
    ).readAsString();

    expect(source, isNot(contains('switch (frame.type)')));
  });

  test(
    'TransferController gates frames by route direction before handlers',
    () async {
      final source = await File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsString();

      expect(source, contains('_hasDataFrameRouteContext'));
      expect(source, contains('route.expectedDirection'));
      expect(source, contains('_lookupIncomingTransfer(transferId) != null'));
      expect(source, contains('_lookupOutgoingTransfer(transferId) != null'));
    },
  );
}
