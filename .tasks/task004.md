# Task 004. Active Route Lease 전이 API 명시화

## 1. Task Purpose

- [x] 이 태스크의 목적은 active route lease를 덮어쓸 수 있는 경로를 이름으로 명시해 generic `select(...)` 호출의 의미 혼재를 줄이는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 `Phase 3. Active Route Lease 상태머신 도입`에 기여한다.
- [x] 이 태스크 완료 후 production 호출부는 인증 핸드셰이크, incoming transfer route 복구, absent-only selection을 구분된 API로 호출해야 한다.

## 2. Current Context

- [x] `PeerPathRegistry.select(...)`는 peer별 selected path를 무조건 교체한다.
- [x] task003에서 `selectIfAbsent(...)`를 추가했지만 production 호출부는 아직 generic `select(...)`를 직접 사용한다.
- [x] 인증 시작과 incoming transfer 복구는 route 교체가 허용되는 명시적 절차다.
- [x] discovery refresh는 active route를 직접 교체해서는 안 된다.

## 3. Scope

### Included

- [x] handshake route 선택 API를 명시한다.
- [x] incoming transfer route 복구 API를 명시한다.
- [x] production 호출부에서 generic mutation `select(...)` 사용을 제거한다.
- [x] registry 테스트로 explicit replacement semantics를 고정한다.

### Excluded

- [x] 전체 상태머신 enum 재설계는 이번 태스크에서 다루지 않는다.
- [x] transfer route snapshot 검증 강화는 이번 태스크에서 다루지 않는다.
- [x] UDP transport와 데이터 채널 성능 변경은 이번 태스크에서 다루지 않는다.
- [x] UI 변경은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 handshake route selection API다.
- [x] 입력은 인증 시작에 사용할 `PeerConnectionPath`다.
- [x] 출력은 selected path가 해당 path로 교체된 registry 상태다.
- [x] 성공 조건은 인증 시작 코드가 `selectForHandshake(...)` 이름으로 route 교체 의도를 드러내는 것이다.
- [x] 실패 조건은 인증 시작 코드가 generic `select(...)`를 계속 직접 호출하는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 incoming transfer recovery selection API다.
- [x] 입력은 수신 transfer init에서 관찰한 `PeerConnectionPath`다.
- [x] 출력은 복구 절차에서만 selected path가 해당 path로 교체된 상태다.
- [x] 성공 조건은 transfer 복구 코드가 `selectForTransferRecovery(...)` 이름으로 route 교체 의도를 드러내는 것이다.
- [x] 실패 조건은 transfer 복구 코드가 generic `select(...)`를 계속 직접 호출하는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 호출부 검색과 회귀 검증이다.
- [x] 입력은 route registry 관련 테스트와 auth/transfer 관련 테스트다.
- [x] 출력은 통과한 검증 명령과 남은 generic select 위치 목록이다.
- [x] 성공 조건은 production mutation 호출부에서 generic `select(...)`가 사라지고 테스트가 통과하는 것이다.
- [x] 실패 조건은 호출부 의미를 검색하지 않고 완료 처리하는 것이다.

## 5. Architecture Notes

- [x] route lease mutation API는 `application/network/peer_path_registry.dart`에 둔다.
- [x] route lease 상태 값과 상태 전이는 기존 `domain/network/peer_connection_path.dart`를 사용한다.
- [x] discovery, auth, transfer controller는 registry mutation API를 통해서만 selected path를 변경한다.
- [x] 도메인 계층은 Riverpod과 Flutter에 의존하지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 변수나 런타임 설정 값을 새로 읽지 않는다.
- [x] route 전이 API는 입력 인자만으로 동작해야 한다.
- [x] 프로세스 중간 환경 설정 삽입 또는 변경을 사용하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] 새 Field Debug log를 추가하지 않는다.
- [x] 후속 diagnostics 태스크에서 route transition event를 축약 로깅할 수 있도록 API 이름을 명확히 한다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 새 상태를 추가하지 않는다.
- [x] 새 API는 기존 상태 전이를 우회하지 않아야 한다.
- [x] route 교체는 handshake 또는 transfer recovery처럼 명시된 절차에서만 허용한다.
- [x] absent-only selection은 `selectIfAbsent(...)`를 사용한다.

