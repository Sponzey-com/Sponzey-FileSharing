# Task 004. TCP Endpoint Negotiation Port Boundary

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP listener/connector 실제 구현 전에 application 계층에서 TCP endpoint negotiation 결정을 테스트 가능하게 분리하는 것이다.
- [x] 인증되지 않은 peer는 TCP endpoint offer를 처리하지 않고, 인증된 peer만 connect command로 승격한다.
- [x] 이미 connected TCP data session이 있는 peer는 새 endpoint offer나 route 변화로 기존 연결을 흔들지 않는다.

## 2. Scope

### Included

- [x] `TcpDataListenerPort`, `TcpDataConnectorPort` interface를 추가한다.
- [x] TCP endpoint offer/request/decision 값을 추가한다.
- [x] authenticated 여부와 기존 TCP session 상태를 기준으로 endpoint offer 결정을 내리는 command를 추가한다.
- [x] unauthenticated reject, authenticated connect, already-connected no-op 테스트를 추가한다.

### Excluded

- [x] `ServerSocket`, `Socket` 기반 infrastructure 구현은 포함하지 않는다.
- [x] control packet serialization 변경은 포함하지 않는다.
- [x] transfer controller runtime wiring은 포함하지 않는다.
- [x] 파일 payload streaming은 포함하지 않는다.

## 3. Functional Units

### Functional Unit 1

- [x] TCP listener/connector port interface를 정의한다.
- [x] interface는 Dart IO socket type을 노출하지 않는다.
- [x] endpoint는 문자열 host와 int port 값으로 표현한다.

### Functional Unit 2

- [x] endpoint offer decision command를 정의한다.
- [x] 인증되지 않은 offer는 reject한다.
- [x] 인증된 offer는 connect decision을 생성한다.

### Functional Unit 3

- [x] 기존 connected session 보호 규칙을 추가한다.
- [x] 이미 connected 상태면 새 endpoint offer는 no-op 처리한다.
- [x] 이 규칙은 route candidate churn 방지와 같은 source-of-truth 원칙을 유지한다.

## 4. TDD Plan

- [x] application test를 먼저 작성한다.
- [x] unauthenticated offer reject 테스트를 작성한다.
- [x] authenticated offer connect 테스트를 작성한다.
- [x] existing connected session no-op 테스트를 작성한다.
- [x] port interface가 Dart IO를 노출하지 않는지 forbidden import 검색으로 검증한다.

## 5. Implementation Checklist

- [x] `test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart`를 먼저 작성한다.
- [x] 테스트 실패를 확인한다.
- [x] `lib/application/transfer/tcp_data_channel_ports.dart`를 추가한다.
- [x] `lib/application/transfer/tcp_data_endpoint_negotiation_command.dart`를 추가한다.
- [x] 테스트를 통과시킨다.
- [x] format, forbidden import, 관련 테스트, diff check를 실행한다.

## 6. Completion Report

Completion summary:

- TCP listener/connector port interface를 application 계층에 추가했다.
- endpoint offer, connect request, negotiation context/decision 값을 추가했다.
- 인증되지 않은 offer reject, 인증된 offer connect, connected session 보호 no-op, invalid port reject를 테스트로 고정했다.

Changed files:

- `.tasks/task004.md`
- `lib/application/transfer/tcp_data_channel_ports.dart`
- `lib/application/transfer/tcp_data_endpoint_negotiation_command.dart`
- `test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart --reporter compact`
- Result: failed first because the implementation file did not exist.
- `dart format lib/application/transfer/tcp_data_channel_ports.dart lib/application/transfer/tcp_data_endpoint_negotiation_command.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart`
- Result: completed, no content changes after format.
- `rg -n "dart:io|ServerSocket|Socket|package:flutter|package:flutter_riverpod|package:riverpod|package:drift" lib/application/transfer/tcp_data_channel_ports.dart lib/application/transfer/tcp_data_endpoint_negotiation_command.dart`
- Result: no forbidden socket/framework imports found.
- `flutter test test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- README.md README.ko.md test/docs/platform_guide_test.dart .tasks/task001.md .tasks/task002.md .tasks/task003.md .tasks/task004.md lib/domain/transfer/tcp_data_peer_session_state_machine.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart lib/application/transfer/data_channel_session_registry.dart test/application/transfer/data_channel_session_registry_test.dart lib/application/transfer/tcp_data_channel_ports.dart lib/application/transfer/tcp_data_endpoint_negotiation_command.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart`
- Result: passed.

Remaining risks:

- 실제 TCP listener/connector infrastructure와 control packet 연결은 후속 task에서 구현한다.

Follow-up:

- task005에서 infrastructure TCP listener/connector loopback test와 구현을 진행한다.
