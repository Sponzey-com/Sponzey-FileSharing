# Task 002. Direction-aware transfer session key와 registry 도입

## 1. Task Purpose

- [x] 이 태스크의 목적은 송신과 수신 session이 같은 transfer id를 사용해도 서로의 상태를 침범하지 않도록 direction-aware key와 registry 모델을 도입하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 2인 `TransferSessionKey와 direction-aware registry 도입`에 기여한다.
- [x] 완료 후 프로젝트는 dispatcher와 session runner 분리 전에 사용할 수 있는 순수 application session identity 모델을 가진다.

## 2. Current Context

- [x] 이전 태스크 `task001.md`에서 `TransferController` 책임 지도와 baseline characterization test를 작성했다.
- [x] 현재 `TransferController`는 `_outgoingTransfers`, `_incomingTransfers`, `_transferIdByFrameKey`를 직접 소유한다.
- [x] `_transferIdByFrameKey`는 direction 정보를 포함하지 않으므로 후속 Data frame dispatcher 분리 전 session identity를 먼저 고정해야 한다.
- [x] 이번 태스크는 production integration 전 단계이며, controller의 runtime behavior 변경은 최소화한다.

## 3. Scope

### Included

- [x] `TransferSessionKey` 값 객체 추가.
- [x] direction별 `TransferSessionRegistry` 추가.
- [x] registry lifecycle과 wrong-direction/late-packet lookup behavior 테스트.

### Excluded

- [x] `TransferController`의 `_outgoingTransfers`와 `_incomingTransfers` 교체는 제외한다.
- [x] `TransferDataFrameDispatcher` 구현은 제외한다.
- [x] `TransferControlPacketDispatcher` 구현은 제외한다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능: `TransferSessionKey`를 정의한다.
- [x] 입력: direction, transferId, peerId, authSessionId.
- [x] 출력: equality/hashCode가 direction을 포함하는 key.
- [x] 성공 조건: 같은 transferId라도 direction이 다르면 다른 key로 취급한다.
- [x] 실패 조건: transferId 단독 또는 direction 없는 key로 session을 찾는다.

### Functional Unit 2

- [x] 구현할 기능: direction이 고정된 `TransferSessionRegistry<T>`를 정의한다.
- [x] 입력: registry direction과 session key/value.
- [x] 출력: register, lookup, markClosing, remove, status query 결과.
- [x] 성공 조건: outgoing registry는 incoming key를 거부하고, 같은 transferId의 opposite direction session은 서로 분리된다.
- [x] 실패 조건: outgoing cleanup이 incoming session을 제거하거나 wrong-direction key가 등록된다.

### Functional Unit 3

- [x] 구현할 기능: removed/closing entry에 대한 late packet lookup 기준을 정의한다.
- [x] 입력: 제거되었거나 closing 상태인 session key.
- [x] 출력: lookup은 `null`, status는 `removed` 또는 `closing`.
- [x] 성공 조건: late packet이 새 session을 암묵적으로 만들지 않는다.
- [x] 실패 조건: removed key lookup이 session을 되살리거나 새 entry를 생성한다.

## 5. Architecture Notes

- [x] 변경 계층은 `lib/application/transfer`와 `test/application/transfer`로 제한한다.
- [x] registry는 socket, file system, platform API, Riverpod provider에 의존하지 않는다.
- [x] registry는 UI state를 보관하지 않는다.
- [x] direction enum은 기존 domain `TransferDirection`을 사용한다.
- [x] 이번 태스크에서는 infrastructure adapter를 만들지 않는다.
- [x] production integration은 다음 태스크에서 별도 리뷰 단위로 수행한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 값을 읽지 않는다.
- [x] timeout이나 tuning 값은 이번 registry 모델에 포함하지 않는다.
- [x] 테스트는 생성자 인자와 fixture 값만 사용한다.
- [x] 프로세스 중간 환경 설정 변경은 없다.

## 7. Logging Requirements

### Product Log

- [x] registry 정상 동작은 Product 로그를 남기지 않는다.
- [x] duplicate/wrong-direction 문제는 이번 순수 모델에서 exception/result로 반환하고 Product 로그를 남기지 않는다.

### Field Debug Log

- [x] 이번 태스크에서는 logger dependency를 추가하지 않는다.
- [x] 후속 dispatcher 통합 시 registry decision을 Field Debug summary로 연결한다.

### Development Log

- [x] 이번 태스크에서는 Development 로그를 추가하지 않는다.
- [x] 테스트는 registry result/status를 직접 검증한다.

## 8. State Machine Requirements

- [x] registry entry lifecycle에는 명시적 상태가 필요하다.
- [x] 상태 목록: `registered`, `closing`, `removed`.
- [x] 이벤트 목록: `register`, `markClosing`, `remove`.
- [x] 전이 조건: `registered -> closing -> removed`, `registered -> removed`.
- [x] 종료 상태: `removed`.
- [x] `removed` 상태는 lookup을 통해 value를 반환하지 않는다.

## 9. TDD Plan

