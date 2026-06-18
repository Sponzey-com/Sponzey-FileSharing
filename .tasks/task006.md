# Task 006. TCP Data Session Hello Validation

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP socket 연결 이후 peer를 authenticated data session으로 승격하기 전 필요한 hello 검증 규칙을 application 계층에 추가하는 것이다.
- [x] wrong peer id, wrong auth session id, protocol mismatch, invalid proof를 명시적으로 reject한다.
- [x] 실제 암호 구현과 stream frame codec은 후속 태스크로 분리한다.

## 2. Scope

### Included

- [x] TCP data session hello 값과 expectation 값을 추가한다.
- [x] proof verifier interface를 추가한다.
- [x] hello validation command를 추가한다.
- [x] valid hello accept와 주요 reject 사유 테스트를 추가한다.

### Excluded

- [x] 실제 session key proof 생성/검증 crypto 구현은 포함하지 않는다.
- [x] TCP stream frame encode/decode는 포함하지 않는다.
- [x] peer UI projection 전환은 포함하지 않는다.
- [x] transfer controller wiring은 포함하지 않는다.

## 3. Functional Units

### Functional Unit 1

- [x] `TcpDataSessionHello`와 `TcpDataSessionHandshakeExpectation` 값을 추가한다.
- [x] password, raw token, reusable verifier는 포함하지 않는다.
- [x] proof는 opaque string으로만 다룬다.

### Functional Unit 2

- [x] `TcpDataSessionProofVerifier` interface를 추가한다.
- [x] 테스트에서는 fake verifier를 주입한다.
- [x] command는 verifier 구현 세부사항을 알지 않는다.

### Functional Unit 3

- [x] hello validation command를 추가한다.
- [x] peer/auth/protocol/proof를 순서대로 검증한다.
- [x] 실패 사유는 issue code로 고정한다.

## 4. TDD Plan

- [x] validation 테스트를 먼저 작성한다.
- [x] valid hello accept 테스트를 작성한다.
- [x] wrong peer id reject 테스트를 작성한다.
- [x] wrong auth session id reject 테스트를 작성한다.
- [x] protocol mismatch reject 테스트를 작성한다.
- [x] invalid proof reject 테스트를 작성한다.

## 5. Completion Report

Completion summary:

- TCP data session hello, expected peer/auth/protocol context, proof verifier interface를 추가했다.
- incoming hello validation command를 추가해 peer mismatch, auth session mismatch, protocol mismatch, invalid proof를 명시적으로 reject한다.
- password, token, reusable verifier, crypto 구현은 포함하지 않고 opaque proof 검증 interface만 둔다.

Changed files:

- `.tasks/task006.md`
- `lib/application/transfer/tcp_data_session_handshake_command.dart`
- `test/application/transfer/tcp_data_session_handshake_command_test.dart`

Validation commands:

- `flutter test test/application/transfer/tcp_data_session_handshake_command_test.dart --reporter compact`
- Result: failed first because implementation did not exist, then passed after implementation.
- `dart format lib/application/transfer/tcp_data_session_handshake_command.dart test/application/transfer/tcp_data_session_handshake_command_test.dart`
- Result: formatted 1 file.
- `rg -n "dart:io|package:flutter|package:flutter_riverpod|package:riverpod|package:drift|password|token" lib/application/transfer/tcp_data_session_handshake_command.dart`
- Result: no forbidden framework/socket imports and no password/token fields found.
- `flutter test test/application/transfer/tcp_data_session_handshake_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/application/transfer/tcp_data_endpoint_negotiation_command_test.dart test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `flutter analyze`
- Result: passed.
- `git diff --check -- .tasks/task006.md lib/application/transfer/tcp_data_session_handshake_command.dart test/application/transfer/tcp_data_session_handshake_command_test.dart`
- Result: passed.

Remaining risks:

- 실제 proof crypto adapter와 TCP frame parser는 아직 구현되지 않았다.

Follow-up:

- task007에서 TCP stream frame codec 또는 hello frame codec을 추가한다.
