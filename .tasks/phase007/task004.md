# Task 004. Control packet routing dispatcher 첫 단계 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 `TransferController._handlePacket`에 있는 Control packet type routing 책임을 작은 application dispatcher로 분리하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 3 `Control packet dispatcher 분리`의 첫 단계에 기여한다.
- [x] 완료 후 `TransferController`는 `AuthPacketType`을 직접 업무 의미로 분류하지 않고 dispatcher의 route 결과를 기준으로 handler를 호출한다.

## 2. Current Context

- [x] `task003.md`에서 direction-aware session registry가 `TransferController`에 통합되었다.
- [x] 현재 `_handlePacket`은 `AuthPacketType` switch로 transfer control packet과 auth packet ignore 정책을 직접 소유한다.
- [x] Control packet routing이 controller에 남아 있으면 후속 use case/runner 분리 시 packet type별 책임을 테스트하기 어렵다.
- [x] 이번 태스크는 routing 분리만 수행하고 실제 transfer handler body는 옮기지 않는다.

## 3. Scope

### Included

- [x] `TransferControlPacketRoute` enum을 추가한다.
- [x] `TransferControlPacketDispatcher` 순수 application class를 추가한다.
- [x] `TransferController._handlePacket`이 dispatcher route 결과를 기준으로 switch하도록 변경한다.

### Excluded

- [x] `_onTransferInit`, `_onTransferChunk`, `_onTransferComplete` handler body 이동은 제외한다.
- [x] Data frame dispatcher 분리는 제외한다.
- [x] Control UDP transport, `AuthPacket`, wire protocol 변경은 제외한다.
- [x] MessageBus event 발행 변경은 제외한다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능: `AuthPacketType`을 transfer control route로 분류한다.
- [x] 입력: `AuthPacketType`.
- [x] 출력: `TransferControlPacketRoute`.
- [x] 성공 조건: transfer init, ack, chunk, nack, window, complete 계열은 명시적 route로 분류된다.
- [x] 실패 조건: auth handshake packet이 transfer handler로 라우팅된다.

### Functional Unit 2

- [x] 구현할 기능: `TransferController._handlePacket`이 dispatcher route를 사용한다.
- [x] 입력: `ControlDatagram`.
- [x] 출력: 기존과 동일한 handler 호출 또는 ignore.
- [x] 성공 조건: 기존 transfer controller 테스트가 모두 통과한다.
- [x] 실패 조건: routing 변경으로 기존 파일 전송, 수신 실패 처리, complete ack 처리가 깨진다.

## 5. Architecture Notes

- [x] 변경 계층은 `lib/application/transfer`와 `test/application/transfer`로 제한한다.
- [x] dispatcher는 socket, file system, Riverpod, Flutter에 의존하지 않는다.
- [x] dispatcher는 `AuthPacketType`만 입력으로 받고 side effect 없이 route enum을 반환한다.
- [x] controller는 route 결과에 따라 기존 private handler를 호출한다.
- [x] handler body 이동은 다음 태스크에서 별도 리뷰 단위로 수행한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] routing은 AppConfig, port, platform state에 의존하지 않는다.
- [x] 프로세스 중간 환경 설정 변경은 없다.

## 7. Logging Requirements

### Product Log

- [x] routing 정상 동작에는 Product 로그를 추가하지 않는다.
- [x] 기존 실패/사용자 영향 로그는 유지한다.

### Field Debug Log

- [x] 이번 태스크에서는 packet별 debug 로그를 추가하지 않는다.
- [x] 후속 dispatcher body 분리 시 summary 수준의 decision log만 검토한다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] 테스트는 route enum을 직접 검증한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 packet routing table 분리이며 새 상태 머신을 추가하지 않는다.
- [x] transfer job 상태 전이는 기존 `TransferJobStateMachine`을 그대로 사용한다.
- [x] route enum은 상태가 아니라 명령 분류 결과로만 사용한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] transfer control packet type 전체가 올바른 route로 매핑되는 테스트를 작성한다.
- [x] auth handshake packet type이 ignored route로 매핑되는 테스트를 작성한다.
- [x] dispatcher가 외부 의존성을 갖지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 dispatcher 테스트를 통과시킨다.
- [x] controller가 dispatcher를 사용하도록 변경한다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성한다.
- [x] 실패하는 테스트를 확인한다.
- [x] dispatcher class와 route enum을 추가한다.
- [x] `_handlePacket` switch를 route 기준으로 변경한다.
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
- [x] 복잡한 흐름이 플래그 조합이 아니라 명시적 route enum으로 표현되었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.

  - `TransferControlPacketRoute` enum과 `TransferControlPacketDispatcher`를 추가했다.
  - transfer control packet type과 auth handshake packet ignore 정책을 순수 dispatcher로 분리했다.
  - `TransferController._handlePacket`은 dispatcher route 결과를 기준으로 기존 handler를 호출하도록 변경했다.
- [x] 생성하거나 수정한 파일을 기록한다.

  - 생성: `lib/application/transfer/transfer_control_packet_dispatcher.dart`
  - 생성: `test/application/transfer/transfer_control_packet_dispatcher_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task004.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.

  - `flutter test test/application/transfer/transfer_control_packet_dispatcher_test.dart --reporter expanded`: 최초 구현 파일 부재로 실패해 red phase 확인, 구현 후 3개 테스트 통과.
  - `dart format lib/application/transfer/transfer_control_packet_dispatcher.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_control_packet_dispatcher_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.

  - transfer control packet type 전체가 명시적 route로 매핑된다.
  - auth handshake packet은 transfer handler가 아니라 ignored route로 매핑된다.
  - dispatcher는 Flutter, Riverpod, dart:io, ControlTransport, DataTransport에 의존하지 않는다.
  - 기존 송수신 controller 회귀 테스트가 모두 통과한다.
- [x] 남은 위험 요소를 기록한다.

  - handler body는 아직 controller 내부에 남아 있다.
  - Control command/result boundary와 session runner는 아직 분리되지 않았다.
  - Data frame dispatcher 분리는 아직 시작하지 않았다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.

  - 다음 태스크는 `transferInit`/`transferInitAck` 중심으로 control command boundary를 분리하거나, Data frame dispatcher의 direction decision을 분리하는 작업 중 하나를 선택해야 한다.

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

결정: 최종 목표에는 아직 도달하지 않았다. 다음 우선순위는 `task005.md`에서 Control handler body를 한 번에 옮기지 않고 `transferInit` 수신 준비 command/result boundary만 분리하는 것이다. 현재 turn에서는 task004 검증 완료 지점에서 중단한다.

실행 결과: 사용자 지시에 따라 중단하지 않고 `task005.md`를 생성한 뒤 즉시 실행했다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
