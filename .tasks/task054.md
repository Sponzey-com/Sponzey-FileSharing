# Task 054. TCP Incoming Pipeline Failure Keeps Transfer Identity

## Goal

TCP incoming frame 처리 중 writer, digest, finalize 같은 effect가 실패해도 `transferId`, `peerId`, `authSessionId`, frame route가 유지된 실패 결과를 반환하게 하여 `TransferController`가 해당 transfer job만 정확히 실패 처리할 수 있도록 한다.

## Scope

- [x] `TcpIncomingStreamFramePipelineCommand`가 runner adapter 예외를 식별자 포함 실패 결과로 변환한다.
- [x] `AppException.code`는 issueCode로 보존하고, 알 수 없는 예외는 `tcp_incoming_frame_pipeline_failed`로 매핑한다.
- [x] listener-level catch는 최후의 안전망으로만 남긴다.

## Functional Requirements

- [x] chunk write 실패 시 result는 `applied=false`이고 `transferId`, `peerId`, `authSessionId`, `route`를 포함한다.
- [x] AppException 실패는 `issueCode`에 AppException code를 사용한다.
- [x] Controller는 해당 result를 받아 기존 TCP incoming job을 failed로 갱신할 수 있다.

## Architecture Requirements

- [x] failure mapping은 socket listener가 아니라 application pipeline에서 수행한다.
- [x] infra writer 예외 상세 타입은 UI로 직접 새지 않는다.
- [x] 실패 결과는 MessageBus와 TransferJob projection 경로에서 재사용 가능한 값 객체로 유지한다.

## TDD Requirements

- [x] pipeline 단위 테스트로 writer chunk 실패가 transfer identity를 보존하는지 먼저 고정한다.
- [x] 관련 TCP incoming pipeline 테스트와 transfer controller 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/application/transfer/tcp_incoming_stream_frame_pipeline_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP incoming effect 실패가 transferId 없는 일반 오류로 손실되지 않는다.
- [x] 해당 transfer job만 실패 처리할 수 있는 결과 정보가 유지된다.
