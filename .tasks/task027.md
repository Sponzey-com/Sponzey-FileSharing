# task027 - TCP Metadata Prepare Hook in Incoming Pipeline

## Goal

TCP metadata 프레임이 들어왔을 때 incoming runner가 `openIncomingWriter` 효과를 실행하기 전에 receiver draft와 writer session이 준비되도록 pipeline hook을 연결한다.

## Scope

- [x] application pipeline에 metadata prepare port를 추가한다.
- [x] metadata route에서만 prepare port를 호출한다.
- [x] prepare 실패 시 runner state transition을 실행하지 않고 명시 issue code를 반환한다.
- [x] infrastructure adapter가 raw metadata payload를 decode하고 writer session prepare command를 호출한다.
- [x] application 계층은 metadata codec, file service, filesystem을 직접 참조하지 않는다.

## Architecture Notes

- port는 `lib/application/transfer`에 둔다.
- infrastructure adapter는 `lib/infrastructure/transfer`에 둔다.
- pipeline은 `TcpDataStreamFrameRoute.metadata`인 경우에만 prepare hook을 실행한다.
- hook 성공 이후에만 `IncomingTransferSessionRunner.receiveDataStart()`가 실행된다.
- receiver 저장 경로는 adapter 생성자 인자로 명시 전달한다.

## TDD Checklist

- [x] metadata frame이 prepare port를 먼저 호출하고 runner open 효과를 실행하는 테스트를 작성한다.
- [x] prepare 실패 시 runner 효과가 실행되지 않는 테스트를 작성한다.
- [x] chunk frame은 prepare port를 호출하지 않는 기존 테스트를 유지한다.
- [x] infrastructure adapter가 encoded metadata payload를 decode하고 writer session registry에 등록하는 테스트를 작성한다.
- [x] malformed metadata payload는 명시 issue code로 거부하는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpIncomingMetadataFramePreparePort`와 result 타입을 추가한다.
- [x] `TcpIncomingStreamFramePipelineCommand` 생성자에 prepare port를 추가하되 기존 테스트와 callsite가 깨지지 않도록 기본 no-op 구현을 제공한다.
- [x] metadata route에서 prepare result를 확인하고 실패 시 pipeline result로 반환한다.
- [x] `TcpIncomingMetadataFramePrepareAdapter`를 추가한다.
- [x] adapter는 codec decode 실패와 writer prepare 실패를 구분 가능한 issue code로 반환한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart test/infrastructure/transfer/tcp_incoming_metadata_frame_prepare_adapter_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task027.md lib/application/transfer/tcp_incoming_metadata_frame_prepare_port.dart lib/application/transfer/tcp_incoming_stream_frame_pipeline_command.dart lib/infrastructure/transfer/tcp_incoming_metadata_frame_prepare_adapter.dart test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart test/infrastructure/transfer/tcp_incoming_metadata_frame_prepare_adapter_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added an application metadata prepare port so pipeline code stays independent from metadata codec and file system details.
  - Metadata frames now prepare receiver writer sessions before `openIncomingWriter` state-machine effects run.
  - Added an infrastructure adapter that decodes metadata and delegates draft/writer session creation.
