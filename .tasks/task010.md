# Task 010. TCP Hello Exchange Loopback

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP listener/connector 위에서 `DATA_SESSION_HELLO` frame을 실제 socket으로 쓰고 읽는 최소 integration을 추가하는 것이다.
- [x] length-prefixed buffer와 hello codec이 socket stream에서 함께 동작하는지 검증한다.
- [x] 파일 payload streaming은 포함하지 않는다.

## 2. Scope

### Included

- [x] `RawTcpDataConnector`가 connected channel에 hello frame을 write할 수 있게 한다.
- [x] `RawTcpDataListener`가 accepted socket에서 hello frame을 read/decode해 stream으로 발행하게 한다.
- [x] loopback hello exchange 테스트를 추가한다.

### Excluded

- [x] 파일 payload frame read/write는 포함하지 않는다.
- [x] promotion command wiring은 포함하지 않는다.
- [x] UI와 transfer controller 변경은 포함하지 않는다.

## 3. TDD Plan

- [x] hello exchange 테스트를 먼저 작성한다.
- [x] connector가 hello를 보내면 listener가 같은 channel id와 hello 값을 수신하는지 테스트한다.
- [x] malformed frame은 listener stream으로 승격하지 않는지 후속 task로 분리한다.

## 4. Completion Report

Completion summary:

- `RawTcpDataConnector.sendHello`를 추가해 connected channel socket으로 hello frame을 전송한다.
- `RawTcpDataListener.hellos` stream을 추가해 accepted socket에서 length-prefixed hello frame을 decode해 발행한다.
- loopback TCP 연결 후 hello exchange를 테스트로 검증했다.

Changed files:

- `.tasks/task010.md`
- `lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`
- `test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`

Validation commands:

- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- Result: failed first because `hellos` and `sendHello` did not exist, then passed after implementation.
- `dart format lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`
- Result: completed.
- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_session_promotion_command_test.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task010.md lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- hello validation과 state promotion은 아직 socket listener에 직접 연결되지 않았다.
