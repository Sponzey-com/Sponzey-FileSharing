# Task 017. Incoming missing chunk 계산 책임 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 수신 경로의 누락 chunk 계산을 controller private helper에서 독립 명령 객체로 분리하는 것이다.
- [x] 이 태스크는 out-of-order 수신 직후 NACK와 missing retry NACK가 같은 계산 규칙을 사용하도록 만든다.
- [x] 완료 후 controller는 누락 chunk index loop를 직접 소유하지 않는다.

## 2. Scope

### Included

- [x] `TransferIncomingMissingChunksCommand`를 추가한다.
- [x] highest received index 직전까지의 missing chunk 계산 기능을 테스트한다.
- [x] expected chunk count까지의 remaining missing chunk 계산 기능을 테스트한다.
- [x] controller가 새 command를 사용하도록 연결한다.
- [x] source guard로 controller helper 재도입을 방지한다.

### Excluded

- [x] ACK/NACK packet format은 변경하지 않는다.
- [x] retransmission window size, timeout, retry 횟수 정책은 변경하지 않는다.
- [x] 파일 저장, digest, finalize 정책은 변경하지 않는다.

## 3. TDD Plan

- [x] 실패하는 command 단위 테스트를 먼저 작성한다.
- [x] 실패하는 controller source guard를 먼저 작성한다.
- [x] 최소 구현으로 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] application command는 Flutter, IO, socket, repository에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] Control/Data packet format이 변경되지 않았다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferIncomingMissingChunksCommand`를 추가해 out-of-order 직후 NACK와 missing retry NACK가 같은 missing index 계산 규칙을 사용하게 했다.
  - controller의 `_missingIndexesUntil`, `_remainingMissingIndexes` private helper를 제거하고 command 호출로 대체했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_incoming_missing_chunks_command.dart`
  - 생성: `test/application/transfer/transfer_incoming_missing_chunks_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_incoming_missing_chunks_command_test.dart --reporter expanded`: 최초 실패 후 구현 뒤 통과
  - `dart format lib/application/transfer/transfer_controller.dart lib/application/transfer/transfer_incoming_missing_chunks_command.dart test/application/transfer/transfer_incoming_missing_chunks_command_test.dart`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - command는 Flutter, IO, socket, repository에 의존하지 않는다.
  - Control/Data packet format과 retry 정책은 변경하지 않았다.
- [x] 남은 위험 요소를 기록한다.
  - 수신 window size 산출은 아직 controller method에 남아 있어 window update 정책과 buffer 상태 의존을 독립적으로 테스트하기 어렵다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task018에서 receiver window calculation 책임을 독립 command로 분리한다.

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

Next task: `.tasks/task018.md`
