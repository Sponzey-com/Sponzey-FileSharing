# Task 051. TCP Incoming Transfer Job Projection

## Goal

TCP data channel로 수신된 파일이 실제 저장되는 것에 그치지 않고 `TransferController`의 `TransferJob` 목록에 수신 진행 상태와 완료 상태로 반영되도록 한다. 수신 UI는 기존 `transferJobsProvider`만 관찰하므로, TCP 수신 파이프라인 결과가 컨트롤러 상태로 명시적으로 투영되어야 한다.

## Scope

- [x] TCP incoming stream frame 처리 결과에 transfer 식별자, peer 식별자, frame route, metadata, payload byte 수를 포함한다.
- [x] `TransferController`가 TCP incoming subscription 결과를 구독하고 incoming job을 생성, 갱신, 완료 처리한다.
- [x] TCP 수신 저장 경로와 진행률이 UDP 수신 job과 섞이지 않도록 TCP 수신 projection은 별도 helper로 제한한다.

## Functional Requirements

- [x] metadata frame이 정상 적용되면 incoming `TransferJob`이 생성된다.
- [x] chunk frame이 정상 적용되면 해당 job의 `bytesTransferred`와 `completedChunks`가 증가하고 status는 `receiving`이 된다.
- [x] complete frame이 정상 적용되면 해당 job의 status는 `completed`, `bytesTransferred`는 `fileSize`, `completedChunks`는 `totalChunks`가 된다.
- [x] TCP incoming 결과에 issueCode가 있으면 기존 UDP 전송 job을 오염시키지 않고 해당 TCP transfer job만 실패 상태로 갱신하거나, job이 없으면 product-visible error만 기록한다.

## Architecture Requirements

- [x] application 계층 결과 모델은 infra codec 타입에 의존하지 않는다.
- [x] metadata decode는 기존 infra adapter 내부에 유지하고, application에는 최소 projection 값만 전달한다.
- [x] 컨트롤러는 MessageBus를 직접 우회하지 않고 `_upsertJob`/`_updateJob` 경로를 사용한다.
- [x] TCP incoming projection은 UDP `_IncomingTransferContext` registry와 독립적으로 동작한다.

## TDD Requirements

- [x] 실제 TCP listener/connector smoke에서 receiver `transferJobsProvider`가 completed incoming job을 포함하는 테스트를 먼저 추가한다.
- [x] pipeline 결과에 metadata projection이 포함되는 단위 테스트를 추가한다.
- [x] 전체 transfer controller 테스트와 관련 TCP pipeline 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "sends and stores file payload over established TCP data channel" --reporter compact`
- [x] `flutter test test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP 수신 파일 저장 성공 시 송신자와 수신자 모두 Transfer Queue에 완료 job이 남는다.
- [x] TCP 수신 진행/완료 상태는 transfer id 단위로 독립 갱신된다.
- [x] 전체 테스트와 정적 분석이 통과한다.
