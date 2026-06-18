# Task 012. Outgoing DATA_WINDOW_UPDATE decision 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 DATA_WINDOW_UPDATE frame의 remote window 적용 값을 순수 command 객체로 분리하는 것이다.
- [x] 이 태스크는 controller가 advertised window size clamp 판단을 직접 수행하는 책임을 줄인다.
- [x] 완료 후 `_onDataWindowUpdate`는 command decision 결과를 context에 반영하고 outgoing pump만 예약한다.

## 2. Current Context

- [x] `task011.md`에서 DATA_NACK decision이 분리되었다.
- [x] 현재 `_onDataWindowUpdate`는 `remoteWindowStart`와 `advertisedWindowSize`를 직접 계산하고 context에 쓴다.
- [x] window update 판단을 분리하면 outgoing session runner 추출 시 flow-control 입력 처리를 독립 테스트할 수 있다.

## 3. Scope

### Included

- [x] `TransferOutgoingWindowUpdateCommand`를 추가한다.
- [x] `windowStart`와 최소 1로 clamp된 `advertisedWindowSize`를 decision으로 반환한다.
- [x] `_onDataWindowUpdate`가 command decision을 사용하도록 변경한다.

### Excluded

- [x] pump scheduling과 window growth/shrink 알고리즘은 변경하지 않는다.
- [x] ACK/NACK handling은 변경하지 않는다.
- [x] protocol frame format은 변경하지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능: remote window update decision을 계산한다.
- [x] 입력: frame window start, frame window size.
- [x] 출력: remote window start, advertised window size.
- [x] 성공 조건: window size가 1보다 작으면 1로 clamp된다.
- [x] 성공 조건: window start는 입력값을 그대로 유지한다.

### Functional Unit 2

- [x] 구현할 기능: `_onDataWindowUpdate`가 decision 결과만 기준으로 outgoing context를 갱신한다.
- [x] 입력: `DataFrameDatagram`.
- [x] 출력: 기존과 동일한 remote window update와 pump scheduling.
- [x] 성공 조건: 기존 transfer controller 회귀 테스트가 모두 통과한다.

## 5. Architecture Notes

- [x] command 객체는 `lib/application/transfer`에 둔다.
- [x] command 객체는 Flutter, Riverpod, dart:io, transport, file service에 의존하지 않는다.
- [x] command 객체는 private controller context 타입을 받지 않는다.
- [x] controller는 command 결과를 실행하는 orchestration만 담당한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] window clamp 기준은 command 내부의 프로토콜 안전 규칙으로 고정한다.
- [x] 테스트는 숨겨진 환경 변경 없이 순수 입력과 출력만 검증한다.

## 7. Logging Requirements

### Product Log

- [x] 정상 window update decision에는 Product 로그를 추가하지 않는다.

### Field Debug Log

- [x] 이번 태스크에서는 debug 로그를 추가하지 않는다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] window update decision 동작은 단위 테스트로 검증한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 송신 session 상태 머신 추출 전의 decision 분리이다.
- [x] window update decision은 상태가 아니라 단일 frame 처리 결과이다.
- [x] 상태 전이 자체는 기존 controller 흐름을 유지한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] positive window size 유지 테스트를 작성한다.
- [x] zero 또는 negative window size clamp 테스트를 작성한다.
- [x] command 객체가 framework와 IO에 의존하지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 command 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 추가한다.
- [x] 실패하는 테스트를 확인한다.
- [x] window update decision class와 command를 추가한다.
- [x] `_onDataWindowUpdate`의 window size clamp 분기를 command 사용으로 변경한다.
- [x] 계층 의존성을 확인한다.
- [x] 관련 테스트와 정적 분석을 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command 객체가 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] controller의 window update 판단 책임이 줄었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferOutgoingWindowUpdateCommand`를 추가해 remote window start와 advertised window size clamp decision을 분리했다.
  - `_onDataWindowUpdate`는 command 결과를 context에 반영하고 pump만 예약한다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 추가: `lib/application/transfer/transfer_outgoing_window_update_command.dart`
  - 추가: `test/application/transfer/transfer_outgoing_window_update_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task012.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_outgoing_window_update_command_test.dart --reporter expanded`: 최초 command 파일 부재로 실패해 red phase 확인, 구현 후 3개 테스트 통과.
  - `dart format lib/application/transfer/transfer_outgoing_window_update_command.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_outgoing_window_update_command_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - command 객체는 framework, IO, transport, file service에 의존하지 않는다.
  - window size가 1 미만일 때 1로 clamp된다.
  - 기존 transfer controller 회귀 테스트가 모두 통과한다.
- [x] 남은 위험 요소를 기록한다.
  - outgoing pump, retransmission timer, file reader는 아직 controller context에 남아 있다.
  - 수신 finalize와 integrity verification decision은 아직 controller 내부에 남아 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 수신 완료 readiness와 missing chunk decision을 순수 객체로 분리한다.

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

결정: `task013.md`를 생성한다. 범위는 수신 DATA_FINISH 처리 전 readiness와 missing chunk decision을 순수 객체로 분리하는 것으로 제한한다.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
