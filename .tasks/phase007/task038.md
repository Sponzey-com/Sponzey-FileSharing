# task038 - Incoming Chunk Write Failure Message Mapper 분리

## Goal

수신 data chunk 저장 실패 시 사용자에게 보여줄 실패 메시지 매핑을 `TransferController`에서 분리한다. 파일 시스템 오류, 애플리케이션 오류, 상태 오류가 모두 예측 가능한 메시지로 변환되도록 테스트한다.

## Scope

- [x] `TransferIncomingChunkWriteFailureMapper`를 추가한다.
- [x] `AppException`, `FileSystemException`, `StateError`, 기타 오류 타입의 reason 매핑을 테스트한다.
- [x] `TransferController._incomingChunkWriteFailureMessage`가 mapper 호출만 수행하도록 변경한다.

## Out of Scope

- [x] 파일 쓰기 정책과 retry 정책은 변경하지 않는다.
- [x] 수신 draft/temporary file 생성 경로는 변경하지 않는다.
- [x] 로그 레벨 정책은 변경하지 않는다.

## TDD Requirements

- [x] `AppException.message`가 reason으로 들어간다.
- [x] message가 있는 `FileSystemException.message`가 reason으로 들어간다.
- [x] `StateError.message`가 reason으로 들어간다.
- [x] 기타 오류는 runtime type 이름을 reason으로 사용한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_incoming_chunk_write_failure_mapper_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] chunk write failure message mapping이 controller가 아닌 mapper에 존재한다.
- [x] 기존 사용자 메시지 의미가 유지된다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferIncomingChunkWriteFailureMapper`와 단위 테스트를 추가했다.
- [x] `_incomingChunkWriteFailureMessage`는 mapper 호출만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task039에서 outgoing chunk byte length 계산을 command로 분리한다.
