# Task 015. TCP Inbound Listener Event Coordinator

## 1. Task Purpose

- [x] 이 태스크의 목적은 raw TCP listener에서 발생하는 accepted/hello/error 이벤트를 application command로 안전하게 연결하는 coordinator를 추가하는 것이다.
- [x] accepted connection 없이 도착한 hello는 registry에 등록하지 않는다.
- [x] malformed hello error는 해당 channel의 pending accepted connection을 제거해 이후 late hello가 잘못 등록되지 않게 한다.

## 2. Scope

### Included

- [x] TCP inbound listener event coordinator를 application 계층에 추가한다.
- [x] listener hello/error 이벤트 값 객체를 application port 경계로 이동한다.
- [x] accepted -> valid hello, hello without accepted, malformed error cleanup 테스트를 추가한다.

### Excluded

- [x] 실제 provider/subscription wiring은 포함하지 않는다.
- [x] TCP payload frame 송수신은 포함하지 않는다.
- [x] UI 상태 표시는 포함하지 않는다.

## 3. TDD Plan

- [x] coordinator 테스트를 먼저 작성한다.
- [x] accepted 후 valid hello가 inbound session을 registry에 등록하는지 테스트한다.
- [x] accepted 없이 hello가 도착하면 `missing_tcp_data_accepted_connection`으로 거부되는지 테스트한다.
- [x] malformed hello error 후 같은 channel의 late hello가 등록되지 않는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpDataInboundListenerEventCoordinator`를 추가해 listener accepted/hello/error 이벤트를 application handshake command로 연결했다.
- `TcpDataReceivedHello`, `TcpDataReceivedHelloError`를 application port 경계로 이동해 infrastructure 타입이 application 흐름에 직접 새지 않도록 했다.
- malformed hello error가 pending accepted connection을 제거하도록 고정해 late hello가 registry에 잘못 등록되지 않게 했다.

Changed files:

- `lib/application/transfer/tcp_data_channel_ports.dart`
- `lib/application/transfer/tcp_data_inbound_listener_event_coordinator.dart`
- `lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`
- `test/application/transfer/tcp_data_inbound_listener_event_coordinator_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_inbound_listener_event_coordinator_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_inbound_handshake_command_test.dart --reporter compact`

Remaining risks:

- 실제 runtime subscription 연결과 socket close 정책은 후속 task에서 구현해야 한다.
