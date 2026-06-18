# Task 001. 책임 지도와 baseline gate 고정

## 1. Task Purpose

- [x] 이 태스크의 목적은 현재 `TransferController`에 집중된 송신, 수신, Control packet, Data frame, file I/O, route 검증, progress projection 책임을 기능 변경 없이 분류하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 Phase 1인 "책임 지도와 baseline gate 고정"에 직접 기여한다.
- [x] 완료 후 프로젝트는 후속 dispatcher, registry, session runner 분리를 시작하기 전에 현재 동작을 보호하는 baseline 테스트와 책임 지도를 가진다.

## 2. Current Context

- [x] 현재 루트 계획은 송수신 안정성 향상을 위해 `TransferFacadeController`, `TransferControlPacketDispatcher`, `TransferDataFrameDispatcher`, `OutgoingTransferSessionRunner`, `IncomingTransferSessionRunner`, `TransferSessionRegistry`, `TransferRouteGuard`로 책임을 분리하는 방향이다.
- [x] 이전 태스크는 없다. 이 태스크가 현재 plan 루프의 시작 태스크다.
- [x] 현재 `TransferController`는 `ControlTransport.packets`와 `DataTransport.frames`를 직접 구독하고, 송신/수신 context map, timers, file service, route validation, UI job projection을 함께 소유한다.
- [x] `.tasks/`는 `.gitignore` 대상이므로 태스크 문서는 commit 대상에 포함하려면 별도 강제 add가 필요하다.
- [x] 현재 작업은 behavior-preserving characterization이 우선이며 대규모 계층 이동은 금지한다.

### Current Responsibility Map

- [x] Subscription ownership: `TransferController` owns `_packetSubscription` and `_dataFrameSubscription`.
- [x] Mutable session maps: `TransferController` owns `_outgoingTransfers`, `_incomingTransfers`, and `_transferIdByFrameKey`.
- [x] User command entry: `sendFile`, `sendFiles`, and `sendFileToPeers` live in `TransferController`.
- [x] Control packet dispatch: `_handlePacket` switches `transferInit`, `transferInitAck`, `transferChunk`, `transferChunkAck`, `transferChunkNack`, `transferWindowUpdate`, `transferComplete`, and `transferCompleteAck`.
- [x] Data frame dispatch: `_handleDataFrame` switches `dataStart`, `dataChunk`, `dataAck`, `dataNack`, `dataWindowUpdate`, `dataFinish`, and `dataAbort`.
- [x] Outgoing responsibilities: `_runOutgoingTransfer`, `_pumpOutgoingWindow`, retransmission scanning, ACK/NACK handling, window update, finish wait, outgoing digest close.
- [x] Incoming responsibilities: `_onTransferInit`, `_onDataChunk`, `_onDataFinish`, incoming draft cleanup, ACK batching, NACK retry, writer close/finalize.
- [x] File I/O ownership: outgoing metadata preparation, incoming draft preparation, writer open, chunk append, temp discard, finalize, and checksum calls are initiated from `TransferController`.
- [x] Route validation ownership: active route snapshot, remote data endpoint validation, data bind endpoint validation, observed incoming path recovery, route lease active check are initiated from `TransferController`.
- [x] Progress projection ownership: `_updateJob`, `_updateOutgoingMetrics`, `_updateIncomingMetrics`, and transfer history persistence are initiated from `TransferController`.
- [x] Logging ownership: transfer control/data/storage logs are emitted directly from `TransferController`; packet-level product logging has already been reduced in transport/controller paths.

### Baseline Tests Identified

