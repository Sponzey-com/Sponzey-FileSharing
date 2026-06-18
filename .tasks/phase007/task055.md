# Task 055. Incoming ACK Retry Scheduling Command

## Goal

수신 Data channel의 ACK batch flush와 retry timer 예약 조건을 application 계층 명령 객체로 분리한다. 컨트롤러는 Timer 생성과 flush 실행만 담당하고, 언제 즉시 flush하거나 retry를 예약할지는 테스트 가능한 순수 predicate가 결정한다.

## Scope

- [x] ACK enqueue 후 즉시 flush 조건을 분리한다.
- [x] Data ACK retry timer 예약 조건을 분리한다.
- [x] out-of-order missing NACK retry timer 예약 조건을 분리한다.

## Functional Requirements

- [x] pending ACK 개수에 새 chunk를 더했을 때 threshold 이상이면 즉시 flush한다.
- [x] nextExpectedChunk가 expectedChunkCount 이상이면 즉시 flush한다.
- [x] ACK flush timer가 이미 있으면 ACK retry를 새로 예약하지 않는다.
- [x] ACK flush timer가 없으면 ACK retry를 예약할 수 있다.
- [x] buffered chunk가 없으면 missing NACK retry를 예약하지 않는다.
- [x] missing NACK timer가 이미 있으면 missing NACK retry를 새로 예약하지 않는다.

## Architecture Requirements

- [x] 명령 객체는 `lib/application/transfer`에 둔다.
- [x] 명령 객체는 Timer, Flutter, Riverpod, 파일 시스템, 네트워크에 의존하지 않는다.
- [x] 컨트롤러는 명령 결과에 따라 Timer 생성만 수행한다.

## TDD Requirements

- [x] ACK flush threshold/complete 조건 테스트를 먼저 작성한다.
- [x] ACK retry timer 예약 조건 테스트를 작성한다.
- [x] missing NACK retry timer 예약 조건 테스트를 작성한다.
- [x] 컨트롤러가 조건 판단을 명령 객체에 위임하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_incoming_ack_retry_schedule_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferIncomingAckRetryScheduleCommand`가 추가되어 있다.
- [x] ACK flush/retry 예약 조건이 명령 객체에 위임되어 있다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
