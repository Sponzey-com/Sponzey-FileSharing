# Task 064. Refresh Plan State After TCP Data Session Migration Work

## Goal

`.tasks/plan.md`가 이미 완료된 문서 정렬, TCP 기본 경로, diagnostics/UI 정리 상태를 과거형으로 반영하도록 갱신한다.

## Scope

- [x] Current Implementation Assessment의 부족한 부분을 현재 남은 리스크 중심으로 갱신한다.
- [x] Phase 6 완료/진행 상태와 최근 task059-063 결과를 plan에 반영한다.
- [x] Next Actions를 현재 남은 검증인 full test, manual host/VM smoke, release run 기록 중심으로 갱신한다.

## Functional Requirements

- [x] plan은 AGENTS.md/README 충돌이 아직 존재한다고 말하지 않는다.
- [x] plan은 TCP 기본 경로가 아직 비활성이라고 말하지 않는다.
- [x] plan은 diagnostics export의 TCP session state, direction, last close reason 반영 상태를 설명한다.

## Architecture Requirements

- [x] 계획 문서는 UDP Discovery/Control, TCP Data payload 구조를 유지한다.
- [x] route lease는 TCP 연결 이후 source of truth가 아니라 connect input/diagnostics context로 설명한다.

## TDD Requirements

- [x] 문서 정리 작업이므로 런타임 테스트 추가는 하지 않는다.
- [x] 대신 `rg` 검증과 기존 docs test/full test 결과를 근거로 완료 처리한다.

## Validation

- [x] `rg -n "아직 UDP Data|아직 기본|AGENTS.md가 아직|active route lease stability" .tasks/plan.md docs/release_gate.md scripts/task011_release_gate.sh`
- [x] `flutter test test/docs/release_gate_test.dart --reporter compact`
- [x] `git diff --check`

## Done Criteria

- [x] `.tasks/plan.md`가 현재 구현 상태와 다음 검증 단계를 정확히 설명한다.
- [x] release gate와 plan이 모두 TCP data session stability 기준을 사용한다.
