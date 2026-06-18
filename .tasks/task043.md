# task043 - TCP Hello Session Identity Boundary

## Goal

TCP data channel의 control offer/connect와 실제 TCP socket hello가 같은 data session을 가리키도록 `TcpDataSessionHello`에 data session id를 포함한다. 이 태스크는 wire identity 정합성만 고정하며, control offer 수신 후 connector 실행과 listener subscription 통합은 후속 task에서 진행한다.

## Scope

- [x] `TcpDataSessionHello`에 `TcpDataSessionId sessionId`를 추가한다.
- [x] TCP hello codec encode/decode가 session id를 보존하도록 수정한다.
- [x] inbound handshake coordinator가 별도 인자로 session id를 받지 않고 hello의 session id를 사용하도록 수정한다.
- [x] 기존 hello validation, promotion, listener tests가 session id를 명시하도록 갱신한다.

## TDD Checklist

- [x] TCP hello codec 테스트에서 session id encode/decode 보존을 먼저 고정한다.
- [x] inbound listener coordinator 테스트에서 hello session id로 registry 등록이 되는지 고정한다.
- [x] session id 누락 또는 빈 문자열이 malformed hello로 거부되는지 테스트한다.

## Implementation Checklist

- [x] `TcpDataSessionHello` 생성자, 필드, `copyWith`에 session id를 추가한다.
- [x] `TcpDataSessionHelloCodec` JSON body에 `sessionId`를 추가하고 decode 필수 field로 읽는다.
- [x] `TcpDataInboundListenerEventCoordinator.handleHello` API에서 별도 `sessionId` 인자를 제거한다.
- [x] 모든 테스트 fixture와 raw TCP transport 테스트 hello 생성부에 session id를 명시한다.

## Validation

- [x] `flutter test test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/tcp_data_inbound_listener_event_coordinator_test.dart test/application/transfer/tcp_data_inbound_handshake_command_test.dart test/application/transfer/tcp_data_session_promotion_command_test.dart test/application/transfer/tcp_data_session_registry_promotion_command_test.dart --reporter compact`
- [x] `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- [x] `flutter test test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task043.md lib/application/transfer/tcp_data_session_handshake_command.dart lib/application/transfer/tcp_data_inbound_listener_event_coordinator.dart lib/infrastructure/transfer_data/tcp_data_session_hello_codec.dart test/application/transfer test/infrastructure/transfer_data`

## Completion Report

- Status: completed
- Notes:
  - TCP hello now carries the same data session identity used by control negotiation and registry promotion.
  - Inbound hello handling now derives the session id from the wire hello instead of receiving a duplicate out-of-band argument.
