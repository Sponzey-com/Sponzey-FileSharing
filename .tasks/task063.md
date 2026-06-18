# Task 063. Align Release Gate With TCP Data Session Stability

## Goal

릴리즈 게이트와 보조 스크립트의 수동 검증 기준을 legacy active route lease 안정성에서 TCP Data Session 안정성으로 전환한다.

## Scope

- [x] `docs/release_gate.md`의 release rule, manual scenario, diagnostics, benchmark, failure handling 기준을 TCP data session 중심으로 수정한다.
- [x] `scripts/task011_release_gate.sh`의 수동 체크 문구를 TCP data session 기준으로 수정한다.
- [x] docs test가 TCP session stability, last close reason, route candidate non-authoritative 기준을 검증한다.

## Functional Requirements

- [x] release gate는 TCP data session이 전송 중 유지되어야 한다고 명시한다.
- [x] discovery/route candidate 변화는 TCP session을 교체하지 않아야 한다고 명시한다.
- [x] diagnostics review는 TCP session state, direction, last close reason, safe endpoint summary를 확인한다.
- [x] benchmark template은 active route lease 안정성 대신 TCP data session stability를 기록한다.

## Architecture Requirements

- [x] 문서는 현재 목표 구조인 UDP Discovery/Control, TCP Data payload와 일치해야 한다.
- [x] release gate는 route lease를 TCP 연결의 source of truth처럼 설명하지 않는다.

## TDD Requirements

- [x] docs test를 먼저 수정하고 실패를 확인한다.
- [x] release gate 문서와 script를 수정해 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/docs/release_gate_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] release gate가 TCP data session 기준으로 release pass/fail을 판단한다.
- [x] legacy route lease 기준 문구가 TCP session 기준 문구로 대체된다.
