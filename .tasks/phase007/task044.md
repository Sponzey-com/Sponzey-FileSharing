# task044 - Incoming Transfer Route Match 분리

## Goal

수신 `TRANSFER_INIT` datagram이 기존 peer route candidate와 같은 경로인지 판단하는 규칙을 `TransferController`에서 분리한다. 다중 NIC, bridge, wildcard bind 환경에서 잘못된 route candidate가 선택되지 않도록 순수 command 테스트로 고정한다.

## Scope

- [x] `TransferIncomingRouteMatchCommand`를 추가한다.
- [x] remote address/port mismatch 거절 규칙을 테스트한다.
- [x] local endpoint가 없거나 wildcard bind이면 remote match만으로 허용하는 규칙을 테스트한다.
- [x] local endpoint가 있으면 candidate local address 일치 또는 candidate bind any일 때만 허용하는 규칙을 테스트한다.
- [x] `TransferController._matchesIncomingTransferRoute`가 command 호출만 수행하도록 변경한다.

## Out of Scope

- [x] peer route candidate store 구조는 변경하지 않는다.
- [x] observed candidate upsert 정책은 변경하지 않는다.
- [x] peer path selection policy는 변경하지 않는다.

## TDD Requirements

- [x] remote address가 다르면 false를 반환한다.
- [x] remote port가 다르면 false를 반환한다.
- [x] local endpoint가 없거나 wildcard이면 true를 반환한다.
- [x] local endpoint가 있으면 local address 일치 또는 candidate bind any만 true를 반환한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_incoming_route_match_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] incoming transfer route match 규칙이 controller가 아닌 command에 존재한다.
- [x] controller는 candidate/datagram field를 command에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferIncomingRouteMatchCommand`와 단위 테스트를 추가했다.
- [x] `_matchesIncomingTransferRoute`는 candidate/datagram field를 command에 전달하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task045에서 transfer event id formatting을 분리한다.
