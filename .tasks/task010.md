# Task 010. UID Active Route Release Gate 문서 고정

## 1. Task Purpose

- [x] 이 태스크의 목적은 release gate가 UID 기반 peer identity와 고정 active route lease 모델을 실제 수동 검증 기준으로 요구하도록 만드는 것이다.
- [x] 이 태스크는 `.tasks/plan.md`의 `Phase 7. Release Gate와 수동 검증` 완료 기준을 문서와 테스트로 고정한다.
- [x] 이 태스크 완료 후 `docs/release_gate.md`와 `scripts/task011_release_gate.sh`는 host/VM 검증에서 UID merge, route candidate 분리, active route 유지, receiver digest를 명확히 요구해야 한다.

## 2. Current Context

- [x] release gate 문서는 bidirectional host/VM 전송과 receiver digest를 이미 요구한다.
- [x] 현재 문서는 UID 기반 peer identity와 active route lease 고정 기준을 직접적으로 충분히 요구하지 않는다.
- [x] 현재 계획은 같은 UID에서 여러 route candidate가 들어와도 active route가 흔들리지 않아야 한다고 정의한다.

## 3. Scope

### Included

- [x] release gate 테스트에 UID/active route 안정성 문구 기대값을 추가한다.
- [x] `docs/release_gate.md`의 manual scenario와 benchmark template을 보강한다.
- [x] `scripts/task011_release_gate.sh`의 manual gate 안내에 UID/active route 검증 항목을 추가한다.

### Excluded

- [x] runtime networking code 변경은 이번 태스크에서 다루지 않는다.
- [x] 실제 host/VM 수동 검증 실행은 이번 태스크에서 수행하지 않는다.
- [x] GitHub Release 생성, tag, push는 이번 태스크에서 다루지 않는다.
- [x] 새 외부 설정 파일은 만들지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] 구현할 기능은 release gate 문서의 UID peer identity 검증 기준이다.
- [x] 입력은 수동 host/VM scenario 기록이다.
- [x] 출력은 같은 UID peer가 candidate 개수와 무관하게 peer 1개로 유지되는 검증 항목이다.
- [x] 성공 조건은 문서 테스트가 `same UID`, `one peer`, `route candidates` 기준을 확인하는 것이다.

### Functional Unit 2

- [x] 구현할 기능은 active route lease stability 검증 기준이다.
- [x] 입력은 discovery 갱신, candidate 추가, active route lease 정보, transfer 결과다.
- [x] 출력은 전송 중 active route lease가 명시 종료/timeout 없이 변경되지 않았다는 기록 항목이다.
- [x] 성공 조건은 benchmark template에 active route lease id, candidate count, route switch count, receiver digest result가 포함되는 것이다.

### Functional Unit 3

- [x] 구현할 기능은 release gate helper의 수동 안내 보강이다.
- [x] 입력은 `scripts/task011_release_gate.sh` 실행 후 출력되는 manual gate checklist다.
- [x] 출력은 UID merge와 active route lease stability를 확인하라는 명시 안내다.
- [x] 성공 조건은 `test/docs/release_gate_test.dart`가 script 문구를 검증하고 통과하는 것이다.

## 5. Architecture Notes

- [x] 문서와 테스트만 변경한다.
- [x] runtime code 계층은 변경하지 않는다.
- [x] release gate는 특정 VM 제품, IP 대역, NIC 이름을 요구하지 않는다.
- [x] 수동 검증은 관찰된 interface, candidate, route lease, digest 결과를 기록하게 한다.

## 6. Configuration Rules

- [x] 새 YAML, JSON, dotenv, 임의 설정 파일을 추가하지 않는다.
- [x] release gate를 위해 프로세스 중간 환경 설정 변경을 요구하지 않는다.
- [x] 필요한 release version은 기존 `SPONZEY_APP_VERSION` 또는 dart define 방식만 문서화한다.

## 7. Logging Requirements

### Product Log

- [x] 해당 없음.

### Field Debug Log

- [x] 문서는 diagnostics export에서 active route lease와 candidate 정보를 확인하도록 요구한다.

### Development Log

- [x] 해당 없음.

## 8. State Machine Requirements

