# Task 011. TCP Hello Malformed Frame Isolation

## 1. Task Purpose

- [x] 이 태스크의 목적은 malformed TCP hello frame이 listener callback 밖으로 예외를 누출하지 않도록 오류 이벤트로 격리하는 것이다.
- [x] 잘못된 frame은 authenticated session으로 승격되지 않아야 한다.
- [x] socket stream은 파일 payload 구현 전에도 안전하게 실패를 보고해야 한다.

## 2. Scope

### Included

- [x] `RawTcpDataListener`에 hello error stream을 추가한다.
- [x] malformed frame decode 실패를 error event로 발행한다.
- [x] malformed frame이 `hellos` stream에 들어가지 않는 테스트를 추가한다.

### Excluded

- [x] 자동 disconnect/reconnect 정책은 포함하지 않는다.
- [x] Product log 정책 변경은 포함하지 않는다.
- [x] UI diagnostics projection은 포함하지 않는다.

## 3. TDD Plan

- [x] malformed frame 테스트를 먼저 작성한다.
- [x] wrong frame type을 전송하면 hello error가 발행되는지 테스트한다.
- [x] 같은 입력이 hello stream으로 승격되지 않는지 테스트한다.

## 4. Completion Report

Completion summary:

- `RawTcpDataListener.helloErrors` stream을 추가했다.
- malformed hello frame decode 실패를 `malformed_tcp_data_hello` issue code로 격리한다.
- malformed frame이 `hellos` stream에 승격되지 않는 테스트를 추가했다.

Changed files:

- `.tasks/task011.md`
- `lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`
- `test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`

Validation commands:

- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- Result: failed first because `helloErrors` did not exist, then passed after implementation.
- `dart format lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`
- Result: completed.
- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task011.md lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- malformed frame 이후 channel close 정책은 후속 state recovery task에서 정해야 한다.
