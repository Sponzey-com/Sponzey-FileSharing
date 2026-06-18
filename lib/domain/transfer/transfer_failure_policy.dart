import 'package:sponzey_file_sharing/domain/entities/transfer_job.dart';

enum TransferFailureCategory {
  none,
  network,
  authentication,
  storage,
  peerPreparation,
  route,
  verification,
  cancelled,
  unknown,
}

class TransferFailureDecision {
  const TransferFailureDecision({
    required this.category,
    required this.retryable,
    required this.userMessage,
    required this.diagnosticCode,
  });

  final TransferFailureCategory category;
  final bool retryable;
  final String userMessage;
  final String diagnosticCode;
}

class TransferFailurePolicy {
  const TransferFailurePolicy();

  TransferFailureDecision classify(TransferJob job) {
    if (job.status == TransferJobStatus.completed) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.none,
        retryable: false,
        userMessage: '전송이 완료되었습니다.',
        diagnosticCode: 'transfer.completed',
      );
    }

    if (job.status == TransferJobStatus.cancelled) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.cancelled,
        retryable: true,
        userMessage: '사용자가 전송을 취소했습니다. 필요하면 다시 전송할 수 있습니다.',
        diagnosticCode: 'transfer.cancelled',
      );
    }

    if (!job.isTerminal) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.none,
        retryable: false,
        userMessage: '전송이 진행 중입니다.',
        diagnosticCode: 'transfer.active',
      );
    }

    final message = (job.message ?? '').toLowerCase();
    if (_containsAny(message, const ['인증', 'auth', 'unauthorized'])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.authentication,
        retryable: false,
        userMessage: '인증되지 않은 피어입니다. 같은 아이디/비밀번호로 다시 연결해 주세요.',
        diagnosticCode: 'transfer.failure.authentication',
      );
    }

    if (_containsAny(message, const ['해시', 'digest', 'hash', '검증'])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.verification,
        retryable: false,
        userMessage: '수신 파일 검증에 실패했습니다. 네트워크 또는 파일 원본을 확인해 주세요.',
        diagnosticCode: 'transfer.failure.verification',
      );
    }

    if (_containsAny(message, const [
      '수신 임시',
      'writer',
      '저장 경로',
      '저장하지 못',
      '권한',
    ])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.storage,
        retryable: true,
        userMessage: '저장 경로나 임시 파일 권한 문제입니다. 수신 경로를 확인한 뒤 재시도해 주세요.',
        diagnosticCode: 'transfer.failure.storage',
      );
    }

    if (_containsAny(message, const ['수신 준비', 'prepare', '준비하지 못'])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.peerPreparation,
        retryable: true,
        userMessage: '상대 노드가 수신 준비를 완료하지 못했습니다. 상대 설정을 확인한 뒤 재시도해 주세요.',
        diagnosticCode: 'transfer.failure.peer_preparation',
      );
    }

    if (job.usesTcpDataChannel &&
        _containsAny(message, const [
          'route',
          '연결 경로가 만료',
          '연결 경로가 변경',
          'endpoint',
          'tcp data channel',
          'tcp 파일 전송',
          'tcp_outgoing',
          'missing_tcp',
        ])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.network,
        retryable: true,
        userMessage: 'TCP 데이터 채널 연결이 종료되었습니다. 피어 연결 상태를 확인한 뒤 다시 전송해 주세요.',
        diagnosticCode: 'transfer.failure.tcp_data_channel',
      );
    }

    if (_containsAny(message, const ['route', '경로', 'endpoint', 'data udp'])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.route,
        retryable: true,
        userMessage: '사용 가능한 네트워크 경로를 찾지 못했습니다. 피어 연결 상태를 확인해 주세요.',
        diagnosticCode: 'transfer.failure.route',
      );
    }

    if (_containsAny(message, const [
      'timeout',
      '초과',
      '응답 시간',
      'retransmission',
    ])) {
      return const TransferFailureDecision(
        category: TransferFailureCategory.network,
        retryable: true,
        userMessage: '네트워크 응답이 지연되거나 손실되었습니다. 연결 상태를 확인한 뒤 재시도해 주세요.',
        diagnosticCode: 'transfer.failure.network',
      );
    }

    return const TransferFailureDecision(
      category: TransferFailureCategory.unknown,
      retryable: false,
      userMessage: '전송 실패 원인을 분류하지 못했습니다. 진단 로그를 확인해 주세요.',
      diagnosticCode: 'transfer.failure.unknown',
    );
  }

  static bool _containsAny(String value, List<String> patterns) {
    for (final pattern in patterns) {
      if (value.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
