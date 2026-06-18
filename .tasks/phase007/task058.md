# Task 058. Incoming Transfer Session State Machine

## Goal

`IncomingTransferSessionRunner` 분리의 첫 단계로 수신 세션 상태 머신을 application 계층에 추가한다. 아직 controller의 수신 실행 로직을 옮기지 않고, storage prepare부터 finalize까지의 수신 절차를 순수 전이 규칙으로 고정한다.

## Scope

- [x] 수신 세션 상태 enum을 추가한다.
- [x] 수신 세션 이벤트 enum을 추가한다.
- [x] core `StateMachine` 인터페이스를 구현한다.
- [x] terminal 상태에서 추가 이벤트를 warning no-op으로 처리한다.

## Functional Requirements

- [x] `offered -> preparingStorage`
- [x] `preparingStorage -> readyForData`
- [x] storage prepare 실패는 `failed`로 전이한다.
- [x] `readyForData -> receiving`
- [x] 정상 chunk 수신은 `receiving` 상태를 유지하고 ACK batch effect를 반환한다.
- [x] out-of-order chunk 수신은 `bufferingOutOfOrder`로 전이한다.
- [x] buffered chunk가 해소되면 `bufferingOutOfOrder -> receiving`으로 전이한다.
- [x] `receiving` 또는 `bufferingOutOfOrder`에서 finish 수신 시 `verifying`으로 전이한다.
- [x] digest 검증 성공 시 `verifying -> finalizing`
- [x] digest mismatch 또는 write failure는 `failed`로 전이한다.
- [x] finalize 성공 시 `finalizing -> completed`
- [x] data abort 또는 cancel 요청은 non-terminal 상태에서 `canceling`으로 전이한다.
- [x] cleanup 완료는 `canceling -> canceled`로 전이한다.
- [x] terminal 상태(`completed`, `canceled`, `failed`)는 추가 이벤트에 대해 warning no-op을 반환한다.
- [x] ready 이전 DATA_CHUNK 같은 금지 전이는 failure로 반환한다.

## Architecture Requirements

- [x] 상태 머신은 `lib/application/transfer`에 둔다.
- [x] 상태 머신은 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] 상태 머신은 storage, ACK/NACK, file write 같은 부작용을 직접 실행하지 않고 `TransitionEffect` 이름만 반환한다.

## TDD Requirements

- [x] happy path 전이 테스트를 먼저 작성한다.
- [x] storage prepare failure/write failure/digest mismatch 전이 테스트를 작성한다.
- [x] out-of-order buffering 전이 테스트를 작성한다.
- [x] cancel/abort 전이 테스트를 작성한다.
- [x] terminal no-op warning 테스트를 작성한다.
- [x] invalid transition failure 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/incoming_transfer_session_state_machine_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `IncomingTransferSessionStateMachine`이 추가되어 있다.
- [x] 상태/이벤트/전이/효과/실패 코드가 테스트로 고정되어 있다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
