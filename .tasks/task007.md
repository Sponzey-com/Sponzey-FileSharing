# Task 007. TCP Data Session Hello Frame Codec

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP stream 첫 frame으로 보낼 `DATA_SESSION_HELLO` 값을 encode/decode하는 최소 codec을 추가하는 것이다.
- [x] 파일 payload chunk codec은 포함하지 않는다.
- [x] length-prefixed frame으로 TCP stream 경계 문제를 후속 parser에서 다룰 수 있게 한다.

## 2. Scope

### Included

- [x] hello frame codec을 infrastructure 계층에 추가한다.
- [x] frame type, length prefix, JSON body 구조를 검증한다.
- [x] malformed length, wrong frame type reject 테스트를 추가한다.

### Excluded

- [x] 파일 payload frame codec은 포함하지 않는다.
- [x] stream incremental parser는 포함하지 않는다.
- [x] socket read/write integration은 포함하지 않는다.

## 3. TDD Plan

- [x] codec 테스트를 먼저 작성한다.
- [x] encode 후 decode roundtrip 테스트를 작성한다.
- [x] wrong frame type reject 테스트를 작성한다.
- [x] truncated body reject 테스트를 작성한다.

## 4. Completion Report

Completion summary:

- `DATA_SESSION_HELLO` 전용 length-prefixed frame codec을 infrastructure 계층에 추가했다.
- frame body는 JSON으로 유지하되 파일 payload chunk에는 사용하지 않는다.
- roundtrip, wrong frame type, truncated body reject를 테스트로 고정했다.

Changed files:

- `.tasks/task007.md`
- `lib/infrastructure/transfer_data/tcp_data_session_hello_codec.dart`
- `test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart`

Validation commands:

- `flutter test test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart --reporter compact`
- Result: failed first because implementation did not exist, then passed after implementation.
- `dart format lib/infrastructure/transfer_data/tcp_data_session_hello_codec.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart`
- Result: completed.
- `flutter test test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task007.md lib/infrastructure/transfer_data/tcp_data_session_hello_codec.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- TCP stream에서 partial read를 누적하는 parser는 아직 후속 task에서 구현해야 한다.
