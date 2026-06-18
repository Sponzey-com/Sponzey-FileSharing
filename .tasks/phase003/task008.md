# Task 008 - UI projection과 네트워크 진단

## 목표

사용자와 개발자가 peer별 활성 네트워크 경로, 후보 인터페이스, degraded/failover 상태를 이해할 수 있도록 projection과 UI/진단 표시를 추가한다.

Product UI는 과도한 네트워크 내부 정보를 노출하지 않고, Debug/Development 관점에서는 문제 분석에 충분한 정보를 제공한다.

## 연관 문서

- [plan.md - MessageBus 이벤트 설계](plan.md#12-messagebus-이벤트-설계)
- [plan.md - 데이터 저장과 projection](plan.md#13-데이터-저장과-projection)
- [plan.md - UI projection과 진단](plan.md#phase-003-008-ui-projection과-진단)
- [task003.md](task003.md)
- [task004.md](task004.md)

## 선행 조건

- [task003.md](task003.md)의 route candidate projection이 있어야 한다.
- [task004.md](task004.md)의 selected path projection이 있어야 한다.
- MessageBus가 interface/path/data path 이벤트를 publish할 수 있어야 한다.

## 포함 기능

### 기능 1. projection provider

- peer별 route candidate 목록 provider를 만든다.
- peer별 active path provider를 만든다.
- degraded/failover 상태 provider를 만든다.
- UI가 MessageBus를 직접 구독하지 않도록 한다.

### 기능 2. UI 표시

- peer detail에 active interface, local address, remote endpoint 요약을 표시한다.
- Debug panel 또는 diagnostics view에 candidate 목록, score, status, RTT, failureCount를 표시한다.
- Product 화면에는 “연결 경로 문제”, “다른 네트워크 경로로 재시도 중” 수준의 간결한 문구를 쓴다.

### 기능 3. 로그/진단 이벤트 연결

- NetworkInterface/PeerRoute/PeerPath/DataPath 이벤트를 logger/diagnostics collector와 연결한다.
- Product/Debug/Development 목적별 로그 노출 기준을 지킨다.
- 민감 정보 노출 금지를 snapshot 또는 단위 테스트로 확인한다.

## 구현 체크리스트

- [x] `peerRouteCandidatesProvider`를 추가했다.
- [x] `activePeerPathProvider`를 추가했다.
- [x] `peerPathDiagnosticsProvider`를 추가했다.
- [x] degraded/failover 상태 projection을 추가했다.
- [x] UI widget이 MessageBus 구현체를 직접 구독하지 않는다.
- [x] peer detail에 active interface 요약을 표시한다.
- [x] peer detail에 remote endpoint 요약을 표시한다.
- [x] diagnostics view에 candidate score/status를 표시한다.
- [x] diagnostics view에 RTT/failureCount를 표시한다.
- [x] Product UI 문구와 Debug UI 문구를 구분했다.
- [ ] path event를 logger/diagnostics collector와 연결했다.
- [x] password/token/session key/file payload가 UI/log에 노출되지 않도록 했다.
- [x] virtual/vpn/bridge interface 표시명이 사용자에게 혼란스럽지 않게 정리했다.

## 테스트

- [x] route candidate provider가 peer별 후보를 반환하는 테스트를 작성했다.
- [x] active path provider가 selected path를 반환하는 테스트를 작성했다.
- [x] degraded 상태 provider 테스트를 작성했다.
- [x] UI widget smoke 테스트를 작성했다.
- [x] candidate 목록이 없을 때 UI fallback 테스트를 작성했다.
- [x] Product UI에 raw local address 목록을 과도하게 노출하지 않는 테스트를 작성했다.
- [x] Debug diagnostics에는 score/status/RTT가 표시되는 테스트를 작성했다.
- [x] password/raw token/session key/file payload가 snapshot에 없는지 테스트했다.
- [x] MessageBus 이벤트가 projection을 직접 변경하지 않고 controller/provider를 통해 반영되는 구조를 확인했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 provider/widget 테스트가 통과한다.
- [x] 일반 사용자는 경로 실패 이유를 간단히 이해할 수 있다.
- [x] 개발자는 candidate 선택과 failover 이유를 진단할 수 있다.
- [x] UI에 긴 interface 이름이 들어와도 레이아웃이 깨지지 않는다.

## 완료 기준

- peer별 active path와 route candidate를 UI/projection에서 확인할 수 있다.
- path degraded/failover 상태가 Product/Debug 목적에 맞게 표시된다.
- 민감 정보 없이 네트워크 경로 문제를 분석할 수 있다.

## 메모

- UI는 과도한 카드 중첩 없이 기존 앱 스타일에 맞춘다.
- 고급 네트워크 정보는 기본 화면보다 세부 패널/진단 영역에 둔다.