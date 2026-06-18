# Task 051. Transfer Job Event Factory

## Goal

`TransferController._upsertJob` 내부의 `TransferSessionAppEvent` 생성 규칙을 application 계층 factory로 분리한다. 컨트롤러는 MessageBus publish만 수행하고, job 상태에 따른 event type, severity, reasonCode 정책은 테스트 가능한 factory가 담당한다.

## Scope

- [x] `TransferJob`에서 `TransferSessionAppEvent`를 생성하는 factory를 추가한다.
- [x] event id와 occurredAt은 factory 내부에서 생성하지 않고 호출자가 명시적으로 전달한다.
- [x] MessageBus publish 생명주기는 컨트롤러에 유지한다.

## Functional Requirements

- [x] eventType은 `transfer${job.status.name}` 형식이다.
- [x] correlationId와 transferId는 `job.transferId`를 사용한다.
- [x] jobId와 peerId는 job 값을 그대로 사용한다.
- [x] failed/rejected job은 `AppEventSeverity.product`를 사용한다.
- [x] failed/rejected job은 `job.message`를 reasonCode로 사용한다.
- [x] 그 외 상태는 `AppEventSeverity.debug`를 사용한다.
- [x] 그 외 상태는 reasonCode를 포함하지 않는다.

## Architecture Requirements

- [x] factory는 `lib/application/transfer`에 둔다.
- [x] factory는 Flutter, Riverpod, MessageBus 구현체, 파일 시스템, 네트워크에 의존하지 않는다.
- [x] factory는 외부 환경 값, 시간, random id를 조회하지 않는다.

## TDD Requirements

- [x] product severity terminal failure 이벤트 테스트를 먼저 작성한다.
- [x] debug severity non-terminal 이벤트 테스트를 작성한다.
- [x] 컨트롤러가 직접 `TransferSessionAppEvent(...)`를 생성하지 않고 factory를 사용하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_job_event_factory_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferJobEventFactory`가 추가되어 있다.
- [x] `_upsertJob`이 이벤트 값 생성을 factory에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
