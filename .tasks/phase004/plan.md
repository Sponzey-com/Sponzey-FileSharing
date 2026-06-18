# 연결 우선 멀티 Ethernet 개발 계획

## 0. 문서 상태

이 문서는 현재 구현을 기준으로 한 연결 우선 실행 계획이다. `.tasks/phase003`의 전체 멀티 Ethernet 계획은 장기 범위로 유지하되, 당장 구현 순서는 이 문서가 우선한다.

핵심 판단은 다음과 같다.

- 파일 전송 완성보다 peer 연결 안정화가 먼저다.
- Discovery 후보, Control/Auth 경로, active path projection이 하나의 연결 절차로 이어져야 한다.
- Data Port 전송과 failover는 연결 성공 기준이 고정된 뒤 진행한다.
- 모든 변경은 AGENTS.md의 Layered Architecture, Clean Architecture, Tidy First, TDD, 상태 머신, MessageBus 원칙을 따른다.

## 1. 목표

현재 구현 상태를 기준으로 1차 목표는 파일 전송이 아니라 피어 연결이다.

같은 ID/PW로 로그인한 앱 인스턴스들이 로컬 네트워크 안에서 자동으로 서로를 발견하고, 사용 가능한 Ethernet 인터페이스 후보 중 하나를 선택해 Control/Auth 핸드셰이크를 완료하며, UI와 diagnostics에서 “연결됨”과 “선택된 경로”를 확인할 수 있어야 한다.

멀티 Ethernet 지원은 이 1차 목표 안에 포함한다. 이더넷 카드 2개, USB Ethernet, 내부 Ethernet bridge, 가상화 bridge 네트워크처럼 여러 경로가 동시에 존재하는 경우에도 사용 가능한 경로를 연결 후보로 보존하고, 연결 시도는 선택된 후보의 local address를 기준으로 수행한다.

여기서 “Ethernet”은 물리 유선 NIC만 의미하지 않는다. 제품 목표상 같은 내부망으로 파일 연동이 가능한 유선 계열, USB LAN, OS bridge, VM bridge, Thunderbolt bridge 성격의 인터페이스를 포함한다. VPN, host-only VM, tunnel, link-local, loopback은 기본 자동 연결 후보에서 제외하거나 별도 정책으로 낮은 우선순위를 부여한다.

## 2. 현재 구현 상태 요약

### 이미 구현된 기반

- `AppConfig`는 Discovery `38400/udp`, Control `38401/udp`, Data `38410~38430/udp` 역할을 분리한다.
- `NetworkInterfaceId`, `NetworkInterfaceSnapshot`, `InterfaceAddress`, `UdpInterfaceEndpoint` 도메인 모델이 있다.
- `DartIoNetworkInterfaceInventory`가 OS `NetworkInterface`를 도메인 snapshot으로 변환한다.
- `DiscoveryTargetBuilder`와 subnet 기반 broadcast 계산 모델이 있다.
- `RawUdpDiscoveryTransport`는 사용 가능한 Ethernet 인터페이스를 우선 선택하고, interface local address별 UDP 송신 소켓을 만든다.
- Discovery packet에는 instance id, control port, data port, data port range, source interface/source address hint를 담을 수 있다.
- `PeerRouteCandidate`, `PeerConnectionPath`, path selection policy, `PeerPathProbeCoordinator`, `PeerPathRegistry`가 있다.
- `ControlTransport` 인터페이스는 `UdpInterfaceEndpoint? localEndpoint` 인자를 받을 수 있다.
- `PeerAuthController`는 같은 ID/PW 기반 JWT challenge/response 흐름으로 자동 인증을 수행한다.
- `DiscoveryController`는 온라인 peer를 발견하면 자동 handshake를 시작한다.
- MessageBus에는 discovery, peer link, route candidate, peer path 계열 이벤트 타입이 있다.
- UI diagnostics provider와 network path summary widget 기반이 있다.

### 현재 연결 목표에서 막히는 지점

