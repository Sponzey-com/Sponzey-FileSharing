# Task 067. Release Run Record Template Guardrail

## Goal

수동 host/VM smoke 결과를 `.tasks/release_runs/<tag>.md`에 기록할 때 TCP Data Channel 기준 필수 항목이 누락되지 않도록, 로컬 release run README와 문서 테스트를 정렬한다.

## Scope

- [x] `.tasks/release_runs/README.md`에 release run 기록 절차와 필수 template을 직접 포함한다.
- [x] 문서 테스트를 추가해 TCP data session, digest, diagnostics, host/VM 양방향 항목을 고정한다.
- [x] 문서 테스트와 diff 검사를 실행한다.

## Functional Requirements

- [x] 기록 문서는 macOS host -> Windows VM, Windows VM -> macOS host 양방향 결과를 분리해서 적게 한다.
- [x] 기록 문서는 TCP data session id, state, direction, stability, restart count, last close reason을 요구한다.
- [x] 기록 문서는 sender/receiver final state, receiver digest, diagnostics export filename을 요구한다.
- [x] 기록 문서는 민감정보를 기록하지 말라는 기준을 포함한다.

## Out Of Scope

- 실제 host/VM 수동 smoke 실행은 이 태스크에서 수행하지 않는다.
- release tag 생성 또는 publish는 이 태스크에서 수행하지 않는다.

## TDD Requirements

- [x] README 필수 문구 테스트를 먼저 추가하고 실패를 확인한다.
- [x] README를 업데이트해 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/docs/release_run_records_test.dart --reporter compact`
- [x] `git diff --check`

## Done Criteria

- [x] `.tasks/release_runs/README.md`만 보고도 수동 smoke 기록을 작성할 수 있다.
- [x] 문서 테스트가 필수 TCP Data Channel release run 필드를 고정한다.
