# Task 003. Route Candidate Registry와 Active Route 불변 규칙

## 1. Task Purpose

- [x] 이 태스크의 목적은 같은 peer identity 아래 여러 route candidate를 유지하되, 이미 인증된 active route가 candidate refresh 때문에 자동 교체되지 않도록 보장하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 `Phase 2. Route Candidate Registry 재정의`와 `Phase 3. Active Route Lease 상태머신 도입`의 선행 안정화에 기여한다.
- [x] 이 태스크 완료 후 프로젝트는 같은 UID가 여러 interface/IP에서 보이더라도 active route lease가 명시적 실패 전까지 흔들리지 않아야 한다.

## 2. Current Context

- [x] `PeerIdentity` 도메인 경계는 task002에서 추가되었다.
- [x] `PeerRouteCandidateProjection`은 같은 peer id 아래 후보를 여러 개 만들 수 있다.
- [x] `PeerPathRegistry.select(...)`는 selected path를 직접 교체할 수 있다.
- [x] 인증 흐름과 transfer 복구 흐름에는 아직 candidate refresh와 active path 교체 경계가 섞일 위험이 있다.

## 3. Scope

### Included

- [x] 같은 peer id에 여러 route candidate가 유지되는 도메인/application 테스트를 보강한다.
- [x] active route가 있는 peer에 대해 discovery refresh가 selected path를 교체하지 않는 테스트를 고정한다.
- [x] 명시적 실패 또는 clear 없이 active route가 바뀌지 않는 최소 구현을 적용한다.

### Excluded

- [x] 전체 active route lease 상태머신 재작성은 이번 태스크에서 다루지 않는다.
- [x] UDP transport 송수신 구조 변경은 이번 태스크에서 다루지 않는다.
- [x] 파일 전송 window/ACK 알고리즘 변경은 이번 태스크에서 다루지 않는다.
- [x] UI 표시 변경은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 같은 peer identity의 다중 route candidate 보존 검증이다.
- [x] 입력은 같은 `peerId`와 다른 local interface/local address/remote address 후보들이다.
- [x] 출력은 candidate collection에 여러 후보가 유지되는 상태다.
- [x] 성공 조건은 candidate가 peer id 기준으로 collapse되지 않고 candidate id 기준으로 분리되는 것이다.
- [x] 실패 조건은 새 후보가 기존 후보를 덮어써 route 선택 근거를 잃는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 active route 불변 규칙 검증이다.
- [x] 입력은 이미 selected active path가 있는 peer와 같은 peer의 새 candidate다.
- [x] 출력은 selected path가 기존 active path로 유지되는 상태다.
- [x] 성공 조건은 명시적 실패, clear, timeout 이벤트 없이 selected path id가 바뀌지 않는 것이다.
- [x] 실패 조건은 discovery refresh나 candidate upsert가 selected path를 즉시 교체하는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 회귀 테스트와 분석 검증이다.
- [x] 입력은 network/auth/discovery 관련 테스트 명령이다.
- [x] 출력은 통과한 테스트와 남은 위험 기록이다.
- [x] 성공 조건은 route registry, connection coordinator, auth controller 관련 테스트가 통과하는 것이다.
- [x] 실패 조건은 route 동작 변경을 테스트 없이 완료 처리하는 것이다.

## 5. Architecture Notes

- [x] route candidate는 `domain/network` 값 객체로 유지한다.
- [x] selected active path mutation은 `application/network/peer_path_registry` 경계에서만 수행한다.
- [x] discovery는 candidate 발견 사실만 전달하고 active route를 직접 교체하지 않는다.
- [x] auth/control 흐름은 명시적인 인증 또는 route refresh 이벤트에서만 selected path 전이를 요청한다.
- [x] transfer 흐름은 후속 태스크에서 active route snapshot을 소비한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 변수나 런타임 설정 값을 새로 읽지 않는다.
- [x] route 후보와 lease 정책 값은 테스트 입력 또는 기존 config 인자로만 전달한다.
- [x] 프로세스 중간 환경 설정 삽입 또는 변경을 사용하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] 필요한 경우 active route가 유지되거나 실패로 전이되는 이벤트만 축약 로그 후보로 문서화한다.
- [x] 이번 태스크에서 per-packet 로그를 추가하지 않는다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 이번 태스크는 active route lease 전체 상태머신을 새로 만들지 않는다.
- [x] 이미 존재하는 `PeerConnectionPath` 상태 전이를 우회하지 않는다.
- [x] 허용되지 않는 route 교체는 no-op 또는 명시적 실패 경로로 테스트한다.
- [x] 후속 태스크에서 explicit disconnect, heartbeat timeout, socket failure 전이를 확장한다.

