# Task 062. Transfer Route Lease Runner Boundary

## Goal

`TransferRouteLeaseStateMachine`을 실제 route 검증 실행 객체로 연결하기 위한 최소 runner 경계를 만든다. 이번 task에서는 네트워크 probe를 구현하지 않고, 상태 전이 결과의 `TransitionEffect`를 명시 executor로 전달하는 구조만 고정한다.

## Scope

- [x] `TransferRouteLeaseRunner`를 application 계층에 추가한다.
- [x] route lease runner용 effect executor 인터페이스를 추가한다.
- [x] runner가 현재 상태를 소유하고 state machine transition 결과로만 상태를 변경한다.
- [x] invalid/warning transition에서는 executor를 호출하지 않는다.

## Functional Requirements

- [x] `requestProbe()`는 `candidate -> probing`으로 전이하고 `probeRoute` effect를 실행한다.
- [x] `markProbeSucceeded()`는 `probing -> verified`로 전이하고 `bindRouteLease` effect를 실행한다.
- [x] `markProbeFailed()`는 `rejected`로 전이하고 `rejectRouteLease` effect를 실행한다.
- [x] `markExpired()`는 `verified -> expired`로 전이하고 `notifyRouteExpired` effect를 실행한다.
- [x] `isUsableForTransfer`는 현재 상태가 `verified`일 때만 true를 반환한다.
- [x] terminal 상태에서 추가 event는 warning no-op으로 반환하고 executor를 호출하지 않는다.

## Architecture Requirements

- [x] runner는 `lib/application/transfer`에 둔다.
- [x] runner는 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] runner는 외부 부작용을 직접 실행하지 않고 executor 인터페이스로만 위임한다.
- [x] executor는 생성자 인자로 명시 주입한다.

## TDD Requirements

- [x] probe request effect delegation 테스트를 먼저 작성한다.
- [x] probe success effect delegation 테스트를 작성한다.
- [x] probe failure effect delegation 테스트를 작성한다.
- [x] expire effect delegation 테스트를 작성한다.
- [x] terminal no-op에서 effect가 실행되지 않는 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_route_lease_runner_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferRouteLeaseRunner`가 추가되어 있다.
- [x] runner가 상태 변경과 effect 실행 경계를 분리한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
