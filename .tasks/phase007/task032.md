# Task 032. Outgoing timeout/exhaustion message 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 outgoing timeout과 retry exhaustion message 문자열 조합을 command로 분리하는 것이다.
- [x] 이 태스크는 retry exhaustion 예외 메시지와 timeout retransmission metric message를 테스트로 고정한다.
- [x] 완료 후 controller에는 outgoing chunk retry exhaustion/timeout 문자열 조합이 직접 남지 않는다.

## 2. Scope

### Included

- [x] `TransferOutgoingChunkMetricMessageCommand.retryExhausted`를 추가한다.
- [x] `TransferOutgoingChunkMetricMessageCommand.timeoutQueued`를 추가한다.
- [x] `_sendChunk` retry exhaustion 예외 message가 command를 사용하도록 변경한다.
- [x] `_onRetransmissionScan` timeout metric message가 command를 사용하도록 변경한다.

### Excluded

- [x] error code는 변경하지 않는다.
- [x] timeout scan, retry queue, window reduction policy는 변경하지 않는다.
- [x] 사용자 표시 문구의 의미는 변경하지 않는다.

## 3. TDD Plan

- [x] 실패하는 command 단위 테스트를 먼저 작성한다.
- [x] 실패하는 controller source guard를 먼저 작성한다.
- [x] 최소 구현으로 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command는 Flutter, IO, socket, repository, infrastructure frame 타입에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] error code와 retry/timeout 정책이 변경되지 않았다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingChunkMetricMessageCommand`에 retry exhaustion, timeout queued 메시지 생성을 추가했다.
  - `_sendChunk`와 `_onRetransmissionScan`의 해당 문자열 조합을 command 호출로 교체했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 수정: `lib/application/transfer/transfer_outgoing_chunk_metric_message_command.dart`
  - 수정: `test/application/transfer/transfer_outgoing_chunk_metric_message_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_chunk_metric_message_command_test.dart --reporter expanded`: 최초 실패 후 구현 뒤 통과
  - `dart format lib/application/transfer/transfer_controller.dart lib/application/transfer/transfer_outgoing_chunk_metric_message_command.dart test/application/transfer/transfer_outgoing_chunk_metric_message_command_test.dart`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - error code, timeout scan, retry queue, window reduction policy, 사용자 표시 문구 의미는 변경하지 않았다.
- [x] 남은 위험 요소를 기록한다.
  - `_sendChunk`의 file read와 data frame send side effect는 아직 같은 메서드에 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task033에서 data frame build input assembly 또는 `_sendChunk` side effect slicing을 진행한다.

## 6. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

Next task: `.tasks/task033.md`
