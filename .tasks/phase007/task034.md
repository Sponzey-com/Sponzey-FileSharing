# task034 - Remote Data Endpoint Route Validation 분리

## Goal

`TransferController` 내부의 remote data endpoint 검증 규칙을 application command로 분리해, 송신 시작 시 control route와 data route가 섞이지 않는지 독립적으로 테스트한다.

## Scope

- [x] `TransferOutgoingRemoteDataEndpointRouteCommand`를 추가한다.
- [x] control remote address와 data remote address의 정규화 비교 규칙을 command 테스트로 고정한다.
- [x] `TransferController._validateRemoteDataEndpoint`가 직접 문자열 비교를 하지 않고 command decision을 사용하도록 변경한다.

## Out of Scope

- [x] data bind endpoint 검증 분리는 task035에서 별도로 처리한다.
- [x] 실제 UDP 송수신 프로토콜 변경은 하지 않는다.
- [x] UI 문구나 peer 표시 정책은 변경하지 않는다.

## TDD Requirements

- [x] 같은 address는 valid decision을 반환한다.
- [x] 앞뒤 공백과 대소문자가 달라도 같은 address로 판단한다.
- [x] 다른 address는 invalid decision과 mismatch message detail을 반환한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_outgoing_remote_data_endpoint_route_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] remote data endpoint 검증 규칙이 controller가 아닌 command에 존재한다.
- [x] 기존 `transfer_route_mismatch` 예외 코드와 사용자 메시지 의미가 유지된다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferOutgoingRemoteDataEndpointRouteCommand`와 단위 테스트를 추가했다.
- [x] `TransferController._validateRemoteDataEndpoint`는 command decision을 AppException으로 매핑하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task035에서 data socket bind endpoint 검증을 command로 분리한다.
