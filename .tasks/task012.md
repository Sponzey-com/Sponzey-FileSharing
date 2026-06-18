# Task 012. TCP Data Session Promotion Registry

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP hello 검증으로 connected가 된 session을 `DataChannelSessionRegistry`에 등록하는 application command를 추가하는 것이다.
- [x] hello 검증 실패 또는 잘못된 source state는 registry에 등록하지 않는다.
- [x] 이 태스크는 socket listener와 UI를 직접 연결하지 않고 application 절차만 고정한다.

## 2. Scope

### Included

- [x] TCP hello promotion 결과를 registry 등록으로 연결하는 command를 추가한다.
- [x] valid hello는 connected session으로 전이 후 registry에 등록한다.
- [x] invalid hello는 failed transition만 반환하고 registry에 등록하지 않는다.
- [x] duplicate registry entry는 명시적 issue code로 반환한다.

### Excluded

- [x] Raw TCP listener stream subscription wiring은 포함하지 않는다.
- [x] UI peer projection 변경은 포함하지 않는다.
- [x] 파일 payload transfer는 포함하지 않는다.

## 3. TDD Plan

- [x] registry promotion 테스트를 먼저 작성한다.
- [x] valid hello 등록 테스트를 작성한다.
- [x] invalid hello 미등록 테스트를 작성한다.
- [x] duplicate registration reject 테스트를 작성한다.

## 4. Completion Report

Completion summary:

- TCP hello validation과 peer session promotion 결과를 `DataChannelSessionRegistry` 등록으로 연결하는 application command를 추가했다.
- valid hello는 connected session으로 registry에 등록된다.
- invalid hello와 duplicate registration은 명시적 issue code로 반환하며 registry 상태를 오염시키지 않는다.

Changed files:

- `.tasks/task012.md`
- `lib/application/transfer/tcp_data_session_registry_promotion_command.dart`
- `test/application/transfer/tcp_data_session_registry_promotion_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_session_registry_promotion_command_test.dart --reporter compact`
- Result: failed first because implementation did not exist, then passed after implementation.
- `dart format lib/application/transfer/tcp_data_session_registry_promotion_command.dart test/application/transfer/tcp_data_session_registry_promotion_command_test.dart`
- Result: completed.
- `flutter test test/application/transfer/tcp_data_session_registry_promotion_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_session_promotion_command_test.dart test/infrastructure/transfer_data/tcp_data_length_prefixed_frame_buffer_test.dart test/infrastructure/transfer_data/tcp_data_session_hello_codec_test.dart test/application/transfer/tcp_data_session_handshake_command_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- .tasks/task012.md lib/application/transfer/tcp_data_session_registry_promotion_command.dart test/application/transfer/tcp_data_session_registry_promotion_command_test.dart`
- Result: passed.
- `flutter analyze`
- Result: passed.

Remaining risks:

- 실제 listener event를 command에 연결하는 adapter는 후속 task에서 구현해야 한다.
