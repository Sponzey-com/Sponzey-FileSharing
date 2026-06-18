# Task 001. 현재 Route 흐름 감사와 Tidy First 경계 식별

## 1. Task Purpose

- [x] 이 태스크의 목적은 UID 기반 peer identity와 고정 active route lease 모델로 전환하기 전에 현재 코드의 route 변경 경로를 식별하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 `Phase 0. 현재 Route 흐름 감사와 Tidy First 경계 분리`에 기여한다.
- [x] 이 태스크 완료 후 프로젝트는 active route mutation, transfer route validation, legacy route update 제거 대상이 문서로 식별된 상태가 되어야 한다.

## 2. Current Context

- [x] 현재 `.tasks/plan.md`는 `instanceUid`를 peer identity 기준으로 고정하고, IP/port/interface를 route candidate로 분리하는 방향을 정의한다.
- [x] 이전 루프 태스크는 없다. 이 태스크가 UID 기반 route 안정화 계획의 시작 태스크다.
- [x] 현재 작업트리에는 `.tasks/plan.md` 문서 변경과 route lease 관련 코드 변경이 이미 남아 있다.
- [x] 이번 태스크는 기존 미커밋 코드 변경 위에 추가 동작 변경을 섞지 않기 위해 감사, 검색, 검증 기록만 수행한다.
- [x] 현재 확인된 제약 사항은 실제 host/VM 네트워크 검증은 자동화 테스트만으로 대체할 수 없다는 점이다.

## 3. Scope

### Included

- [x] active route를 변경하는 호출 지점 식별
- [x] transfer route validation과 selected path 재조회 지점 식별
- [x] 기존 테스트/정적 분석 기준 상태 확인

### Excluded

- [x] `instanceUid` 모델 구현은 이번 태스크에서 다루지 않는다.
- [x] route candidate key 변경은 이번 태스크에서 다루지 않는다.
- [x] UI peer card 변경은 후속 태스크로 넘긴다.

## 4. Functional Units

이번 태스크는 기능 2~3개 단위로만 구성한다.

### Functional Unit 1

- [x] 구현할 기능은 active route mutation call site 목록화다.
- [x] 입력은 현재 코드베이스의 `select`, `markFailed`, `expireLease`, `applyEvent`, `selectedForPeer` 검색 결과다.
- [x] 출력은 Completion Report의 active route mutation audit 목록이다.
- [x] 성공 조건은 active route를 바꾸거나 조회하는 핵심 경로가 파일과 책임 단위로 정리되는 것이다.
- [x] 실패 조건은 검색 결과 없이 추정으로만 목록을 작성하는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 transfer route validation call site 목록화다.
- [x] 입력은 `routeSnapshot`, `_ensureRouteLeaseStillActive`, `_requireActiveTransferRoute`, `_validateDataBindEndpoint`, `_validateRemoteDataEndpoint` 검색 결과다.
- [x] 출력은 Completion Report의 transfer route validation audit 목록이다.
- [x] 성공 조건은 전송 시작과 전송 중 검증 지점이 구분되는 것이다.
- [x] 실패 조건은 transfer controller 내부 검증 흐름을 확인하지 않고 후속 태스크를 만드는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 baseline verification이다.
- [x] 입력은 현재 작업트리 상태와 관련 테스트 명령이다.
- [x] 출력은 실행한 검증 명령과 결과다.
- [x] 성공 조건은 문서 작업과 기존 코드 변경 상태에서 `flutter analyze`와 관련 route/transfer 테스트가 통과하는 것이다.
- [x] 실패 조건은 검증 없이 task를 완료 처리하는 것이다.

## 5. Architecture Notes

- [x] 변경되는 계층은 `.tasks` 문서 계층뿐이다.
- [x] 도메인, 유스케이스, 어댑터, 인프라 코드는 이번 태스크에서 변경하지 않는다.
- [x] 의존성 방향은 코드 변경이 없으므로 새 위반을 만들지 않는다.
- [x] 외부 시스템 접근은 테스트 명령과 코드 검색에만 한정한다.
- [x] 필요한 인터페이스, 포트, 어댑터 변경은 후속 태스크에서 정의한다.
- [x] 전역 상태, 숨겨진 I/O, 암묵적 설정 접근을 추가하지 않는다.

## 6. Configuration Rules

- [x] 외부 설정 파일 의존을 추가하지 않는다.
- [x] 환경 값은 프로그램 시작 시 최초 1회만 수신한다는 계획 기준을 유지한다.
- [x] 최초 수신 이후에는 환경 값을 전역 상수처럼 사용하지 않는다는 계획 기준을 유지한다.
- [x] 환경 값 전달 방식 변경은 이번 태스크에서 수행하지 않는다.
- [x] 프로세스 중간에 환경 설정 값을 삽입하거나 변경하지 않는다.
- [x] 런타임 중간 재설정, 동적 환경 변경, 숨겨진 설정 조회를 추가하지 않는다.

