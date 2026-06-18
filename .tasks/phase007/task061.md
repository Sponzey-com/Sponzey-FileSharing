# Task 061. Incoming Transfer Session Runner Boundary

## Goal

`IncomingTransferSessionStateMachine`을 실제 수신 실행 객체로 연결하기 위한 최소 runner 경계를 만든다. 이번 task에서는 storage, file writer, ACK/NACK 전송을 옮기지 않고, 상태 전이 결과의 `TransitionEffect`를 명시 executor로 전달하는 구조만 고정한다.

## Scope

- [x] `IncomingTransferSessionRunner`를 application 계층에 추가한다.
- [x] 수신 runner용 effect executor 인터페이스를 추가한다.
- [x] runner가 현재 상태를 소유하고 state machine transition 결과로만 상태를 변경한다.
- [x] invalid/warning transition에서는 executor를 호출하지 않는다.

## Functional Requirements

- [x] `receiveInit()`은 `offered -> preparingStorage`로 전이하고 `prepareStorage` effect를 실행한다.
- [x] `markStoragePrepared()`는 `preparingStorage -> readyForData`로 전이하고 `sendTransferInitAck` effect를 실행한다.
- [x] `receiveDataStart()`는 `readyForData -> receiving`으로 전이하고 `openIncomingWriter` effect를 실행한다.
- [x] `markStoragePrepareFailed()`는 `failed`로 전이하고 `rejectTransferInit`, `failTransfer` effect를 실행한다.
- [x] terminal 상태에서 추가 event는 warning no-op으로 반환하고 executor를 호출하지 않는다.

## Architecture Requirements

- [x] runner는 `lib/application/transfer`에 둔다.
- [x] runner는 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] runner는 외부 부작용을 직접 실행하지 않고 executor 인터페이스로만 위임한다.
- [x] executor는 생성자 인자로 명시 주입한다.

## TDD Requirements

- [x] receive init effect delegation 테스트를 먼저 작성한다.
- [x] storage prepared effect delegation 테스트를 작성한다.
- [x] data start effect delegation 테스트를 작성한다.
- [x] storage prepare failure delegation 테스트를 작성한다.
- [x] terminal no-op에서 effect가 실행되지 않는 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/incoming_transfer_session_runner_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `IncomingTransferSessionRunner`가 추가되어 있다.
- [x] runner가 상태 변경과 effect 실행 경계를 분리한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
