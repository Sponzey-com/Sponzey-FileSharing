# Task 021. TCP Incoming Stream Frame Runner Adapter

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP stream frame dispatch decision을 incoming transfer session runner 이벤트로 변환하는 adapter를 추가하는 것이다.
- [x] TCP socket event가 runner 상태 머신을 우회해 파일 I/O나 UI 상태를 직접 변경하지 못하게 한다.
- [x] missing/denied dispatch decision은 runner에 전달하지 않는다.

## 2. Scope

### Included

- [x] TCP incoming stream frame runner adapter를 application 계층에 추가한다.
- [x] metadata, chunk, complete, cancel/error route를 incoming runner event로 매핑한다.
- [x] allowed/denied decision 테스트와 runner effect 테스트를 추가한다.

### Excluded

- [x] 실제 파일 writer 구현은 포함하지 않는다.
- [x] TCP listener subscription wiring은 포함하지 않는다.
- [x] MessageBus event 발행은 포함하지 않는다.

## 3. TDD Plan

- [x] adapter 테스트를 먼저 작성한다.
- [x] metadata route가 `receiveDataStart`를 통해 writer open effect를 실행하는지 테스트한다.
- [x] chunk route가 `receiveChunk`를 통해 write/ack effect를 실행하는지 테스트한다.
- [x] complete route가 `receiveDataFinish`를 통해 digest verify effect를 실행하는지 테스트한다.
- [x] denied decision은 runner state와 effects를 변경하지 않는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpIncomingStreamFrameRunnerAdapter`를 추가해 TCP stream dispatch decision을 incoming runner 이벤트로 변환한다.
- metadata는 `receiveDataStart`, chunk는 `receiveChunk`, complete는 `receiveDataFinish`, cancel/error는 `dataAbortReceived`로 매핑한다.
- denied decision은 runner state와 executor effects를 변경하지 않도록 고정했다.

Changed files:

- `lib/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart`
- `test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart test/application/transfer/incoming_transfer_session_runner_test.dart test/application/transfer/incoming_transfer_session_state_machine_test.dart --reporter compact`

Remaining risks:

- runner effect executor를 실제 TCP frame payload와 file writer에 연결하는 작업은 후속 task에서 구현해야 한다.
