# Task 023. Outgoing digest advance decision 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 `_sendChunk` 내부의 outgoing digest advance 조건을 독립 command로 분리하는 것이다.
- [x] 이 태스크는 최초 송신 chunk만 순서대로 digest에 반영하고 retransmission은 digest에 재반영하지 않는 규칙을 테스트로 고정한다.
- [x] 완료 후 controller는 digest cursor 조건식을 직접 소유하지 않는다.

## 2. Scope

### Included

- [x] `TransferOutgoingDigestAdvanceCommand`를 추가한다.
- [x] 순서에 맞는 최초 송신 chunk는 digest append와 cursor advance가 필요한지 테스트한다.
- [x] retransmission 또는 순서 밖 chunk는 digest cursor를 변경하지 않는지 테스트한다.
- [x] controller가 새 command를 사용하도록 변경한다.

### Excluded

- [x] digest 알고리즘과 digest writer 구현은 변경하지 않는다.
- [x] file read와 data frame 전송 방식은 변경하지 않는다.
- [x] retry, window, ACK/NACK 정책은 변경하지 않는다.

## 3. TDD Plan

- [x] 실패하는 command 단위 테스트를 먼저 작성한다.
- [x] 실패하는 controller source guard를 먼저 작성한다.
- [x] 최소 구현으로 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command는 Flutter, IO, socket, repository, infrastructure digest 타입에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] digest 알고리즘과 packet format이 변경되지 않았다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingDigestAdvanceCommand`를 추가해 최초 송신 chunk의 digest append 여부와 next digest cursor advance를 분리했다.
  - `_sendChunk`는 command decision에 따라 digest writer에 bytes를 추가하고 cursor를 반영한다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_outgoing_digest_advance_command.dart`
  - 생성: `test/application/transfer/transfer_outgoing_digest_advance_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_digest_advance_command_test.dart --reporter expanded`: 최초 실패 후 구현 뒤 통과
  - `dart format lib/application/transfer/transfer_controller.dart lib/application/transfer/transfer_outgoing_digest_advance_command.dart test/application/transfer/transfer_outgoing_digest_advance_command_test.dart`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - digest 알고리즘, digest writer 구현, file read, data frame 전송 방식, retry/window/ACK/NACK 정책은 변경하지 않았다.
  - command는 infrastructure digest 타입에 의존하지 않는다.
- [x] 남은 위험 요소를 기록한다.
  - `_sendChunk`는 아직 file read, data frame building, send failure side effect를 함께 수행한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task024에서 `_sendChunk`의 data endpoint validation 또는 data frame build input assembly를 분리한다.

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

Next task: `.tasks/task024.md`
