# task050 - TCP File Payload End-to-End Receive

## Goal

연결된 TCP data channel을 통해 `TransferController.sendFile()`이 실제 파일 payload를 송신하고, 상대 노드가 기본 수신 경로에 파일을 저장하는지 검증한다.

## Scope

- [x] 인증 및 TCP data channel registry 등록이 완료된 peer를 대상으로 파일을 전송한다.
- [x] 송신은 TCP outbound channel을 사용하고 UDP transfer init fallback으로 내려가지 않는다.
- [x] 수신은 TCP inbound listener pipeline을 통해 metadata, chunk, complete frame을 처리한다.
- [x] 수신 파일은 기본 저장 경로에 최종 파일로 저장되고 원본 내용과 일치한다.

## TDD Checklist

- [x] 실제 raw TCP listener/connector를 사용하는 end-to-end 파일 저장 테스트를 작성한다.
- [x] 수신 파일 내용이 원본과 byte-for-byte 일치하는지 확인한다.
- [x] sender transfer job이 TCP 성공 경로로 completed 상태가 되는지 확인한다.
- [x] 테스트 종료 시 TCP connector/listener와 ProviderContainer를 정리한다.

## Implementation Checklist

- [x] `transfer_controller_test.dart`에 TCP file payload end-to-end 테스트를 추가한다.
- [x] 필요한 경우 수신 파일 대기 helper를 추가한다.
- [x] 실패 시 TCP frame pipeline, writer session, finalize 단계 중 어느 단계인지 좁혀 수정한다.
- [x] UDP legacy 전송 테스트와 fallback 경로는 변경하지 않는다.
- [x] TCP metadata frame이 missing runner 상태에서 incoming runner를 생성하도록 수정한다.
- [x] TCP frame 처리 순서를 subscription coordinator에서 보존하도록 순차 큐를 적용한다.
- [x] TCP complete frame이 verify, finalize, complete 전이를 모두 수행하도록 runner adapter를 수정한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "sends and stores file payload over established TCP data channel" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart test/application/transfer/tcp_incoming_listener_stream_subscription_coordinator_test.dart test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task050.md test/application/transfer/transfer_controller_test.dart lib/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart lib/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart lib/application/transfer/tcp_incoming_stream_frame_runner_adapter.dart lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart test/application/transfer/tcp_incoming_stream_frame_runner_adapter_test.dart`

## Completion Report

- Status: completed
- Notes:
  - 실제 raw TCP listener/connector 기반으로 파일 payload가 수신 저장 경로에 저장되는 것을 확인했다.
  - metadata frame은 TCP 전송의 transfer init 역할을 하므로 incoming runner를 생성하도록 변경했다.
  - stream frame 처리는 순서 보존이 필요하므로 listener subscription에서 순차 큐를 적용했다.
  - complete frame은 digest verify, finalize, complete 전이를 한 번에 마무리한다.
