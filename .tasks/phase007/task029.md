# Task 029. Outgoing route lease validation 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 송신 전 active route lease 검증 조건을 controller에서 독립 command로 분리하는 것이다.
- [x] 이 태스크는 현재 선택 경로의 lease id와 status가 기대 lease와 일치해야만 전송을 계속하는 규칙을 테스트로 고정한다.
- [x] 완료 후 `_ensureRouteLeaseStillActive`는 registry 조회 후 command decision을 적용하는 얇은 adapter만 담당한다.

## 2. Scope

### Included

- [x] `TransferOutgoingRouteLeaseCommand`를 추가한다.
- [x] route id가 일치하고 status가 active이면 valid인지 테스트한다.
- [x] route id mismatch, inactive status, missing route는 invalid인지 테스트한다.
- [x] controller route lease 검증이 새 command를 사용하도록 변경한다.

### Excluded

- [x] peer path registry 조회 방식은 변경하지 않는다.
- [x] route selection, candidate scoring, path recovery 정책은 변경하지 않는다.
- [x] error code/message와 packet format은 변경하지 않는다.

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
- [x] route selection과 error code/message가 변경되지 않았다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingRouteLeaseCommand`를 추가해 expected route lease와 현재 selected path 상태 검증을 분리했다.
  - `_ensureRouteLeaseStillActive`는 registry 조회 후 command decision을 적용한다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_outgoing_route_lease_command.dart`
  - 생성: `test/application/transfer/transfer_outgoing_route_lease_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_route_lease_command_test.dart --reporter expanded`: 최초 실패 후 구현 뒤 통과
  - `dart format lib/application/transfer/transfer_controller.dart lib/application/transfer/transfer_outgoing_route_lease_command.dart test/application/transfer/transfer_outgoing_route_lease_command_test.dart`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - peer path registry 조회 방식, route selection, candidate scoring, path recovery, error code/message, packet format은 변경하지 않았다.
- [x] 남은 위험 요소를 기록한다.
  - `_sendChunk`에는 아직 file read와 frame send side effect가 함께 남아 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task030에서 전송 metric message assembly 또는 data frame build input assembly를 추가 분리한다.

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

Next task: `.tasks/task030.md`
