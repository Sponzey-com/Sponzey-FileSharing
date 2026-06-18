# Task 005. TRANSFER_INIT 수신 command boundary 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 `TRANSFER_INIT` 수신 packet의 필수 필드 검증과 peer id 계산을 `TransferController`에서 분리하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 3의 Control packet dispatcher 분리 중 command/result boundary를 만드는 단계에 기여한다.
- [x] 완료 후 `_onTransferInit`은 raw packet field를 직접 조합하지 않고 `TransferInitReceiveCommand`를 통해 수신 준비 절차를 시작한다.

## 2. Current Context

- [x] `task004.md`에서 Control packet type routing은 `TransferControlPacketDispatcher`로 분리되었다.
- [x] `_onTransferInit`은 아직 raw `AuthPacket`에서 transfer id, file name, file size, chunk count, peer id를 직접 추출한다.
- [x] field 검증과 file I/O, route 검증이 같은 메서드에 섞여 있어 후속 handler body 분리가 어렵다.
- [x] 이번 태스크는 packet-to-command boundary만 분리하고 file writer, route lease, data bind는 변경하지 않는다.

## 3. Scope

### Included

- [x] `TransferInitReceiveCommand` 값을 추가한다.
- [x] `TransferInitReceiveCommandResult`를 추가해 missing field를 명시적으로 표현한다.
- [x] `_onTransferInit`의 raw packet field 추출을 command boundary로 교체한다.

### Excluded

- [x] file draft 생성, writer open, data transport bind 이동은 제외한다.
- [x] route lease 검증 이동은 제외한다.
- [x] 인증 session lookup 이동은 제외한다.
- [x] wire protocol 변경은 제외한다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능: `TRANSFER_INIT` packet을 `TransferInitReceiveCommand`로 변환한다.
- [x] 입력: decoded `AuthPacket`.
- [x] 출력: transfer id, file name, file size, sha256, chunk count, packet peer id, display name, accepted chunk size, data auth context id.
- [x] 성공 조건: instance id가 있으면 `user@instance`, 없으면 `user@device` peer id를 만든다.
- [x] 실패 조건: raw packet field를 controller 곳곳에서 직접 조합한다.

### Functional Unit 2

- [x] 구현할 기능: 필수 transfer init field 누락을 result로 표현한다.
- [x] 입력: transfer id, file name, file size, chunk count 중 하나가 없는 packet.
- [x] 출력: invalid result와 reason code.
- [x] 성공 조건: controller는 invalid command를 처리하지 않고 return한다.
- [x] 실패 조건: null field가 뒤쪽 file I/O나 route 검증까지 흘러간다.

## 5. Architecture Notes

- [x] 변경 계층은 `lib/application/transfer`와 `test/application/transfer`로 제한한다.
- [x] command boundary는 Flutter, Riverpod, socket, file system, storage, platform API에 의존하지 않는다.
- [x] command boundary는 side effect 없이 packet field를 immutable command로 바꾼다.
- [x] `AuthPacket`은 현재 Control channel decoded packet model이므로 adapter seam으로만 사용한다.
- [x] 후속 태스크에서 controller private handler body를 더 작은 use case로 분리한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] command boundary는 AppConfig, port, platform state에 의존하지 않는다.
- [x] 프로세스 중간 환경 설정 변경은 없다.

## 7. Logging Requirements

### Product Log

- [x] command 변환 정상 동작에는 Product 로그를 추가하지 않는다.
- [x] 기존 transfer init 수신 로그는 유지한다.

### Field Debug Log

- [x] 이번 태스크에서는 packet별 debug 로그를 추가하지 않는다.
- [x] invalid reason은 result code로 테스트하고 로그 남발을 피한다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] 테스트는 command/result 값을 직접 검증한다.

## 8. State Machine Requirements

- [x] 이번 태스크는 command boundary 분리이며 새 상태 머신을 추가하지 않는다.
- [x] 수신 준비 상태 전이는 기존 job state transition을 유지한다.
- [x] invalid command는 상태 전이를 발생시키지 않는다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] complete transfer init packet이 command로 변환되는 테스트를 작성한다.
- [x] 필수 field 누락이 invalid result가 되는 테스트를 작성한다.
- [x] command boundary가 framework/IO adapter에 의존하지 않는 architecture guard를 작성한다.
- [x] 최소 구현으로 command 테스트를 통과시킨다.
- [x] controller가 command boundary를 사용하도록 변경한다.
- [x] 기존 transfer controller 회귀 테스트를 실행한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성한다.
- [x] 실패하는 테스트를 확인한다.
- [x] command/result class를 추가한다.
- [x] `_onTransferInit` raw field 추출을 command 사용으로 변경한다.
- [x] 기존 transfer init 로그와 ACK 동작이 유지되는지 확인한다.
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
- [x] invalid command가 상태 전이를 발생시키지 않는다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferInitReceiveCommand`와 `TransferInitReceiveCommandResult`를 추가했다.
  - `TRANSFER_INIT` 필수 field 검증, peer id 계산, display name fallback을 command boundary로 분리했다.
  - `_onTransferInit`은 command 값을 사용하도록 변경했고, 기존 `_peerIdFromPacket` helper는 제거했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_init_receive_command.dart`
  - 생성: `test/application/transfer/transfer_init_receive_command_test.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `.tasks/task005.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_init_receive_command_test.dart --reporter expanded`: 최초 구현 파일 부재로 실패해 red phase 확인, 구현 후 4개 테스트 통과.
  - `dart format lib/application/transfer/transfer_init_receive_command.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_init_receive_command_test.dart`: 통과.
  - `flutter analyze`: 최초 unused helper 경고 확인 후 제거, 재실행 통과.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - complete `TRANSFER_INIT` packet이 command로 변환된다.
  - instance id가 없으면 device id 기반 peer id로 fallback된다.
  - 필수 transfer field 누락은 invalid result가 된다.
  - command boundary는 Flutter, Riverpod, dart:io, file service, transport에 의존하지 않는다.
- [x] 남은 위험 요소를 기록한다.
  - `AuthPacket` infra model 의존은 아직 application command boundary에 남아 있다. 후속 단계에서 decoded packet port를 두면 더 깔끔해진다.
  - `_onTransferInit`의 file draft, writer, route, data bind 책임은 아직 controller에 남아 있다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 Data frame routing의 direction decision을 `TransferController`에서 분리해 Phase 4로 진입한다.

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

결정: `task006.md`를 생성한다. 범위는 Data frame type을 incoming/outgoing route로 분류하는 순수 dispatcher 첫 단계와 controller switch 통합으로 제한한다.

실행 결과: `task006.md`를 생성하고 즉시 실행했다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
