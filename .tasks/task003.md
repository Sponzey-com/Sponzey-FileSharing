# Task 003. DataChannel Registry Boundary 분리

## 1. Task Purpose

- [x] 이 태스크의 목적은 transfer controller가 UDP/TCP 구현체를 직접 알지 않도록 application 계층에 DataChannel session boundary를 추가하는 것이다.
- [x] 이 태스크는 `.tasks/plan.md` Phase 1의 `DataChannelSessionRegistry`, `DataChannelMode`, UDP/TCP boundary 분리 작업에 기여한다.
- [x] 이 태스크 완료 후 TCP Data Channel 구현은 후속 infrastructure task에서 registry/port boundary 뒤에 붙일 수 있어야 한다.

## 2. Scope

### Included

- [x] `DataChannelMode` 값을 application boundary에 추가한다.
- [x] `DataChannelSessionKey`와 registry result 값을 추가한다.
- [x] `DataChannelSessionRegistry` interface를 추가한다.
- [x] 테스트용/기본 in-memory registry 구현을 추가한다.
- [x] registry가 peer, auth session, direction별로 data channel session을 분리하는 테스트를 추가한다.

### Excluded

- [x] transfer controller runtime wiring은 포함하지 않는다.
- [x] TCP listener/connector 구현은 포함하지 않는다.
- [x] 기존 UDP data endpoint manager rename은 포함하지 않는다.
- [x] UDP Data 기본 경로 제거는 포함하지 않는다.

## 3. Functional Units

### Functional Unit 1

- [x] `DataChannelMode`를 추가한다.
- [x] 값은 `legacyUdp`와 `tcp`로 제한한다.
- [x] runtime 중간 변경 API는 만들지 않는다.

### Functional Unit 2

- [x] `DataChannelSessionRegistry` interface와 key/result 값을 추가한다.
- [x] key는 peer id, auth session id, direction을 포함한다.
- [x] result는 accepted/rejected, status, issue code를 명시한다.

### Functional Unit 3

- [x] in-memory registry 구현을 추가한다.
- [x] 같은 peer라도 direction이 다르면 다른 session으로 저장한다.
- [x] removed session은 늦은 재등록으로 되살아나지 않는다.

## 4. Architecture Notes

- [x] 새 코드는 `lib/application/transfer`에 둔다.
- [x] registry는 domain의 `TcpDataPeerSessionSnapshot`을 값으로 받되 socket 구현을 알지 않는다.
- [x] registry는 Flutter, Riverpod, Dart IO, 파일 시스템에 의존하지 않는다.
- [x] infrastructure TCP 구현은 후속 task에서 registry interface 뒤에 붙인다.

## 5. TDD Plan

- [x] registry 테스트를 먼저 작성한다.
- [x] 같은 peer/auth라도 direction별 session이 분리되는지 테스트한다.
- [x] 중복 등록이 거절되는지 테스트한다.
- [x] removed key가 재등록으로 되살아나지 않는지 테스트한다.
- [x] mode 값이 registry 생성 시 고정되고 runtime mutator가 없음을 테스트 가능한 구조로 둔다.

## 6. Implementation Checklist

- [x] `test/application/transfer/data_channel_session_registry_test.dart`를 먼저 작성한다.
- [x] 테스트 실패를 확인한다.
- [x] `lib/application/transfer/data_channel_session_registry.dart`를 추가한다.
- [x] 테스트를 통과시킨다.
- [x] forbidden import 검색을 수행한다.
- [x] 관련 테스트와 `git diff --check`를 실행한다.

## 7. Validation Checklist

- [x] 기능 요구사항이 충족되었다.
- [x] 테스트가 통과한다.
- [x] 실패 테스트가 먼저 확인되었다.
- [x] 외부 환경 값이 추가되지 않았다.
- [x] 로그가 추가되지 않았다.
- [x] registry가 UDP/TCP concrete transport에 의존하지 않는다.

## 8. Completion Report

Completion summary:

- `DataChannelMode`, `DataChannelSessionKey`, registry result/status, `DataChannelSessionRegistry` interface를 application 계층에 추가했다.
- TCP session snapshot을 concrete socket 구현 없이 registry에 등록/조회/삭제할 수 있는 in-memory 구현을 추가했다.
- peer/auth/direction별 분리, 중복 등록 거절, removed session 부활 방지, direction mismatch 거절을 테스트로 고정했다.

Changed files:

- `.tasks/task003.md`
- `lib/application/transfer/data_channel_session_registry.dart`
- `test/application/transfer/data_channel_session_registry_test.dart`

Validation commands:

- `flutter test test/application/transfer/data_channel_session_registry_test.dart --reporter compact`
- Result: failed first because the implementation file did not exist.
- `dart format lib/application/transfer/data_channel_session_registry.dart test/application/transfer/data_channel_session_registry_test.dart`
- Result: formatted 2 files.
- `rg -n "dart:io|package:flutter|package:flutter_riverpod|package:riverpod|package:drift" lib/application/transfer/data_channel_session_registry.dart lib/domain/transfer/tcp_data_peer_session_state_machine.dart`
- Result: no forbidden dependency imports found.
- `flutter test test/application/transfer/data_channel_session_registry_test.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart test/docs/platform_guide_test.dart --reporter compact`
- Result: passed.
- `git diff --check -- README.md README.ko.md test/docs/platform_guide_test.dart .tasks/task001.md .tasks/task002.md .tasks/task003.md lib/domain/transfer/tcp_data_peer_session_state_machine.dart test/domain/transfer/tcp_data_peer_session_state_machine_test.dart lib/application/transfer/data_channel_session_registry.dart test/application/transfer/data_channel_session_registry_test.dart`
- Result: passed.

Remaining risks:

- transfer controller wiring과 TCP infrastructure 구현은 아직 후속 task 범위다.

Follow-up:

- task004에서 TCP listener/connector port interface와 negotiation boundary를 추가한다.

## 9. Stop Conditions

- `plan.md`의 최종 목표에 도달했다.
- 필수 요구사항이 불명확하여 더 이상 안전하게 진행할 수 없다.
- 외부 정보, 권한, 비밀값, 접근 권한이 없어 진행할 수 없다.
- `AGENTS.md` 원칙과 충돌하는 요구사항이 발견되었다.
- 테스트 또는 검증 환경이 없어 완료 여부를 판단할 수 없다.
