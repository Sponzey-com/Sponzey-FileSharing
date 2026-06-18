# Task 047. Transfer Job List Upsert Command

## Goal

`TransferController._upsertJob` 내부의 전송 작업 목록 갱신 규칙을 application 계층의 순수 명령 객체로 분리한다. 컨트롤러는 상태 저장, MessageBus 이벤트 발행, terminal history 저장만 담당하고, 목록에서 같은 job을 교체하고 최신순으로 정렬하는 규칙은 테스트 가능한 객체가 담당한다.

## Scope

- [x] `TransferJob` 목록 upsert 규칙을 순수 명령 객체로 분리한다.
- [x] 같은 `id`의 기존 job은 제거하고 새 job 하나만 남긴다.
- [x] 결과 목록은 `updatedAt` 내림차순으로 정렬한다.

## Functional Requirements

- [x] 빈 목록에 새 job을 넣으면 한 개의 job 목록을 반환한다.
- [x] 같은 `id`가 있는 기존 job은 새 job으로 교체된다.
- [x] 다른 `id`의 기존 job은 보존된다.
- [x] 반환 목록은 가장 최근에 업데이트된 job이 먼저 온다.
- [x] 입력 목록 객체를 직접 수정하지 않는다.

## Architecture Requirements

- [x] 명령 객체는 `lib/application/transfer`에 둔다.
- [x] 명령 객체는 Flutter, Riverpod, MessageBus, 파일 시스템, 네트워크에 의존하지 않는다.
- [x] 명령 객체는 `TransferJob` 값만 입력으로 받고 결과 목록을 반환한다.
- [x] `_upsertJob`은 명령 결과를 `state.copyWith(jobs: ...)`에 전달한다.

## TDD Requirements

- [x] 추가, 교체, 정렬, 입력 불변성 테스트를 먼저 작성한다.
- [x] 컨트롤러가 직접 list comprehension과 sort 규칙을 들고 있지 않고 명령 객체를 사용하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_job_list_upsert_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferJobListUpsertCommand`가 추가되어 있다.
- [x] `_upsertJob`의 목록 갱신 규칙이 명령 객체에 위임되어 있다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
