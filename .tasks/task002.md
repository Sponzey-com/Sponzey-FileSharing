# Task 002. TCP Data Peer Session 상태 모델

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP Data Channel 전환의 첫 구현 단위로, peer별 TCP data session 상태와 전이 규칙을 domain 계층에 추가하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 1, "TCP Data Channel Boundary 설계와 기존 UDP Data 경로 격리"의 state model 작업에 기여한다.
- [x] 이 태스크 완료 후 discovery route 변화나 lease 만료가 연결된 TCP data session을 흔들 수 없다는 규칙이 테스트로 고정되어야 한다.

## 2. Current Context

- [x] 문서와 AGENTS.md는 UDP Discovery/Control + TCP Data Channel 방향으로 정렬되어 있다.
- [x] 기존 파일 전송 구현은 UDP Data path와 route lease 기반 로직이 많아, TCP 전환 전에 peer session source of truth가 필요하다.
- [x] 현재 태스크는 TCP socket, listener, connector를 만들지 않고 순수 domain state machine만 추가한다.
- [x] domain 계층은 Dart IO, Flutter, Riverpod, 파일 시스템, 네트워크 API에 의존하면 안 된다.

## 3. Scope

### Included

- [x] `TcpDataPeerSessionStatus` 상태 enum을 추가한다.
- [x] `TcpDataPeerSessionEvent` 이벤트 enum을 추가한다.
- [x] `TcpDataChannelDirection`, `TcpDataChannelId`, `TcpDataSessionId`, `TcpDataPeerSessionSnapshot` 값을 추가한다.
- [x] `TcpDataPeerSessionStateMachine`을 추가한다.
- [x] discovery stale, route candidate 변경, route lease 만료가 connected session을 변경하지 않는 테스트를 추가한다.

### Excluded

- [x] TCP listener와 connector 구현은 포함하지 않는다.
- [x] TCP frame codec 구현은 포함하지 않는다.
- [x] transfer controller wiring 변경은 포함하지 않는다.
- [x] UDP Data path 제거 또는 기본 경로 전환은 포함하지 않는다.

## 4. Functional Units

### Functional Unit 1

- [x] TCP data peer session 값 객체를 추가한다.
- [x] 입력은 peer id, session id, channel id, direction, local endpoint label, remote endpoint label, 상태다.
- [x] 출력은 domain 계층에서 transport 구현 없이 전송 가능한 순수 snapshot이다.
- [x] 성공 조건은 값 객체가 `dart:io`, Flutter, Riverpod import 없이 컴파일되는 것이다.

### Functional Unit 2

- [x] TCP data peer session state machine을 추가한다.
- [x] 입력은 현재 snapshot과 이벤트다.
- [x] 출력은 다음 snapshot, transition disposition, side effect 이름, issue 코드다.
- [x] 성공 조건은 정상 연결, 인증 완료, close/error, explicit disconnect 전이가 테스트로 고정되는 것이다.

### Functional Unit 3

- [x] 경로 흔들림 방지 전이를 추가한다.
- [x] 입력은 connected 상태에서 들어오는 discovery stale, route candidate observed, route lease expired 이벤트다.
- [x] 출력은 no-op 또는 warning이 아니라 의도된 no-op으로 같은 상태를 유지하는 결과다.
- [x] 성공 조건은 TCP channel이 연결된 동안 discovery/route 이벤트가 session 상태를 변경하지 않는 것이다.

## 5. Architecture Notes

- [x] 모든 새 domain 코드는 `lib/domain/transfer`에 둔다.
- [x] state machine은 `core/state_machine`의 기존 `StateMachine`, `TransitionResult`, `TransitionEffect`, `TransitionIssue`를 사용한다.
- [x] 외부 endpoint는 실제 socket address가 아니라 문자열 label 값으로만 보관한다.
- [x] 실제 TCP socket binding, accept, connect side effect는 후속 infrastructure task에서 port interface를 통해 수행한다.
- [x] 이번 태스크는 application 또는 presentation 계층에 runtime wiring을 추가하지 않는다.

## 6. Configuration Rules

- [x] 새 외부 설정 파일을 만들지 않는다.
- [x] TCP port 기본값을 추가하지 않는다.
- [x] 환경 변수를 읽지 않는다.
- [x] runtime 중간에 data channel mode를 바꾸는 API를 추가하지 않는다.
- [x] 테스트 값은 생성자 인자와 snapshot literal로만 전달한다.

## 7. Logging Requirements

- [x] 이번 태스크는 domain state machine 추가이므로 로그를 추가하지 않는다.
- [x] 후속 task에서 로그를 추가할 때 Product, Debug, Development 목적을 분리한다.
- [x] domain 계층은 logger 구현체에 의존하지 않는다.

## 8. State Machine Requirements

- [x] 상태는 명시적인 enum으로 표현한다.
- [x] 이벤트는 명시적인 enum으로 표현한다.
- [x] 허용 전이는 한 state machine class 안에서 추적 가능해야 한다.
- [x] invalid transition은 warning으로 반환하고 issue code를 제공한다.
- [x] socket close와 socket error는 reconnecting 또는 failed로 전이한다.
- [x] explicit disconnect는 closing으로 전이한다.
- [x] discovery stale, route candidate observed, route lease expired는 connected session에서 no-op으로 처리한다.

