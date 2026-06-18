# Task 022. TCP Incoming Transfer Frame Context Store

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP stream frame payload를 incoming runner effect executor가 안전하게 읽을 수 있도록 transfer별 frame context store를 추가하는 것이다.
- [x] runner의 인자 없는 `writeChunk()` 구조를 깨지 않고, application command가 검증한 frame context만 저장한다.
- [x] denied dispatch decision이나 transfer id 없는 decision은 store에 들어가지 않는다.

## 2. Scope

### Included

- [x] TCP incoming transfer frame context key/value/store를 application 계층에 추가한다.
- [x] allowed dispatch decision을 transfer별 context로 stage하는 command를 추가한다.
- [x] stage, lookup, clear, denied decision 거부 테스트를 추가한다.

### Excluded

- [x] 실제 file writer effect executor 구현은 포함하지 않는다.
- [x] MessageBus event 발행은 포함하지 않는다.
- [x] UI 변경은 포함하지 않는다.

## 3. TDD Plan

- [x] frame context store 테스트를 먼저 작성한다.
- [x] allowed chunk decision이 peer/auth/transfer id별 context로 저장되는지 테스트한다.
- [x] clear 후 context가 제거되는지 테스트한다.
- [x] denied decision은 `tcp_stream_frame_context_not_allowed`로 거부되는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpIncomingTransferFrameContextKey`, `TcpIncomingTransferFrameContext`, `TcpIncomingTransferFrameContextStore`를 추가했다.
- `TcpIncomingTransferFrameContextStageCommand`를 추가해 검증된 dispatch decision만 transfer별 frame context로 저장한다.
- denied decision이나 불완전한 decision은 `tcp_stream_frame_context_not_allowed`로 거부하고 store를 변경하지 않도록 했다.

Changed files:

- `lib/application/transfer/tcp_incoming_transfer_frame_context_store.dart`
- `test/application/transfer/tcp_incoming_transfer_frame_context_store_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_incoming_transfer_frame_context_store_test.dart test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart test/application/transfer/tcp_data_stream_frame_dispatch_command_test.dart --reporter compact`

Remaining risks:

- store를 실제 incoming transfer executor와 연결하는 작업은 후속 task에서 구현해야 한다.
