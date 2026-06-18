# task048 - TCP Hello Peer Identity Direction Fix

## Goal

TCP data channel 연결에서 registry key와 hello identity의 의미를 분리한다. Outbound registry는 전송 대상 remote peer 기준으로 유지하지만, TCP listener가 받는 `TcpDataSessionHello.peerId`는 실제 연결을 걸어온 local peer id를 나타내야 한다.

## Scope

- [x] `TcpDataOutboundChannelOpenCommand`가 `connectRequest.peerId`와 `hello.peerId`가 다를 수 있음을 허용한다.
- [x] `TransferController._onDataChannelOffer`가 TCP hello의 `peerId`에 local peer id를 넣는다.
- [x] outbound registry는 계속 remote peer id 기준으로 등록한다.
- [x] inbound hello expectation resolver가 remote에서 들어온 local peer id를 기존 auth session으로 검증할 수 있게 한다.

## TDD Checklist

- [x] outbound open command가 remote peer와 local hello peer id를 분리해도 연결을 등록하는 테스트를 작성한다.
- [x] outbound open command가 `sessionId` 또는 `authSessionId` mismatch는 계속 거부하는 테스트를 유지한다.
- [x] `TransferController`가 `DATA_CHANNEL_OFFER` 처리 시 local peer id로 hello를 생성하는 테스트를 작성한다.
- [x] listener expectation resolver가 들어온 hello peer id를 authenticated session key로 검증하는 기존 테스트와 충돌하지 않는지 확인한다.

## Implementation Checklist

- [x] `TcpDataOutboundChannelOpenCommand`의 잘못된 `hello.peerId == connectRequest.peerId` 검증을 제거한다.
- [x] 대신 `hello.sessionId == connectRequest.sessionId`와 `hello.authSessionId == connectRequest.authSessionId`는 유지한다.
- [x] `TransferController._onDataChannelOffer`에서 `PeerIdentity.resolve(...)`로 local peer id를 계산해 hello에 넣는다.
- [x] 기존 control offer handling과 TCP registry 등록 방향을 변경하지 않는다.

## Validation

- [x] `flutter test test/application/transfer/tcp_data_outbound_channel_open_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "opens outbound TCP data channel from authenticated offer packet" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task048.md lib/application/transfer/tcp_data_outbound_channel_open_command.dart lib/application/transfer/transfer_controller.dart test/application/transfer/tcp_data_outbound_channel_open_command_test.dart test/application/transfer/transfer_controller_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Outbound registry key는 remote peer 기준으로 유지하고, TCP hello peer id는 연결을 건 local peer 기준으로 분리했다.
  - TCP hello mismatch 검증은 session id와 auth session id에만 적용한다.
  - `DATA_CHANNEL_OFFER` 수신 시 생성되는 hello가 local peer id를 싣도록 수정했다.