- `DiscoveryController`가 아직 `PeerRouteCandidateProjection`을 실제 런타임 상태로 사용하지 않는다.
- `DiscoveryDatagram`에는 수신 local interface/local address 정보가 없다.
- Dart `RawDatagramSocket`만으로는 수신 datagram의 destination local address를 직접 얻기 어렵다.
- 현재 `DiscoveryController`는 packet을 `PeerNode` 하나로 병합하고, 같은 peer의 여러 interface candidate를 보존하지 않는다.
- `PeerAuthController`는 `ControlTransport`가 아니라 `AuthTransport`를 직접 사용한다.
- `AuthControlTransportAdapter`는 `localEndpoint` 인자를 받지만 실제 송신에서는 무시한다.
- `RawUdpAuthTransport`는 `InternetAddress.anyIPv4`에만 bind하고, selected local address bind를 지원하지 않는다.
- `PeerPathRegistry`와 diagnostics provider는 실제 discovery/auth 흐름과 완전히 연결되어 있지 않다.
- `peerRouteCandidateStoreProvider`의 기본값은 빈 리스트라 실제 후보가 UI diagnostics로 흐르지 않는다.
- active path가 인증 성공/실패와 함께 상태 전이되지 않는다.
- 현재 Discovery packet의 `pairingProof`는 password-derived 값이므로 보안 경계 재검토가 필요하다. Discovery에는 인증에 재사용 가능한 verifier, JWT, token, session key를 싣지 않는 방향으로 정리해야 한다.
- 현재 자동 handshake 시작 책임이 `DiscoveryController`에 강하게 붙어 있다. 후보 수집과 연결 오케스트레이션을 분리하지 않으면 Discovery, Control/Auth, path state가 한 컨트롤러에 섞일 위험이 있다.
- Linux 지원 하한은 Ubuntu 22.04 LTS로 고정한다. 연결 검증과 릴리스 빌드는 Ubuntu 22.04를 기준으로 하며, 더 최신 Linux 런타임에만 존재하는 동작에 의존하지 않는다.

## 3. 1차 범위

### 포함

- 사용 가능한 Ethernet interface scan과 후보 생성
- Discovery packet 수신 시 peer route candidate 생성
- 같은 peer의 여러 route candidate 보존
- subnet 기반 local interface 추론
- 인증 재료가 아닌 discovery group tag 정리
- 후보 점수화와 active Control path 선택
- 연결 오케스트레이션 application coordinator 도입
- 선택된 Control path의 local address bind 송신
- 자동 Control/Auth 핸드셰이크
- 인증 성공 시 active path 등록
- 인증 실패, timeout, bind 실패의 명시적 상태와 로그
- UI/diagnostics에서 연결 상태와 active path 확인
- macOS, Windows, Ubuntu 22.04 LTS 이상 Linux에서 최소 연결 검증 절차

### 제외

- Data Port 기반 파일 chunk 전송 완성
- 전송 중 Data path failover 완성
- 1:N 파일 전송 최적화
- NAT traversal
- IPv6 active path
- 운영 중 interface hotplug 완전 자동 복구
- OS별 packet info API를 이용한 수신 NIC 직접 판별
- 파일 전송 payload 암호화 또는 Data session key lifecycle 완성

## 4. 설계 결정

### 4.1 Interface 후보 정책

자동 연결 후보는 “실제로 같은 내부망 peer와 통신 가능한 경로”를 기준으로 선정한다.

우선순위는 다음과 같다.

- 1순위: active IPv4를 가진 물리 Ethernet, USB Ethernet, Thunderbolt Ethernet
- 2순위: active IPv4를 가진 내부 Ethernet bridge, VM bridge, OS bridge
- 3순위: active IPv4를 가진 Wi-Fi 또는 unknown LAN interface
- 기본 제외: loopback, link-local, VPN, tunnel, host-only virtual adapter
- 예외 포함: 같은 장비의 다중 인스턴스 검증용 loopback local registry

