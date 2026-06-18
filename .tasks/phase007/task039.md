# task039 - Outgoing Chunk Byte Length 계산 분리

## Goal

ACK/NACK 처리 중 acknowledged bytes 계산에 사용하는 chunk byte length 규칙을 `TransferController`에서 분리한다. 파일 크기와 chunk 크기만으로 계산되는 순수 규칙을 application command로 고정해 전송 진행률 계산의 혼재를 줄인다.

## Scope

- [x] `TransferOutgoingChunkByteLengthCommand`를 추가한다.
- [x] 일반 chunk는 `chunkSize`를 반환하는 규칙을 테스트한다.
- [x] 마지막 chunk는 남은 byte 수를 반환하는 규칙을 테스트한다.
- [x] `TransferController._chunkByteLength`가 command 호출만 수행하도록 변경한다.

## Out of Scope

- [x] 파일 읽기 chunking 구현은 변경하지 않는다.
- [x] 진행률 UI 표시 방식은 변경하지 않는다.
- [x] ACK/NACK 프로토콜은 변경하지 않는다.

## TDD Requirements

- [x] chunk 시작 위치 이후 남은 크기가 chunk size보다 크면 chunk size를 반환한다.
- [x] 남은 크기가 chunk size 이하이면 remaining byte를 반환한다.
- [x] `PreparedTransferMetadata`를 command에 직접 넘기지 않는다.

## Validation

- [x] `flutter test test/application/transfer/transfer_outgoing_chunk_byte_length_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] chunk byte length 계산이 controller가 아닌 command에 존재한다.
- [x] controller는 metadata field를 command에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferOutgoingChunkByteLengthCommand`와 단위 테스트를 추가했다.
- [x] `_chunkByteLength`는 `PreparedTransferMetadata` field를 command에 전달하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task040에서 transfer throughput/loss metric 계산을 command로 분리한다.
