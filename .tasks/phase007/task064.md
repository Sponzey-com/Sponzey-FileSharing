# Task 064. Outgoing Runner Explicit Event Methods

## Goal

`TransferController`가 송신 상태 머신 enum을 직접 다루지 않도록 `OutgoingTransferSessionRunner`에 명시적인 이벤트 메서드를 추가한다. 이후 controller 송신 로직 이관 시 runner API를 사용자 의도와 전송 절차 이름으로 호출할 수 있게 한다.

## Scope

- [x] 송신 data endpoint bound 메서드를 추가한다.
- [x] 송신 data start/chunk window/finish/complete 메서드를 추가한다.
- [x] 송신 cancel/failure 메서드를 추가한다.

## Functional Requirements

- [x] `markDataEndpointBound()`는 `sendDataStartFrame` effect를 실행한다.
- [x] `markStartFrameSent()`는 `pumpChunkWindow` effect를 실행한다.
- [x] `markWindowSaturated()`와 `markAckOpenedWindow()`는 ACK 대기와 chunk 전송 상태를 오간다.
- [x] `markAllChunksAcked()`, `markFinishFrameSent()`, `markFinishAccepted()`는 finish 완료 흐름을 수행한다.
- [x] `cancel()`과 `markCancellationCompleted()`는 cancel cleanup 흐름을 수행한다.
- [x] `markFailure()`는 failure 흐름을 수행한다.

## Architecture Requirements

- [x] 새 메서드는 enum event를 감싸는 thin wrapper로 유지한다.
- [x] runner는 Flutter, Riverpod, UDP, 파일 시스템, Timer에 의존하지 않는다.
- [x] 외부 설정이나 전역 상태를 읽지 않는다.

## TDD Requirements

- [x] 명시 메서드가 기존 exhaustive effect 테스트를 통과하도록 테스트를 갱신한다.
- [x] cancel/failure helper 테스트를 추가한다.

## Validation

- [x] `flutter test test/application/transfer/outgoing_transfer_session_runner_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] 송신 runner가 controller 이관에 필요한 명시 이벤트 메서드를 가진다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
