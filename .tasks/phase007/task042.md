# task042 - Transfer Log Safe Formatter 분리

## Goal

전송 로그에 사용하는 session id, transfer id, file name 축약 규칙을 `TransferController`에서 분리한다. Product/Debug 로그에 민감할 수 있는 전체 식별자와 전체 경로가 남지 않도록 formatter 테스트로 고정한다.

## Scope

- [x] `TransferLogSafeFormatter`를 추가한다.
- [x] session id와 transfer id는 최대 8자까지만 노출하는 규칙을 테스트한다.
- [x] null/empty transfer id는 `-`로 표시하는 규칙을 테스트한다.
- [x] file name은 경로를 제거하고 basename만 남기는 규칙을 테스트한다.
- [x] file name은 80자를 초과하면 77자와 `...`로 축약하는 규칙을 테스트한다.
- [x] `TransferController`의 safe log helper가 formatter 호출만 수행하도록 변경한다.

## Out of Scope

- [x] endpoint label formatting은 변경하지 않는다.
- [x] event id 생성 방식은 변경하지 않는다.
- [x] 로그 호출 위치와 로그 레벨은 변경하지 않는다.

## TDD Requirements

- [x] 짧은 session/transfer id는 그대로 반환한다.
- [x] 긴 session/transfer id는 앞 8자만 반환한다.
- [x] 빈 transfer id는 `-`를 반환한다.
- [x] POSIX/Windows 경로 file name은 basename만 반환한다.
- [x] 긴 basename은 80자 길이로 축약한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_log_safe_formatter_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] log-safe formatting 규칙이 controller가 아닌 formatter에 존재한다.
- [x] controller는 formatter 호출 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferLogSafeFormatter`와 단위 테스트를 추가했다.
- [x] `_safeSession`, `_safeTransfer`, `_safeFileNameForLog`는 formatter 호출만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task043에서 UDP endpoint label formatter를 분리한다.
