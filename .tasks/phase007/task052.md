# Task 052. Transfer Job Update Lookup Command

## Goal

`TransferController._updateJob`의 job lookup/update 결정 규칙을 application 계층 순수 명령 객체로 분리한다. 컨트롤러는 state 목록과 updater를 전달하고, 결과가 있을 때만 `_upsertJob`을 호출한다.

## Scope

- [x] transfer id와 일치하는 job 검색 규칙을 분리한다.
- [x] job이 존재할 때 updater를 한 번 적용해 next job을 반환한다.
- [x] job이 없으면 null을 반환해 컨트롤러가 no-op 처리한다.

## Functional Requirements

- [x] 일치하는 job이 있으면 updater 결과를 반환한다.
- [x] 일치하는 job이 없으면 null을 반환한다.
- [x] 첫 번째 일치 job만 updater에 전달한다.
- [x] 입력 목록 자체는 수정하지 않는다.

## Architecture Requirements

- [x] 명령 객체는 `lib/application/transfer`에 둔다.
- [x] 명령 객체는 Flutter, Riverpod, MessageBus, 파일 시스템, 네트워크에 의존하지 않는다.
- [x] 명령 객체는 상태 저장이나 `_upsertJob` 호출을 수행하지 않는다.

## TDD Requirements

- [x] found/no-op/updater 호출 횟수 테스트를 먼저 작성한다.
- [x] 컨트롤러가 lookup 루프를 직접 갖지 않고 명령 객체를 사용하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_job_update_lookup_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferJobUpdateLookupCommand`가 추가되어 있다.
- [x] `_updateJob`이 명령 객체 결과를 받아 `_upsertJob`만 호출한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