중요한 점은 bridge를 단순 virtual adapter로 보고 일괄 제외하지 않는 것이다. 내부 Ethernet bridge와 가상화 bridge 네트워크는 실제 peer 연결 경로가 될 수 있으므로 discovery/control 후보에 남겨야 한다. 다만 VPN이나 host-only VM처럼 제품의 로컬 Ethernet 파일 연동 목표와 다른 경로는 기본 자동 선택에서 제외하거나 낮은 점수를 준다.

이 정책은 외부 설정 파일로 제어하지 않는다. 필요한 값은 `AppConfig`, provider override, 테스트 fake inventory, 유스케이스 입력값으로 명시 주입한다.

### 4.2 수신 local interface 판별

1차 구현은 OS별 packet info에 의존하지 않는다.

Dart `RawDatagramSocket`의 수신 이벤트에서 destination local address를 얻기 어렵기 때문에, Discovery packet의 remote address와 현재 `NetworkInterfaceInventory` snapshot을 기준으로 local interface 후보를 계산한다.

기본 정책은 다음과 같다.

- remote address와 같은 subnet에 있는 active Ethernet/bridge IPv4 address를 우선 후보로 만든다.
- 같은 subnet 후보가 여러 개이면 모두 route candidate로 보존한다.
- Ethernet/bridge 후보가 없으면 Wi-Fi 또는 unknown LAN 후보를 fallback으로 만든다.
- 그래도 없으면 unknown local address `0.0.0.0` candidate를 만들고 any bind 경로로만 연결을 시도한다.
- local registry로 발견한 같은 장비 내 다른 인스턴스는 loopback candidate로만 다룬다.

subnet이 겹치는 두 NIC처럼 어느 local interface로 수신됐는지 추론할 수 없는 경우가 있다. 이때 하나의 후보로 단정하지 않고 가능한 후보를 모두 보존한 뒤 Control/Auth 송신에서 실제 응답하는 경로를 active path로 승격한다.

### 4.3 Discovery 보안 경계

Discovery는 peer 검색과 presence에만 사용한다. 같은 ID/PW 그룹을 찾기 위한 식별자는 필요하지만, 그 값이 인증 재료로 재사용되면 안 된다.

정리 방향은 다음과 같다.

- Discovery packet에는 JWT, session key, raw password, password-derived reusable verifier를 넣지 않는다.
- 기존 `pairingProof`가 인증 verifier와 동일한 의미라면 `discoveryGroupTag` 같은 비인증 식별자로 분리한다.
- `discoveryGroupTag`는 protocol version, user id, password에서 파생하더라도 인증 서명 키나 challenge 검증에 재사용하지 않는다.
- tag는 충분히 짧은 수명 또는 protocol scope를 갖고, 로그에는 전체 값을 남기지 않는다.
- 실제 인증은 Control/Auth의 challenge/response에서만 완료한다.

### 4.4 Control/Auth 경로

Control/Auth handshake는 선택된 `PeerConnectionPath.controlEndpoint`를 사용해야 한다.

- 송신 소켓은 selected path의 `localAddress`에 bind한다.
- bind 실패 시 같은 candidate는 degraded/failed로 표시한다.
- fallback anyIPv4 송신은 Debug 로그와 diagnostics에 degraded로 남긴다.
- 인증 성공 시 path 상태는 `active`가 된다.
- 인증 실패와 probe/bind 실패는 구분한다.
- Control/Auth packet은 Discovery packet에 담긴 group tag를 신뢰하지 않고, 같은 ID/PW로 생성한 challenge/response 검증을 반드시 수행한다.

### 4.5 연결 오케스트레이션 책임

DiscoveryController가 직접 모든 연결 절차를 관리하지 않는다.

권장 구조는 다음과 같다.

- `DiscoveryController`: packet 수신, peer presence 갱신, route candidate 발견 이벤트 발행
- `PeerConnectionCoordinator`: candidate 선택, active path registry 갱신, handshake 시작 명령
- `PeerAuthController`: selected path를 사용한 Control/Auth 상태 머신 실행
- `PeerPathRegistry`: active/degraded/failed path projection 보관
- `MessageBus`: 이미 발생한 candidate/path/auth event 발행

