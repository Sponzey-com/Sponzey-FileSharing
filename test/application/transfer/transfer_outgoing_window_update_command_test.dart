import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_window_update_command.dart';

void main() {
  test('keeps positive window size and remote window start', () {
    final decision = TransferOutgoingWindowUpdateCommand.decide(
      windowStart: 42,
      windowSize: 8,
    );

    expect(decision.remoteWindowStart, 42);
    expect(decision.advertisedWindowSize, 8);
  });

  test('clamps zero or negative window size to one', () {
    final zero = TransferOutgoingWindowUpdateCommand.decide(
      windowStart: 10,
      windowSize: 0,
    );
    final negative = TransferOutgoingWindowUpdateCommand.decide(
      windowStart: 11,
      windowSize: -4,
    );

    expect(zero.advertisedWindowSize, 1);
    expect(negative.advertisedWindowSize, 1);
  });

  test('command stays independent from framework and IO adapters', () async {
    final source = await File(
      'lib/application/transfer/transfer_outgoing_window_update_command.dart',
    ).readAsString();

    expect(source, isNot(contains('flutter')));
    expect(source, isNot(contains('riverpod')));
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('TransferFileService')));
    expect(source, isNot(contains('ControlTransport')));
    expect(source, isNot(contains('DataTransport')));
  });
}
