# Task 018. TCP Stream Frame Dispatcher

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP stream frame type을 application transfer action으로 분류하는 dispatcher를 추가하는 것이다.
- [x] 기존 UDP `TransferDataFrameDispatcher`와 TCP dispatcher를 섞지 않는다.
- [x] dispatcher는 Flutter, IO, socket, file service에 의존하지 않는 순수 application 객체로 유지한다.

## 2. Scope

### Included

- [x] TCP stream frame route enum과 expected direction을 추가한다.
- [x] `TcpDataStreamFrameType`을 route로 변환하는 dispatcher를 추가한다.
- [x] 모든 TCP stream frame type의 route와 계층 독립성 테스트를 추가한다.

### Excluded

- [x] transfer runner 호출은 포함하지 않는다.
- [x] file writer/read 연결은 포함하지 않는다.
- [x] socket subscription wiring은 포함하지 않는다.

## 3. TDD Plan

- [x] TCP stream frame dispatcher 테스트를 먼저 작성한다.
- [x] metadata/chunk/complete/cancel/error route를 모두 검증한다.
- [x] dispatcher가 framework, IO, socket 구현에 의존하지 않는지 source guard 테스트를 추가한다.

## 4. Completion Report

Completion summary:

- `TcpDataStreamFrameDispatcher`를 추가해 TCP stream frame type을 metadata/chunk/complete/cancel/error route로 분류한다.
- 모든 TCP stream payload route는 inbound TCP channel에서 수신되는 파일 payload 흐름이므로 expected direction을 incoming으로 고정했다.
- dispatcher가 Flutter, Riverpod, IO, socket, file service, raw transport에 의존하지 않도록 source guard 테스트를 추가했다.

Changed files:

- `lib/application/transfer/tcp_data_stream_frame_dispatcher.dart`
- `test/application/transfer/tcp_data_stream_frame_dispatcher_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_stream_frame_dispatcher_test.dart test/infrastructure/transfer_data/tcp_data_stream_frame_codec_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`

Remaining risks:

- route 결과를 실제 incoming/outgoing runner에 연결하는 작업은 후속 task에서 진행해야 한다.
