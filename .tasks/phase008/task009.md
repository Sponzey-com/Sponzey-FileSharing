# Task 009. 현재 변경 세트 회귀 검증과 Release Gate 정리

## 1. Task Purpose

- [x] 이 태스크의 목적은 task001부터 task008까지의 변경이 계획의 핵심 목표와 테스트 기준을 깨뜨리지 않는지 검증하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 `Phase 7. Release Gate와 수동 검증`에 기여한다.
- [x] 이 태스크 완료 후 현재 변경 세트는 최소한 정적 분석, 핵심 route/transfer 회귀 테스트, task markdown 추적성 검증을 통과해야 한다.

## 2. Current Context

- [x] peer identity는 `PeerIdentity`로 단일화되었다.
- [x] route candidate upsert와 active route 변경 경계가 분리되었다.
- [x] handshake와 transfer recovery의 active route 변경 API가 명시화되었다.
- [x] transfer route lease 실패 사유가 route changed와 route expired로 분리되었다.
- [x] diagnostics export가 route failure와 storage failure를 구분하도록 수정되었다.
- [x] `.tasks/*.md`가 git ignore에서 빠져 추적 가능해졌다.

## 3. Scope

### Included

- [x] 현재 변경 세트 기준으로 핵심 단위 테스트와 application 회귀 테스트를 실행한다.
- [x] `flutter analyze`와 가능한 범위의 전체 `flutter test`를 실행한다.
- [x] `.tasks` markdown 문서가 추적 가능하고 non-markdown 산출물은 ignored 상태인지 확인한다.
- [x] 실패가 발생하면 원인 계층을 구분하고, 이번 task 범위에서 해결 가능한 실패만 수정한다.
  - 실패가 발생하지 않아 수정은 수행하지 않았다.

### Excluded

- [x] 실제 Parallels host/VM 수동 전송 검증은 이번 자동 gate에서 직접 수행하지 않는다.
- [x] 새 네트워크 프로토콜이나 파일 전송 성능 정책은 이번 태스크에서 변경하지 않는다.
- [x] UI 디자인 변경은 이번 태스크에서 다루지 않는다.
- [x] release tag 생성과 push는 이번 태스크에서 다루지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 route identity와 active route lease 회귀 검증이다.
- [x] 입력은 domain/application의 peer identity, peer path registry, auth/discovery controller 테스트다.
- [x] 출력은 같은 UID 후보 병합, active route 고정, handshake/recovery route selection 규칙의 통과 결과다.
- [x] 성공 조건은 route candidate 갱신이 active route를 임의로 흔들지 않는 테스트가 모두 통과하는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 transfer snapshot과 failure classification 회귀 검증이다.
- [x] 입력은 transfer controller, route lease command, diagnostics export 테스트다.
- [x] 출력은 route snapshot 불변, route changed/expired 실패 분류, storage path 분류 유지의 통과 결과다.
- [x] 성공 조건은 전송 중 route 변경 감지가 controlled failure로 유지되고 diagnostics가 이를 정확히 분류하는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 repository gate 검증이다.
- [x] 입력은 `flutter analyze`, `flutter test`, `git status`, `git check-ignore` 결과다.
- [x] 출력은 release 전 검토 가능한 변경 목록과 검증 기록이다.
- [x] 성공 조건은 정적 분석과 테스트가 통과하고 task markdown 문서가 ignored 상태가 아닌 것이다.

## 5. Architecture Notes

- [x] 이 태스크는 새 runtime behavior를 추가하지 않는다.
- [x] 실패 수정이 필요하면 해당 계층 안에서만 최소 수정한다.
- [x] domain은 Flutter, Riverpod, UDP, filesystem에 의존하지 않아야 한다.
- [x] application 테스트는 infrastructure를 test double로 대체할 수 있어야 한다.
- [x] MessageBus나 상태머신 경계를 우회하는 수정은 하지 않는다.

## 6. Configuration Rules

- [x] 새 외부 설정 파일을 만들지 않는다.
- [x] 테스트를 위해 프로세스 중간 환경 설정을 삽입하거나 변경하지 않는다.
- [x] 검증 명령은 저장소의 현재 bootstrap/config 구조를 그대로 사용한다.
- [x] 필요한 테스트 값은 fixture, 생성자 인자, provider override로 명시 전달한다.

## 7. Logging Requirements

### Product Log

- [x] 새 Product log를 추가하지 않는다.

### Field Debug Log

- [x] 새 Field Debug log를 추가하지 않는다.

### Development Log

- [x] 임시 개발 로그를 추가하지 않는다.
- [x] 테스트 실패 분석은 테스트 출력과 diagnostics 분류 결과로 확인한다.

## 8. State Machine Requirements

