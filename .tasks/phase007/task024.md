# Task 024. Outgoing completion decision 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 송신 완료 판단 조건을 controller 여러 위치에서 독립 command로 분리하는 것이다.
- [x] 이 태스크는 all-acked, no-in-flight, already-completed 조건을 테스트로 고정한다.
- [x] 완료 후 controller에는 `acknowledgedChunks.length == preparedFile.chunkCount && inFlightChunks.isEmpty` 조건 중복이 남지 않는다.

## 2. Scope

### Included

- [x] `TransferOutgoingCompletionCommand`를 추가한다.
- [x] 모든 chunk가 ACK 되고 in-flight가 없을 때만 완료 가능한지 테스트한다.
- [x] 이미 completion future가 완료된 경우 중복 complete를 막는지 테스트한다.
- [x] controller의 완료 판단 세 위치가 새 command를 사용하도록 변경한다.

### Excluded

- [x] ACK 처리, window pump, retransmission scan 취소 정책은 변경하지 않는다.
- [x] 완료 future 타입과 lifecycle은 변경하지 않는다.
- [x] packet format은 변경하지 않는다.

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
- [x] ACK 처리와 packet format이 변경되지 않았다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingCompletionCommand`를 추가해 outgoing transfer completion 판단을 분리했다.
  - pump, Data ACK, legacy ACK 경로의 중복 완료 조건을 command 호출로 교체했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_outgoing_completion_command.dart`
  - 생성: `test/application/transfer/transfer_outgoing_completion_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_completion_command_test.dart --reporter expanded`: 최초 실패 후 구현 뒤 통과
  - `dart format lib/application/transfer/transfer_controller.dart lib/application/transfer/transfer_outgoing_completion_command.dart test/application/transfer/transfer_outgoing_completion_command_test.dart`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - ACK 처리, window pump, retransmission scan 취소 정책, completion future lifecycle, packet format은 변경하지 않았다.
  - command는 infrastructure frame 타입에 의존하지 않는다.
- [x] 남은 위험 요소를 기록한다.
  - `_sendChunk`와 `_onDataAck`에는 아직 여러 side effect가 남아 있어 후속 task에서 더 작은 handler로 분리할 수 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task025에서 outgoing side effect adapter 또는 route/data endpoint validation 분리를 진행한다.

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

Next task: `.tasks/task025.md`
