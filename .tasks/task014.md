# Task 014. TCP Inbound Handshake Command

## 1. Task Purpose

- [x] 이 태스크의 목적은 accepted connection, hello, expectation, session id를 application command 하나로 처리해 registry 등록까지 완료하는 inbound handshake 절차를 추가하는 것이다.
- [x] raw listener stream wiring 없이 순수 command로 절차를 고정한다.
- [x] valid hello는 registry에 connected inbound session으로 등록되고, invalid hello는 등록되지 않는다.

## 2. Scope

### Included

- [x] inbound handshake command를 application 계층에 추가한다.
- [x] accepted session factory와 registry promotion command를 조합한다.
- [x] valid/invalid handshake 테스트를 추가한다.

### Excluded

- [x] raw listener subscription adapter는 포함하지 않는다.
- [x] UI projection 변경은 포함하지 않는다.
- [x] 파일 payload transfer는 포함하지 않는다.

## 3. TDD Plan

- [x] inbound handshake command 테스트를 먼저 작성한다.
- [x] valid handshake가 registry에 connected inbound session을 등록하는지 테스트한다.
- [x] invalid proof가 registry에 등록되지 않는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpDataInboundHandshakeCommand`를 추가해 accepted connection, hello, session id, expectation을 하나의 application command에서 처리하도록 했다.
- valid hello는 connected inbound session으로 registry에 등록되고, invalid proof는 failed promotion 결과만 반환하며 registry를 변경하지 않는다.

Changed files:

- `lib/application/transfer/tcp_data_inbound_handshake_command.dart`
- `test/application/transfer/tcp_data_inbound_handshake_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_inbound_handshake_command_test.dart test/application/transfer/tcp_data_accepted_session_factory_test.dart test/application/transfer/tcp_data_session_registry_promotion_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_session_promotion_command_test.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- `flutter analyze`
- `git diff --check -- .tasks/task014.md lib/application/transfer/tcp_data_inbound_handshake_command.dart test/application/transfer/tcp_data_inbound_handshake_command_test.dart`

Remaining risks:

- 실제 stream adapter는 후속 task에서 listener event ordering과 함께 구현해야 한다.