- [x] `sends and receives a single file between authenticated peers`.
- [x] `handles simultaneous bidirectional file transfers`.
- [x] `fails before data chunks when data bind local address differs from route lease`.
- [x] `receiver temp draft failure rejects transfer init before data starts`.
- [x] `receiver data chunk write failure notifies sender and classifies storage`.
- [x] `does not send file chunks through the Control channel`.
- [x] `batches Data channel ACK frames below chunk count`.
- [x] `reports incoming progress from contiguous written chunks while buffering out-of-order data`.
- [x] `does not emit packet-level product logs for Data channel chunks`.
- [x] `does not emit transfer metric debug logs during noisy delivery`.
- [x] Added in this task: `ignores unknown Data channel frames without creating transfer job`.

## 3. Scope

### Included

- [x] `TransferController` 책임 지도 작성.
- [x] 기존 transfer baseline 테스트 목록 정리.
- [x] 누락된 baseline characterization test 1개 이상 추가.

### Excluded

- [x] `TransferControlPacketDispatcher` 구현은 제외한다.
- [x] `TransferDataFrameDispatcher` 구현은 제외한다.
- [x] outgoing/incoming registry 분리는 후속 태스크로 넘긴다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능: 현재 transfer 책임 지도를 task 문서에 기록한다.
- [x] 입력: `.tasks/plan.md`, `AGENTS.md`, `lib/application/transfer/transfer_controller.dart`, 관련 transfer 테스트.
- [x] 출력: 송신, 수신, control, data, file I/O, route, logging, state 후보 목록.
- [x] 성공 조건: 후속 개발자가 어느 책임을 어떤 Phase에서 분리해야 하는지 확인할 수 있다.
- [x] 실패 조건: 단순 파일 목록만 있고 실제 책임 소유 위치가 드러나지 않는다.

### Functional Unit 2

- [x] 구현할 기능: 기존 baseline 테스트와 누락된 characterization gap을 정리한다.
- [x] 입력: `test/application/transfer/transfer_controller_test.dart`, `test/domain/transfer`, `test/infrastructure/transfer_data`.
- [x] 출력: 현재 보호되는 behavior 목록과 추가해야 할 baseline test.
- [x] 성공 조건: 양방향 전송, route mismatch, storage failure, log suppression, unknown frame discard 중 최소 2개 이상 baseline이 확인된다.
- [x] 실패 조건: 후속 리팩터링 시 어떤 behavior를 보존해야 하는지 알 수 없다.

### Functional Unit 3

- [x] 구현할 기능: unknown DataFrame이 새 transfer job/session을 만들지 않는 characterization test를 추가한다.
- [x] 입력: fake `DataTransport.frames`에 등록되지 않은 transfer id의 `DataFrame`.
- [x] 출력: transfer jobs가 생성되지 않고 Product 로그가 발생하지 않는 테스트.
- [x] 성공 조건: unknown data frame이 no-op으로 처리되고 후속 `TransferDataFrameDispatcher` 분리의 기준이 된다.
- [x] 실패 조건: unknown data frame이 transfer job을 만들거나 사용자 영향 로그를 남긴다.

## 5. Architecture Notes

- [x] 변경되는 계층은 `test/application`과 `.tasks` 문서로 제한한다.
- [x] 도메인, 유스케이스, 어댑터, 인프라 책임을 구분한다.
- [x] 의존성 방향이 안쪽으로 향하는지 확인한다.
- [x] 외부 시스템 접근이 경계 계층에만 위치하는지 확인한다.
- [x] 이번 태스크에서는 새 production interface, port, adapter를 정의하지 않는다.
- [x] 전역 상태, 숨겨진 I/O, 암묵적 설정 접근을 추가하지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일 의존을 최소화한다.
- [x] 환경 값은 프로그램 시작 시 최초 1회만 수신한다.
- [x] 최초 수신 이후에는 환경 값을 전역 상수처럼 사용하지 않는다.
- [x] 환경 값은 명시적 인자, 생성자 인자, 컨텍스트 객체, 의존성 주입으로 전달한다.
- [x] 프로세스 중간에 환경 설정 값을 삽입하거나 변경하지 않는다.
- [x] 런타임 중간 재설정, 동적 환경 변경, 숨겨진 설정 조회를 금지한다.

