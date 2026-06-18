# task039 - TransferController TCP Send Path

## Goal

`TransferController.sendFile`이 연결된 TCP data channel이 있을 때 TCP 전송 use case를 먼저 사용하도록 전환한다. TCP channel이 없는 경우에는 기존 UDP 경로를 유지해 기존 동작을 깨지 않으면서 TCP 전환 경로를 활성화한다.

## Scope

- [x] `sendFile`이 인증된 peer에 대해 TCP send use case를 먼저 호출한다.
- [x] TCP send 성공 시 UDP `transferInit`와 UDP data loop를 실행하지 않는다.
- [x] TCP send 성공 시 outgoing transfer job을 completed 상태로 기록한다.
- [x] TCP channel missing은 기존 UDP fallback으로 처리한다.
- [x] TCP send failure는 사용자 오류 메시지로 표시하고 UDP fallback을 수행하지 않는다.

## Architecture Notes

- controller는 `tcpTransferSendUseCaseProvider`를 통해 application use case만 호출한다.
- controller는 TCP socket, metadata codec, writer registry를 직접 알지 않는다.
- fallback은 명시적으로 `missing_tcp_outgoing_data_channel`에만 허용한다.
- 이후 task에서 TCP listener lifecycle과 실제 connected channel 생성 경로를 controller lifecycle에 연결한다.

## TDD Checklist

- [x] TCP send success에서 use case가 호출되고 UDP `transferInit`이 전송되지 않는 테스트를 작성한다.
- [x] TCP send success에서 outgoing job이 completed로 생성되는 테스트를 작성한다.
- [x] TCP missing channel에서는 기존 UDP path가 유지되는 회귀 테스트를 유지한다.

## Implementation Checklist

- [x] `TransferController.sendFile` 앞단에 TCP send attempt를 추가한다.
- [x] TCP success job upsert helper를 추가하거나 기존 `_upsertJob`을 사용한다.
- [x] fallback 허용 issue code를 한 곳에서 판단한다.
- [x] 테스트 harness에 TCP use case override 옵션을 추가한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "uses TCP send path without UDP transfer init when TCP channel is connected"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "uses active route remote address instead of stale session loopback target"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/tcp_transfer_send_use_case_test.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task039.md lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_controller_test.dart`

## Completion Report

- Status: completed
- Notes:
  - `TransferController.sendFile` now tries TCP transfer first for authenticated peers.
  - TCP success records a completed outgoing job and bypasses UDP `transferInit`.
  - Missing TCP data channel remains the only UDP fallback condition.
