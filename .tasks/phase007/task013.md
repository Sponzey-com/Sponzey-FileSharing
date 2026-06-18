# Task 013. Incoming DATA_FINISH readiness decision 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 DATA_FINISH 수신 시 완료 가능한지와 누락 chunk 요청 목록을 순수 command 객체로 분리하는 것이다.
- [x] 이 태스크는 controller가 수신 완료 readiness와 remaining missing index 계산을 직접 수행하는 책임을 줄인다.
- [x] 완료 후 `_onDataFinish`는 command decision으로 누락 NACK 또는 검증/finalize 경로를 선택한다.

## 2. Scope

### Included

- [x] `TransferIncomingDataFinishCommand`를 추가한다.
- [x] next expected chunk, expected chunk count, acknowledged chunks, buffered chunk 여부를 기준으로 ready 또는 waiting decision을 반환한다.
- [x] waiting decision에는 제한된 missing chunk indexes를 포함한다.
- [x] `_onDataFinish`가 command decision을 사용하도록 변경한다.

### Excluded

- [x] legacy Control `TRANSFER_COMPLETE` 경로는 변경하지 않는다.
- [x] digest 검증과 file finalize 동작은 변경하지 않는다.
- [x] NACK send 방식과 retry scheduling은 변경하지 않는다.

## 3. Functional Units

### Functional Unit 1

- [x] 구현할 기능: DATA_FINISH readiness를 계산한다.
- [x] 입력: next expected chunk, expected chunk count, acknowledged chunks, buffered chunk count, missing limit.
- [x] 출력: ready 또는 wait-for-missing decision.
- [x] 성공 조건: next expected가 expected count와 같고 buffered chunk가 없으면 ready이다.
- [x] 성공 조건: 완료 불가이면 missing indexes를 limit 이하로 반환한다.

### Functional Unit 2

- [x] 구현할 기능: `_onDataFinish`가 decision 결과만 기준으로 기존 부작용을 실행한다.
- [x] 입력: `DataFrameDatagram`.
- [x] 출력: 기존과 동일한 missing NACK 또는 digest/finalize 처리.
- [x] 성공 조건: 기존 transfer controller 회귀 테스트가 모두 통과한다.

## 4. Architecture Notes

- [x] command 객체는 `lib/application/transfer`에 둔다.
- [x] command 객체는 Flutter, Riverpod, dart:io, transport, file service에 의존하지 않는다.
- [x] command 객체는 private controller context 타입을 받지 않는다.
- [x] controller는 command 결과를 실행하는 orchestration만 담당한다.

## 5. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] complete ready 테스트를 작성한다.
- [x] missing indexes limit 테스트를 작성한다.
- [x] buffered chunk가 남아 있으면 waiting decision인 테스트를 작성한다.
- [x] command 객체가 framework와 IO에 의존하지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 command 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 6. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] command 객체가 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] controller의 DATA_FINISH readiness 판단 책임이 줄었다.

## 7. Completion Report

- [x] 수행한 변경 사항을 요약한다.

  - `TransferIncomingDataFinishCommand`를 추가해 DATA_FINISH readiness와 missing index decision을 분리했다.
  - `_onDataFinish`는 command 결과로 missing NACK 또는 digest/finalize 경로만 선택한다.
- [x] 생성하거나 수정한 파일을 기록한다.

  - 추가: `lib/application/transfer/transfer_incoming_data_finish_command.dart`
  - 추가: `test/application/transfer/transfer_incoming_data_finish_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task013.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.

  - `flutter test test/application/transfer/transfer_incoming_data_finish_command_test.dart --reporter expanded`: 최초 command 파일 부재로 실패해 red phase 확인, 구현 후 4개 테스트 통과.
  - `dart format lib/application/transfer/transfer_incoming_data_finish_command.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_incoming_data_finish_command_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.

  - command 객체는 framework, IO, transport, file service에 의존하지 않는다.
  - ready, missing limit, buffered remainder decision이 단위 테스트로 고정됐다.
  - 기존 transfer controller 회귀 테스트가 모두 통과한다.
- [x] 남은 위험 요소를 기록한다.

  - digest 검증, file finalize, failure ack 전송은 아직 controller 내부에 남아 있다.
  - incoming session runner 상태 머신은 아직 추출되지 않았다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.

  - 다음 태스크는 incoming finalize failure mapping 또는 writer/finalize boundary 분리 중 하나로 제한한다.

## 8. Next Task Decision Hook

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

결정: `task014.md`를 생성한다. 범위는 incoming finalize failure mapping을 별도 객체로 분리하는 것으로 제한한다.

## 9. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
