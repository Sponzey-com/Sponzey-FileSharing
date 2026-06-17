import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_outgoing_chunk_metric_message_command.dart';

void main() {
  group('TransferOutgoingChunkMetricMessageCommand', () {
    test('builds retryable send failure message', () {
      expect(
        TransferOutgoingChunkMetricMessageCommand.retryQueued(chunkIndex: 7),
        'data chunk 7 송신 실패, 재전송 대기 중',
      );
    });

    test('builds retransmission progress message', () {
      expect(
        TransferOutgoingChunkMetricMessageCommand.sent(
          chunkIndex: 7,
          isRetransmission: true,
          windowSize: 32,
        ),
        'chunk 7 재전송 중',
      );
    });

    test('builds normal send progress message', () {
      expect(
        TransferOutgoingChunkMetricMessageCommand.sent(
          chunkIndex: 7,
          isRetransmission: false,
          windowSize: 32,
        ),
        'window 32 기준으로 전송 중',
      );
    });

    test('controller delegates outgoing chunk metric messages to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, contains('TransferOutgoingChunkMetricMessageCommand'));
      expect(source, isNot(contains('송신 실패, 재전송 대기 중')));
      expect(source, isNot(contains('기준으로 전송 중')));
    });

    test('builds retry exhaustion message', () {
      expect(
        TransferOutgoingChunkMetricMessageCommand.retryExhausted(chunkIndex: 9),
        'chunk 9 재전송 한도를 초과했습니다.',
      );
    });

    test('builds timeout retransmission queued message', () {
      expect(
        TransferOutgoingChunkMetricMessageCommand.timeoutQueued(chunkCount: 3),
        'timeout 3 chunks, 재전송 대기 중',
      );
    });

    test('controller delegates timeout and exhaustion messages to command', () {
      final source = File(
        'lib/application/transfer/transfer_controller.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('재전송 한도를 초과했습니다.')));
      expect(source, isNot(contains('chunks, 재전송 대기 중')));
    });
  });
}
