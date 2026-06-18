# Task 055. TCP Incoming Failure Result Updates Existing Job

## Goal

TCP incoming pipeline이 `transferId`를 포함한 실패 result를 반환하면 `TransferController`가 전역 오류로 흘리지 않고 기존 수신 job 하나만 정확히 failed 상태로 갱신하는지 application test로 고정한다.

## Scope

- [x] TCP incoming listener test fake가 result stream에 result를 주입할 수 있게 한다.
- [x] metadata result로 생성된 TCP incoming job에 chunk 실패 result를 적용하는 컨트롤러 테스트를 추가한다.
- [x] 실패 메시지가 해당 `issueCode`를 포함하고 TCP capability가 유지되는지 검증한다.

## Functional Requirements

- [x] metadata result 수신 후 incoming job이 생성된다.
- [x] 동일 transferId의 failed chunk result 수신 후 해당 job만 failed가 된다.
- [x] 컨트롤러 전체 `errorMessage`가 아닌 transfer job message에 실패 원인이 반영된다.

## Architecture Requirements

- [x] 테스트는 socket 구현체가 아니라 `TcpIncomingListenerSubscriptionPort` 경계를 사용한다.
- [x] 실패 처리는 presentation이 아니라 application controller projection에서 검증한다.
- [x] TCP transfer capability는 실패 상태에서도 유지된다.

## TDD Requirements

- [x] 실패 result projection 컨트롤러 테스트를 먼저 작성한다.
- [x] 필요한 test fake helper만 최소로 추가한다.
- [x] 기존 TCP incoming pipeline 테스트와 transfer controller 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "marks existing TCP incoming job failed from preserved failure result" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP incoming effect 실패가 기존 job을 잃지 않고 job 단위 failed 상태로 표시된다.
- [x] 실패 result가 listener-level 익명 오류로 손실되지 않는 회귀 테스트가 존재한다.
