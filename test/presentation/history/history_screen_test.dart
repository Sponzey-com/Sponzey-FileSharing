import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/application/transfer/transfer_overview_provider.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/presentation/history/history_screen.dart';

void main() {
  testWidgets(
    'shows persisted transfer history job with unified failure text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 700);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transferHistoryJobsProvider.overrideWith((ref) {
              return [
                _job(
                  status: TransferJobStatus.failed,
                  message: '상대 노드의 전송 응답 시간이 초과되었습니다.',
                ),
              ];
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('demo.txt'), findsOneWidget);
      expect(find.text('실패'), findsOneWidget);
      expect(find.textContaining('네트워크 응답이 지연'), findsOneWidget);
    },
  );
}

TransferJob _job({required TransferJobStatus status, String? message}) {
  final now = DateTime.utc(2026, 1, 1, 12);
  return TransferJob(
    id: 'job-1',
    transferId: 'transfer-1',
    direction: TransferDirection.outgoing,
    peerId: 'peer-1',
    peerDisplayName: 'peer',
    fileName: 'demo.txt',
    fileSize: 12,
    bytesTransferred: 0,
    totalChunks: 1,
    completedChunks: 0,
    status: status,
    createdAt: now,
    updatedAt: now,
    message: message,
  );
}
