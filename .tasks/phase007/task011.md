# Task 011. Outgoing DATA_NACK decision 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 DATA_NACK frame에서 재전송해야 할 chunk index 계산을 순수 command 객체로 분리하는 것이다.
- [x] 이 태스크는 controller가 NACK bitmap 해석과 acknowledged chunk 제외 판단을 직접 수행하는 책임을 줄인다.
- [x] 완료 후 `_onDataNack`는 command 결과를 사용해 retransmission queue 조작만 수행한다.

## 2. Current Context

- [x] `task010.md`에서 DATA_ACK decision이 분리되었다.
- [x] 현재 `_onDataNack`는 primary chunk index, bitmap word 확장, acknowledged chunk 제외, retransmission queue mutation을 모두 수행한다.
- [x] NACK 판단을 분리해야 outgoing session runner에서 재전송 정책을 독립적으로 테스트할 수 있다.

## 3. Scope

### Included

- [x] `TransferOutgoingDataNackCommand`를 추가한다.
- [x] primary NACK index와 bitmap word를 retransmission index 목록으로 확장한다.
- [x] 이미 ACK된 index를 retransmission 대상에서 제외한다.
- [x] `_onDataNack`가 command decision을 사용하도록 변경한다.

### Excluded

- [x] window shrink 정책은 변경하지 않는다.
- [x] retransmission queue 내부 구현은 변경하지 않는다.
- [x] NACK packet/frame codec은 변경하지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능: NACK bitmap을 retransmission chunk index 목록으로 확장한다.
- [x] 입력: primary chunk index, ack base, ack bitmap words, acknowledged chunk set.
- [x] 출력: retransmission chunk indexes.
- [x] 성공 조건: primary index와 bitmap index가 모두 포함된다.
- [x] 성공 조건: 결과는 중복 없이 정렬된다.

### Functional Unit 2

- [x] 구현할 기능: `_onDataNack`가 decision 결과만 기준으로 outgoing context를 갱신한다.
- [x] 입력: `DataFrameDatagram`.
- [x] 출력: 기존과 동일한 window shrink, in-flight removal, retransmission queueing, pump scheduling.
- [x] 성공 조건: 기존 transfer controller 회귀 테스트가 모두 통과한다.

## 5. Architecture Notes

- [x] command 객체는 `lib/application/transfer`에 둔다.
- [x] command 객체는 Flutter, Riverpod, dart:io, transport, file service에 의존하지 않는다.
- [x] command 객체는 private controller context 타입을 받지 않는다.
- [x] controller는 command 결과를 실행하는 orchestration만 담당한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] NACK bitmap 해석 기준은 입력값으로만 전달한다.
- [x] 테스트는 숨겨진 환경 변경 없이 순수 입력과 출력만 검증한다.

## 7. Logging Requirements

### Product Log

- [x] 정상 NACK decision에는 Product 로그를 추가하지 않는다.

### Field Debug Log

- [x] 이번 태스크에서는 debug 로그를 추가하지 않는다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] NACK decision 동작은 단위 테스트로 검증한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 송신 session 상태 머신 추출 전의 decision 분리이다.
- [x] NACK decision은 상태가 아니라 단일 NACK frame 처리 결과이다.
- [x] 상태 전이 자체는 기존 controller 흐름을 유지한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] primary NACK index 포함 테스트를 작성한다.
- [x] bitmap word 확장 테스트를 작성한다.
- [x] acknowledged chunk 제외 테스트를 작성한다.
- [x] 중복 제거와 정렬 테스트를 작성한다.
- [x] command 객체가 framework와 IO에 의존하지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 command 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 추가한다.
- [x] 실패하는 테스트를 확인한다.
- [x] NACK decision class와 command를 추가한다.
- [x] `_onDataNack`의 NACK bitmap 판단 분기를 command 사용으로 변경한다.
- [x] 계층 의존성을 확인한다.
- [x] 관련 테스트와 정적 분석을 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command 객체가 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] controller의 outgoing NACK 판단 책임이 줄었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingDataNackCommand`를 추가해 primary NACK index와 bitmap words를 retransmission index 목록으로 확장한다.
  - 이미 ACK된 chunk는 retransmission 대상에서 제외한다.
  - `_onDataNack`는 command 결과로 in-flight 제거, sentAt 제거, retransmission queueing만 수행한다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 추가: `lib/application/transfer/transfer_outgoing_data_nack_command.dart`
  - 추가: `test/application/transfer/transfer_outgoing_data_nack_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task011.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_data_nack_command_test.dart --reporter expanded`: 최초 command 파일 부재로 실패해 red phase 확인, 구현 후 6개 테스트 통과.
  - `dart format lib/application/transfer/transfer_outgoing_data_nack_command.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_outgoing_data_nack_command_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - command 객체는 framework, IO, transport, file service에 의존하지 않는다.
  - command는 입력 acknowledged set을 변경하지 않는다.
  - bitmap 확장, ACK 제외, 중복 제거, 정렬이 단위 테스트로 고정됐다.
- [x] 남은 위험 요소를 기록한다.
  - window update와 retransmission queue runner는 아직 controller 내부에 남아 있다.
  - outgoing session runner 상태 머신은 아직 추출되지 않았다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 DATA_WINDOW_UPDATE의 window clamp decision을 순수 command로 분리한다.

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

결정: `task012.md`를 생성한다. 범위는 DATA_WINDOW_UPDATE의 remote window start와 advertised window size clamp decision을 순수 command로 분리하는 것으로 제한한다.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
