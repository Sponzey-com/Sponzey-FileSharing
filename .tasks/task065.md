# Task 065. Lock Documentation Guardrails To TCP Data Source Of Truth

## Goal

AGENTS.md와 README 계열 문서가 TCP Data Channel을 미래 전환 대상이 아니라 현재 기본 파일 payload 경로로 설명하고, active route lease를 전송 source of truth처럼 설명하지 않도록 고정한다.

## Scope

- [x] AGENTS.md의 peer/route guardrail을 TCP data session 기준으로 정리한다.
- [x] README.md와 README.ko.md의 TCP Data 문구를 미래형 전환 표현에서 현재 기본 경로 표현으로 바꾼다.
- [x] docs test가 AGENTS/README 문서 회귀를 잡도록 추가한다.

## Functional Requirements

- [x] AGENTS.md는 전송 가능 여부와 기본 전송 대상 선택을 authenticated TCP data session 기준으로 설명한다.
- [x] route lease는 TCP connect input과 diagnostics context로 설명한다.
- [x] README 계열은 file payload transfer가 TCP Data Channel을 사용한다고 현재형으로 설명한다.

## Architecture Requirements

- [x] 문서는 UDP Discovery/Control, TCP Data payload 책임 분리를 유지한다.
- [x] 문서는 특정 VM, NIC, IP 대역을 전제로 하지 않는다.

## TDD Requirements

- [x] docs test를 먼저 추가하고 실패를 확인한다.
- [x] 문서 수정 후 docs test를 통과시킨다.

## Validation

- [x] `flutter test test/docs/agent_guardrails_test.dart test/docs/platform_guide_test.dart --reporter compact`
- [x] `git diff --check`

## Done Criteria

- [x] AGENTS.md와 README 계열 문서가 TCP Data 기본 경로를 일관되게 설명한다.
- [x] active route lease가 TCP 전송의 source of truth처럼 문서화되지 않는다.