- [x] runtime 상태머신은 변경하지 않는다.
- [x] release gate는 active route lease가 명시 종료, timeout, socket failure 없이 변경되지 않았는지 확인하도록 요구한다.
- [x] release gate는 transfer 완료 상태가 sender success만으로 확정되지 않고 receiver digest pass를 포함하도록 요구한다.

## 9. TDD Plan

- [x] 먼저 `test/docs/release_gate_test.dart`에 새 문구 기대값을 추가한다.
- [x] release gate 테스트가 실패하는 것을 확인한다.
- [x] `docs/release_gate.md`와 `scripts/task011_release_gate.sh`를 보강한다.
- [x] release gate 테스트를 통과시킨다.
- [x] `flutter analyze`를 실행한다.

## 10. Implementation Checklist

- [x] `.tasks/task010.md`를 생성한다.
- [x] `.tasks/task009.md`의 다음 태스크 결정 hook을 완료 처리한다.
- [x] release gate 테스트에 UID/active route 기대값을 추가한다.
- [x] 테스트 실패를 확인한다.
- [x] release gate 문서를 업데이트한다.
- [x] release gate helper script 안내를 업데이트한다.
- [x] release gate 테스트를 재실행한다.
- [x] `flutter analyze`를 실행한다.
- [x] 완료 보고를 업데이트한다.

## 11. Validation Checklist

- [x] release gate 문서가 same UID one peer 기준을 포함한다.
- [x] release gate 문서가 route candidates와 active route lease를 분리해 기록하도록 요구한다.
- [x] benchmark template이 active route lease id, route candidate count, route switch count를 포함한다.
- [x] manual failure handling이 active route switch와 receiver digest failure를 release hold 조건으로 포함한다.
- [x] release gate helper script가 UID merge와 active route lease stability 수동 확인을 안내한다.
- [x] `flutter test test/docs/release_gate_test.dart --reporter compact`가 통과한다.
- [x] `flutter analyze`가 통과한다.

## 12. Completion Report

- [x] 수행한 변경 사항을 요약한다.
  - release gate 문서에 UID one-peer, route candidate와 active route lease 분리, active route lease stability 기준을 추가했다.
  - benchmark template에 route candidate count, active route lease id, active route stability, route switch count를 추가했다.
  - release helper script의 수동 gate 안내에 same UID one peer와 active route lease stability 확인을 추가했다.
- [x] 생성하거나 수정한 파일을 기록한다.
  - 생성: `.tasks/task010.md`
  - 수정: `.tasks/task009.md`
  - 수정: `docs/release_gate.md`
  - 수정: `scripts/task011_release_gate.sh`
  - 수정: `test/docs/release_gate_test.dart`
- [x] 실행한 테스트 명령과 결과를 기록한다.
  - `flutter test test/docs/release_gate_test.dart --reporter compact`: 의도한 최초 실패 확인 후 통과
  - `flutter analyze`: 통과
- [x] 검증한 항목을 기록한다.
  - 문서 테스트가 UID one-peer, route candidates 분리, active route lease stability, route switch count 기준을 확인한다.
  - release helper script가 same UID one peer와 active route lease stability 수동 확인을 안내한다.
- [x] 남은 위험 요소를 기록한다.
  - 실제 host/VM 수동 검증은 현재 세션에서 실행하지 않았다.
  - 수동 검증 결과는 `.tasks/release_runs/<tag>.md`에 별도 기록해야 한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.
  - 다음 태스크는 현재 계획 대비 완료/미완료 범위를 감사하고, 자동화로 더 진행할 수 있는 남은 항목이 있는지 확인한다.

## 13. Next Task Decision Hook

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
  - 자동 테스트와 release gate 문서 보강은 완료했지만, 특정 VM/IP/NIC 의존 코드가 남아 있는지 금지 패턴 감사가 필요하다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
  - 해당 없음.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
  - AGENTS.md의 “특정 IP 대역, VM 제품, NIC 이름 전제 금지” 기준을 현재 구현 코드에서 검증해야 한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
  - 다음 우선순위는 prohibited route environment pattern audit다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
  - 다음 파일명은 `.tasks/task011.md`다.
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
