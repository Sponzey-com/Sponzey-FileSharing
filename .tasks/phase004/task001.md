# Task 001 - 현재 연결 경로 감사와 실패 원인 기준 고정

## 목표

현재 구현의 실제 연결 흐름을 테스트와 문서로 고정한다.

이 태스크는 기능 구현을 크게 바꾸기 전에 현재 `DiscoveryController -> PeerAuthController -> AuthTransport` 호출 경로, Discovery packet 보안 경계, interface 분류 상태, 실패 원인 표현 방식을 확인하는 기반 작업이다. 이후 task에서 구조를 바꿀 때 무엇을 보존하고 무엇을 의도적으로 깨는지 명확히 알 수 있어야 한다.

## 연관 문서

- [plan.md - 5.1 현재 연결 경로 감사](plan.md#51-현재-연결-경로-감사)
- [plan.md - 2. 현재 구현 상태 요약](plan.md#2-현재-구현-상태-요약)
- [AGENTS.md - TDD Workflow](../AGENTS.md#tdd-workflow)
- [AGENTS.md - Product-Specific Guardrails](../AGENTS.md#product-specific-guardrails)
- [task001_audit.md](task001_audit.md) - 현재 연결 경로 baseline 감사 결과

## 선행 조건

- 현재 `DiscoveryController`, `PeerAuthController`, `AuthTransport`, `ControlTransport` 구현을 읽는다.
- 현재 `DiscoveryPacket`의 `pairingProof` 의미와 `SharedVerifierService` 사용 위치를 확인한다.
- `.tasks/plan.md`가 우선 개발 방향임을 확인한다.

## 포함 기능

### 기능 1. 현재 자동 연결 호출 경로 감사

- Discovery 수신 이후 자동 handshake가 어디서 시작되는지 정리한다.
- `PeerNode`만 전달되는지, `PeerRouteCandidate`/`PeerConnectionPath`가 우회되는지 확인한다.
- `AuthTransport.send`가 `InternetAddress.anyIPv4` 기반 경로만 쓰는지 확인한다.
- 현재 동작을 깨지 않는 characterization test를 먼저 만든다.

### 기능 2. Discovery 보안 경계와 interface 분류 감사

- `DiscoveryPacket.pairingProof`가 인증 verifier와 동일한 값인지 확인한다.
- packet, log, diagnostics에 password-derived reusable verifier가 노출될 수 있는지 확인한다.
- `DartIoNetworkInterfaceInventory`가 물리 Ethernet, bridge, virtual, VPN, Wi-Fi, loopback을 어떻게 분류하는지 fixture로 고정한다.
- Windows/macOS/Linux에서 이름 기반 분류가 흔들릴 수 있는 부분을 기록한다.

### 기능 3. 실패 원인 reason code 기준 정리

- discovery 수신 실패, candidate 없음, control bind 실패, auth timeout, token reject, peer offline을 구분한다.
- Product 로그와 Debug diagnostics에 들어갈 메시지 기준을 정한다.
- 사용자 UI 문구와 개발자 diagnostics 문구를 분리한다.

## 구현 체크리스트

- [x] 현재 `DiscoveryController._maybeAutoHandshake` 호출 조건을 문서화했다.
- [x] 현재 `PeerAuthController.startHandshake(PeerNode)`가 사용하는 address/port 출처를 테스트로 고정했다.
- [x] 현재 `PeerAuthController`가 `AuthTransport`를 직접 읽는 지점을 찾았다.
- [x] 현재 `ControlTransport`가 실제 런타임에서 사용되지 않는 지점을 정리했다.
- [x] 현재 `RawUdpAuthTransport` bind/send 정책을 정리했다.
- [x] `pairingProof`가 `deriveVerifierBase64` 결과인지 확인했다.
- [x] Discovery packet에 인증 재사용 가능 값이 들어가는 위험을 기록했다.
- [x] bridge, virtual, VPN, Wi-Fi, loopback interface name fixture를 만들었다.
- [x] 실패 원인 reason code 후보를 정했다.
- [x] 로그에 password, token, verifier 전체값, session key, 파일 경로가 남지 않는 기준을 정했다.

## 테스트

- [x] 기존 자동 handshake가 `PeerNode.address`와 `PeerNode.port`로 `CONNECT_REQUEST`를 보내는 characterization test를 작성했다.
- [x] `PeerRouteCandidate`와 `PeerConnectionPath`가 현재 handshake 경로에 반영되지 않는 실패/기대 테스트를 작성했다.
- [x] `DiscoveryPacket` encode/decode에 현재 `pairingProof`가 포함되는 테스트를 확인하거나 추가했다.
- [x] `DartIoNetworkInterfaceInventory` type hint fixture 테스트를 작성했다.
- [x] reason code mapper가 discovery/control/auth/offline 원인을 구분하는 단위 테스트를 작성했다.
- [x] 기존 discovery/auth controller 테스트가 통과한다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 discovery/auth/network 단위 테스트가 통과한다.
- [x] 현재 동작과 목표 동작의 차이가 문서와 테스트에서 드러난다.
- [x] 다음 task에서 바꿔야 할 대상이 `DiscoveryController`, `PeerAuthController`, `AuthTransport`, `network diagnostics` 중 어디인지 명확하다.

## 완료 기준

- 현재 연결 흐름이 테스트로 설명된다.
- 보안상 문제가 되는 Discovery field가 확인된다.
- 멀티 Ethernet 연결을 막는 구조적 지점이 코드 참조 기준으로 정리된다.
- 이후 task가 기존 동작을 실수로 되돌리지 않도록 baseline이 만들어진다.