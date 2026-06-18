# Task 058. Document Legacy UDP Fallback Bootstrap Boundary

## Goal

TCP 기본 전송 경로와 legacy UDP data fallback의 경계를 계획 문서에 구체적인 구현 이름으로 고정한다.

## Scope

- [x] `.tasks/plan.md`에 `AppConfig.allowLegacyUdpDataFallback` 이름을 명시한다.
- [x] production 기본값이 false이고 bootstrap/test override에서만 true가 될 수 있음을 명시한다.
- [x] runtime 중간 변경 금지를 configuration policy에 반영한다.

## Functional Requirements

- [x] 기본 제품 경로는 TCP strict이다.
- [x] legacy UDP fallback은 기본 제품 경로가 아니라 호환성/테스트 목적의 명시적 bootstrap option이다.

## Architecture Requirements

- [x] fallback mode는 전역 mutable flag나 외부 설정 파일 재조회로 결정하지 않는다.
- [x] fallback mode는 `AppConfig` 생성자 또는 provider override로만 전달한다.

## TDD Requirements

- [x] `task057`에서 production false와 explicit true 단위 테스트를 이미 추가했다.

## Validation

- [x] `rg -n "allowLegacyUdpDataFallback|legacy fallback|runtime 중간에 TCP/UDP" .tasks/plan.md lib/app/app_config.dart test/core/network/udp_port_config_test.dart`
- [x] `flutter test test/core/network/udp_port_config_test.dart --reporter compact`
- [x] 전체 `flutter test` 통과 확인.

## Done Criteria

- [x] 개발 계획, config 구현, 단위 테스트가 모두 같은 fallback 정책을 설명한다.