MessageBus는 명령 실행 경로가 아니다. 자동 연결 시작은 coordinator가 controller/usecase 메서드를 명시적으로 호출한다.

### 4.6 Probe 전략

1차에서는 별도 packet type을 추가하지 않고, 실제 `CONNECT_REQUEST` 송신과 응답 수신을 연결 probe로 취급한다.

후속 단계에서 Control packet에 `CONTROL_PROBE` 또는 `PATH_PROBE` 타입을 추가할 수 있지만, 지금은 인증 연결을 앞당기는 것이 목표다.

## 5. 개발 단계

### 5.1 현재 연결 경로 감사

- [ ] `DiscoveryController -> PeerAuthController.startHandshake -> AuthTransport.send` 호출 경로를 테스트로 고정한다.
- [ ] 현재 경로가 `PeerRouteCandidate`, `PeerConnectionPath`, `ControlTransport`를 우회한다는 실패 테스트를 작성한다.
- [ ] Discovery packet의 `pairingProof`가 인증 verifier와 동일한 값인지 확인하고, 로그/packet/security risk를 문서화한다.
- [ ] bridge, virtual, VPN, host-only adapter가 현재 inventory에서 어떤 `InterfaceTypeHint`로 분류되는지 fixture로 고정한다.
- [ ] macOS 단일 인스턴스 2개 local registry 연결과 UDP discovery 연결을 구분해 기록한다.
- [ ] Windows VM에서 discovery 수신 실패, control bind 실패, auth timeout을 구분하는 진단 로그 기준을 정한다.

검증:

- [ ] 기존 discovery/auth 테스트가 현재 동작을 설명한다.
- [ ] 실패 원인이 “peer 없음” 하나로 뭉개지지 않는다.

### 5.2 Discovery 보안 경계 정리

- [ ] `pairingProof`를 인증 verifier로 쓰고 있다면 `discoveryGroupTag`로 분리한다.
- [ ] Discovery packet schema는 backward compatible하게 decode한다.
- [ ] Discovery group tag 전체 값은 UI/log/event에 노출하지 않는다.
- [ ] Control/Auth JWT signing key derivation은 Discovery group tag를 사용하지 않는다.
- [ ] AGENTS의 Discovery/Control/Data 책임 분리 기준과 충돌하지 않도록 문서화한다.

테스트:

- [ ] Discovery packet에 JWT/token/session key/raw password가 들어가지 않는 테스트를 작성한다.
- [ ] group tag만 같은 peer는 Discovery 후보가 되지만 인증 완료로 취급되지 않는 테스트를 작성한다.
- [ ] 기존 packet decode 호환 테스트가 통과한다.
- [ ] 로그/event snapshot에 group tag 전체 값이 없는지 검증한다.

### 5.3 Discovery candidate runtime 연결

- [ ] `PeerRouteCandidateProjection` 또는 동등한 application store를 런타임 상태로 둔다.
- [ ] Discovery packet 수신 시 `PeerNode`만 만들지 않고 `PeerRouteCandidate`도 만든다.
- [ ] remote address와 interface inventory snapshot으로 local interface 후보를 계산하는 정책을 만든다.
- [ ] 같은 peer가 여러 local interface 후보로 발견되면 candidate를 모두 보존한다.
- [ ] candidate found/updated/expired 이벤트를 MessageBus에 publish한다.
- [ ] `peerRouteCandidateStoreProvider`가 실제 runtime candidate를 읽도록 바꾼다.
- [ ] DiscoveryController는 candidate 수집까지만 담당하고, 연결 시작 판단은 coordinator로 이동한다.

테스트:

