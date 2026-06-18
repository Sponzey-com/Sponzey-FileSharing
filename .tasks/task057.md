# Task 057. Bootstrap-Only Legacy UDP Fallback Config Test

## Goal

legacy UDP data fallback이 제품 기본 동작으로 켜지지 않고, bootstrap 시점 `AppConfig`에서 명시적으로만 활성화되는지 단위 테스트로 고정한다.

## Scope

- [x] `AppConfig.production()`의 `allowLegacyUdpDataFallback` 기본값이 false임을 검증한다.
- [x] 개발/test config에서 명시적으로 true를 주입할 수 있음을 검증한다.
- [x] 이 설정이 런타임 중간 변경 경로가 아니라 `AppConfig` 생성자 입력임을 문서화한다.

## Functional Requirements

- [x] production config는 TCP strict 기본값을 가진다.
- [x] legacy UDP fallback은 명시적 생성자 인자로만 true가 된다.

## Architecture Requirements

- [x] 설정은 외부 파일이나 환경 변수 재조회가 아니라 bootstrap config 값으로만 표현한다.
- [x] `TransferController`는 전역 mutable flag가 아니라 주입된 `AppConfig`를 읽는다.

## TDD Requirements

- [x] `AppConfig` 단위 테스트를 먼저 추가한다.
- [x] controller fallback 차단 회귀 테스트와 함께 통과시킨다.

## Validation

- [x] `flutter test test/core/network/udp_port_config_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "does not fallback to legacy UDP transfer when TCP channel is missing" --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP 기본 경로가 production config에서 legacy UDP fallback 없이 시작되는 것이 테스트로 고정된다.
