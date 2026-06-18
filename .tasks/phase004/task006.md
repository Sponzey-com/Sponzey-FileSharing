# Task 006 - ControlTransport local address bind와 AuthTransport 정렬

## 목표

Control/Auth packet이 selected path의 local address를 기준으로 송신되도록 transport 계층을 정렬한다.

현재 `ControlTransport` 인터페이스는 `localEndpoint`를 받을 수 있지만 실제 `PeerAuthController`는 `AuthTransport`를 직접 사용하고, adapter는 `localEndpoint`를 무시한다. 이 태스크는 selected path가 실제 UDP 송신 경로에 반영되도록 만드는 핵심 작업이다.

## 연관 문서

- [plan.md - 4.4 Control/Auth 경로](plan.md#44-controlauth-경로)
- [plan.md - 5.5 ControlTransport와 AuthTransport 정렬](plan.md#55-controltransport와-authtransport-정렬)
- [AGENTS.md - Architecture Rules](../AGENTS.md#architecture-rules)
- [task005.md](task005.md)

## 선행 조건

- [task005.md](task005.md)의 selected path가 만들어져야 한다.
- `PeerAuthController.startHandshake`가 selected path를 받을 준비가 되어 있어야 한다.
- Windows `reusePort` 관련 회귀를 반드시 막아야 한다.

## 포함 기능

### 기능 1. PeerAuthController의 ControlTransport 전환

- `PeerAuthController`가 `authTransportProvider` 대신 `controlTransportProvider`를 사용한다.
- packet stream도 `ControlDatagram` 기준으로 처리한다.
- 기존 transfer controller와 auth transport 공유 구조에 영향이 있는지 확인한다.

### 기능 2. selected local address sender socket

- selected `UdpInterfaceEndpoint.localAddress`에 bind한 sender socket으로 Control/Auth packet을 보낸다.
- receive socket은 Control port 수신 책임을 유지한다.
- per-interface sender socket lifecycle을 명확히 관리한다.
- bind 실패 시 anyIPv4 fallback 또는 명확한 failure를 반환한다.

### 기능 3. platform socket policy와 실패 event

- macOS/Linux/Windows `reuseAddress`, `reusePort` 정책을 분리한다.
- Windows에서 `10022`가 재발하지 않도록 한다.
- bind 실패, fallback, degraded 상태를 MessageBus/diagnostics에 남긴다.
- token/password/session key가 로그에 남지 않도록 한다.

## 구현 체크리스트

- [x] `PeerAuthController`가 `ControlTransport`를 사용한다.
- [x] `ControlDatagram` 기반 packet subscription으로 변경했다.
- [x] `AuthControlTransportAdapter`가 `localEndpoint`를 무시하지 않는다.
- [x] `RawUdpAuthTransport` 확장 또는 `RawUdpControlTransport`를 도입했다.
- [x] selected local address sender socket을 bind한다.
- [x] sender socket은 재사용하거나 명확히 close된다.
- [x] receive socket과 sender socket lifecycle을 분리했다.
- [x] bind 실패 시 reason code를 반환한다.
- [x] fallback anyIPv4 송신은 degraded로 표시한다.
- [x] Windows에서 `reusePort: false` 정책을 유지한다.
- [x] 로그에 packet type, peer/session 요약만 남기고 token 본문은 남기지 않는다.

## 테스트

- [x] fake control transport가 selected endpoint를 받는 controller 테스트를 작성했다.
- [x] selected endpoint가 있으면 `CONNECT_REQUEST`가 해당 endpoint로 send되는 테스트를 작성했다.
- [x] selected local address bind 성공 테스트를 작성했다.
- [x] bind 실패 시 fallback event가 publish되는 테스트를 작성했다.
- [x] 모든 bind 실패 시 handshake가 failed/degraded로 전이되는 테스트를 작성했다.
- [x] Windows socket option 정책 테스트를 작성했다.
- [x] token/password/session key가 로그/event에 없는지 검증했다.
- [x] 기존 peer auth controller 테스트가 통과한다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] auth/control infrastructure 테스트가 통과한다.
- [x] selected path 기반 Control packet 송신이 fake transport와 raw transport 테스트로 재현된다.
- [x] local bind 실패가 침묵하지 않는다.
- [x] OS routing 의존 경로와 selected endpoint 경로가 코드상 구분된다.

## 구현 결과

- `PeerAuthController`는 `authTransportProvider` 직접 의존 대신 `controlTransportProvider`를 사용한다.
- `ControlDatagram` 기반 packet subscription으로 바꾸어 수신 datagram의 local endpoint context를 보존할 수 있게 했다.
- `RawUdpControlTransport`를 도입해 Control receive socket과 selected local address sender socket lifecycle을 분리했다.
- selected path가 있으면 `CONNECT_REQUEST`는 selected candidate의 remote endpoint로 전송되고, selected `controlEndpoint.localAddress`에 bind한 sender socket을 사용한다.
- selected local address bind 실패 시 anyIPv4 sender로 fallback하고 `controlSenderBindFallback` event를 publish한다.
- fallback까지 실패하면 `ControlTransportBindException(reasonCode: controlBindFailed)`으로 실패를 명시하고, `PeerAuthSession.failed`로 전이한다.
- `AuthControlTransportAdapter`는 selected local endpoint를 조용히 무시하지 않고 명시적으로 거부한다. 테스트 harness는 기존 fake `AuthTransport`와 `ControlTransport`를 adapter로 연결한다.
- `ControlSocketBindPolicy`를 추가해 receive/sender socket option을 분리했고, Windows에서는 sender/receive 모두 `reusePort: false`가 되도록 고정했다.
- 로그와 이벤트에는 packet type, 축약 session, endpoint/reason만 남기고 token/password/session key 본문은 남기지 않는다.

## 실행 결과

- `flutter test test/infrastructure/control/control_transport_test.dart test/infrastructure/control/raw_udp_control_transport_test.dart test/application/auth/peer_auth_controller_test.dart test/application/network/peer_connection_coordinator_test.dart`: 통과
- `flutter test test/application/discovery/discovery_controller_test.dart`: 통과
- `flutter test test/application/transfer/transfer_controller_test.dart`: 통과
- `flutter analyze`: 통과
- `flutter test`: 통과, 179 tests
- 참고: 전체 테스트 중 기존 Drift multiple database warning이 출력되지만 실패는 아니다.

## 완료 기준

- selected path가 Control/Auth UDP 송신 경로에 실제 반영된다.
- fallback과 실패가 diagnostics로 추적된다.
- Windows/macOS/Linux socket option 차이가 테스트와 정책으로 설명된다.