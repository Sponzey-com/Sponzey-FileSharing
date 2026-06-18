# Task 057. Outgoing Transfer Session State Machine

## Goal

`OutgoingTransferSessionRunner` 분리의 첫 단계로 송신 세션 상태 머신을 application 계층에 추가한다. 아직 controller의 송신 실행 로직을 옮기지 않고, Phase 5에서 정의한 송신 상태와 주요 전이를 테스트로 먼저 고정한다.

## Scope

- [x] 송신 세션 상태 enum을 추가한다.
- [x] 송신 세션 이벤트 enum을 추가한다.
- [x] core `StateMachine` 인터페이스를 구현한다.
- [x] terminal 상태에서 추가 이벤트를 warning no-op으로 처리한다.

## Functional Requirements

- [x] `created -> waitingForReceiverPrepare`
- [x] `waitingForReceiverPrepare -> bindingDataEndpoint`
- [x] receiver rejected 또는 failure event는 `failed`로 전이한다.
- [x] `bindingDataEndpoint -> sendingStartFrame`
- [x] `sendingStartFrame -> sendingChunks`
- [x] window saturation은 `sendingChunks -> waitingForChunkAcks`로 전이한다.
- [x] ack로 window가 열리면 `waitingForChunkAcks -> sendingChunks`로 전이한다.
- [x] 모든 chunk ACK 이후 `sendingChunks` 또는 `waitingForChunkAcks`에서 `sendingFinish`로 전이한다.
- [x] `sendingFinish -> waitingForFinishAck`
- [x] `waitingForFinishAck -> completed`
- [x] cancel 요청은 non-terminal 상태에서 `canceling`으로 전이한다.
- [x] cancel 완료는 `canceling -> canceled`로 전이한다.
- [x] terminal 상태(`completed`, `canceled`, `failed`)는 추가 이벤트에 대해 warning no-op을 반환한다.

## Architecture Requirements

- [x] 상태 머신은 `lib/application/transfer`에 둔다.
- [x] 상태 머신은 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] 상태 머신은 부작용을 직접 실행하지 않고 `TransitionEffect` 이름만 반환한다.

## TDD Requirements

- [x] happy path 전이 테스트를 먼저 작성한다.
- [x] receiver rejected/failure 전이 테스트를 작성한다.
- [x] cancel 전이 테스트를 작성한다.
- [x] terminal no-op warning 테스트를 작성한다.
- [x] invalid transition failure 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/outgoing_transfer_session_state_machine_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `OutgoingTransferSessionStateMachine`이 추가되어 있다.
- [x] 상태/이벤트/전이/효과/실패 코드가 테스트로 고정되어 있다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
