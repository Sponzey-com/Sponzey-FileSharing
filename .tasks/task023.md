# Task 023. TCP Incoming Stream Frame Pipeline Command

## 1. Task Purpose

- [x] 이 태스크의 목적은 raw TCP listener에서 받은 stream frame을 data channel context 검증, transfer runner lookup, frame context staging, runner adapter 적용까지 하나의 application pipeline으로 연결하는 것이다.
- [x] runner가 없는 transfer frame은 file writer나 UI로 전달하지 않는다.
- [x] pipeline은 UDP route lease, discovery candidate, socket 구현체를 재조회하지 않는다.

## 2. Scope

### Included

- [x] TCP incoming stream frame pipeline command를 application 계층에 추가한다.
- [x] `DataChannelSessionRegistry`, `TransferSessionRegistry<IncomingTransferSessionRunner>`, frame context store를 조합한다.
- [x] valid frame, missing runner, missing channel context 테스트를 추가한다.

### Excluded

- [x] raw listener subscription wiring은 포함하지 않는다.
- [x] actual file writer executor 구현은 포함하지 않는다.
- [x] UI projection 변경은 포함하지 않는다.

## 3. TDD Plan

- [x] pipeline command 테스트를 먼저 작성한다.
- [x] registered channel + registered runner의 chunk frame이 runner write effect로 이어지는지 테스트한다.
- [x] transfer runner가 없으면 `missing_tcp_incoming_transfer_runner`로 거부하고 context를 stage하지 않는지 테스트한다.
- [x] channel context가 없으면 기존 context issue code를 반환하는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpIncomingStreamFramePipelineCommand`를 추가해 received TCP frame을 data channel context 검증, runner lookup, context staging, runner adapter 적용 순서로 처리한다.
- incoming runner가 없는 transfer frame은 `missing_tcp_incoming_transfer_runner`로 거부하고 context를 stage하지 않도록 했다.
- channel context가 없으면 기존 `missing_tcp_data_channel_context` issue를 그대로 반환한다.

Changed files:

- `lib/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart`
- `test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart test/application/transfer/tcp_incoming_transfer_frame_context_store_test.dart test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart --reporter compact`

Remaining risks:

- 실제 listener stream subscription에서 이 pipeline을 호출하는 runtime wiring은 후속 task에서 구현해야 한다.
