# Task 016. Legacy complete readiness command 재사용

## 1. Task Purpose

- [x] 이 태스크의 목적은 legacy Control `TRANSFER_COMPLETE` 경로도 `TransferIncomingDataFinishCommand`를 재사용하게 만드는 것이다.
- [x] 이 태스크는 Data channel finish와 legacy Control complete의 완료 가능/누락 chunk 판단 정책을 일치시킨다.
- [x] 완료 후 controller에는 `nextExpectedChunk != expectedChunkCount || bufferedChunks.isNotEmpty` 완료 조건이 직접 남지 않는다.

## 2. Scope

### Included

- [x] controller source guard로 완료 readiness 조건 중복을 금지한다.
- [x] `_onTransferComplete`가 `TransferIncomingDataFinishCommand`를 사용하도록 변경한다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

### Excluded

- [x] legacy Control chunk ACK/NACK packet format은 변경하지 않는다.
- [x] Data channel finish 경로는 변경하지 않는다.
- [x] digest, file finalize, ACK 전송 방식은 변경하지 않는다.

## 3. TDD Plan

- [x] 실패하는 source guard 테스트를 먼저 작성한다.
- [x] 최소 구현으로 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] Data/Control incoming complete readiness decision이 일관화되었다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - legacy Control `TRANSFER_COMPLETE` 경로가 직접 완료 readiness 조건을 판단하지 않고 `TransferIncomingDataFinishCommand.decide`를 사용하도록 변경했다.
  - controller source guard를 추가해 `nextExpectedChunk != expectedChunkCount || bufferedChunks.isNotEmpty` 조건 중복이 재발하지 않도록 했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `test/application/transfer/transfer_incoming_data_finish_command_test.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `dart format lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_incoming_data_finish_command_test.dart`: 통과
  - `flutter test test/application/transfer/transfer_incoming_data_finish_command_test.dart --reporter expanded`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - Data channel finish와 legacy Control complete가 동일한 readiness decision 객체를 사용한다.
  - Control packet format, Data finish 경로, digest/finalize/ACK 정책은 변경하지 않았다.
- [x] 남은 위험 요소를 기록한다.
  - `_missingIndexesUntil`, `_remainingMissingIndexes` 계산 로직이 아직 controller private helper에 남아 있어 재시도 경로와 finish 경로 간 계산 책임이 완전히 분리되지 않았다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task017에서 누락 chunk 계산을 독립 명령 객체로 분리하고 controller helper 의존을 줄인다.

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

Next task: `.tasks/task017.md`