- [ ] remote `192.168.10.20` 수신 시 local `192.168.10.5/24` candidate가 생성된다.
- [ ] local Ethernet 2개가 같은 remote subnet에 걸리면 candidate 2개가 유지된다.
- [ ] bridge interface가 연결 가능한 후보로 보존된다.
- [ ] VPN/host-only/tunnel interface는 기본 자동 후보에서 제외되거나 낮은 우선순위가 된다.
- [ ] Ethernet/bridge 후보가 없으면 Wi-Fi 또는 unknown LAN 후보로 fallback한다.
- [ ] 후보가 없으면 unknown candidate가 만들어지고 any bind 대상이 된다.
- [ ] 기존 `DiscoveryController` peer 목록 테스트가 깨지지 않는다.

### 5.4 Control path selection 연결

- [ ] `PeerConnectionCoordinator`가 peer별 selectable candidate를 path selection policy에 전달한다.
- [ ] selected path를 `PeerPathRegistry`에 저장한다.
- [ ] selected path event를 MessageBus에 publish한다.
- [ ] auto handshake는 `PeerNode`만 넘기지 않고 selected path를 함께 넘긴다.
- [ ] 기존 session에는 selected path id 또는 candidate id를 추적할 수 있는 context를 둔다.
- [ ] candidate가 둘 이상이면 실패한 candidate와 다음 candidate 전이를 상태 머신으로 표현한다.

테스트:

- [ ] 같은 subnet Ethernet candidate가 virtual/unknown candidate보다 먼저 선택된다.
- [ ] bridge candidate는 host-only virtual candidate보다 먼저 선택된다.
- [ ] failed/degraded candidate는 후순위가 된다.
- [ ] 선택된 path가 registry와 diagnostics provider에 보인다.
- [ ] 후보가 없는 peer는 handshake를 시작하지 않고 명확한 진단 메시지를 남긴다.
- [ ] MessageBus event만으로 handshake 명령이 암묵 실행되지 않는 구조를 확인한다.

### 5.5 ControlTransport와 AuthTransport 정렬

- [ ] `PeerAuthController`가 `AuthTransport` 직접 의존 대신 `ControlTransport`를 사용하도록 변경한다.
- [ ] `ControlDatagram`에 local endpoint 정보를 보존할 수 있게 한다.
- [ ] `AuthControlTransportAdapter`가 `localEndpoint`를 무시하지 않도록 구현을 바꾼다.
- [ ] 필요하면 `RawUdpAuthTransport`에 local endpoint 기반 send API를 추가하거나 `RawUdpControlTransport`를 별도로 만든다.
- [ ] selected local address에 bind한 sender socket을 재사용하거나 lifecycle을 명확히 관리한다.
- [ ] platform별 `reuseAddress/reusePort` 정책을 discovery transport와 동일한 기준으로 분리한다.
- [ ] receive socket은 Control port 수신 책임을 유지하고, per-interface sender socket lifecycle과 분리한다.

테스트:

- [ ] selected endpoint가 있으면 fake control transport가 해당 local endpoint로 send된다.
- [ ] raw transport가 selected local address bind를 시도한다.
- [ ] bind 실패 시 fallback/degraded event가 발생한다.
- [ ] Windows에서는 잘못된 `reusePort` 사용으로 `10022`가 재발하지 않는다.
- [ ] token/password/session key가 로그와 event에 남지 않는다.

### 5.6 자동 인증 상태와 active path 전이

- [ ] `PeerAuthController.startHandshake`가 selected path를 인자로 받는다.
- [ ] `_HandshakeContext`에 path id, candidate id, local endpoint를 저장한다.
- [ ] `CONNECT_REQUEST`, `AUTH_CHALLENGE`, `AUTH_TOKEN`, `AUTH_ACCEPT`, `AUTH_REJECT`가 같은 selected path를 사용한다.
- [ ] 인증 성공 시 `PeerConnectionPathStateMachine`에 `authSucceeded`를 적용하고 active path로 등록한다.
- [ ] 인증 실패 또는 timeout 시 path를 failed/degraded로 표시하고 다음 candidate 시도 여부를 결정한다.
- [ ] 이미 authenticated 상태인 peer에는 중복 handshake를 시작하지 않는다.

테스트:

