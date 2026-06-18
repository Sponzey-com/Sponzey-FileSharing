# Task 002. Peer Identity Boundary 단일화

## 1. Task Purpose

- [x] 이 태스크의 목적은 peer identity 생성 규칙을 단일 경계로 고정해 IP, port, interface 변화가 peer id를 흔들지 못하게 만드는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 `Phase 1. Instance UID와 Peer Identity 경계 고정`에 기여한다.
- [x] 이 태스크 완료 후 프로젝트는 `userId@instanceUid`를 live peer identity의 기본 규칙으로 사용하고, legacy fallback은 명시적으로 분리된 경로에서만 사용해야 한다.

## 2. Current Context

- [x] 현재 `PeerNode.id`, discovery projection, auth packet 처리, transfer init 처리에 peer id 생성 규칙이 중복되어 있다.
- [x] 현재 규칙은 대부분 `instanceId`가 있으면 `userId@instanceId`, 없으면 `userId@deviceId`를 사용한다.
- [x] 현재 구현은 중복으로 인해 후속 route candidate registry 변경 시 일부 경로가 다른 peer id를 만들 위험이 있다.
- [x] 현재 작업트리에는 이전 route lease 관련 코드 변경이 남아 있으므로 이번 태스크는 identity 경계 변경만 수행한다.

## 3. Scope

### Included

- [x] peer identity 생성 규칙을 순수 도메인 경계로 이동한다.
- [x] discovery, auth, transfer init의 peer id 생성 중복을 제거한다.
- [x] 같은 instance uid와 다른 endpoint가 같은 peer id를 만든다는 테스트를 추가한다.
- [x] 다른 instance uid와 같은 endpoint가 다른 peer id를 만든다는 테스트를 추가한다.
- [x] legacy packet의 device id fallback이 명시적 호환 경로로만 동작한다는 테스트를 추가한다.

### Excluded

- [x] active route lease 선택 정책 변경은 이번 태스크에서 다루지 않는다.
- [x] route candidate key 구조 변경은 이번 태스크에서 다루지 않는다.
- [x] UI peer card 표시 변경은 이번 태스크에서 다루지 않는다.
- [x] 실제 UDP 송수신 또는 host/VM 실기 검증은 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 `PeerIdentity` 또는 동등한 순수 도메인 경계 도입이다.
- [x] 입력은 `userId`, `instanceId`, `deviceId`다.
- [x] 출력은 stable peer id 문자열이다.
- [x] 성공 조건은 live peer identity가 `userId@instanceId`로 고정되고, `instanceId`가 없을 때만 legacy fallback이 명시적으로 사용되는 것이다.
- [x] 실패 조건은 UI, Flutter, Riverpod, UDP packet 구현체에 의존하는 identity 규칙을 만드는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 중복 peer id 생성 제거다.
- [x] 입력은 `PeerNode`, `DiscoveryPacket`, `AuthPacket`, transfer init packet에서 들어오는 identity 필드다.
- [x] 출력은 모든 경로가 동일한 peer id 생성 경계를 사용하는 상태다.
- [x] 성공 조건은 discovery candidate, auth session, transfer init command가 같은 입력에 대해 같은 peer id를 만드는 것이다.
- [x] 실패 조건은 문자열 보간으로 `userId@...`를 새로 만드는 경로가 남는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 TDD 검증과 baseline 회귀 확인이다.
- [x] 입력은 새 도메인 테스트와 관련 application 테스트다.
- [x] 출력은 통과한 테스트 명령과 결과다.
- [x] 성공 조건은 새 identity 테스트, 기존 peer node 테스트, discovery projection 테스트, transfer init receive 테스트가 통과하는 것이다.
- [x] 실패 조건은 동작 변경을 테스트 없이 완료 처리하는 것이다.

## 5. Architecture Notes

- [x] identity 규칙은 `domain`에 위치해야 한다.
- [x] `domain`은 Flutter, Riverpod, UDP, 파일 시스템, secure storage에 의존하지 않아야 한다.
- [x] `application`은 도메인의 identity 경계를 호출할 수 있다.
- [x] `infrastructure` packet 타입은 raw field 운반만 담당하고 identity 정책을 소유하지 않는다.
- [x] UI는 peer id 생성 규칙을 직접 알지 않아야 한다.
- [x] MessageBus 이벤트 payload에 peer id가 필요할 경우 이미 계산된 application/domain 값만 전달한다.

## 6. Configuration Rules

- [x] 외부 설정 파일을 추가하지 않는다.
- [x] 환경 변수나 런타임 설정 값을 새로 읽지 않는다.
- [x] instance id는 기존 부트스트랩/identity service 흐름에서 전달된 값을 사용한다.
- [x] 프로세스 중간에 환경 설정 값을 삽입하거나 변경하지 않는다.
- [x] 테스트는 환경을 숨겨 바꾸지 않고 입력값을 직접 주입한다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.
- [x] identity 생성 실패가 사용자 영향 오류로 노출되어야 하는 경우 기존 오류 경계를 사용한다.

### Field Debug Log

- [x] 새 Field Debug log를 추가하지 않는다.
- [x] 후속 route registry 태스크에서 peer id와 route candidate의 관계를 안전하게 축약 로깅한다.

### Development Log

- [x] 새 Development log를 추가하지 않는다.
- [x] 테스트를 위해 임시 로그를 추가하지 않는다.

## 8. State Machine Requirements