## 9. TDD Plan

- [x] 먼저 registry explicit replacement 테스트를 추가하고 실패를 확인한다.
- [x] `selectForHandshake(...)`가 기존 selected path를 교체한다는 테스트를 통과시킨다.
- [x] `selectForTransferRecovery(...)`가 기존 selected path를 교체한다는 테스트를 통과시킨다.
- [x] production mutation 호출부 검색으로 generic `select(...)` 제거 여부를 확인한다.
- [x] auth, transfer, network 관련 테스트를 실행한다.

## 10. Implementation Checklist

- [x] `.tasks/task004.md`를 생성한다.
- [x] registry 테스트를 추가한다.
- [x] `PeerPathRegistry`에 explicit selection API를 추가한다.
- [x] `PeerPathRegistryMutations`에 explicit selection API를 추가한다.
- [x] `PeerConnectionCoordinator` 호출부를 변경한다.
- [x] `PeerAuthController` 호출부를 변경한다.
- [x] `TransferController` 호출부를 변경한다.
- [x] generic mutation select 호출이 남았는지 검색한다.
- [x] 관련 테스트를 실행한다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] handshake selection API가 route 교체를 수행한다.
- [x] transfer recovery selection API가 route 교체를 수행한다.
- [x] production mutation 호출부에서 generic `select(...)` 직접 호출이 없다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 변경이 없다.
- [x] 복잡한 흐름을 새 boolean 조합으로 추가하지 않았다.
- [x] 리팩터링과 기능 변경이 route lease API 명시화에 한정되었다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `PeerPathRegistry.selectForHandshake(...)`와 `selectForTransferRecovery(...)`를 추가했다.
  - mutation wrapper에도 같은 API를 추가했다.
  - `PeerConnectionCoordinator`, `PeerAuthController`, `TransferController` production 호출부를 generic `select(...)`에서 명시적 API로 교체했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task004.md`
  - 수정: `.tasks/task003.md`
  - 수정: `lib/application/network/peer_path_registry.dart`
  - 수정: `lib/application/network/peer_connection_coordinator.dart`
  - 수정: `lib/application/auth/peer_auth_controller.dart`
  - 수정: `lib/application/transfer/transfer_controller.dart`
  - 수정: `test/application/network/peer_path_registry_test.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/application/network/peer_path_registry_test.dart --reporter compact`: 의도한 최초 실패 확인
  - `flutter test test/application/network/peer_path_registry_test.dart --reporter compact`: 통과
  - `flutter test test/application/network/peer_connection_coordinator_test.dart --reporter compact`: 통과
  - `flutter test test/application/auth/peer_auth_controller_test.dart --reporter compact`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.
  - production mutation 호출부에서 generic `select(...)` 직접 호출이 제거되었다.
  - 테스트 코드에는 fixture setup 목적으로만 generic `select(...)`가 남아 있다.
  - transfer controller test는 기존 drift 다중 database 경고를 출력했지만 모든 테스트가 통과했다.
- [x] 남은 위험 요소를 기록한다.
  - generic `PeerPathRegistry.select(...)` 자체는 테스트와 내부 호환성 때문에 남아 있다.
  - transfer route snapshot은 아직 전송 중 selected path 변경을 더 강하게 격리하는 별도 검증이 필요하다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 transfer start 시점 route snapshot을 고정하고, 전송 중 route refresh가 job endpoint를 바꾸지 못하도록 테스트해야 한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 도달하지 못했다. transfer route snapshot 검증과 이후 diagnostics 정리가 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - outgoing transfer route snapshot mismatch 검증이 남아 있다.
  - diagnostics와 UI 표시 정리가 남아 있다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 transfer route snapshot 불변 검증이다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task005.md`다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

## 14. Stop Conditions

- [ ] `plan.md`의 최종 목표에 도달했다.
- [ ] 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- [ ] 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- [ ] `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- [ ] 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- [ ] 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- [ ] 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
