# task026 - TCP Incoming Metadata Draft and Writer Session Preparation

## Goal

TCP metadata 프레임 수신 시 파일 수신 draft와 digest writer를 준비하고, `TcpIncomingTransferPayloadWriterAdapter`가 사용할 writer session registry에 등록할 수 있는 인프라 경계를 만든다.

## Scope

- [x] TCP metadata wire payload를 명시적인 값 객체로 decode/encode한다.
- [x] metadata에는 sender 파일 정보만 포함하고, receiver 저장 경로는 로컬 런타임 입력값으로 명시 전달한다.
- [x] metadata 수신 후 `TransferFileService.createIncomingDraft`와 `openIncomingDigestingWriter`를 호출해 writer session을 준비한다.
- [x] draft 생성 실패, writer open 실패, 잘못된 저장 경로 입력을 명시적인 오류 코드로 반환한다.
- [x] writer open 실패 시 생성된 draft는 best-effort로 discard한다.

## Architecture Notes

- metadata codec은 `lib/infrastructure/transfer_data`에 둔다.
- writer session prepare command는 `lib/infrastructure/transfer`에 둔다.
- application pipeline은 아직 직접 수정하지 않는다. 다음 task에서 pipeline에 준비 command를 주입한다.
- sender metadata는 receiver 저장 경로를 결정하지 않는다. `destinationDirectory`는 receiver 설정 로딩 결과를 command 인자로 전달한다.
- 외부 설정 파일이나 전역 환경 조회를 추가하지 않는다.

## TDD Checklist

- [x] metadata codec이 `fileName`, `fileSize`, `chunkCount`, `sha256`를 round-trip 하는 테스트를 작성한다.
- [x] metadata codec이 필수 필드 누락과 잘못된 숫자를 거부하는 테스트를 작성한다.
- [x] prepare command가 draft와 digest writer를 열고 writer session을 registry에 등록하는 테스트를 작성한다.
- [x] destination directory가 비어 있으면 파일 시스템 호출 없이 실패하는 테스트를 작성한다.
- [x] writer open 실패 시 draft discard를 호출하는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpIncomingTransferMetadata` 값 객체를 추가한다.
- [x] `TcpIncomingTransferMetadataCodec`을 추가한다.
- [x] `TcpIncomingTransferWriterSessionPrepareCommand`를 추가한다.
- [x] prepare result는 성공 여부, key, temp path, issue code를 명시한다.
- [x] 오류 처리는 `AppException` 코드로 고정한다.

## Validation

- [x] `flutter test test/infrastructure/transfer_data/tcp_data_stream_metadata_codec_test.dart test/infrastructure/transfer/tcp_incoming_transfer_writer_session_prepare_command_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task026.md lib/infrastructure/transfer_data/tcp_data_stream_metadata_codec.dart lib/infrastructure/transfer/tcp_incoming_transfer_writer_session_prepare_command.dart test/infrastructure/transfer_data/tcp_data_stream_metadata_codec_test.dart test/infrastructure/transfer/tcp_incoming_transfer_writer_session_prepare_command_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added a TCP metadata codec for sender file metadata.
  - Added writer session preparation that creates receiver draft files, opens digest writers, registers isolated TCP payload writer sessions, and cleans up drafts on open failure.