## 7. Logging Requirements

### Product Log

- [x] 운영에 필요한 최소 로그만 정의한다.
- [x] 사용자 영향, 핵심 상태 변화, 장애 원인 추적에 필요한 정보만 포함한다.
- [x] 민감 정보와 과도한 내부 상태를 기록하지 않는다.

### Field Debug Log

- [x] 현장 확인용 디버그 로그가 필요한지 판단한다.
- [x] 필요한 경우 활성화 조건을 정의한다.
- [x] 민감 정보 마스킹 기준을 정의한다.
- [x] 보존 범위와 사용 범위를 제한한다.

### Development Log

- [x] 개발 및 테스트 중 확인할 로그를 정의한다.
- [x] 프로덕션 기본 동작에 포함되지 않도록 한다.
- [x] 테스트 완료 후 제거 또는 비활성화 기준을 정의한다.

## 8. State Machine Requirements

- [x] 상태머신이 필요한지 판단한다.
- [x] 복잡한 내부 흐름을 암묵적 플래그 조합으로 관리하지 않는다.
- [x] 필요한 경우 상태 목록을 정의한다.
- [x] 필요한 경우 이벤트 목록을 정의한다.
- [x] 필요한 경우 전이 조건을 정의한다.
- [x] 필요한 경우 실패 상태와 종료 상태를 정의한다.
- [x] 상태 전이를 테스트 가능하게 만든다.

### State Machine Candidates Found

- [x] Outgoing transfer: `preparing -> awaitingAcceptance -> sending -> verifying -> completed|failed|rejected|cancelled`.
- [x] Incoming transfer: `awaitingAcceptance -> receiving -> verifying -> completed|failed|rejected|cancelled`.
- [x] Data frame receive readiness: current code must ignore unknown transfer ids and reject chunks before incoming context exists.
- [x] Registry lifecycle: current `_outgoingTransfers` and `_incomingTransfers` maps need explicit direction-aware lifecycle in the next task.
- [x] Timer lifecycle: retransmission, backpressure retry, ACK flush, missing NACK retry timers need session-owned cleanup in later runner phases.

## 9. TDD Plan

- [ ] 실패하는 테스트를 먼저 작성한다.

  - [x] Characterization test를 production 변경 전에 먼저 작성했다.
  - [ ] 이 test는 현재 구현이 이미 요구 동작을 만족하여 red phase 없이 통과했다.
- [x] 테스트 대상 유스케이스를 정의한다.
- [x] 정상 케이스 테스트를 작성한다.
- [x] 실패 케이스 테스트를 작성한다.
- [x] 경계값 테스트를 작성한다.
- [x] 외부 의존성은 테스트 더블로 대체한다.
- [x] 설정 값 전달 방식 테스트를 작성한다.
- [x] 로그 정책 검증 테스트를 작성한다.
- [x] 상태 전이가 있다면 상태 전이 테스트를 작성한다.
- [x] 테스트를 통과하는 최소 구현만 작성한다.
- [x] 테스트 통과 후 구조를 정리한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성한다.
- [ ] 실패하는 테스트를 확인한다.

  - [x] Characterization test는 추가 즉시 통과했다.
  - [ ] production behavior 변경이 없으므로 red phase는 발생하지 않았다.
- [x] 최소 구현을 작성한다.

  - [x] production 구현 변경은 필요하지 않았다.
- [x] 계층 간 의존성을 확인한다.
- [x] 외부 의존성이 경계 계층에만 있는지 확인한다.
- [x] 설정 값 전달 방식이 명시적인지 확인한다.
- [x] 필요한 로그를 정책에 맞게 추가한다.

  - [x] 새 로그는 추가하지 않았다.
- [x] 상태 관리가 필요한 경우 명시적 상태 전이로 구현한다.

  - [x] 이번 태스크에서는 production 상태 전이를 추가하지 않고 후보만 기록했다.