## 9. TDD Plan

- [x] 실패 테스트를 먼저 작성한다.
- [x] 정상 outbound 연결 전이를 테스트한다.
- [x] 정상 inbound 연결 전이를 테스트한다.
- [x] connected 상태에서 discovery stale이 no-op인지 테스트한다.
- [x] connected 상태에서 route candidate observed가 no-op인지 테스트한다.
- [x] connected 상태에서 route lease expired가 no-op인지 테스트한다.
- [x] socket close가 reconnecting으로 전이되는지 테스트한다.
- [x] socket error가 failed로 전이되는지 테스트한다.
- [x] invalid transition이 warning과 issue code를 반환하는지 테스트한다.

## 10. Implementation Checklist

- [x] `test/domain/transfer/tcp_data_peer_session_state_machine_test.dart`를 먼저 작성한다.
- [x] 테스트 실패를 확인한다.
- [x] `lib/domain/transfer/tcp_data_peer_session_state_machine.dart`를 추가한다.
- [x] 테스트를 통과시킨다.
- [x] domain import가 framework와 socket에 의존하지 않는지 확인한다.
- [x] `flutter test test/domain/transfer/tcp_data_peer_session_state_machine_test.dart --reporter compact`를 실행한다.
- [x] `git diff --check`를 실행한다.

## 11. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 통과한다.
- [x] 실패 테스트가 먼저 확인되었다.
- [x] domain 계층이 외부 프레임워크에 의존하지 않는다.
- [x] 외부 환경 값이 추가되지 않았다.
- [x] 로그가 추가되지 않았다.
- [x] 복잡한 흐름이 명시적 상태 전이로 표현되었다.
- [x] 리팩터링과 기능 변경이 분리되었다.

## 12. Completion Report

태스크 완료 후 다음 내용을 기록한다.

- [x] 수행한 변경 사항을 요약한다.
- [x] 생성하거나 수정한 파일을 기록한다.
- [x] 실행한 테스트 명령과 결과를 기록한다.
- [x] 검증한 항목을 기록한다.
- [x] 남은 위험 요소를 기록한다.
- [x] 후속 태스크에서 이어받아야 할 내용을 기록한다.

Completion summary:

- TCP data peer session 상태, 이벤트, 방향, session/channel id, snapshot 값을 domain 계층에 추가했다.
- outbound/inbound 연결, 인증 완료, discovery/route churn no-op, socket close/error, explicit disconnect, invalid transition을 테스트로 고정했다.
- TCP socket, listener, connector, frame codec, runtime wiring은 추가하지 않았다.

Changed files:

- `.tasks/task002.md`
- `lib/domain/transfer/tcp_data_peer_session_state_machine.dart`
- `test/domain/transfer/tcp_data_peer_session_state_machine_test.dart`

Validation commands:

- `flutter test test/domain/transfer/tcp_data_peer_session_state_machine_test.dart --reporter compact`
- Result: failed first because the implementation file did not exist.
- `dart format lib/domain/transfer/tcp_data_peer_session_state_machine.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart`
- Result: completed, no content changes after format.
- `rg -n "dart:io|package:flutter|package:flutter_riverpod|package:riverpod|package:drift" lib/domain/transfer/tcp_data_peer_session_state_machine.dart`
- Result: no forbidden dependency imports found.
- `flutter test test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- README.md README.ko.md test/docs/platform_guide_test.dart .tasks/task001.md .tasks/task002.md lib/domain/transfer/tcp_data_peer_session_state_machine.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart`
- Result: passed.

Remaining risks:

- TCP listener, connector, frame codec, registry boundary는 아직 구현되지 않는다.

Follow-up:

- task003에서 DataChannel abstraction과 UDP/TCP boundary 분리를 진행한다.

## 13. Next Task Decision Hook

이 태스크 완료 후 반드시 다음 판단을 수행한다.

- [x] `plan.md`의 최종 목표에 도달했는지 확인한다.
- [x] 도달했다면 추가 태스크를 생성하지 않는다.
- [x] 도달하지 못했다면 남은 목표를 정리한다.
- [x] 남은 목표 중 가장 우선순위가 높은 작업을 선택한다.
- [x] 다음 태스크가 기능 2~3개 단위를 넘지 않도록 범위를 제한한다.
- [x] 다음 태스크가 테스트와 검증을 포함하도록 정의한다.
- [x] 다음 태스크가 `AGENTS.md` 원칙과 충돌하지 않는지 확인한다.
- [x] 다음 태스크 파일명을 결정한다.
- [x] 다음 태스크를 `taskXXX.md`로 생성한다.
- [x] 다음 태스크 생성을 완료한 뒤 즉시 실행을 시작한다.

Decision:

- 최종 목표에는 아직 도달하지 않았다.
- 다음 우선순위는 Phase 1의 `DataChannelSessionRegistry`, `DataChannelMode`, UDP/TCP boundary 분리다.
- 다음 파일명은 `.tasks/task003.md`다.

## 14. Stop Conditions

다음 조건 중 하나라도 발생하면 루프를 멈추고 사용자에게 보고한다.

- `plan.md`의 최종 목표에 도달했다.
- 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
- 코드베이스 구조가 계획과 크게 달라 태스크 재설계가 필요하다.
- 사용자 결정이 필요한 아키텍처 선택지가 발생했다.
