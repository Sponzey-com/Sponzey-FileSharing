# Task 024. TCP Incoming Transfer Effect Executor Port

## 1. Task Purpose

- [x] 이 태스크의 목적은 incoming runner effect가 staged TCP frame context를 사용해 payload writer port를 호출하도록 adapter를 추가하는 것이다.
- [x] application 계층은 파일 시스템 구현을 직접 알지 않고 writer port만 호출한다.
- [x] `writeChunk()`는 반드시 검증된 transfer frame context의 chunk payload만 writer로 전달한다.

## 2. Scope

### Included

- [x] TCP incoming payload writer port를 application 계층에 추가한다.
- [x] `IncomingTransferSessionEffectExecutor` 구현체를 추가해 frame context store와 writer port를 연결한다.
- [x] open/write/verify/finalize/cancel effect 테스트와 missing context 테스트를 추가한다.

### Excluded

- [x] 실제 파일 시스템 writer 구현은 포함하지 않는다.
- [x] digest 계산 구현은 포함하지 않는다.
- [x] UI와 MessageBus event 발행은 포함하지 않는다.

## 3. TDD Plan

- [x] fake writer port 기반 executor 테스트를 먼저 작성한다.
- [x] `writeChunk()`가 staged chunk payload를 writer로 전달하는지 테스트한다.
- [x] chunk context가 없으면 `missing_tcp_incoming_frame_context`로 실패하는지 테스트한다.
- [x] verify/finalize/cancel/cleanup effect가 writer port로 위임되는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpIncomingTransferPayloadWriterPort`를 추가해 application 계층에서 파일 시스템 구현을 직접 참조하지 않도록 했다.
- `TcpIncomingTransferEffectExecutor`를 추가해 incoming runner effect가 staged TCP frame context와 writer port를 통해 실행되도록 했다.
- `writeChunk()`는 staged chunk context가 없으면 `missing_tcp_incoming_frame_context`를 포함한 `StateError`로 실패한다.

Changed files:

- `lib/application/transfer/tcp_incoming_transfer_effect_executor.dart`
- `test/application/transfer/tcp_incoming_transfer_effect_executor_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_incoming_transfer_effect_executor_test.dart test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart --reporter compact`

Remaining risks:

- payload writer port의 infrastructure 파일 시스템 구현은 후속 task에서 작성해야 한다.
