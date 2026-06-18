# Task 066. Local Release Gate Regression For TCP Data Channel

## Goal

현재 TCP Data Channel 전환 구현과 문서 기준이 로컬에서 실행 가능한 release gate를 통과하는지 검증한다. host/VM 양방향 수동 smoke는 실제 Windows VM 런타임이 필요하므로 이 태스크에서는 자동화 가능한 전체 테스트, 정적 분석, 문서 가드레일, diff 검사를 완료한다.

## Scope

- [x] 전체 `flutter test`를 실행해 domain/application/infrastructure/presentation 회귀를 확인한다.
- [x] `flutter analyze`를 실행해 정적 분석 오류가 없는지 확인한다.
- [x] TCP Data 문서 가드레일 테스트를 다시 실행해 AGENTS/README 기준이 유지되는지 확인한다.
- [x] `git diff --check`로 whitespace와 patch 형식 문제를 확인한다.

## Out Of Scope

- macOS host -> Parallels Windows VM 실제 전송 smoke는 이 태스크에서 수행하지 않는다.
- Parallels Windows VM -> macOS host 실제 전송 smoke는 이 태스크에서 수행하지 않는다.
- release tag 생성 또는 push는 이 태스크에서 수행하지 않는다.

## Validation

- [x] `flutter test --reporter compact`
- [x] `flutter analyze`
- [x] `flutter test test/docs/agent_guardrails_test.dart test/docs/platform_guide_test.dart test/docs/release_gate_test.dart --reporter compact`
- [x] `git diff --check`

## Done Criteria

- [x] 로컬 전체 테스트가 통과한다.
- [x] 정적 분석이 통과한다.
- [x] 문서 가드레일 테스트가 통과한다.
- [x] 남은 release gate gap은 실제 host/VM 수동 smoke로만 제한된다.