## 9. TDD Plan

- [x] 먼저 active route 불변 테스트를 작성하거나 기존 테스트를 확인한다.
- [x] 같은 peer id의 새 candidate upsert가 selected path를 바꾸지 않는 테스트를 통과시킨다.
- [x] 명시적 failure/clear 없이 selected path가 유지되는 테스트를 통과시킨다.
- [x] 기존 discovery/auth/connection coordinator 테스트를 실행한다.
- [x] 구현 후 중복 mutation 경로를 검색한다.

## 10. Implementation Checklist

- [x] route candidate registry 관련 테스트를 확인한다.
- [x] active route 불변 관련 테스트를 추가하거나 기존 테스트를 보강한다.
- [x] 필요한 최소 구현만 적용한다.
- [x] `PeerPathRegistry.select(...)` 호출자가 active route를 의도 없이 교체하지 않는지 검색한다.
- [x] 관련 테스트를 실행한다.
- [x] `.tasks/task003.md` 체크박스와 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] 같은 peer identity 아래 다중 candidate가 유지된다.
- [x] active route가 있는 상태에서 discovery refresh가 selected path를 바꾸지 않는다.
- [x] 명시적 실패 또는 clear 없이 selected path가 바뀌지 않는다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않는다.
- [x] 로그 정책 변경이 없다.
- [x] 복잡한 흐름을 새 boolean 조합으로 추가하지 않았다.
- [x] 리팩터링과 기능 변경이 route registry 경계에 한정되었다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.

  - `PeerPathRegistry.selectIfAbsent(...)`와 mutation wrapper를 추가해 이미 selected path가 있는 peer의 route를 no-op으로 보존하는 명시적 API를 만들었다.
  - `peer_path_registry_test`에 active path 보존과 비어 있는 peer 선택 테스트를 추가했다.
  - 기존 discovery/auth 테스트로 candidate refresh가 authenticated endpoint를 교체하지 않는 동작을 재확인했다.
- [x] 생성하거나 수정한 파일을 기록한다.

  - 수정: `lib/application/network/peer_path_registry.dart`
  - 수정: `test/application/network/peer_path_registry_test.dart`
  - 생성: `.tasks/task003.md`
  - 수정: `.tasks/task002.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.

  - `flutter test test/application/network/peer_path_registry_test.dart --reporter compact`: 의도한 최초 실패 확인
  - `flutter test test/application/network/peer_path_registry_test.dart test/domain/network/peer_route_candidate_test.dart --reporter compact`: 통과
  - `flutter test test/application/auth/peer_auth_controller_test.dart test/application/discovery/peer_route_candidate_projection_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.

  - 같은 peer id의 다중 candidate는 `PeerRouteCandidateCollection`에서 유지된다.
  - active route가 있는 peer에 `selectIfAbsent`를 호출하면 기존 path가 유지된다.
  - selected path가 없는 peer에 `selectIfAbsent`를 호출하면 새 path가 선택된다.
  - production `select(...)` 호출부는 인증 시작, 인증 route 선택, incoming transfer route 복구 같은 명시적 절차에 남아 있다.
- [x] 남은 위험 요소를 기록한다.

  - production 호출부는 아직 `selectIfAbsent`를 사용하지 않는다. 후속 태스크에서 호출 의도를 `forceSelect`, `selectIfAbsent`, `failoverSelect`로 더 명확히 분리해야 한다.
  - incoming transfer route 복구는 여전히 active route를 재선택할 수 있으므로 transfer snapshot 고정 태스크에서 추가 검증이 필요하다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.

  - 다음 태스크는 active route lease 상태 전이 API를 명시화하고, 호출부가 어떤 전이를 요청하는지 이름으로 드러나게 해야 한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.

  - 도달하지 못했다. identity와 registry 보존 API는 정리했지만 active route lease 전이 API와 transfer snapshot 고정이 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.

  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.

  - production 호출부에서 `select(...)`가 어떤 의도의 route 전이인지 이름으로 분리되어야 한다.
  - active route lease의 실패, 종료, failover 요청 전이가 더 명확해야 한다.
  - transfer는 전송 시작 시 route snapshot을 더 강하게 고정해야 한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.

  - 다음 우선순위는 active route lease 전이 API 명시화다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.

  - 다음 파일명은 `.tasks/task004.md`다.
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
