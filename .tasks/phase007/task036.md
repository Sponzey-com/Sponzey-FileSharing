# task036 - Active Transfer Route Validation 분리

## Goal

`TransferController._requireActiveTransferRoute`에 남아 있는 active route endpoint 검증과 loopback 차단 규칙을 application command로 분리한다. 연결 경로 선택은 controller가 유지하되, 경로가 파일 전송에 사용 가능한지 판단하는 규칙은 독립 테스트로 고정한다.

## Scope

- [x] `TransferActiveRouteValidationCommand`를 추가한다.
- [x] local address, remote address, remote port 필수 검증을 테스트로 고정한다.
- [x] 외부 peer에 loopback route를 사용할 수 없는 규칙을 테스트로 고정한다.
- [x] `TransferController._requireActiveTransferRoute`가 command decision을 AppException으로 매핑하도록 변경한다.

## Out of Scope

- [x] peer route registry의 선택 정책은 변경하지 않는다.
- [x] route recovery 로직은 변경하지 않는다.
- [x] 실제 연결 또는 파일 전송 프로토콜은 변경하지 않는다.

## TDD Requirements

- [x] 정상 endpoint와 외부 peer address 조합은 valid decision을 반환한다.
- [x] 빈 local address, 빈 remote address, 0 이하 remote port는 invalid decision을 반환한다.
- [x] route remote address가 loopback이고 session peer address가 외부 주소이면 loopback mismatch로 invalid decision을 반환한다.
- [x] route remote address와 session peer address가 모두 loopback이면 valid decision을 반환한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_active_route_validation_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] active route endpoint/loopback 검증 규칙이 controller가 아닌 command에 존재한다.
- [x] 기존 `transfer_active_route_invalid`, `transfer_loopback_route_mismatch` 예외 코드와 메시지 의미가 유지된다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferActiveRouteValidationCommand`와 단위 테스트를 추가했다.
- [x] `TransferController._requireActiveTransferRoute`는 active path 조회와 command decision 매핑만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task037에서 data frame route context 존재 판단을 command로 분리한다.