- [ ] selected endpoint로 `CONNECT_REQUEST`가 전송된다.
- [ ] challenge/token/accept 응답도 같은 path context를 유지한다.
- [ ] 인증 성공 후 active path가 `active`가 된다.
- [ ] timeout 시 해당 candidate가 failed가 되고 다음 candidate가 있으면 재시도된다.
- [ ] 모든 candidate 실패 시 peer session은 failed가 되고 UI에 원인이 표시된다.

### 5.7 연결 UI와 diagnostics 정리

- [ ] peer list에는 최소 연결 상태만 표시한다.
- [ ] debug diagnostics에는 candidate count, active interface, local address, remote endpoint, last failure reason을 표시한다.
- [ ] Product UI에는 raw network detail을 과도하게 노출하지 않는다.
- [ ] stale/offline peer는 active path와 authenticated session에서 정리된다.
- [ ] 창 크기를 줄여도 overflow가 나지 않도록 peer card와 diagnostics row를 검증한다.

테스트:

- [ ] active path가 있으면 “연결됨” 상태가 표시된다.
- [ ] candidate만 있고 active path가 없으면 “연결 확인 중” 상태가 표시된다.
- [ ] 모든 candidate 실패 시 간단한 실패 메시지가 표시된다.
- [ ] 긴 interface 이름과 긴 host name에서 overflow가 발생하지 않는다.

### 5.8 수동 연결 검증

- [ ] macOS 동일 장비 앱 2개, 같은 ID/PW, local registry loopback 연결 확인
- [ ] macOS 장비 2대, 같은 Ethernet subnet 연결 확인
- [ ] macOS + Windows Parallels bridged network 연결 확인
- [ ] Windows + macOS에서 firewall 허용 후 연결 확인
- [ ] Ethernet NIC 2개 장비에서 candidate 2개 이상 표시 확인
- [ ] 한 NIC 연결 차단 시 다른 candidate로 연결 재시도 확인
- [ ] 앱 하나 종료 후 peer가 stale/offline으로 정리되는지 확인

## 6. 우선순위

1. 현재 연결 경로와 Discovery 보안 경계 감사
2. Discovery group tag와 인증 verifier 분리
3. Discovery candidate runtime 연결
4. selected path registry와 diagnostics 연결
5. PeerAuthController의 ControlTransport 전환
6. selected local address bind 송신
7. 인증 성공/실패와 active path 상태 전이
8. macOS/Windows 실제 연결 검증
9. Data Port 전송 경로 연결은 1차 연결 안정화 이후 진행

## 7. 완료 기준

- 같은 ID/PW로 로그인한 두 노드가 별도 수동 승인 없이 자동 연결된다.
- 연결은 discovery peer 목록뿐 아니라 `PeerAuthSession.authenticated`와 active `PeerConnectionPath.active`로 확인된다.
- 멀티 Ethernet 환경에서 peer별 route candidate가 하나로 덮어써지지 않는다.
- selected path가 있으면 Control/Auth packet은 해당 local address bind 경로로 나간다.
- bind 실패, auth timeout, token reject, peer offline이 서로 다른 reason code로 기록된다.
- Discovery packet에는 인증에 재사용 가능한 verifier, JWT, token, session key, 파일 정보가 없다.
- bridge network는 연결 가능한 후보로 유지되고, VPN/host-only/tunnel은 기본 자동 연결 후보에서 제외되거나 명확히 낮은 우선순위를 갖는다.
- Product UI는 단순히 연결 상태를 보여주고, Debug diagnostics는 경로 선택 이유를 설명한다.
- `flutter analyze`와 관련 discovery/auth/network/application/widget 테스트가 통과한다.

## 8. 후속 범위

연결 1차 목표가 완료된 뒤 다음 범위를 진행한다.

- Data Port 전용 전송을 active path에 연결
- `TRANSFER_INIT` 이후 chunk를 DataTransport로 이동
- Data path failover effect를 TransferController에 연결
- 1:N 전송에서 peer별 path와 transfer session 완전 분리
- platform별 release packaging과 실제 multi-NIC 베타 검증
