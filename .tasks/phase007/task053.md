# Task 053. Transfer Identity Selection Command

## Goal

`TransferController`의 사용자/디바이스 식별 값 선택과 필수 값 검증 규칙을 application 계층 명령 객체로 분리한다. 컨트롤러는 provider와 local identity에서 값을 읽고, null/blank 처리와 fallback 결정은 순수 명령 객체가 담당한다.

## Scope

- [x] current user id 필수 검증을 명령 객체로 분리한다.
- [x] display name fallback 규칙을 명령 객체로 분리한다.
- [x] device id와 instance id 필수 검증을 명령 객체로 분리한다.

## Functional Requirements

- [x] user id가 null이면 `transfer_no_session` 예외를 던진다.
- [x] user id가 blank이면 `transfer_no_session` 예외를 던진다.
- [x] display name이 null 또는 blank이면 user id를 반환한다.
- [x] display name이 있으면 trim하지 않은 원본 display name을 반환한다.
- [x] device id가 null 또는 blank이면 `transfer_local_device_missing` 예외를 던진다.
- [x] instance id가 null 또는 blank이면 `transfer_local_instance_missing` 예외를 던진다.

## Architecture Requirements

- [x] 명령 객체는 `lib/application/transfer`에 둔다.
- [x] 명령 객체는 Flutter, Riverpod, auth entity, local identity entity, 파일 시스템, 네트워크에 의존하지 않는다.
- [x] 컨트롤러는 provider/local identity 접근만 담당한다.

## TDD Requirements

- [x] user id, display name, device id, instance id 규칙 테스트를 먼저 작성한다.
- [x] 컨트롤러가 identity 선택을 명령 객체에 위임하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_identity_selection_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferIdentitySelectionCommand`가 추가되어 있다.
- [x] `_currentUserId`, `_currentDisplayName`, `_currentDeviceId`, `_currentInstanceId`가 명령 객체에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
