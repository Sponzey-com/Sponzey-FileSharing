# Task 009. Incoming Data chunk decision 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 수신 Data chunk 처리에서 순수 판단 로직과 부작용을 분리하는 것이다.
- [x] 이 태스크는 controller가 chunk index 상태를 직접 해석하는 책임을 줄이고, 수신 session runner 추출의 선행 단계를 만든다.
- [x] 완료 후 `_onDataChunk`는 command decision을 실행하고, out-of-range/duplicate/in-order/out-of-order 판단 자체는 별도 객체가 담당한다.

## 2. Current Context

- [x] `task008.md`에서 route direction gate가 추가되어 wrong-direction frame은 handler 전에 차단된다.
- [x] 현재 `_onDataChunk`는 context lookup, data endpoint 갱신, chunk index 판단, payload 저장, ACK/NACK, metric update를 모두 수행한다.
- [x] chunk 판단을 먼저 분리해야 이후 file writer, ACK batch, missing NACK retry를 runner로 안전하게 이동할 수 있다.

## 3. Scope

### Included

- [x] `TransferIncomingDataChunkCommand`를 추가한다.
- [x] 수신 chunk 판단 action을 out-of-range, duplicate, append in-order, buffer out-of-order로 분리한다.
- [x] `_onDataChunk`가 command decision을 사용하도록 변경한다.

### Excluded

- [x] file writer와 temp file handling은 이동하지 않는다.
- [x] ACK/NACK 전송 방식과 batch threshold는 변경하지 않는다.
- [x] window, retry, RTT 알고리즘은 변경하지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능: 수신 Data chunk의 action decision을 계산한다.
- [x] 입력: chunk index, expected chunk count, next expected chunk, acknowledged chunk set.
- [x] 출력: out-of-range, duplicate, append in-order, buffer out-of-order 중 하나.
- [x] 성공 조건: decision 객체는 입력 collection을 변경하지 않는다.

### Functional Unit 2

- [x] 구현할 기능: `_onDataChunk`가 decision action만 기준으로 기존 부작용을 실행한다.
- [x] 입력: `DataFrameDatagram`.
- [x] 출력: 기존과 동일한 ACK/NACK, 저장, metric update.
- [x] 성공 조건: 기존 transfer controller 회귀 테스트가 모두 통과한다.

## 5. Architecture Notes

- [x] command 객체는 `lib/application/transfer`에 둔다.
- [x] command 객체는 Flutter, Riverpod, dart:io, transport, file service에 의존하지 않는다.
- [x] command 객체는 private controller context 타입을 받지 않는다.
- [x] controller는 command 결과를 실행하는 orchestration만 담당한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] decision threshold는 런타임 설정이 아니라 입력값으로만 전달한다.
- [x] 테스트는 환경 변경 없이 순수 입력과 출력만 검증한다.

## 7. Logging Requirements

### Product Log

- [x] 정상 chunk decision에는 Product 로그를 추가하지 않는다.

### Field Debug Log

- [x] 이번 태스크에서는 debug 로그를 추가하지 않는다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] decision 동작은 단위 테스트로 검증한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 수신 session 상태 머신 추출 전의 decision 분리이다.
- [x] action enum은 상태가 아니라 단일 frame 처리 결정을 표현한다.
- [x] 상태 전이 자체는 기존 controller 흐름을 유지한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] out-of-range decision 테스트를 작성한다.
- [x] duplicate decision 테스트를 작성한다.
- [x] in-order append decision 테스트를 작성한다.
- [x] out-of-order buffer decision 테스트를 작성한다.
- [x] command 객체가 framework와 IO에 의존하지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 command 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 추가한다.
- [x] 실패하는 테스트를 확인한다.
- [x] command action enum과 decision class를 추가한다.
- [x] `_onDataChunk`의 chunk 판단 분기를 command 사용으로 변경한다.
- [x] 계층 의존성을 확인한다.
- [x] 관련 테스트와 정적 분석을 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command 객체가 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] controller의 수신 chunk 판단 책임이 줄었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferIncomingDataChunkCommand`를 추가해 수신 chunk decision을 순수 객체로 분리했다.
  - `_onDataChunk`가 out-of-range, duplicate, append in-order, buffer out-of-order action을 command 결과로 실행하도록 변경했다.
  - 기존 ACK/NACK, 저장, metric update 정책은 유지했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 추가: `lib/application/transfer/transfer_incoming_data_chunk_command.dart`
  - 추가: `test/application/transfer/transfer_incoming_data_chunk_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task009.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_incoming_data_chunk_command_test.dart --reporter expanded`: 최초 command 파일 부재로 실패해 red phase 확인, 구현 후 5개 테스트 통과.
  - `dart format lib/application/transfer/transfer_incoming_data_chunk_command.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_incoming_data_chunk_command_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - command 객체는 framework, IO, transport, file service에 의존하지 않는다.
  - command는 입력 acknowledged set을 변경하지 않는다.
  - 기존 transfer controller 회귀 테스트가 모두 통과한다.
- [x] 남은 위험 요소를 기록한다.
  - 파일 쓰기와 ACK/NACK 전송 부작용은 아직 controller에 남아 있다.
  - 수신 session runner 상태 머신은 아직 추출되지 않았다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 송신 DATA_ACK decision을 순수 command로 분리해 outgoing handler의 판단 책임을 줄인다.

## 13. Next Task Decision Hook

이 태스크 완료 후 반드시 다음 판단을 수행한다.

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다. 최종 목표에는 아직 도달하지 않았다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

결정: `task010.md`를 생성한다. 범위는 송신 DATA_ACK frame의 valid/new/duplicate ACK 판단을 순수 command 객체로 분리하고 `_onDataAck`가 그 결과를 실행하도록 제한한다.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
