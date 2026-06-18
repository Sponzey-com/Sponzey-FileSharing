# Task 013. TCP Accepted Connection Session Factory

## 1. Task Purpose

- [x] 이 태스크의 목적은 raw TCP accepted connection과 hello 값을 application/domain session snapshot으로 변환하는 factory를 추가하는 것이다.
- [x] infrastructure socket 이벤트가 domain state machine에 직접 의존하지 않도록 application boundary에서 값을 조립한다.
- [x] factory는 socket 구현체를 알지 않고 `TcpDataAcceptedConnection` 값만 사용한다.

## 2. Scope

### Included

- [x] accepted connection + hello + session id를 authenticating inbound session snapshot으로 변환한다.
- [x] endpoint label 포맷을 안정적으로 만든다.
- [x] peer id는 hello 값에서 가져온다.

### Excluded

- [x] hello proof 검증은 포함하지 않는다.
- [x] registry registration은 포함하지 않는다.
- [x] raw listener subscription wiring은 포함하지 않는다.

## 3. TDD Plan

- [x] factory 테스트를 먼저 작성한다.
- [x] accepted connection과 hello로 authenticating inbound snapshot이 만들어지는지 테스트한다.
- [x] endpoint label이 local/remote host:port 형식인지 테스트한다.

## 4. Completion Report

Completion summary:

- Raw TCP accepted connection과 hello 값을 authenticating inbound `TcpDataPeerSessionSnapshot`으로 변환하는 factory를 추가했다.
- endpoint label은 `host:port` 형식으로 안정화했다.
- factory는 socket 구현체를 직접 알지 않고 application port value만 사용한다.

Changed files:

- `.tasks/task013.md`
- `lib/application/transfer/tcp_data_accepted_session_factory.dart`
- `test/application/transfer/tcp_data_accepted_session_factory_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_accepted_session_factory_test.dart --reporter compact`
- Result: failed first because implementation did not exist, then passed after implementation.
- `dart format lib/application/transfer/tcp_data_accepted_session_factory.dart test/application/transfer/tcp_data_accepted_session_factory_test.dart`
- Result: completed.
- `flutter test test/application/transfer/tcp_data_accepted_session_factory_test.dart test/application/transfer/tcp_data_session_registry_promotion_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_session_promotion_command_test.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task013.md lib/application/transfer/tcp_data_accepted_session_factory.dart test/application/transfer/tcp_data_accepted_session_factory_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- 실제 listener stream을 이 factory와 registry promotion command에 연결하는 adapter는 후속 task에서 구현해야 한다.