## 7. Logging Requirements

### Product Log

- [x] 운영 로그 변경은 없다.
- [x] 사용자 영향, 핵심 상태 변화, 장애 원인 추적에 필요한 새 로그는 이번 태스크에서 추가하지 않는다.
- [x] 민감 정보와 과도한 내부 상태를 기록하지 않는다.

### Field Debug Log

- [x] 현장 확인용 디버그 로그 추가는 이번 태스크 범위에서 제외한다.
- [x] 필요한 로그 후보는 후속 구현 태스크에서 active route mutation, candidate merge, lease transition 기준으로 정의한다.
- [x] 민감 정보 마스킹 기준은 `.tasks/plan.md`의 로그 정책을 따른다.
- [x] 보존 범위와 사용 범위는 이번 태스크에서 변경하지 않는다.

### Development Log

- [x] 개발 및 테스트 중 확인할 로그를 추가하지 않는다.
- [x] 프로덕션 기본 동작에 포함되는 로그 변경은 없다.
- [x] 테스트 완료 후 제거 또는 비활성화할 임시 로그를 만들지 않는다.

## 8. State Machine Requirements

- [x] 상태머신이 필요한 대상은 active route lease lifecycle이다.
- [x] 복잡한 내부 흐름을 암묵적 플래그 조합으로 관리하지 않는다는 계획 기준을 유지한다.
- [x] 이번 태스크에서는 새 상태 목록을 구현하지 않는다.
- [x] 이번 태스크에서는 새 이벤트 목록을 구현하지 않는다.
- [x] 이번 태스크에서는 새 전이 조건을 구현하지 않는다.
- [x] 실패 상태와 종료 상태 정의는 후속 active route lease 태스크로 넘긴다.
- [x] 상태 전이를 테스트 가능하게 만들기 위한 call site 감사만 수행한다.

## 9. TDD Plan

- [x] 실패하는 테스트 작성은 이번 감사 태스크에서는 적용하지 않는다. 동작 변경이 없기 때문이다.
- [x] 테스트 대상 유스케이스 후보는 peer identity resolve, route candidate upsert, active route lease acquire, transfer route snapshot으로 정의한다.
- [x] 정상 케이스 테스트 후보를 Completion Report에 기록한다.
- [x] 실패 케이스 테스트 후보를 Completion Report에 기록한다.
- [x] 경계값 테스트 후보를 Completion Report에 기록한다.
- [x] 외부 의존성은 후속 테스트에서 fake UDP transport, fake clock, fake settings repository로 대체해야 한다.
- [x] 설정 값 전달 방식 테스트는 후속 `instanceUid` 태스크에서 작성한다.
- [x] 로그 정책 검증 테스트는 후속 diagnostics/logging 태스크에서 작성한다.
- [x] 상태 전이 테스트는 후속 active route lease state machine 태스크에서 작성한다.
- [x] 이번 태스크는 최소 구현 대신 문서 감사와 기준 검증만 수행한다.
- [x] 테스트 통과 후 구조 정리는 수행하지 않는다.

## 10. Implementation Checklist

