# Task 001 Audit - 현재 연결 경로와 실패 기준 Baseline

이 문서는 현재 구현을 바꾸기 전에 연결 경로, discovery 보안 경계, interface 분류 휴리스틱, 실패 원인 표현의 baseline을 고정한다.

## 1. 현재 자동 연결 호출 경로

현재 자동 handshake 시작 지점은 `DiscoveryController` 내부 두 군데다.

- `lib/application/discovery/discovery_controller.dart`
  - discovery packet 수신 후 `_handlePacket -> _maybeAutoHandshake(peer)`
  - local registry 병합 후 `_mergeLocalRegistryPeers -> _maybeAutoHandshake(peer)`

`_maybeAutoHandshake`의 현재 조건은 다음과 같다.

- `peer.isCompatible == true`
- `peer.presence == PeerPresence.online`
- 기존 세션이 `authenticated`가 아님
- 기존 세션 상태가 `connecting`, `challengeIssued`, `tokenSent`, `verifying`가 아님
- 마지막 자동 시도 시각이 `discoveryBroadcastInterval` cooldown 밖임

그 뒤 실제 연결 시작은 아래 한 줄이다.

- `ref.read(peerAuthControllerProvider.notifier).startHandshake(peer);`

즉 현재 discovery는 `PeerNode` 대표 projection만 넘기고, route candidate나 selected path를 넘기지 않는다.

## 2. 현재 handshake route baseline

현재 `PeerAuthController.startHandshake(PeerNode)`는 `PeerNode.address`와 `PeerNode.port`만 사용한다.

- `lib/application/auth/peer_auth_controller.dart`
  - `_HandshakeContext.peerAddress = peer.address`
  - `_HandshakeContext.peerPort = peer.port`
  - `_send(... address: InternetAddress(peer.address), port: peer.port)`

현재 runtime에 존재하는 `PeerRouteCandidate`, `PeerConnectionPath`, `ControlTransport`는 handshake 시작 경로에 반영되지 않는다.

### characterization 결과

- active path가 있어도 `startHandshake`는 그 path의 remote endpoint를 쓰지 않는다.
- route candidate store에 더 좋은 candidate가 있어도 무시된다.
- 실제 CONNECT_REQUEST 목적지는 항상 `PeerNode.address:PeerNode.port`다.

이 baseline은 `test/application/auth/peer_auth_controller_test.dart`에 고정했다.

## 3. AuthTransport / ControlTransport 정렬 상태

현재 `PeerAuthController`는 `AuthTransport`를 직접 읽는다.

- `lib/application/auth/peer_auth_controller.dart`
  - `_initialize()`에서 `authTransportProvider.start(...)`
  - `_initialize()`에서 `authTransportProvider.packets.listen(...)`
  - `_send()`에서 `authTransportProvider.send(...)`

현재 `ControlTransport`는 runtime 분리 구현이 아니라 adapter만 존재한다.

- `lib/infrastructure/control/control_transport.dart`
  - `AuthControlTransportAdapter`가 `AuthTransport`를 그대로 감싼다.
  - `controlTransportProvider`는 현재 `authTransportProvider` wrapper다.

즉 현재 코드에서 Control/Auth 분리는 개념만 있고, 실제 런타임 경로는 아직 `AuthTransport` 단일 경로다.

## 4. RawUdpAuthTransport bind/send baseline

현재 `RawUdpAuthTransport` 정책은 다음과 같다.

- bind 주소: `InternetAddress.anyIPv4`
- `reuseAddress: false`
- `reusePort: false`
- preferred port 충돌 시 ephemeral port로 fallback
- send socket은 bind socket 하나를 그대로 사용
- local interface / local address 선택 기능 없음

따라서 멀티 Ethernet 환경에서 특정 local NIC를 강제해 handshake를 보낼 수 없다.

관련 구현:

- `lib/infrastructure/auth/raw_udp_auth_transport.dart`

## 5. Discovery 보안 경계 baseline

현재 `DiscoveryPacket.pairingProof`는 discovery 전용 tag가 아니라 인증 verifier와 동일한 값이다.

- `lib/application/discovery/discovery_controller.dart`
  - `_currentPairingProof()`가 `SharedVerifierService.deriveVerifierBase64(...)`를 사용한다.
- `lib/infrastructure/auth/shared_verifier_service.dart`
  - `deriveVerifierBase64(userId, password)`
  - `deriveSigningKey(verifierBase64, sessionId, nonce, ...)`

