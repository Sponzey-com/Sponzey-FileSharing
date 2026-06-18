# Task 059. Export TCP Data Session Diagnostics

## Goal

TCP data channel 전환 이후 peer 연결 상태의 기준이 UDP route lease가 아니라 TCP session이 되었는지 diagnostics export에서 확인할 수 있게 한다.

## Scope

- [x] TCP data session registry가 현재 등록된 session 목록을 안전한 스냅샷으로 제공한다.
- [x] diagnostics export debug section에 TCP session 상태, 방향, 안전한 endpoint 요약을 포함한다.
- [x] diagnostics export provider가 실제 TCP data session registry snapshot을 bundle input으로 전달한다.

## Functional Requirements

- [x] 연결된 TCP session은 `peerId`, `direction`, `status`, `localEndpoint`, `remoteEndpoint`를 export한다.
- [x] session id와 channel id는 전체 값을 노출하지 않고 축약된 값만 export한다.
- [x] password, token, session key, 파일 원문, 전체 파일 경로는 export되지 않는다.

## Architecture Requirements

- [x] TCP session snapshot API는 application 계층의 registry interface에 둔다.
- [x] diagnostics bundle은 network socket이나 파일 시스템에 직접 접근하지 않고 입력 DTO만 사용한다.
- [x] provider 조립부만 registry provider를 읽고, bundle builder는 순수 함수로 유지한다.

## TDD Requirements

- [x] registry snapshot 단위 테스트를 먼저 추가하고 실패를 확인한다.
- [x] diagnostics bundle redaction/export 테스트를 먼저 추가하고 실패를 확인한다.
- [x] provider wiring은 기존 provider 구조를 깨지 않는 범위에서 최소 구현으로 통과시킨다.

## Validation

- [x] `flutter test test/application/transfer/data_channel_session_registry_test.dart --reporter compact`
- [x] `flutter test test/application/diagnostics/diagnostics_export_bundle_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] diagnostics export만으로 TCP data session 상태와 방향을 확인할 수 있다.
- [x] 민감 정보와 전체 경로가 diagnostics export에 포함되지 않는다.
- [x] TCP data session 정보는 hidden global state가 아니라 명시적 input/provider wiring으로 전달된다.
