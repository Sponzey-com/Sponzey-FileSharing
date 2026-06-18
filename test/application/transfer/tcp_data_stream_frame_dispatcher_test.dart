import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/tcp_data_stream_frame_dispatcher.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/tcp_data_stream_frame.dart';

void main() {
  test('routes every TCP stream frame type to a concrete action route', () {
    const dispatcher = TcpDataStreamFrameDispatcher();

    expect(
      dispatcher.routeFor(TcpDataStreamFrameType.metadata),
      TcpDataStreamFrameRoute.metadata,
    );
    expect(
      dispatcher.routeFor(TcpDataStreamFrameType.chunk),
      TcpDataStreamFrameRoute.chunk,
    );
    expect(
      dispatcher.routeFor(TcpDataStreamFrameType.complete),
      TcpDataStreamFrameRoute.complete,
    );
    expect(
      dispatcher.routeFor(TcpDataStreamFrameType.cancel),
      TcpDataStreamFrameRoute.cancel,
    );
    expect(
      dispatcher.routeFor(TcpDataStreamFrameType.error),
      TcpDataStreamFrameRoute.error,
    );
  });

  test('declares incoming transfer direction for stream payload routes', () {
    for (final route in TcpDataStreamFrameRoute.values) {
      expect(route.expectedDirection, TransferDirection.incoming);
    }
  });

  test('dispatcher stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/tcp_data_stream_frame_dispatcher.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('Socket')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('RawTcpData')));
  });
}
