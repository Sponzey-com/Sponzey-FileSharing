# Task 063. Runner Effect Mapping Exhaustiveness Tests

## Goal

상태 머신의 `TransitionEffect` 이름과 runner executor 매핑이 어긋나는 회귀를 막는다. 이번 task는 runtime 구조 변경 없이 테스트를 보강해 송신/수신 runner가 현재 정의된 모든 effect를 실행할 수 있음을 고정한다.

## Scope

- [x] 송신 runner의 전체 effect delegation 테스트를 추가한다.
- [x] 수신 runner의 전체 effect delegation 테스트를 추가한다.
- [x] 기존 route runner effect coverage가 전체 effect를 포함하는지 확인한다.

## Functional Requirements

- [x] 송신 runner가 data start, chunk pump, finish, complete, cancel, cleanup effect를 실행한다.
- [x] 수신 runner가 chunk write, out-of-order buffer, verify, finalize, complete, cancel, cleanup effect를 실행한다.
- [x] invalid/warning transition에서는 기존처럼 executor가 호출되지 않는다.

## Architecture Requirements

- [x] production code 변경 없이 테스트만 보강한다.
- [x] runner가 effect 이름을 command처럼 외부로 노출하지 않음을 유지한다.
- [x] Flutter, Riverpod, UDP, 파일 시스템, Timer 의존성을 추가하지 않는다.

## TDD Requirements

- [x] 송신 runner 누락 effect 테스트를 작성한다.
- [x] 수신 runner 누락 effect 테스트를 작성한다.
- [x] 테스트 실패가 발생하면 runner switch 누락만 수정한다.

## Validation

- [x] `flutter test test/application/transfer/outgoing_transfer_session_runner_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/incoming_transfer_session_runner_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] 송신 runner 전체 effect mapping이 테스트로 고정되어 있다.
- [x] 수신 runner 전체 effect mapping이 테스트로 고정되어 있다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
