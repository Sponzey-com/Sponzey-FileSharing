# task045 - TCP Outbound Channel Open Command

## Goal

수신한 TCP data channel offer를 기반으로 outbound TCP socket을 열고, data session hello를 송신한 뒤 outbound data channel registry에 connected session을 등록한다. 이 태스크는 control packet 수신 라우팅과는 분리하고, 순수 application command와 connector port 계약을 먼저 완성한다.

## Scope

- [x] `TcpDataConnectorPort`에 `sendHello` 계약을 추가한다.
- [x] TCP connect 요청과 hello 송신을 하나의 command로 묶는다.
- [x] connect와 hello 송신이 성공한 경우 outbound registry에 connected session을 등록한다.
- [x] 이미 connected outbound session이 있으면 reconnect하지 않고 no-op으로 반환한다.

## TDD Checklist

- [x] command가 connector.connect와 connector.sendHello를 호출하고 outbound registry에 세션을 등록하는 테스트를 작성한다.
- [x] 이미 connected session이 있으면 connector를 호출하지 않는 테스트를 작성한다.
- [x] connector 실패 시 registry에 세션을 등록하지 않는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpDataConnectorPort` interface에 `sendHello`를 추가하고 raw connector 구현을 `@override`로 맞춘다.
- [x] `TcpDataOutboundChannelOpenCommand`와 result value object를 추가한다.
- [x] provider 조립부에 outbound open command provider를 추가한다.
- [x] 기존 connector test doubles에 `sendHello` 구현을 추가한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_data_outbound_channel_open_command_test.dart --reporter compact`
- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart test/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task045.md lib/application/transfer/tcp_data_channel_ports.dart lib/application/transfer/tcp_data_outbound_channel_open_command.dart lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/application/transfer/tcp_data_outbound_channel_open_command_test.dart test/infrastructure/transfer`

## Completion Report

- Status: completed
- Notes:
  - Outbound TCP connect, hello send, and connected registry registration are now one application command behind the connector port.
  - Existing connected outbound sessions are locked and do not reconnect.
