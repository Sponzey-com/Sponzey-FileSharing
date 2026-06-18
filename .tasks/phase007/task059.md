# Task 059. Transfer Route Lease State Machine

## Goal

전송 session이 검증되지 않은 route를 사용하거나, 만료된 route를 계속 사용하는 문제를 막기 위해 route lease 상태 머신을 application 계층에 추가한다.

## Scope

- [x] route lease 상태 enum을 추가한다.
- [x] route lease 이벤트 enum을 추가한다.
- [x] core `StateMachine` 인터페이스를 구현한다.
- [x] expired/rejected terminal 상태에서 추가 이벤트를 warning no-op으로 처리한다.

## Functional Requirements

- [x] `candidate -> probing`
- [x] `probing -> verified`
- [x] probe 실패는 `rejected`로 전이한다.
- [x] 명시 reject 요청은 `rejected`로 전이한다.
- [x] `verified -> expired`
- [x] transfer session은 `verified` 상태만 usable route로 판단할 수 있다.
- [x] `expired`, `rejected` 상태는 terminal 상태로 처리한다.
- [x] 검증되지 않은 candidate에서 probe success 같은 금지 전이는 failure로 반환한다.

## Architecture Requirements

- [x] 상태 머신은 `lib/application/transfer`에 둔다.
- [x] 상태 머신은 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] 상태 머신은 probe, bind, expire notification 같은 부작용을 직접 실행하지 않고 `TransitionEffect` 이름만 반환한다.
- [x] route candidate를 peer identity로 취급하지 않는다.

## TDD Requirements

- [x] probe happy path 전이 테스트를 먼저 작성한다.
- [x] probe failed/reject 전이 테스트를 작성한다.
- [x] verified route expiration 전이 테스트를 작성한다.
- [x] verified-only usability 테스트를 작성한다.
- [x] terminal no-op warning 테스트를 작성한다.
- [x] invalid transition failure 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_route_lease_state_machine_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferRouteLeaseStateMachine`이 추가되어 있다.
- [x] route 상태/이벤트/전이/효과/실패 코드가 테스트로 고정되어 있다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
