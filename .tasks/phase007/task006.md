# Task 006. Data frame routing dispatcher 첫 단계 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 `TransferController._handleDataFrame`에 있는 Data frame type routing과 direction decision을 작은 application dispatcher로 분리하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 4 `Data frame dispatcher 분리`의 첫 단계에 기여한다.
- [x] 완료 후 Data frame type은 명시적 route enum으로 분류되고, controller는 route 결과에 따라 기존 handler를 호출한다.

## 2. Current Context

- [x] `task003.md`에서 direction-aware session registry가 controller에 통합되었다.
- [x] `task004.md`에서 Control packet type routing은 dispatcher로 분리되었다.
- [x] 현재 `_handleDataFrame`은 `DataFrameType` switch를 직접 소유한다.
- [x] DATA_CHUNK와 DATA_ACK가 서로 다른 direction session을 수정해야 하므로 direction decision을 먼저 분리해야 한다.

## 3. Scope

### Included

- [x] `TransferDataFrameRoute` enum을 추가한다.
- [x] `TransferDataFrameDispatcher` 순수 application class를 추가한다.
- [x] `_handleDataFrame` switch가 Data frame route를 사용하도록 변경한다.

### Excluded

- [x] `_onDataChunk`, `_onDataAck`, `_onDataFinish` handler body 이동은 제외한다.
- [x] Data session runner 추출은 제외한다.
- [x] UDP frame format, codec, socket transport 변경은 제외한다.
- [x] retransmission, ACK/NACK algorithm 변경은 제외한다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능: `DataFrameType`을 incoming/outgoing route로 분류한다.
- [x] 입력: `DataFrameType`.
- [x] 출력: `TransferDataFrameRoute`.
- [x] 성공 조건: DATA_CHUNK/START/FINISH/ABORT는 incoming route, ACK/NACK/WINDOW_UPDATE는 outgoing route로 분류된다.
- [x] 실패 조건: ACK가 incoming context를 수정하거나 CHUNK가 outgoing context를 수정한다.

### Functional Unit 2

- [x] 구현할 기능: `_handleDataFrame`이 route enum을 사용한다.
- [x] 입력: `DataFrameDatagram`.
- [x] 출력: 기존과 동일한 handler 호출 또는 ignore.
- [x] 성공 조건: 기존 transfer controller 테스트가 모두 통과한다.
- [x] 실패 조건: routing 변경으로 송수신, ACK, NACK, finish 처리 흐름이 깨진다.

## 5. Architecture Notes

- [x] 변경 계층은 `lib/application/transfer`와 `test/application/transfer`로 제한한다.
- [x] dispatcher는 Flutter, Riverpod, socket, file system에 의존하지 않는다.
- [x] dispatcher는 decoded frame type만 입력으로 받고 side effect 없이 route enum을 반환한다.
- [x] controller는 route 결과에 따라 기존 private handler를 호출한다.
- [x] handler body 이동은 후속 태스크에서 별도 리뷰 단위로 수행한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] routing은 AppConfig, tuning policy, platform state에 의존하지 않는다.
- [x] 프로세스 중간 환경 설정 변경은 없다.

## 7. Logging Requirements

### Product Log

- [x] routing 정상 동작에는 Product 로그를 추가하지 않는다.
- [x] 기존 실패/사용자 영향 로그는 유지한다.

### Field Debug Log

- [x] 이번 태스크에서는 frame별 debug 로그를 추가하지 않는다.
- [x] 후속 dispatcher body 분리 시 summary 수준의 decision log만 검토한다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] 테스트는 route enum을 직접 검증한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 frame routing table 분리이며 새 상태 머신을 추가하지 않는다.
- [x] transfer job 상태 전이는 기존 `TransferJobStateMachine`을 그대로 사용한다.
- [x] route enum은 상태가 아니라 frame 분류 결과로만 사용한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] incoming Data frame type 전체가 incoming route로 매핑되는 테스트를 작성한다.
- [x] outgoing Data frame type 전체가 outgoing route로 매핑되는 테스트를 작성한다.
- [x] dispatcher가 외부 의존성을 갖지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 dispatcher 테스트를 통과시킨다.
- [x] controller가 dispatcher를 사용하도록 변경한다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성한다.
- [x] 실패하는 테스트를 확인한다.
- [x] dispatcher class와 route enum을 추가한다.
- [x] `_handleDataFrame` switch를 route 기준으로 변경한다.
- [x] 기존 handler 호출 결과가 바뀌지 않았는지 확인한다.
- [x] 계층 간 의존성을 확인한다.
- [x] 설정과 로그 정책 위반이 없는지 확인한다.
- [x] 관련 테스트와 정적 분석을 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 유스케이스가 명시적 입력과 출력을 가진다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 외부 환경 값이 전역 상수처럼 사용되지 않는다.
- [x] 로그가 Product Log, Field Debug Log, Development Log 기준에 맞게 분리되었다.
- [x] 개발용 로그가 프로덕션 기본 동작에 포함되지 않는다.
- [x] frame direction decision이 명시적 route enum으로 표현되었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferDataFrameRoute` enum과 `TransferDataFrameDispatcher`를 추가했다.
  - Data frame type을 incoming/outgoing route로 분류했다.
  - `_handleDataFrame`이 dispatcher route 결과를 기준으로 기존 handler를 호출하도록 변경했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_data_frame_dispatcher.dart`
  - 생성: `test/application/transfer/transfer_data_frame_dispatcher_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task006.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_data_frame_dispatcher_test.dart --reporter expanded`: 최초 구현 파일 부재로 실패해 red phase 확인, 구현 후 3개 테스트 통과.
  - `dart format lib/application/transfer/transfer_data_frame_dispatcher.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_data_frame_dispatcher_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - DATA_START, DATA_CHUNK, DATA_FINISH, DATA_ABORT는 incoming route로 분류된다.
  - DATA_ACK, DATA_NACK, DATA_WINDOW_UPDATE는 outgoing route로 분류된다.
  - dispatcher는 Flutter, Riverpod, dart:io, file service, transport에 의존하지 않는다.
  - 기존 송수신 회귀 테스트가 모두 통과한다.
- [x] 남은 위험 요소를 기록한다.
  - `_handleDataFrame` 안에 route별 nested `DataFrameType` switch가 아직 남아 있다.
  - handler body는 아직 controller 내부에 남아 있다.
  - route enum이 incoming/outgoing 2분류라 구체 action route까지는 분리되지 않았다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 `TransferDataFrameRoute`를 구체 action route로 확장해 `_handleDataFrame`에서 `DataFrameType` switch를 제거한다.

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

결정: `task007.md`를 생성한다. 범위는 Data frame route를 구체 action route로 확장하고 `_handleDataFrame`의 nested `DataFrameType` switch를 제거하는 것으로 제한한다.

실행 결과: `task007.md`를 생성하고 즉시 실행했다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