- [x] 새 상태머신을 추가하지 않는다.
- [x] 기존 route lease와 transfer state machine 테스트가 통과하는지 확인한다.
- [x] 실패 수정이 상태 전이를 변경한다면 먼저 테스트를 추가하거나 갱신한다.
  - 실패가 없어 상태 전이 변경은 수행하지 않았다.

## 9. TDD Plan

- [x] 먼저 핵심 변경 영역의 테스트를 실행해 현재 실패 여부를 확인한다.
- [x] 실패가 있으면 테스트가 표현한 기대 동작이 계획과 맞는지 확인한다.
  - 실패가 없었다.
- [x] 계획과 맞는 실패만 최소 구현으로 수정한다.
  - 수정할 실패가 없었다.
- [x] 수정 후 해당 테스트와 `flutter analyze`를 다시 실행한다.
  - 정적 분석을 실행해 통과를 확인했다.
- [x] 마지막에 가능한 범위의 전체 `flutter test`를 실행한다.

## 10. Implementation Checklist

- [x] `.tasks/task009.md`를 생성한다.
- [x] `.tasks/task008.md`의 다음 태스크 결정 hook을 완료 처리한다.
- [x] route identity와 active route 관련 테스트를 실행한다.
- [x] transfer route snapshot과 diagnostics 관련 테스트를 실행한다.
- [x] 전체 또는 준전체 테스트 gate를 실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] `.tasks` markdown 추적성과 non-markdown ignore 상태를 확인한다.
- [x] 실패가 있으면 수정하고 관련 테스트를 재실행한다.
  - 실패가 없어 추가 수정은 없었다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] `PeerIdentity` 테스트가 통과한다.
- [x] `PeerPathRegistry` 테스트가 통과한다.
- [x] `PeerAuthController` 테스트가 통과한다.
- [x] `DiscoveryController` 테스트가 통과한다.
- [x] `TransferOutgoingRouteLeaseCommand` 테스트가 통과한다.
- [x] `TransferController` 테스트가 통과한다.
- [x] `DiagnosticsExportBundle` 테스트가 통과한다.
- [x] `flutter analyze`가 통과한다.
- [x] 가능한 범위의 전체 `flutter test`가 통과한다.
- [x] task markdown 파일은 ignored가 아니다.
- [x] `.tasks/release_runs/` 같은 non-markdown 산출물은 ignored 상태를 유지한다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - task001부터 task008까지 적용된 route identity, active route lease, transfer snapshot, diagnostics 변경의 회귀 테스트 gate를 수행했다.
  - `.tasks` markdown 추적성과 non-markdown artifact ignore 상태를 확인했다.
  - runtime code 수정은 추가로 수행하지 않았다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task009.md`
  - 수정: `.tasks/task008.md`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/domain/entities/peer_identity_test.dart test/domain/entities/peer_node_test.dart test/application/network/peer_path_registry_test.dart test/application/auth/peer_auth_controller_test.dart test/application/discovery/discovery_controller_test.dart test/application/discovery/peer_route_candidate_projection_test.dart test/application/transfer/transfer_outgoing_route_lease_command_test.dart test/application/transfer/transfer_controller_test.dart test/application/diagnostics/diagnostics_export_bundle_test.dart --reporter compact`: 통과
  - `flutter analyze`: 통과
  - `git check-ignore -v .tasks/task001.md .tasks/task009.md .tasks/release_runs`: task markdown allowlist와 release_runs ignore 확인
  - `git status --short --ignored .tasks/task001.md .tasks/task009.md .tasks/release_runs .gitignore`: task markdown `??`, release_runs `!!` 확인
  - `flutter test --reporter compact`: 통과
- [x] 검증한 항목을 기록한다.
  - route identity 병합, active route 고정, handshake/recovery route selection 테스트가 통과했다.
  - transfer route snapshot, route changed/expired 분류, storage path 분류 테스트가 통과했다.
  - 전체 Flutter 테스트가 통과했다.
- [x] 남은 위험 요소를 기록한다.
  - 실제 host/VM/다중 NIC 수동 검증은 자동 테스트로 대체할 수 없으므로 release gate 문서와 수행 기록이 필요하다.
  - drift 테스트 경고는 기존 테스트 fixture 경고이며 이번 변경의 실패는 아니다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 release gate 문서가 UID 기반 peer identity와 active route lease 안정성을 직접 검증하도록 보강한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 아직 도달하지 못했다. 수동 release gate가 UID/active route lease 모델을 직접 검증하도록 문서와 테스트 보강이 남아 있다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - 수동 host/VM 검증 문서가 route identity 안정성과 route switch 금지 기준을 명시해야 한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 release gate 문서/테스트 보강이다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task010.md`다.
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
