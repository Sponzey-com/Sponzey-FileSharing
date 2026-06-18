# Task 019. Data ACK bitmap 해석 책임 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 Data ACK frame의 primary chunk와 bitmap word를 ACK index set으로 해석하는 책임을 controller에서 분리하는 것이다.
- [x] 이 태스크는 application command가 primitive 입력만 받아 ACK index를 계산하게 하여 infrastructure `DataFrame` 의존을 피한다.
- [x] 완료 후 controller는 `_chunkIndexesFromAckFrame` private helper를 소유하지 않는다.

## 2. Scope

### Included

- [x] `TransferOutgoingAckIndexesCommand`를 추가한다.
- [x] primary ACK chunk가 항상 포함되는지 테스트한다.
- [x] ack bitmap word의 bit가 `ackBase + wordIndex * 32 + bit`로 해석되는지 테스트한다.
- [x] controller의 Data ACK 처리 경로가 새 command를 사용하도록 변경한다.

### Excluded

- [x] DataFrame packet format은 변경하지 않는다.
- [x] ACK/NACK 전송 빈도와 batching 정책은 변경하지 않는다.
- [x] outgoing congestion window 정책은 변경하지 않는다.

## 3. TDD Plan

- [x] 실패하는 command 단위 테스트를 먼저 작성한다.
- [x] 실패하는 controller source guard를 먼저 작성한다.
- [x] 최소 구현으로 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 4. Validation Checklist

- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command는 Flutter, IO, socket, repository, infrastructure frame 타입에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] Data packet format이 변경되지 않았다.

## 5. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingAckIndexesCommand`를 추가해 Data ACK primary chunk와 bitmap words를 ACK index set으로 해석하는 책임을 분리했다.
  - `_onDataAck`는 DataFrame을 직접 루프 해석하지 않고 primitive 값을 command에 전달한다.
  - controller의 `_chunkIndexesFromAckFrame` helper를 제거했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_outgoing_ack_indexes_command.dart`
  - 생성: `test/application/transfer/transfer_outgoing_ack_indexes_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_ack_indexes_command_test.dart --reporter expanded`: 최초 실패 후 구현 뒤 통과
  - `dart format lib/application/transfer/transfer_controller.dart lib/application/transfer/transfer_outgoing_ack_indexes_command.dart test/application/transfer/transfer_outgoing_ack_indexes_command_test.dart`: 통과
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과, 기존 Drift 다중 DB 경고만 출력
- [x] 검증한 항목을 기록한다.
  - command는 infrastructure `DataFrame` 타입에 의존하지 않는다.
  - Data packet format, ACK/NACK 빈도, batching, congestion window 정책은 변경하지 않았다.
- [x] 남은 위험 요소를 기록한다.
  - ACK/NACK packet 생성용 bitmap words 계산이 아직 controller helper에 남아 있어 송신 packet 구성 책임이 일부 혼재되어 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - Task020에서 ACK bitmap 생성 로직을 독립 command로 분리한다.

## 6. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

Next task: `.tasks/task020.md`
