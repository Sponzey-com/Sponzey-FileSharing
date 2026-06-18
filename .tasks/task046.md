# task046 - DATA_CHANNEL_OFFER Control Handler

## Goal

`DATA_CHANNEL_OFFER` control packet을 기존 UDP transfer packet 흐름과 분리된 TCP data channel negotiation route로 처리한다. 인증된 peer/session의 offer만 outbound TCP open command로 전달하고, 이미 connected session이 있으면 command의 no-op 결과를 그대로 유지한다.

## Scope

- [x] `TransferControlPacketDispatcher`가 `DATA_CHANNEL_OFFER`를 별도 route로 반환한다.
- [x] `TransferController`가 `DATA_CHANNEL_OFFER`를 수신하면 authenticated peer session을 확인한다.
- [x] offer packet의 data session id, host, port가 유효할 때 outbound open command를 호출한다.
- [x] invalid offer 또는 미인증 peer offer는 TCP connector로 전달하지 않는다.

## TDD Checklist

- [x] dispatcher가 `DATA_CHANNEL_OFFER`를 `dataChannelOffer` route로 분류하는 테스트를 갱신한다.
- [x] transfer controller가 인증된 offer를 outbound open command로 전달하는 테스트를 작성한다.
- [x] transfer controller가 미인증 또는 invalid endpoint offer를 무시하는 테스트를 작성한다.

## Implementation Checklist

- [x] `TransferControlPacketRoute.dataChannelOffer`를 추가한다.
- [x] `TransferController._handlePacket`에 offer route handler를 추가한다.
- [x] `TransferController` 테스트 하네스에 `TcpDataOutboundChannelOpenCommand` override를 추가한다.
- [x] offer handler에서 local instance id와 auth session id를 사용해 `TcpDataSessionHello`를 생성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_control_packet_dispatcher_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task046.md lib/application/transfer/transfer_control_packet_dispatcher.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_control_packet_dispatcher_test.dart test/application/transfer/transfer_controller_test.dart`

## Completion Report

- Status: completed
- Notes:
  - `DATA_CHANNEL_OFFER` is now a first-class transfer control route.
  - Authenticated offers open outbound TCP data channels through `TcpDataOutboundChannelOpenCommand`; invalid offers do not reach the connector.
