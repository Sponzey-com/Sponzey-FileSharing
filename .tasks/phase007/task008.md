# Task 008. Data frame route direction gate 추가

## 1. Task Purpose

- [x] 이 태스크의 목적은 Data frame action route마다 허용되는 transfer direction을 명시하는 것이다.
- [x] 이 태스크는 wrong-direction frame이 handler에 진입해 송신/수신 상태를 오염시키는 일을 막는다.
- [x] 완료 후 `_handleDataFrame`은 route를 계산한 뒤 session registry와 route direction을 검증하고, 검증된 frame만 handler에 전달한다.

## 2. Current Context

- [x] `task007.md`에서 Data frame route가 구체 action route로 분리되었다.
- [x] 현재 `_handleDataFrame`은 transferId만 찾으면 frame trace를 기록하고 handler를 호출한다.
- [x] 같은 transferId가 잘못된 direction frame으로 들어오면 controller 내부 handler가 방어해야 하므로 책임이 분산된다.

## 3. Scope

### Included

- [x] `TransferDataFrameRoute`에 expected transfer direction을 추가한다.
- [x] `_handleDataFrame`에 route/session gate를 추가한다.
- [x] dispatcher test와 controller source guard로 direction gate를 고정한다.

### Excluded

- [x] handler body를 별도 runner로 이동하지 않는다.
- [x] Data channel protocol packet format을 변경하지 않는다.
- [x] retransmission, window, ACK/NACK 알고리즘은 변경하지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능: Data frame action route별 expected direction을 반환한다.
- [x] 입력: `TransferDataFrameRoute`.
- [x] 출력: `TransferDirection.incoming` 또는 `TransferDirection.outgoing`.
- [x] 성공 조건: DATA_START, DATA_CHUNK, DATA_FINISH, DATA_ABORT는 incoming route로 분류된다.
- [x] 성공 조건: DATA_ACK, DATA_NACK, DATA_WINDOW_UPDATE는 outgoing route로 분류된다.

### Functional Unit 2

- [x] 구현할 기능: `_handleDataFrame`이 route/session gate를 통과한 frame만 처리한다.
- [x] 입력: `DataFrameDatagram`.
- [x] 출력: 허용된 direction이면 기존 handler 호출, 아니면 no-op.
- [x] 성공 조건: incoming route는 incoming session이 있을 때만 처리된다.
- [x] 성공 조건: outgoing route는 outgoing session이 있을 때만 처리된다.

## 5. Architecture Notes

- [x] 변경 계층은 `lib/application/transfer`와 `test/application/transfer`로 제한한다.
- [x] dispatcher는 side effect 없이 route metadata만 제공한다.
- [x] session 존재 여부 판단은 controller의 registry helper를 통해 수행한다.
- [x] UI, socket, file I/O, codec은 변경하지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] direction gate는 런타임 설정으로 바꾸지 않는다.
- [x] 테스트는 숨겨진 환경 변경 없이 코드와 public behavior만 검증한다.

## 7. Logging Requirements

### Product Log

- [x] wrong-direction frame no-op에는 Product 로그를 추가하지 않는다.
- [x] 사용자 영향 실패 메시지는 기존 경로를 유지한다.

### Field Debug Log

- [x] 이번 태스크에서는 frame별 debug 로그를 추가하지 않는다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] 검증은 테스트와 source guard로 수행한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 state transition 추가가 아니라 handler 진입 전 guard 추가이다.
- [x] 잘못된 direction frame은 상태 전이를 발생시키지 않는 no-op으로 처리한다.
- [x] 추후 task에서 session runner 상태 머신으로 이동할 때 이 gate를 선행 조건으로 유지한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] 모든 Data frame route의 expected direction 테스트를 작성한다.
- [x] controller에 route/session gate helper가 존재하는 source guard를 작성한다.
- [x] 최소 구현으로 dispatcher 테스트를 통과시킨다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 수정한다.
- [x] 실패하는 테스트를 확인한다.
- [x] `TransferDataFrameRoute.expectedDirection`을 추가한다.
- [x] `_hasDataFrameRouteContext` helper를 controller에 추가한다.
- [x] `_handleDataFrame`에서 trace 기록과 handler 호출 전에 gate를 수행한다.
- [x] 계층 간 의존성을 확인한다.
- [x] 관련 테스트와 정적 분석을 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 위반이 없다.
- [x] wrong-direction frame이 handler 호출 전에 차단된다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferDataFrameRoute.expectedDirection`을 추가해 route별 허용 direction을 명시했다.
  - `_hasDataFrameRouteContext`를 추가해 incoming route는 incoming registry, outgoing route는 outgoing registry가 있을 때만 처리한다.
  - `_handleDataFrame`에서 trace 기록과 handler 호출 전에 route/session gate를 수행한다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 수정: `lib/application/transfer/transfer_data_frame_dispatcher.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `test/application/transfer/transfer_data_frame_dispatcher_test.dart`
  - 수정: `.tasks/task008.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_data_frame_dispatcher_test.dart --reporter expanded`: 최초 `expectedDirection` 부재로 실패해 red phase 확인, 구현 후 5개 테스트 통과.
  - `dart format lib/application/transfer/transfer_data_frame_dispatcher.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_data_frame_dispatcher_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - Data frame route별 expected direction이 명확하다.
  - controller는 `route.expectedDirection` 기준으로 registry lookup을 수행한다.
  - wrong-direction frame은 handler 호출 전에 no-op 처리된다.
- [x] 남은 위험 요소를 기록한다.
  - handler body와 파일 쓰기, ACK/NACK 부작용은 아직 controller 내부에 남아 있다.
  - direction gate는 source guard와 기존 회귀 테스트로 고정했으며, 전용 runtime wrong-direction 테스트는 추후 session runner 분리 후 추가한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 수신 Data chunk decision을 순수 command 객체로 분리해 controller handler의 분기 책임을 줄인다.

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

결정: `task009.md`를 생성한다. 범위는 수신 Data chunk의 out-of-range, duplicate, in-order, out-of-order 판단을 순수 command 객체로 분리하고 controller가 그 결과만 실행하도록 제한한다.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
