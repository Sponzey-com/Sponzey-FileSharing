# Task 008. TCP Length-Prefixed Frame Buffer

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP stream partial read를 length-prefixed frame 단위로 조립하는 buffer를 추가하는 것이다.
- [x] TCP는 message boundary가 없으므로, codec만으로는 socket read chunk를 안전하게 처리할 수 없다.
- [x] 파일 payload 전송 전 공통 frame 조립 규칙을 먼저 테스트로 고정한다.

## 2. Scope

### Included

- [x] length-prefixed frame buffer를 infrastructure 계층에 추가한다.
- [x] partial read가 frame을 조기 방출하지 않는지 테스트한다.
- [x] 이어진 chunk로 complete frame이 생성되는지 테스트한다.
- [x] 한 chunk에 frame 여러 개가 들어온 경우 모두 방출하는지 테스트한다.

### Excluded

- [x] socket read subscription wiring은 포함하지 않는다.
- [x] 파일 payload frame type은 포함하지 않는다.
- [x] backpressure 정책은 포함하지 않는다.

## 3. TDD Plan

- [x] buffer 테스트를 먼저 작성한다.
- [x] partial frame no emit 테스트를 작성한다.
- [x] split frame completion 테스트를 작성한다.
- [x] multiple frame emit 테스트를 작성한다.

## 4. Completion Report

Completion summary:

- TCP stream partial read를 length-prefixed frame 단위로 조립하는 buffer를 추가했다.
- incomplete frame은 방출하지 않고, split frame completion과 multiple frame in one chunk를 테스트로 고정했다.
- max body length 초과 frame은 `FormatException`으로 거부한다.

Changed files:

- `.tasks/task008.md`
- `lib/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer.dart`
- `test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart`

Validation commands:

- `flutter test test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart --reporter compact`
- Result: failed first because implementation did not exist, then passed after implementation.
- `dart format lib/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart`
- Result: completed.
- `flutter test test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task008.md lib/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- 실제 socket stream integration과 frame dispatch는 후속 task에서 구현해야 한다.
