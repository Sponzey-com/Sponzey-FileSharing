# Task 019. TCP Stream Frame Channel Context

## 1. Task Purpose

- [x] 이 태스크의 목적은 수신된 TCP stream frame이 등록된 inbound TCP data session에서 온 것인지 검증하는 application command를 추가하는 것이다.
- [x] channel id가 registry에 없으면 frame은 transfer runner로 전달하지 않는다.
- [x] peer/auth/session context는 TCP data session registry에서만 가져오고 discovery route candidate를 재조회하지 않는다.

## 2. Scope

### Included

- [x] data channel session registry에 channel id lookup 기능을 추가한다.
- [x] TCP stream frame channel context command를 application 계층에 추가한다.
- [x] registered inbound channel, missing channel, wrong direction 테스트를 추가한다.

### Excluded

- [x] frame route별 runner 호출은 포함하지 않는다.
- [x] 파일 I/O는 포함하지 않는다.
- [x] UI projection 변경은 포함하지 않는다.

## 3. TDD Plan

- [x] registry channel lookup 테스트를 먼저 작성한다.
- [x] command가 registered inbound channel에서 peer/auth/session context를 반환하는지 테스트한다.
- [x] missing channel과 outbound-only channel은 명시적 issue code로 거부하는지 테스트한다.

## 4. Completion Report

Completion summary:

- `DataChannelSessionRegistry`에 direction + channel id lookup과 peer/auth context lookup을 추가했다.
- `TcpDataStreamFrameChannelContextCommand`를 추가해 수신 TCP stream frame이 등록된 inbound TCP data session에서 온 경우에만 허용한다.
- missing channel과 outbound-only channel은 `missing_tcp_data_channel_context`로 거부해 transfer runner에 잘못 진입하지 않도록 했다.

Changed files:

- `lib/application/transfer/data_channel_session_registry.dart`
- `lib/application/transfer/tcp_data_stream_frame_channel_context_command.dart`
- `test/application/transfer/data_channel_session_registry_test.dart`
- `test/application/transfer/tcp_data_stream_frame_channel_context_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_stream_frame_channel_context_command_test.dart test/application/transfer/data_channel_session_registry_test.dart --reporter compact`

Remaining risks:

- route별 runner dispatch와 MessageBus event 발행은 후속 task에서 구현해야 한다.
