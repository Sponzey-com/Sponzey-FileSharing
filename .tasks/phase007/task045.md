# task045 - Transfer Event Id Formatter 분리

## Goal

전송 상태 변경 이벤트에 사용하는 event id 생성 규칙을 `TransferController`에서 분리한다. 시간 값은 formatter 내부에서 조회하지 않고 명시 인자로 받아 테스트 가능성과 설정/환경 명시 전달 원칙을 유지한다.

## Scope

- [x] `TransferEventIdFormatter`를 추가한다.
- [x] prefix와 `DateTime.microsecondsSinceEpoch`를 결합하는 규칙을 테스트한다.
- [x] `TransferController._eventId`가 formatter 호출만 수행하도록 변경한다.

## Out of Scope

- [x] event publish 위치와 MessageBus 구조는 변경하지 않는다.
- [x] event id prefix 정책은 변경하지 않는다.
- [x] clock provider 구성은 변경하지 않는다.

## TDD Requirements

- [x] `prefix-microseconds` 형식을 반환한다.
- [x] formatter는 직접 현재 시간을 조회하지 않는다.

## Validation

- [x] `flutter test test/application/transfer/transfer_event_id_formatter_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] event id formatting이 controller가 아닌 formatter에 존재한다.
- [x] controller는 `_now()` 결과를 formatter에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferEventIdFormatter`와 단위 테스트를 추가했다.
- [x] `_eventId`는 `_now()` 결과를 formatter에 전달하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task046에서 남은 transfer controller 책임을 audit하고 다음 구조 분리 단위를 확정한다.
