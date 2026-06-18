import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';
import 'package:sponzey_file_sharing/domain/transfer/data_transfer_protocol.dart';
import 'package:sponzey_file_sharing/domain/transfer/transfer_failure_policy.dart';

void main() {
  const policy = TransferFailurePolicy();

  test('classifies retryable network failures', () {
    final decision = policy.classify(
      _job(
        status: TransferJobStatus.failed,
        message: '상대 노드의 전송 응답 시간이 초과되었습니다.',
      ),
    );

    expect(decision.category, TransferFailureCategory.network);
    expect(decision.retryable, isTrue);
    expect(decision.diagnosticCode, 'transfer.failure.network');
  });

  test('classifies non-retryable verification failures', () {
    final decision = policy.classify(
      _job(status: TransferJobStatus.failed, message: '파일 해시가 일치하지 않습니다.'),
    );

    expect(decision.category, TransferFailureCategory.verification);
    expect(decision.retryable, isFalse);
    expect(decision.diagnosticCode, 'transfer.failure.verification');
  });

  test('classifies incoming data chunk write failures as storage failures', () {
    final decision = policy.classify(
      _job(
        status: TransferJobStatus.failed,
        message: '수신 data chunk 를 저장하지 못했습니다. 저장 경로 또는 임시 파일 권한을 확인해 주세요.',
      ),
    );

    expect(decision.category, TransferFailureCategory.storage);
    expect(decision.retryable, isTrue);
    expect(decision.diagnosticCode, 'transfer.failure.storage');
  });

  test('treats cancelled jobs as terminal and retryable', () {
    final job = _job(status: TransferJobStatus.cancelled, message: '사용자 취소');
    final decision = policy.classify(job);

    expect(job.isTerminal, isTrue);
    expect(job.statusLabel, '취소됨');
    expect(decision.category, TransferFailureCategory.cancelled);
    expect(decision.retryable, isTrue);
  });

  test(
    'uses the same status vocabulary for sender and receiver directions',
    () {
      final sender = _job(
        direction: TransferDirection.outgoing,
        status: TransferJobStatus.completed,
      );
      final receiver = _job(
        direction: TransferDirection.incoming,
        status: TransferJobStatus.completed,
      );

      expect(sender.statusLabel, receiver.statusLabel);
      expect(
        policy.classify(sender).userMessage,
        policy.classify(receiver).userMessage,
      );
    },
  );

  test('classifies TCP route lease messages as TCP data channel failures', () {
    final decision = policy.classify(
      _job(
        status: TransferJobStatus.failed,
        message: '전송 중 연결 경로가 만료되어 전송을 중단했습니다. route=path:peer-a@1',
        dataCapability: DataTransferCapability.tcpDataStreamV1,
      ),
    );

    expect(decision.category, TransferFailureCategory.network);
    expect(decision.retryable, isTrue);
    expect(decision.diagnosticCode, 'transfer.failure.tcp_data_channel');
    expect(decision.userMessage, contains('TCP 데이터 채널'));
  });

  test('keeps legacy UDP route failures in route category', () {
    final decision = policy.classify(
      _job(
        status: TransferJobStatus.failed,
        message: '전송 중 연결 경로가 만료되어 전송을 중단했습니다.',
        dataCapability: DataTransferCapability.udpDataBinaryV1,
      ),
    );

    expect(decision.category, TransferFailureCategory.route);
    expect(decision.diagnosticCode, 'transfer.failure.route');
  });
}

TransferJob _job({
  TransferDirection direction = TransferDirection.outgoing,
  TransferJobStatus status = TransferJobStatus.failed,
  String? message,
  DataTransferCapability? dataCapability,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return TransferJob(
    id: 'job-1',
    transferId: 'transfer-1',
    direction: direction,
    peerId: 'peer-1',
    peerDisplayName: 'peer',
    fileName: 'demo.txt',
    fileSize: 12,
    bytesTransferred: status == TransferJobStatus.completed ? 12 : 0,
    totalChunks: 1,
    completedChunks: status == TransferJobStatus.completed ? 1 : 0,
    status: status,
    createdAt: now,
    updatedAt: now,
    message: message,
    dataCapability: dataCapability,
  );
}