- [x] 중복과 구조 문제를 정리한다.
- [x] 모든 테스트를 실행한다.

  - [x] 이번 태스크 범위의 transfer controller 테스트를 실행했다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다.
- [ ] 실패 테스트가 먼저 작성되었다.

  - [x] Characterization test는 production 변경 전에 작성되었고 통과했다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 유스케이스가 명시적 입력과 출력을 가진다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 외부 환경 값이 전역 상수처럼 사용되지 않는다.
- [x] 로그가 Product Log, Field Debug Log, Development Log 기준에 맞게 분리되었다.
- [x] 개발용 로그가 프로덕션 기본 동작에 포함되지 않는다.
- [x] 복잡한 흐름이 플래그 조합이 아니라 명시적 상태로 표현되었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [ ] 수행한 변경 사항을 요약한다.
- [ ] 생성하거나 수정한 파일을 기록한다.
- [ ] 실행한 테스트 명령과 결과를 기록한다.
- [ ] 검증한 항목을 기록한다.
- [ ] 남은 위험 요소를 기록한다.
- [ ] 후속 태스크에서 이어받아야 할 내용을 기록한다.

### Completion Notes

- [x] 수행한 변경 사항:

  - [x] `TransferController`의 현재 책임 지도를 문서화했다.
  - [x] 후속 분리 작업에서 보존해야 할 transfer baseline 테스트를 정리했다.
  - [x] unknown Data channel frame이 transfer job을 만들지 않고 Product 로그를 남기지 않는 characterization test를 추가했다.
- [x] 생성하거나 수정한 파일:

  - [x] `.tasks/task001.md`
  - [x] `test/application/transfer/transfer_controller_test.dart`
- [x] 실행한 테스트 명령과 결과:

  - [x] `flutter test test/application/transfer/transfer_controller_test.dart --name "ignores unknown Data channel frames without creating transfer job" --reporter expanded` 통과.
  - [x] `flutter analyze` 통과.
  - [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact` 통과.
- [x] 검증한 항목:

  - [x] fake `DataTransport`를 사용해 외부 UDP 의존 없이 테스트했다.
  - [x] 테스트 config는 provider override와 명시 인자로 주입했다.
  - [x] unknown frame 수신이 transfer job을 생성하지 않음을 확인했다.
  - [x] unknown frame 수신이 transfer control/data Product 로그를 남기지 않음을 확인했다.
- [x] 남은 위험 요소:

  - [x] `TransferController`는 여전히 송신/수신 registry를 mutable map으로 직접 소유한다.
  - [x] `_transferIdByFrameKey`는 direction 정보를 포함하지 않는다.
  - [x] packet/frame dispatch와 file I/O가 아직 같은 controller에 있다.
- [x] 후속 태스크에서 이어받아야 할 내용:

  - [x] 다음 우선순위는 `TransferSessionKey`와 direction-aware registry의 순수 모델 및 테스트를 만드는 것이다.

## 13. Next Task Decision Hook

이 태스크 완료 후 반드시 다음 판단을 수행한다.

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.

  - [x] 아직 최종 목표에 도달하지 못했다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [ ] 다음 태스크를 `taskXXX.md`로 생성한다.
- [ ] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

### Next Task Decision

- [x] 최종 목표 달성 여부: 미달성. dispatcher, session runner, registry 분리가 아직 구현되지 않았다.
- [x] 남은 목표 중 최우선 작업: `TransferSessionKey`와 direction-aware registry 도입.
- [x] 우선순위 근거: 현재 `_outgoingTransfers`, `_incomingTransfers`, `_transferIdByFrameKey`가 분리되어 있지만 lookup key가 direction-aware가 아니므로 후속 dispatcher 분리 전에 session identity를 먼저 고정해야 한다.
- [x] 다음 파일명: `.tasks/task002.md`.
- [x] 다음 범위: production integration 전에 순수 key/registry 모델과 테스트를 만든다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.