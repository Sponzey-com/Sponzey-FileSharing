# Task 062. Track TCP Data Session Last Close Reason

## Goal

TCP Data Channel diagnostics가 단순히 connected/failed 상태만 보여주는 것이 아니라 마지막 close/error reason code를 안전하게 제공하도록 한다.

## Scope

- [x] `TcpDataPeerSessionSnapshot`에 `lastCloseReason`을 추가한다.
- [x] TCP session state machine이 socket close, socket error, auth failure, explicit disconnect reason을 snapshot에 기록한다.
- [x] diagnostics export가 TCP session `lastCloseReason`을 redacted debug section에 포함한다.

## Functional Requirements

- [x] socket close는 `tcp_data_socket_closed`를 기록한다.
- [x] socket error는 `tcp_data_socket_error`를 기록한다.
- [x] auth failure는 `tcp_data_auth_failed`를 기록한다.
- [x] successful auth transition은 이전 close reason을 clear한다.

## Architecture Requirements

- [x] close reason은 domain snapshot의 안전한 code로만 저장한다.
- [x] diagnostics export는 raw exception, token, endpoint secret이 아니라 snapshot의 safe code만 출력한다.
- [x] socket 구현체나 infrastructure exception 객체를 presentation으로 전달하지 않는다.

## TDD Requirements

- [x] state machine 실패 테스트를 먼저 추가하고 실패를 확인한다.
- [x] diagnostics export 실패 테스트를 먼저 추가하고 실패를 확인한다.
- [x] 최소 구현 후 관련 테스트를 통과시킨다.

## Validation

- [x] `flutter test test/domain/transfer/tcp_data_peer_session_state_machine_test.dart --reporter compact`
- [x] `flutter test test/application/diagnostics/diagnostics_export_bundle_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP session snapshot이 마지막 close/error reason code를 보존한다.
- [x] diagnostics export가 TCP session state와 last close reason을 함께 보여준다.
