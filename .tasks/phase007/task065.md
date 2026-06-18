# Task 065. Incoming Runner Explicit Event Methods

## Goal

`TransferController`가 수신 상태 머신 enum을 직접 다루지 않도록 `IncomingTransferSessionRunner`에 명시적인 이벤트 메서드를 추가한다. 이후 controller 수신 절차를 runner로 옮길 때 storage, writer, ACK/NACK 흐름을 runner API 뒤로 숨긴다.

## Scope

- [x] 수신 chunk/write/buffer 메서드를 추가한다.
- [x] 수신 finish/verify/finalize 메서드를 추가한다.
- [x] 수신 cancel/failure/cleanup 메서드를 추가한다.

## Functional Requirements

- [x] `receiveChunk()`는 `writeChunk`, `scheduleAckBatch` effect를 실행한다.
- [x] `receiveOutOfOrderChunk()`와 `markBufferGapClosed()`는 buffer/NACK/flush/ACK 흐름을 수행한다.
- [x] `receiveDataFinish()`, `markDigestVerified()`, `markFinalizeCompleted()`는 verify/finalize/complete 흐름을 수행한다.
- [x] `markDigestMismatch()`와 `markFileWriteFailed()`는 failure 흐름을 수행한다.
- [x] `cancel()`과 `markCleanupCompleted()`는 cancel cleanup 흐름을 수행한다.

## Architecture Requirements

- [x] 새 메서드는 enum event를 감싸는 thin wrapper로 유지한다.
- [x] runner는 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] 외부 설정이나 전역 상태를 읽지 않는다.

## TDD Requirements

- [x] 명시 메서드가 기존 exhaustive effect 테스트를 통과하도록 테스트를 갱신한다.
- [x] write failure helper 테스트를 추가한다.

## Validation

- [x] `flutter test test/application/transfer/incoming_transfer_session_runner_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] 수신 runner가 controller 이관에 필요한 명시 이벤트 메서드를 가진다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.