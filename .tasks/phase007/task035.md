# task035 - Data Bind Endpoint Route Validation 분리

## Goal

`TransferController` 내부의 data socket bind endpoint 검증 규칙을 application command로 분리해, 송신과 수신 모두에서 route local address와 다른 socket bind가 섞이지 않도록 테스트 가능한 경계로 만든다.

## Scope

- [x] `TransferDataBindEndpointRouteCommand`를 추가한다.
- [x] wildcard bind mode와 wildcard address 허용 규칙을 테스트로 고정한다.
- [x] route local address와 bind local address mismatch 거절 규칙을 테스트로 고정한다.
- [x] `TransferController._validateDataBindEndpoint`가 command decision만 사용하도록 변경한다.

## Out of Scope

- [x] UDP socket bind 구현 자체는 변경하지 않는다.
- [x] route lease 선택 정책은 변경하지 않는다.
- [x] UI 오류 표시 문구 구조는 변경하지 않는다.

## TDD Requirements

- [x] wildcard bind mode는 valid decision을 반환한다.
- [x] `0.0.0.0`, `::`, `0:0:0:0:0:0:0:0` wildcard address는 valid decision을 반환한다.
- [x] route local address와 같은 bind local address는 valid decision을 반환한다.
- [x] route local address와 다른 bind local address는 invalid decision과 mismatch message detail을 반환한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_data_bind_endpoint_route_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] data bind endpoint 검증 규칙이 controller가 아닌 command에 존재한다.
- [x] 기존 `transfer_data_bind_mismatch` 예외 코드와 사용자 메시지 의미가 유지된다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferDataBindEndpointRouteCommand`와 단위 테스트를 추가했다.
- [x] `TransferController._validateDataBindEndpoint`는 command decision을 AppException으로 매핑하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task036에서 transfer controller의 다음 독립 절차를 찾아 command로 분리한다.
