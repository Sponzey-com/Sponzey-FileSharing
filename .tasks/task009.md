# Task 009. TCP Data Session Promotion Command

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP data session hello 검증 결과를 peer session state machine 전이에 연결하는 application command를 추가하는 것이다.
- [x] valid hello는 authenticating session을 connected로 승격한다.
- [x] invalid hello는 session을 failed로 전이시킨다.

## 2. Scope

### Included

- [x] promotion command를 application 계층에 추가한다.
- [x] valid hello -> connected 테스트를 추가한다.
- [x] invalid hello -> failed 테스트를 추가한다.
- [x] authenticating이 아닌 상태에서 promotion을 시도하면 warning/no-op 성격으로 처리하는 테스트를 추가한다.

### Excluded

- [x] socket read/write integration은 포함하지 않는다.
- [x] UI peer projection 변경은 포함하지 않는다.
- [x] transfer controller wiring은 포함하지 않는다.

## 3. TDD Plan

- [x] promotion command 테스트를 먼저 작성한다.
- [x] valid hello 승격 테스트를 작성한다.
- [x] invalid proof 실패 전이 테스트를 작성한다.
- [x] invalid source state 방어 테스트를 작성한다.

## 4. Completion Report

Completion summary:

- TCP data session hello validation 결과를 peer session state machine 전이에 연결하는 promotion command를 추가했다.
- valid hello는 authenticating session을 connected로 승격한다.
- invalid proof는 failed로 전이시키고, authenticating이 아닌 source state는 warning으로 방어한다.

Changed files:

- `.tasks/task009.md`
- `lib/application/transfer/tcp_data_session_promotion_command.dart`
- `test/application/transfer/tcp_data_session_promotion_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_session_promotion_command_test.dart --reporter compact`
- Result: failed first because implementation did not exist, then passed after implementation.
- `dart format lib/application/transfer/tcp_data_session_promotion_command.dart test/application/transfer/tcp_data_session_promotion_command_test.dart`
- Result: completed.
- `flutter test test/application/transfer/tcp_data_session_promotion_command_test.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task009.md lib/application/transfer/tcp_data_session_promotion_command.dart test/application/transfer/tcp_data_session_promotion_command_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- 실제 TCP stream에서 hello frame을 읽어 command에 전달하는 integration은 아직 후속 task 범위다.
