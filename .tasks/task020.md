# Task 020. TCP Stream Frame Dispatch Decision Command

## 1. Task Purpose

- [x] 이 태스크의 목적은 수신된 TCP stream frame을 channel context 검증과 route 분류를 거쳐 transfer runner가 처리할 수 있는 dispatch decision으로 변환하는 것이다.
- [x] 등록되지 않은 channel의 frame은 runner로 전달하지 않는다.
- [x] TCP frame dispatch는 discovery route, UDP route lease, socket 구현체를 재조회하지 않는다.

## 2. Scope

### Included

- [x] TCP stream frame dispatch decision command를 application 계층에 추가한다.
- [x] context command와 TCP stream frame dispatcher를 조합한다.
- [x] valid frame, missing channel, route mapping 테스트를 추가한다.

### Excluded

- [x] 실제 incoming transfer runner 호출은 포함하지 않는다.
- [x] 파일 writer/read 연결은 포함하지 않는다.
- [x] MessageBus event 발행은 포함하지 않는다.

## 3. TDD Plan

- [x] dispatch decision command 테스트를 먼저 작성한다.
- [x] registered inbound channel의 chunk frame이 allowed decision으로 변환되는지 테스트한다.
- [x] missing channel은 `missing_tcp_data_channel_context`로 거부되는지 테스트한다.
- [x] metadata/complete/cancel/error frame route가 유지되는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpDataStreamFrameDispatchCommand`를 추가해 TCP stream frame을 channel context 검증과 route 분류를 거친 dispatch decision으로 변환한다.
- 등록되지 않은 channel은 `missing_tcp_data_channel_context`로 거부하고 frame/route를 노출하지 않도록 했다.
- allowed decision에는 peer id, auth session id, transfer id, session snapshot, frame, route를 포함해 후속 runner adapter가 discovery/UDP route를 재조회하지 않게 했다.

Changed files:

- `lib/application/transfer/tcp_data_stream_frame_dispatch_command.dart`
- `test/application/transfer/tcp_data_stream_frame_dispatch_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_stream_frame_dispatch_command_test.dart test/application/transfer/tcp_data_stream_frame_channel_context_command_test.dart test/application/transfer/tcp_data_stream_frame_dispatcher_test.dart --reporter compact`

Remaining risks:

- decision 결과를 실제 incoming transfer runner에 연결하는 adapter는 후속 task에서 구현해야 한다.
