# Task 005 - Control transport local bind 확장

## 목표

Control/Auth 송신이 OS routing table에만 의존하지 않도록, 선택된 route candidate의 local address/interface endpoint를 기준으로 UDP socket bind와 send를 수행할 수 있게 한다.

기존 `AuthTransport`가 담당하던 Control Port 역할을 명확히 정리하고, local bind 실패 시 fallback/degraded 상태를 관찰 가능하게 만든다.

## 연관 문서

- [plan.md - Control Transport 분리](plan.md#91-control-transport-분리)
- [plan.md - 특정 local address bind](plan.md#92-특정-local-address-bind)
- [task004.md](task004.md)
- [phase002 task007](../phase002/task007.md)

## 선행 조건

- [task004.md](task004.md)의 selected path 모델과 probe 상태 머신이 있어야 한다.
- phase002의 JWT challenge/response 인증 흐름이 정상 동작해야 한다.

## 포함 기능

### 기능 1. ControlTransport interface 도입

- Control packet 송수신 역할을 `ControlTransport`로 명명한다.
- 기존 `AuthTransport`와 migration 호환 경로를 정한다.
- send API가 optional local endpoint 또는 selected candidate를 받을 수 있게 한다.

### 기능 2. local address specific bind

- selected path의 local address에 socket bind를 시도한다.
- bind 성공 시 해당 endpoint로 Control packet을 송수신한다.
- bind 실패 시 platform별 fallback을 적용한다.
- fallback은 조용히 숨기지 않고 degraded event로 남긴다.

### 기능 3. PeerAuthController 연결

- PeerAuthController가 selected path를 사용해 LinkRequest/Challenge/Token/Accept를 보낸다.
- 수신 datagram과 selected path를 correlation할 수 있게 한다.
- 기존 단일 인터페이스 테스트가 깨지지 않도록 기본 path fallback을 유지한다.

## 구현 체크리스트

- [x] `ControlTransport` interface를 정의했다.
- [x] 기존 `AuthTransport`와 호환 alias 또는 adapter를 만들었다.
- [x] `ControlDatagram` 모델을 정의했다.
- [x] send API에 `UdpInterfaceEndpoint? localEndpoint`를 추가했다.
- [x] selected path 없이도 기존 `anyIPv4` 경로가 동작한다.
- [ ] selected path가 있으면 specific local address bind를 시도한다.
- [ ] bind 실패 시 `anyIPv4` fallback 또는 명확한 failure를 반환한다.
- [ ] fallback 시 candidate/path status를 degraded로 표시한다.
- [ ] Windows/macOS/Linux socket option 차이를 코드 주석이 아니라 정책으로 분리했다.
- [ ] PeerAuthController가 selected path를 사용할 수 있게 했다.
- [ ] Control packet 로그에 token/password/session key가 남지 않는다.
- [ ] MessageBus에 `controlPathBindFailed`, `controlPathDegraded` 이벤트를 추가했다.

## 테스트

- [x] selected local endpoint가 없을 때 기존 handshake가 통과하는 테스트를 작성했다.
- [x] selected local endpoint가 있을 때 fake transport가 해당 endpoint를 사용한다는 테스트를 작성했다.
- [ ] specific bind 실패 시 fallback event가 publish되는 테스트를 작성했다.
- [ ] fallback 후 path degraded 상태가 되는 테스트를 작성했다.
- [ ] 모든 bind 실패 시 probe/auth가 failed로 전이하는 테스트를 작성했다.
- [ ] LinkRequest/Challenge/Token/Accept가 selected path correlationId를 유지하는 테스트를 작성했다.
- [ ] raw token이 로그/event에 없는지 검증했다.
- [x] 기존 `peer_auth_controller_test.dart`가 통과한다.
- [x] 기존 `transfer_controller_test.dart`의 인증 준비 흐름이 통과한다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위/Application 테스트가 통과한다.
- [x] selected path 기반 Control packet 송신이 fake transport로 재현된다.
- [ ] local bind 실패가 침묵하지 않는다.
- [ ] OS routing 의존 경로와 selected endpoint 경로가 코드상 구분된다.

## 완료 기준

- Control/Auth 핸드셰이크가 선택된 local interface endpoint를 기준으로 수행될 수 있다.
- fallback과 degraded 상태가 MessageBus와 state projection으로 관찰 가능하다.
- 후속 DataTransport가 같은 selected path를 사용할 수 있다.

## 메모

- 기존 `AuthTransport` 이름은 단계적으로 정리한다.
- rename이 큰 변경이면 adapter를 먼저 두고 후속 cleanup으로 분리한다.