- [x] 실패하는 테스트를 먼저 작성한다.
- [x] `TransferSessionKey` equality/hashCode 테스트를 작성한다.
- [x] 같은 transferId의 outgoing/incoming 동시 등록 테스트를 작성한다.
- [x] outgoing cleanup이 incoming registry를 제거하지 않는 테스트를 작성한다.
- [x] wrong-direction registration 거부 테스트를 작성한다.
- [x] removed entry lookup이 null을 반환하는 테스트를 작성한다.
- [x] 외부 의존성은 사용하지 않는다.
- [x] 설정 값 전달 방식은 생성자 인자만 사용한다.
- [x] 로그 정책은 logger dependency 부재로 검증한다.
- [x] 상태 전이 테스트를 작성한다.
- [x] 테스트를 통과하는 최소 구현만 작성한다.
- [x] 테스트 통과 후 구조를 정리한다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성한다.
- [x] 실패하는 테스트를 확인한다.
- [x] 최소 구현을 작성한다.
- [x] 계층 간 의존성을 확인한다.
- [x] 외부 의존성이 경계 계층에만 있는지 확인한다.
- [x] 설정 값 전달 방식이 명시적인지 확인한다.
- [x] 필요한 로그를 정책에 맞게 추가한다. 이번 태스크는 logger dependency를 추가하지 않는 것이 정책에 맞는 구현이다.
- [x] 상태 관리가 명시적 상태 전이로 구현되었는지 확인한다.
- [x] 중복과 구조 문제를 정리한다.
- [x] 관련 테스트와 정적 분석을 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 모두 통과한다. 관련 registry 테스트, 기존 unknown-frame characterization 테스트, `flutter analyze`를 통과했다.
- [x] 실패 테스트가 먼저 작성되었다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 유스케이스가 명시적 입력과 출력을 가진다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 외부 환경 값이 전역 상수처럼 사용되지 않는다.
- [x] 로그가 Product Log, Field Debug Log, Development Log 기준에 맞게 분리되었다. 이번 변경은 로그를 추가하지 않는 방식으로 정책을 만족한다.
- [x] 개발용 로그가 프로덕션 기본 동작에 포함되지 않는다.
- [x] 복잡한 흐름이 플래그 조합이 아니라 명시적 상태로 표현되었다.
- [x] 리팩터링과 기능 변경이 가능한 한 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
  - `TransferSessionKey`를 추가해 direction, transfer id, peer id, auth session id를 모두 session identity에 포함했다.
  - `TransferSessionRegistry<T>`를 추가해 direction이 고정된 register, lookup, closing, remove, status query를 제공했다.
  - `registered`, `closing`, `removed` entry lifecycle을 명시적으로 모델링했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/application/transfer/transfer_session_registry.dart`
  - 생성: `test/application/transfer/transfer_session_registry_test.dart`
  - 수정: `.tasks/task002.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/transfer/transfer_session_registry_test.dart --reporter expanded`: 최초 실행은 구현 파일 부재로 실패해 red phase를 확인했고, 구현 후 4개 테스트 통과.
  - `dart format lib/application/transfer/transfer_session_registry.dart test/application/transfer/transfer_session_registry_test.dart test/application/transfer/transfer_controller_test.dart`: 0 changed.
  - `flutter analyze`: No issues found.
  - `flutter test test/application/transfer/transfer_controller_test.dart --name "ignores unknown Data channel frames without creating transfer job" --reporter expanded`: 통과.
- [x] 검증한 항목을 기록한다.
  - direction이 session identity에 포함된다.
  - 같은 transfer id의 outgoing/incoming session이 분리된다.
  - wrong-direction registration은 거부된다.
  - closing/removed session lookup은 value를 반환하지 않고 late packet이 session을 되살리지 않는다.
  - 새 모델은 socket, file system, Flutter, Riverpod, 환경 값, logger에 의존하지 않는다.
- [x] 남은 위험 요소를 기록한다.
  - 새 registry는 아직 `TransferController` production path에 통합되지 않았다.
  - 현재 controller의 기존 map 구조와 새 registry가 함께 존재하므로 후속 태스크에서 통합 seam을 만들어야 실제 송수신 혼재 위험을 줄일 수 있다.
  - removed key 재등록은 막았으며 transfer id 재사용이 필요한 요구가 생기면 별도 lifecycle policy가 필요하다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 `TransferController`의 session lookup/cleanup path가 direction-aware registry를 사용하도록 통합하되, dispatcher 추출은 아직 하지 않는다.
  - 통합 시 기존 파일 전송 동작을 깨지 않도록 characterization test를 먼저 추가해야 한다.

## 13. Next Task Decision Hook

이 태스크 완료 후 반드시 다음 판단을 수행한다.

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다. 최종 목표에는 아직 도달하지 않았으므로 적용 대상이 아니다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

결정: `task003.md`를 생성한다. 범위는 `TransferSessionRegistry`를 `TransferController`의 현재 session tracking path에 통합하는 최소 변경으로 제한한다. Control/Data dispatcher 추출, socket 구현 변경, protocol 변경은 제외한다.

실행 결과: `task003.md`를 생성하고 즉시 실행했다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
