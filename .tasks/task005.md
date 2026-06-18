# Task 005. TCP Listener/Connector Loopback Infrastructure

## 1. Task Purpose

- [x] 이 태스크의 목적은 application port 뒤에 붙는 최소 TCP listener/connector infrastructure를 추가하는 것이다.
- [x] TCP 연결 성립 여부를 loopback 테스트로 검증한다.
- [x] 파일 payload streaming, session hello, control packet wiring은 후속 태스크로 분리한다.

## 2. Scope

### Included

- [x] `TcpDataListenerPort`에 accepted connection stream과 close 경계를 추가한다.
- [x] `TcpDataConnectorPort`에 close 경계를 추가한다.
- [x] `RawTcpDataListener`를 infrastructure 계층에 추가한다.
- [x] `RawTcpDataConnector`를 infrastructure 계층에 추가한다.
- [x] loopback TCP 연결 성립 테스트를 추가한다.

### Excluded

- [x] 파일 frame read/write는 포함하지 않는다.
- [x] DATA_SESSION_HELLO 검증은 포함하지 않는다.
- [x] control packet serialization/wiring은 포함하지 않는다.
- [x] transfer controller integration은 포함하지 않는다.

## 3. Functional Units

### Functional Unit 1

- [x] Application TCP port interface를 listener lifecycle에 맞게 보강한다.
- [x] `ServerSocket`과 `Socket` 타입은 application으로 노출하지 않는다.
- [x] accepted connection은 channel id와 local/remote endpoint 값으로만 전달한다.

### Functional Unit 2

- [x] Infrastructure TCP listener를 구현한다.
- [x] bind host/port를 명시적 request로만 받는다.
- [x] port `0`이면 OS가 배정한 실제 bound port를 반환한다.

### Functional Unit 3

- [x] Infrastructure TCP connector를 구현한다.
- [x] connect request host/port로 TCP 연결을 시도하고 channel id를 반환한다.
- [x] close 시 열린 socket을 정리한다.

## 4. TDD Plan

- [x] loopback infrastructure 테스트를 먼저 작성한다.
- [x] listener bind가 실제 bound port를 반환하는지 테스트한다.
- [x] connector connect 후 listener가 accepted connection을 발행하는지 테스트한다.
- [x] close 후 추가 자원 누수가 없도록 tearDown으로 정리한다.

## 5. Implementation Checklist

- [x] `test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`를 먼저 작성한다.
- [x] 테스트 실패를 확인한다.
- [x] application port interface를 보강한다.
- [x] `lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`를 추가한다.
- [x] 테스트를 통과시킨다.
- [x] format, analyze, 관련 테스트, diff check를 실행한다.

## 6. Completion Report

Completion summary:

- `TcpDataListenerPort`에 accepted connection stream과 close lifecycle을 추가했다.
- `TcpDataConnectorPort`에 close lifecycle을 추가했다.
- `RawTcpDataListener`와 `RawTcpDataConnector`를 infrastructure 계층에 추가했다.
- loopback TCP bind/connect/accept를 테스트로 검증했다.

Changed files:

- `.tasks/task005.md`
- `lib/application/transfer/tcp_data_channel_ports.dart`
- `lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`
- `test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`

Validation commands:

- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- Result: failed first because implementation did not exist; then failed once because broadcast accepted stream was subscribed too late; fixed test order and passed.
- `dart format lib/application/transfer/tcp_data_channel_ports.dart lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`
- Result: formatted 1 file.
- `rg -n "dart:io|ServerSocket|Socket" lib/application/transfer/tcp_data_channel_ports.dart lib/application/transfer/tcp_data_endpoint_negotiation_command.dart`
- Result: no socket type exposure from application port files.
- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `flutter analyze`
- Result: passed.
- `git diff --check -- .tasks/task005.md lib/application/transfer/tcp_data_channel_ports.dart lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`
- Result: passed.

Remaining risks:

- 연결된 socket은 아직 payload stream으로 노출하지 않는다.
- session hello/auth binding은 후속 task에서 추가해야 한다.

Follow-up:

- task006에서 TCP data session hello/accept frame과 인증된 session 승격 규칙을 추가한다.