- [x] 테스트 파일을 먼저 작성하지 않는다. 이번 태스크는 동작 변경 없는 감사 태스크다.
- [x] 실패하는 테스트 대신 현재 기준 테스트 통과 상태를 확인한다.
- [x] 최소 구현은 `.tasks/task001.md` 생성과 audit 기록이다.
- [x] 계층 간 의존성을 확인한다.
- [x] 외부 의존성이 경계 계층에만 있어야 한다는 후속 검증 기준을 기록한다.
- [x] 설정 값 전달 방식이 명시적이어야 한다는 후속 검증 기준을 기록한다.
- [x] 로그 추가는 하지 않는다.
- [x] 상태 관리가 필요한 지점을 active route lease lifecycle로 식별한다.
- [x] 중복과 구조 문제는 후속 태스크로 분리한다.
- [x] 관련 테스트를 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항인 route 흐름 감사가 완료되었다.
- [x] 관련 테스트가 통과한다.
- [x] 실패 테스트는 동작 변경 태스크에서 작성하기로 명시했다.
- [x] 도메인 계층이 외부 프레임워크에 의존하지 않아야 한다는 검증 기준을 유지했다.
- [x] 유스케이스가 명시적 입력과 출력을 가져야 한다는 검증 기준을 유지했다.
- [x] 외부 환경 값이 런타임 중간에 재조회되지 않아야 한다는 검증 기준을 유지했다.
- [x] 외부 환경 값이 전역 상수처럼 사용되지 않아야 한다는 검증 기준을 유지했다.
- [x] 로그가 Product Log, Field Debug Log, Development Log 기준에 맞게 분리되어야 한다는 기준을 유지했다.
- [x] 개발용 로그가 프로덕션 기본 동작에 포함되지 않도록 새 로그를 추가하지 않았다.
- [x] 복잡한 흐름이 플래그 조합이 아니라 명시적 상태로 표현되어야 한다는 후속 기준을 기록했다.
- [x] 리팩터링과 기능 변경이 분리되었다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - `.tasks/task001.md`를 생성했다.
  - 현재 active route mutation 흐름과 transfer route validation 흐름을 검색 기반으로 감사했다.
  - 동작 변경 없이 기준 검증을 수행했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task001.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter analyze`: 통과
  - `flutter test test/application/transfer/transfer_outgoing_route_lease_command_test.dart --reporter compact`: 통과
  - `flutter test test/application/transfer/transfer_controller_test.dart --plain-name 'fails before data chunks when route lease expires' --reporter compact`: 통과
- [x] 검증한 항목을 기록한다.
  - active route mutation call site는 `PeerPathRegistry`, `PeerPathRegistryMutations`, `PeerAuthController`, `TransferController` 경로에 집중되어 있다.
  - transfer route validation은 `_requireActiveTransferRoute`, `_ensureRouteLeaseStillActive`, `_validateDataBindEndpoint`, `_validateRemoteDataEndpoint`, `TransferOutgoingRouteLeaseCommand` 경로에 집중되어 있다.
  - 기존 route lease 관련 테스트는 현재 작업트리 기준 통과한다.
- [x] 남은 위험 요소를 기록한다.
  - 현재 작업트리에는 task001 외에도 이전 route lease 코드 변경이 남아 있어 후속 코드 태스크에서 변경 범위가 섞이지 않도록 주의해야 한다.
  - 실제 host/VM 경로 흔들림은 자동화 테스트만으로 충분히 검증할 수 없다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 `instanceUid`와 peer identity boundary를 TDD로 고정해야 한다.

### Active Route Mutation Audit

- [x] `PeerPathRegistry.select(path)`는 peer별 selected path를 직접 교체한다.
- [x] `PeerPathRegistry.applyEvent(...)`는 selected path 상태를 상태 머신 결과로 갱신한다.
- [x] `PeerPathRegistry.markFailed(...)`는 selected path를 failed로 전이한다.
- [x] `PeerPathRegistry.expireLeaseForCandidate(...)`는 selected path를 failoverRequested로 전이한다.
- [x] `PeerPathRegistryMutations`는 위 mutation에 revision bump를 결합한다.
- [x] `PeerAuthController`는 route candidate/selected path를 인증 흐름에 연결한다.
- [x] `TransferController._recoverIncomingTransferRoute(...)`는 incoming transfer init 관찰로 route를 복구하고 active로 만든다.

### Transfer Route Validation Audit

- [x] `_requireActiveTransferRoute(...)`는 transfer start 시 selected active path를 요구한다.
- [x] `_ensureRouteLeaseStillActive(...)`는 outgoing transfer 진행 중 현재 selected path와 transfer snapshot을 비교한다.
- [x] `_validateDataBindEndpoint(...)`는 data socket bind local address와 route local address를 비교한다.
- [x] `_validateRemoteDataEndpoint(...)`는 remote data endpoint와 route remote address를 비교한다.
- [x] `TransferOutgoingRouteLeaseCommand`는 current route lease와 expected route snapshot의 유효성을 판정한다.

### Follow-up Test Candidates

- [x] 같은 `instanceUid`, 다른 IP가 peer 1개와 candidate 여러 개로 병합되는 실패 테스트
- [x] 다른 `instanceUid`, 같은 IP가 peer 2개로 분리되는 실패 테스트
- [x] active lease가 있는 상태에서 같은 `instanceUid`의 새 candidate가 selected path를 바꾸지 않는 실패 테스트
- [x] transfer 중 candidate refresh가 transfer route snapshot endpoint를 바꾸지 않는 실패 테스트

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 도달하지 못했다. 현재는 감사와 시작 기준만 완료했다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - `instanceUid` 기반 peer identity 경계 고정이 남아 있다.
  - route candidate registry 재정의가 남아 있다.
  - active route lease state machine 강화가 남아 있다.
  - transfer route snapshot 고정이 남아 있다.
  - UI와 diagnostics 정리가 남아 있다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 `instanceUid`와 peer identity boundary를 테스트로 고정하는 것이다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task002.md`다.
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