- [x] 이번 태스크는 상태머신을 새로 만들지 않는다.
- [x] identity 생성은 순수 값 계산이어야 하며 상태 전이를 포함하지 않는다.
- [x] auth, route lease, transfer 상태머신은 기존 위치를 유지한다.
- [x] 후속 active route lease 태스크에서 identity 값을 상태머신 key로 사용한다.

## 9. TDD Plan

- [x] 먼저 domain identity 테스트를 작성하고 실패를 확인한다.
- [x] 같은 `userId`와 같은 `instanceId`는 endpoint가 달라도 같은 peer id를 반환해야 한다.
- [x] 같은 `userId`와 다른 `instanceId`는 endpoint가 같아도 다른 peer id를 반환해야 한다.
- [x] `instanceId`가 없는 legacy 입력은 `userId@deviceId`로 fallback해야 한다.
- [x] `userId`가 비어 있으면 유효하지 않은 입력으로 거부해야 한다.
- [x] `instanceId`와 `deviceId`가 모두 비어 있으면 유효하지 않은 입력으로 거부해야 한다.
- [x] 실패 테스트를 통과시키는 최소 구현을 작성한다.
- [x] 중복 문자열 생성 경로를 새 경계 호출로 교체한다.
- [x] 관련 테스트를 다시 실행한다.

## 10. Implementation Checklist

- [x] 새 도메인 테스트 파일을 추가한다.
- [x] peer identity 도메인 경계를 추가한다.
- [x] `PeerNode.id`가 새 경계를 사용하도록 변경한다.
- [x] `PeerRouteCandidateProjection`이 새 경계를 사용하도록 변경한다.
- [x] `PeerAuthController`가 새 경계를 사용하도록 변경한다.
- [x] `TransferInitReceiveCommand`가 새 경계를 사용하도록 변경한다.
- [x] 문자열 보간 기반 peer id 생성 중복이 남았는지 검색한다.
- [x] 관련 테스트를 실행한다.
- [x] `.tasks/task002.md` 체크박스와 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] 기능 요구사항인 peer identity 경계 단일화가 완료되었다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 유스케이스와 command는 명시적 입력과 출력을 가진다.
- [x] 외부 환경 값이 프로그램 시작 이후 암묵적으로 재조회되지 않는다.
- [x] 설정 값이 프로세스 중간에 삽입되거나 변경되지 않는다.
- [x] 외부 API, DB, 파일시스템, 네트워크 접근이 경계 계층에만 남아 있다.
- [x] 테스트 더블 없이도 순수 도메인 identity 규칙을 검증할 수 있다.
- [x] 로그 정책 변경이 없다.
- [x] 개발용 로그가 프로덕션 기본 동작에 포함되지 않는다.
- [x] 복잡한 내부 흐름을 새 boolean 조합으로 추가하지 않았다.
- [x] 리팩터링과 기능 변경 범위가 identity 경계에 한정되었다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `PeerIdentity` 도메인 경계를 추가해 live identity와 legacy fallback을 한 곳에서 계산하도록 했다.
  - `PeerNode`, discovery projection, discovery controller, auth controller, transfer init command의 peer id 생성 경로를 `PeerIdentity.resolve(...)` 호출로 통일했다.
  - 기존 route lease 선택 정책과 UDP 송수신 정책은 변경하지 않았다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `lib/domain/entities/peer_identity.dart`
  - 생성: `test/domain/entities/peer_identity_test.dart`
  - 수정: `lib/domain/entities/peer_node.dart`
  - 수정: `lib/application/discovery/peer_route_candidate_projection.dart`
  - 수정: `lib/application/discovery/discovery_controller.dart`
  - 수정: `lib/application/auth/peer_auth_controller.dart`
  - 수정: `lib/application/transfer/transfer_init_receive_command.dart`
  - 수정: `.tasks/task001.md`
  - 생성: `.tasks/task002.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/domain/entities/peer_identity_test.dart --reporter compact`: 의도한 최초 실패 확인
  - `flutter test test/domain/entities/peer_identity_test.dart test/domain/entities/peer_node_test.dart --reporter compact`: 통과
  - `flutter test test/application/discovery/peer_route_candidate_projection_test.dart test/application/transfer/transfer_init_receive_command_test.dart --reporter compact`: 통과
  - `flutter test test/application/discovery/discovery_controller_test.dart --reporter compact`: 통과
  - `flutter test test/application/auth/peer_auth_controller_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.
  - 같은 `userId`와 같은 `instanceId`는 endpoint/device rename과 무관하게 같은 peer id를 만든다.
  - 같은 `userId`와 다른 `instanceId`는 같은 device id라도 다른 peer id를 만든다.
  - `instanceId`가 없는 legacy 입력만 `deviceId` fallback을 사용한다.
  - application 계층의 discovery, auth, transfer init 경로가 새 도메인 경계를 사용한다.
- [x] 남은 위험 요소를 기록한다.
  - active route lease 선택 정책은 아직 identity별 고정 lease 모델로 완전히 재구성되지 않았다.
  - `.tasks/task001.md`와 `.tasks/task002.md`는 현재 ignore 규칙에 걸려 있어 커밋 대상 여부를 별도로 결정해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 route candidate registry가 같은 peer identity 아래 다중 후보를 유지하되 active route를 흔들지 않는 구조를 TDD로 고정해야 한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 도달하지 못했다. peer identity 경계는 고정했지만 route candidate registry와 active route lease 고정이 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - route candidate registry의 다중 후보 유지와 selected path 불변 규칙이 남아 있다.
  - active route lease 상태머신 강화가 남아 있다.
  - transfer route snapshot 고정 검증이 남아 있다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 같은 peer identity의 route candidate registry와 active route 불변 규칙이다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task003.md`다.
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
