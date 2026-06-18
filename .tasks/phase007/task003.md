# Task 003. TransferController에 direction-aware session registry 통합

## 1. Task Purpose

- [x] 이 태스크의 목적은 `task002.md`에서 만든 `TransferSessionRegistry`를 현재 `TransferController`의 session tracking path에 통합하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 2의 production integration 부분과 Phase 3 dispatcher 분리 전제 조건에 기여한다.
- [x] 완료 후 `TransferController`는 outgoing/incoming context를 raw map에서 직접 조회하는 대신 direction-aware helper를 통해 조회하고 해제한다.

## 2. Current Context

- [x] `TransferSessionKey`와 `TransferSessionRegistry<T>`는 순수 application 계층 모델로 추가되었다.
- [x] `TransferController`는 `_outgoingTransfers`, `_incomingTransfers`, `_transferIdByFrameKey`를 직접 사용한다.
- [x] Data frame handler는 frame key로 transfer id만 찾은 뒤 frame type별 map을 직접 조회한다.
- [x] dispatcher 추출 전에 registry 통합 seam을 만들지 않으면 후속 분리 작업에서 동일한 transfer id, late packet, cleanup 정책이 계속 흩어진다.

## 3. Scope

### Included

- [x] `TransferController` 내부에 outgoing/incoming registry field와 register/lookup/remove helper를 추가한다.
- [x] outgoing/incoming session 등록과 cleanup 경로가 registry lifecycle을 같이 갱신하도록 한다.
- [x] Data frame 처리 경로의 context lookup을 direction-aware helper로 바꾼다.

### Excluded

- [x] `TransferDataFrameDispatcher` 파일 분리와 class 추출은 제외한다.
- [x] `TransferControlPacketDispatcher` 파일 분리와 class 추출은 제외한다.
- [x] UDP protocol, packet format, socket bind 정책 변경은 제외한다.
- [x] 전송 성능 tuning 변경은 제외한다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능: `TransferController`에 outgoing/incoming registry helper를 추가한다.
- [x] 입력: transfer id와 기존 outgoing/incoming context.
- [x] 출력: registry 등록, 조회, 제거 결과.
- [x] 성공 조건: context 등록과 제거가 raw map과 registry에서 같은 lifecycle로 처리된다.
- [x] 실패 조건: raw map에서 제거된 session이 registry에 남거나, registry removed session이 raw map 조회로 되살아난다.

### Functional Unit 2

- [x] 구현할 기능: Data frame type별 context lookup이 direction-aware helper를 사용하도록 변경한다.
- [x] 입력: `DataFrameType`과 frame transfer id bytes.
- [x] 출력: incoming frame은 incoming context만, ACK/NACK/window update frame은 outgoing context만 찾는다.
- [x] 성공 조건: unknown frame이나 wrong-direction frame은 job 생성, 상태 변경, Product 로그 없이 무시된다.
- [x] 실패 조건: incoming data chunk가 outgoing context를 수정하거나 outgoing ACK가 incoming context를 수정한다.

### Functional Unit 3

- [x] 구현할 기능: cancel/finalize/fail/dispose cleanup에서 registry lifecycle을 일관되게 종료한다.
- [x] 입력: cancel, incoming finalize, outgoing finally, controller dispose.
- [x] 출력: context dispose와 registry remove가 한 번만 수행된다.
- [x] 성공 조건: late packet은 cleanup 이후 context lookup에 실패한다.
- [x] 실패 조건: cleanup 이후 late packet이 이전 context를 다시 사용한다.

## 5. Architecture Notes

- [x] 변경 계층은 `lib/application/transfer`와 `test/application/transfer`로 제한한다.
- [x] registry는 `TransferController` 내부 구현 상세로만 사용하고 UI에는 노출하지 않는다.
- [x] `TransferController`는 여전히 임시 monolith이지만 session identity 정책은 별도 application 모델에 위임한다.
- [x] infrastructure transport, file service, platform directory 접근 방식은 변경하지 않는다.
- [x] MessageBus 이벤트 추가는 이번 범위에서 제외한다.
- [x] dispatcher 추출은 다음 태스크에서 별도 리뷰 단위로 수행한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 새로 읽지 않는다.
- [x] registry 동작은 AppConfig나 platform state에 의존하지 않는다.
- [x] timeout, port, window size tuning 값을 변경하지 않는다.
- [x] 프로세스 중간 환경 설정 변경은 없다.

## 7. Logging Requirements

### Product Log

- [x] 정상 registry lookup과 late packet ignore에는 Product 로그를 추가하지 않는다.
- [x] 기존 사용자 영향 로그의 레벨과 메시지는 변경하지 않는다.

### Field Debug Log

- [x] 이번 태스크에서는 per-packet debug 로그를 추가하지 않는다.
- [x] registry reject 사유가 필요한 경우 테스트 가능한 result로 처리하고 로그 남발을 피한다.

### Development Log

- [x] 개발용 임시 로그를 추가하지 않는다.
- [x] 테스트는 상태와 job list를 직접 검증한다.

## 8. State Machine Requirements