즉 현재 discovery packet에 들어가는 `pairingProof`는 후속 JWT signing key 파생의 입력으로 재사용된다.

### 현재 위험

- discovery packet에 password-derived reusable verifier가 들어간다.
- `DiscoveryState.pairingProofPreview`와 diagnostics에서 preview가 보일 수 있다.
- packet 자체에는 전체 verifier가 실린다.
- 현재 로그는 packet 전체를 그대로 남기지는 않지만, payload 경계가 discovery 전용으로 분리되어 있지 않다.

이 baseline은 `test/application/discovery/discovery_controller_test.dart`와 `test/infrastructure/discovery/discovery_packet_test.dart`에서 확인 가능하다.

## 6. Interface 분류 baseline

현재 `DartIoNetworkInterfaceInventory`는 OS 공통 API가 제공하는 type metadata를 쓰지 못하고 이름 휴리스틱으로 분류한다.

- ethernet: `en*`, `eth*`
- wifi: `wifi`, `wi-fi`, `wlan`, `airport`
- bridge: `bridge*`, `br*`
- virtual: `docker`, `vbox`, `vmnet`, `veth`, `hyper-v`
- vpn: `utun`, `tun`, `tap`
- loopback: 이름 또는 loopback address

### 흔들릴 수 있는 지점

- Windows의 `Local Area Connection`, `Ethernet Instance 0` 같은 이름은 현재 `unknown`
- macOS/Windows/Linux의 localized adapter name은 휴리스틱 miss 가능
- bridge와 virtual이 이름상 겹칠 수 있음

이 baseline은 `test/infrastructure/network/dart_io_network_interface_inventory_test.dart`에 fixture로 고정했다.

## 7. 실패 원인 reason code baseline

현재 task001에서 다음 reason code를 baseline 후보로 고정한다.

- `discoveryReceiveFailed`
- `routeCandidateMissing`
- `controlBindFailed`
- `authTimeout`
- `authTokenRejected`
- `peerOffline`

구분 원칙:

- Product UI 문구는 짧고 원인 범주만 보여준다.
- Debug diagnostics 문구는 stage와 세부 detail을 보여준다.
- token, password, verifier 전체값, session key, 파일 전체 경로는 포함하지 않는다.

현재 baseline mapper는 아래 파일에 추가했다.

- `lib/application/network/peer_link_reason_code.dart`

테스트:

- `test/application/network/peer_link_reason_code_test.dart`

## 8. 다음 task에서 바꿔야 할 대상

현재 baseline 기준으로 다음 수정 포인트는 명확하다.

1. `DiscoveryController`
   - discovery packet에서 representative `PeerNode`만 만들지 말고 route candidate를 같이 runtime에 보존해야 한다.

2. `PeerAuthController`
   - `startHandshake(PeerNode)`만으로는 부족하다.
   - selected candidate 또는 `PeerConnectionPath`를 인자로 받는 경로가 필요하다.

3. `AuthTransport` / `ControlTransport`
   - local interface / local address bind가 가능한 control 경로가 필요하다.
   - 현재 adapter 구조는 실질적인 분리가 아니다.

4. `network diagnostics`
   - product summary와 debug detail은 이미 분리 시작점이 있지만, 실제 active path / failure reason과 연결이 더 필요하다.

## 9. 검증 결과

- `flutter test test/application/auth/peer_auth_controller_test.dart test/application/discovery/discovery_controller_test.dart test/infrastructure/discovery/discovery_packet_test.dart test/infrastructure/network/dart_io_network_interface_inventory_test.dart test/application/network/peer_link_reason_code_test.dart test/infrastructure/control/control_transport_test.dart`
- `flutter analyze`
- `flutter test`

전체 테스트는 통과했다. `flutter test` 중 Drift multiple database debug warning이 출력되지만 테스트 실패는 아니며, task001 변경 범위의 실패는 없다.

## 10. 결론

현재 구현은 "peer 발견 -> representative peer 하나 선택 -> 그 peer 주소로 바로 auth handshake" 구조다.

이 구조에서는:

- 멀티 Ethernet candidate를 보존하지 못하고
- control/auth local bind를 선택하지 못하며
- discovery 보안 경계가 인증 verifier와 섞여 있다.

task001의 목적은 이 baseline을 테스트와 문서로 고정하는 것이다. 이후 task002 이상에서는 이 baseline을 의도적으로 깨면서 discovery/security/control path를 분리해야 한다.
