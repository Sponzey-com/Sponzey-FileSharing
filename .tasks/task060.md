# Task 060. Hide UDP Route Lease Failures From TCP Transfer UI

## Goal

TCP 기본 전송 경로에서 내부 UDP route lease 만료/변경 문구가 사용자 화면의 실패 원인으로 노출되지 않도록 실패 분류와 표시 정책을 분리한다.

## Scope

- [x] `TransferFailurePolicy`가 TCP transfer job의 route 계열 내부 오류를 TCP data channel 실패로 분류한다.
- [x] transfer queue UI는 terminal failure에서 raw internal message보다 사용자용 failure policy message를 우선 표시한다.
- [x] TCP transfer UI에 `연결 경로가 만료`, `연결 경로가 변경`, `route=` 같은 UDP route lease 원문이 노출되지 않도록 테스트한다.

## Functional Requirements

- [x] TCP job의 route lease 내부 오류는 `transfer.failure.tcp_data_channel` diagnostic code를 가진다.
- [x] TCP job의 route lease 내부 오류는 retry 가능 network failure로 분류한다.
- [x] UDP/legacy job의 route failure 분류는 기존 route category를 유지한다.

## Architecture Requirements

- [x] 실패 분류 규칙은 domain policy에 둔다.
- [x] presentation은 domain policy의 `userMessage`를 표시하고 route parsing 규칙을 중복 구현하지 않는다.
- [x] raw internal message는 diagnostics/export의 redacted debug 정보로 남길 수 있지만 product UI의 1차 문구로 사용하지 않는다.

## TDD Requirements

- [x] domain policy 실패 테스트를 먼저 추가하고 실패를 확인한다.
- [x] transfer screen widget 실패 테스트를 먼저 추가하고 실패를 확인한다.
- [x] 최소 구현 후 관련 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/domain/transfer/transfer_failure_policy_test.dart --reporter compact`
- [x] `flutter test test/presentation/transfers/transfers_screen_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP transfer 실패 화면에서 UDP route lease 원문이 보이지 않는다.
- [x] TCP transfer 실패는 TCP data channel 기준 사용자 메시지와 diagnostic code로 분류된다.
- [x] legacy UDP route failure 분류는 기존 동작을 유지한다.