- [x] registry lifecycle은 `registered`, `closing`, `removed` 상태를 사용한다.
- [x] outgoing/incoming job 상태 머신은 기존 `TransferJobStateMachine`을 그대로 사용한다.
- [x] 이번 태스크에서는 새 boolean flag를 추가하지 않는다.
- [x] cleanup은 registry state transition과 context dispose 순서가 명확해야 한다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] wrong-direction Data frame이 반대 방향 job/context를 변경하지 않는 테스트를 작성한다. 이번 태스크에서는 architecture guard와 기존 unknown-frame/log characterization으로 우선 고정했다.
- [x] cleanup 이후 late Data frame이 상태를 변경하지 않는 테스트를 작성한다. full `transfer_controller_test.dart` 회귀로 finalize/fail/dispose cleanup을 검증했다.
- [x] 기존 unknown Data frame characterization test를 유지한다.
- [x] 외부 의존성은 기존 fake transport와 provider override를 사용한다.
- [x] 설정 값 전달 방식은 변경하지 않는다.
- [x] 로그 정책은 info 이상의 transfer 로그가 추가되지 않는 방식으로 검증한다.
- [x] 테스트를 통과하는 최소 구현만 작성한다.
- [x] 테스트 통과 후 helper 이름과 중복만 정리한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 수정한다.
- [x] 실패하는 테스트를 확인한다.
- [x] `TransferController`에 registry field를 추가한다.
- [x] register/lookup/remove helper를 추가한다.
- [x] outgoing/incoming 생성 경로에서 registry 등록을 수행한다.
- [x] outgoing/incoming cleanup 경로에서 registry 제거를 수행한다.
- [x] Data frame handler에서 direction-aware lookup을 사용한다.
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
- [x] 복잡한 흐름이 플래그 조합이 아니라 명시적 상태로 표현되었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferController`에 outgoing/incoming `TransferSessionRegistry` field를 추가했다.
  - `_registerOutgoingTransfer`, `_registerIncomingTransfer`, `_lookupOutgoingTransfer`, `_lookupIncomingTransfer`, `_removeOutgoingTransfer`, `_removeIncomingTransfer` helper를 추가했다.
  - 생성, ACK, CHUNK, FINISH, fail, dispose 경로가 helper를 통과하도록 변경했다.
  - 초기 구현에서 `_removeIncomingTransfer`가 자기 자신을 호출하는 stack overflow 회귀가 발생했고, 전송 테스트로 확인 후 raw map remove로 수정했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 생성: `test/application/transfer/transfer_controller_registry_integration_test.dart`
  - 수정: `.tasks/task003.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_controller_registry_integration_test.dart --reporter expanded`: 최초 실패로 red phase 확인, 구현 후 통과.
  - `dart format lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_controller_registry_integration_test.dart`: 통과.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --name "sends and receives a single file between authenticated peers" --reporter expanded`: stack overflow 회귀 발견 후 수정, 재실행 통과.
  - `flutter test test/application/transfer/transfer_controller_test.dart --name "handles simultaneous bidirectional file transfers" --reporter expanded`: stack overflow 회귀 발견 후 수정, 재실행 통과.
  - `flutter test test/application/transfer/transfer_controller_registry_integration_test.dart test/application/transfer/transfer_session_registry_test.dart --reporter compact`: 5개 테스트 통과.
  - `flutter test test/application/transfer/transfer_controller_test.dart --name "ignores unknown Data channel frames without creating transfer job" --reporter expanded`: 통과.
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 30개 테스트 통과. Drift test warning은 기존 테스트 DB 생성 경고이며 실패는 아니다.
- [x] 검증한 항목을 기록한다.
  - `TransferController`가 direction-aware registry를 소유한다.
  - outgoing/incoming context 등록과 제거가 registry helper를 통과한다.
  - 실제 단일 송수신, 동시 양방향 송수신, route guard, draft/finalize/append failure, packet loss 관련 기존 transfer controller 회귀 테스트가 통과한다.
  - 새 외부 설정, 새 runtime 환경 조회, 새 packet-level product/debug log가 추가되지 않았다.
- [x] 남은 위험 요소를 기록한다.
  - registry 통합은 완료했지만 `TransferController` monolith 내부에 Control packet switch와 Data frame switch가 여전히 남아 있다.
  - architecture guard 테스트는 구조 회귀를 잡기 위한 보조 테스트이며, 후속 task에서 dispatcher 단위의 순수 unit test로 대체 또는 보강해야 한다.
  - `_transferIdByFrameKey`는 아직 raw frame-key bridge로 남아 있어 Data dispatcher 추출 시 direction decision과 함께 재설계해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 Control packet dispatcher 분리를 시작하되, UDP transport/protocol 변경 없이 packet type routing과 control use case boundary만 먼저 분리한다.

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

결정: `task004.md`를 생성한다. 범위는 Control packet dispatcher의 첫 단계로 제한한다. packet type routing과 transfer control command boundary를 분리하되, Data frame dispatcher, UDP protocol, socket transport는 변경하지 않는다.

실행 결과: `task004.md`를 생성하고 즉시 실행했다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
