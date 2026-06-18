# Task 004 - MessageBus 기반과 typed application event 체계

## 목표

계층 간 비동기 사건 전달을 위한 MessageBus 기반을 만들고, Discovery, 인증, 전송, 진단 이벤트를 typed event로 정의한다.

MessageBus는 명령 실행 경로를 숨기는 도구가 아니라 이미 발생한 사실을 전달하는 장치로 사용한다.

## 연관 문서

- [phase002 plan.md - MessageBus 설계](plan.md#7-messagebus-설계)
- [AGENTS.md - MessageBus Rules](../../AGENTS.md#messagebus-rules)

## 선행 조건

- [task001.md](task001.md)가 완료되어 application event 경계가 정리되어 있어야 한다.
- [task002.md](task002.md), [task003.md](task003.md)의 상태 머신 결과 이벤트와 연동 가능해야 한다.

## 포함 기능

### 기능 1. MessageBus 인터페이스와 in-memory 구현

- publish, subscribe, unsubscribe 또는 subscription dispose 방식을 정의한다.
- 타입별 구독 또는 filter 기반 구독 방식을 정한다.
- subscriber 실패가 전체 publish를 중단하지 않도록 정책을 둔다.

### 기능 2. AppEvent 타입 체계

- AppLifecycleEvent, UdpPortEvent, DiscoveryEvent, PeerLinkEvent, TransferQueueEvent, TransferSessionEvent, SecurityEvent, DiagnosticsEvent를 정의한다.
- eventId, occurredAt, correlationId, source, severity 같은 공통 metadata를 포함한다.
- peerId, sessionId, transferId, jobId, portRole, messageId, reasonCode 같은 도메인 필드를 필요한 이벤트에 포함한다.

### 기능 3. Event projection과 logging 연결 기준

- MessageBus event를 application projection, history updater, diagnostics collector, logger가 관찰할 수 있게 한다.
- UI 위젯은 MessageBus 구현체를 직접 구독하지 않고 provider state를 본다는 경계를 유지한다.
- Product, Debug, Development 로그로 이어질 event severity 기준을 둔다.

## 구현 체크리스트

- [x] `MessageBus` 인터페이스를 정의했다.
- [x] in-memory 구현을 추가했다.
- [x] publish 순서 정책을 정했다.
- [x] typed subscribe 또는 filtered subscribe 방식을 구현했다.
- [x] subscription dispose 방식을 구현했다.
- [x] subscriber exception 처리 정책을 구현했다.
- [x] `AppEvent` base type과 공통 metadata를 정의했다.
- [x] Discovery 관련 event를 정의했다.
- [x] PeerLink/Auth 관련 event를 정의했다.
- [x] Transfer 관련 event를 정의했다.
- [x] Security/Diagnostics 관련 event를 정의했다.
- [x] MessageBus가 전역 singleton이 아니라 provider 또는 생성자 주입으로 전달된다.

## 테스트

- [x] publish 순서 유지 테스트를 작성했다.
- [x] 타입별 구독 테스트를 작성했다.
- [x] 구독 해제 후 event가 전달되지 않는 테스트를 작성했다.
- [x] subscriber 하나가 실패해도 다른 subscriber가 event를 받는 테스트를 작성했다.
- [x] correlationId가 event chain에서 유지되는 테스트를 작성했다.
- [x] mutable payload를 전달하지 않는 기준을 테스트 또는 코드 구조로 보장했다.
- [x] UI widget이 MessageBus 구현체를 직접 구독하지 않는 구조를 확인했다.

## 검증

- [x] command를 MessageBus event로 publish해 실행하는 흐름이 없다.
- [x] 이벤트 이름은 이미 발생한 사실을 나타낸다.
- [x] 이벤트 payload에 파일 원문, raw token, password, session key가 들어가지 않는다.
- [x] 상태 머신 전이 결과와 MessageBus event 발행 흐름이 명확히 연결된다.

## 진행 결과

- `lib/core/message_bus/app_event.dart`
- `lib/core/message_bus/message_bus.dart`
- `test/core/message_bus/message_bus_test.dart`
- Discovery/Auth/Transfer controller에서 주요 상태 변경을 typed event로 publish하도록 연결했다.

## 완료 기준

- application controller가 MessageBus 인터페이스를 주입받아 typed event를 publish할 수 있다.
- Discovery/Auth/Transfer의 관찰 이벤트가 공통 방식으로 전달된다.
- 후속 기능이 event 전달 방식을 새로 만들 필요가 없다.
