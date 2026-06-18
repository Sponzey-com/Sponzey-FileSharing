# Sponzey FileSharing 멀티 Ethernet 인터페이스 전체 지원 개발 계획

이 문서는 하나의 PC에 여러 Ethernet, Wi-Fi, VPN, 가상 어댑터, 브리지 어댑터가 동시에 존재하는 환경에서 Sponzey FileSharing이 가능한 모든 유효 네트워크 인터페이스를 활용해 peer를 발견하고, 연결하고, 파일을 전송하도록 만들기 위한 상세 개발 계획이다.

기존 phase002 문서는 [.tasks/phase002](../phase002/README.md)로 이동했다. 이 계획은 phase002에서 마련한 상태 머신, MessageBus, Discovery/Control/Data UDP 포트 분리, 인증, 전송 신뢰성 기반 위에 네트워크 인터페이스 계층을 명시적으로 추가한다.

## 1. 배경과 문제 정의

현재 구현은 다중 네트워크 인터페이스 환경을 부분적으로만 지원한다.

- Discovery transport는 `NetworkInterface.list()`로 IPv4 인터페이스를 훑고 broadcast/multicast 대상 후보를 만든다.
- Discovery receive socket은 `InternetAddress.anyIPv4`에 bind한다.
- Control/Auth transport도 `InternetAddress.anyIPv4`에 bind하고, 송신 경로 선택은 OS routing table에 맡긴다.
- Data Port 전용 transport는 아직 완전히 분리되지 않았고, 현재 전송은 기존 auth/control transport 경로를 재사용한다.
- peer projection에는 어떤 local interface를 통해 발견됐는지, 어떤 local address를 source bind로 써야 하는지, 어떤 endpoint 후보가 있는지 명시적으로 저장하지 않는다.
- directed broadcast 계산은 현재 `/24` 형태의 단순 계산에 가깝고, 실제 subnet mask/prefix length를 반영하지 않는다.

따라서 현재 상태는 “여러 인터페이스 중 일부로 discovery가 될 수 있고, 연결/전송은 OS 라우팅에 의존한다”에 가깝다. 제품 목표는 “활성화된 모든 유효 인터페이스를 후보로 관리하고, discovery부터 control/data 전송까지 선택된 경로를 명시적으로 추적하며, 실패 시 다른 인터페이스 후보로 복구하는 것”이다.

## 2. 목표

### 2.1 사용자 목표

- 사용자는 여러 Ethernet 포트, Wi-Fi, USB LAN, Thunderbolt Bridge, VM network가 있는 PC에서도 peer를 안정적으로 찾을 수 있어야 한다.
- 사용자는 같은 PC의 어떤 네트워크 경로로 peer와 연결됐는지 대략적으로 확인할 수 있어야 한다.
- 특정 인터페이스 하나가 막히거나 방화벽에 차단되어도 다른 유효 인터페이스 후보가 있으면 자동 재시도되어야 한다.
- 연결과 전송이 실패했을 때 “peer가 없음”과 “특정 네트워크 인터페이스 경로 실패”를 구분할 수 있어야 한다.
- 기본값은 자동 선택이어야 하며, 고급 설정은 필요할 때만 제공한다.

### 2.2 기술 목표

- OS routing table에만 의존하지 않고 interface 후보를 도메인 모델로 명시한다.
- Discovery, Control, Data transport가 모두 `localAddress/interfaceId` 후보를 받을 수 있게 한다.
- Discovery packet과 peer projection에 interface/candidate 정보를 추가하되, 민감 정보는 절대 넣지 않는다.
- 상태 머신으로 interface scan, candidate discovery, path selection, failover 절차를 관리한다.
- MessageBus로 interface 상태, candidate 발견, path 선택, failover, degraded 전송 이벤트를 관찰 가능하게 만든다.
- 테스트는 fake interface inventory/fake UDP transport를 우선 사용하고, 실제 OS multi-NIC 확인은 수동 체크리스트로 분리한다.

## 3. 비목표

이번 계획에서 제외하는 내용은 다음과 같다.

- 인터넷 원격 전송
- NAT traversal
- 중앙 서버 기반 relay
- TURN/STUN 도입
- IPv6 전체 지원
- 네트워크 인터페이스 hotplug를 실시간 완전 지원하는 UI
- 관리자 권한으로 방화벽 규칙을 자동 변경하는 기능
- 사용자의 OS 라우팅 테이블을 앱에서 변경하는 기능

IPv6는 모델이 확장 가능하도록 막지 않되, 첫 구현은 IPv4 기반으로 제한한다.

## 4. 설계 원칙

### 4.1 계층 원칙

- `domain`은 interface 후보, route 후보, path selection policy를 순수 모델로 표현한다.
- `application`은 interface inventory, discovery/controller, auth/controller, transfer/controller를 조합한다.
- `infrastructure`는 실제 `NetworkInterface`, UDP socket bind/send, platform별 subnet 정보 수집을 담당한다.
- `presentation`은 interface 후보와 연결 경로를 읽기 전용 projection으로 보여준다.

### 4.2 설정 원칙

- 외부 설정 파일에 interface 정책을 저장하지 않는다.
- 환경 상수는 최초 bootstrap 시점에만 받는다.
- 런타임 중간에 포트나 interface bind 정책을 숨겨서 바꾸지 않는다.
- interface 선택 정책은 값 객체와 인자로 전달한다.
- 기본 정책은 자동이며, 테스트는 명시적 fake inventory를 주입한다.

### 4.3 상태 머신 원칙

네트워크 인터페이스 처리는 다음 상태 머신으로 분리한다.

- `NetworkInterfaceInventoryStateMachine`
- `DiscoveryPathStateMachine`
- `PeerRouteCandidateStateMachine`
- `PeerConnectionPathStateMachine`
- `DataPathFailoverStateMachine`

각 상태 머신은 socket, timer, file system을 직접 사용하지 않는다. 전이 결과는 effect로 표현하고 controller가 실행한다.

### 4.4 MessageBus 원칙

MessageBus는 명령 실행이 아니라 이미 발생한 사실을 전달한다.

예:

- `NetworkInterfaceScanned`
- `NetworkInterfaceRejected`
- `DiscoveryProbeSentOnInterface`
- `PeerRouteCandidateFound`
- `PeerPathSelected`
- `PeerPathFailed`
- `PeerPathFailoverStarted`
- `DataPathBound`
- `DataPathDegraded`

이벤트에는 password, token, session key, 파일 원문, 전체 파일 경로를 넣지 않는다.

## 5. 현재 구조 감사 기준

구현 전 다음 파일과 흐름을 다시 확인한다.

- `lib/infrastructure/discovery/raw_udp_discovery_transport.dart`
- `lib/infrastructure/auth/raw_udp_auth_transport.dart`
- `lib/application/discovery/discovery_controller.dart`
- `lib/application/auth/peer_auth_controller.dart`
- `lib/application/transfer/transfer_controller.dart`
- `lib/app/app_config.dart`
- `lib/core/network/udp_port_config.dart`
- `lib/infrastructure/discovery/local_instance_registry.dart`
- `test/application/discovery/discovery_controller_test.dart`
- `test/application/transfer/transfer_controller_test.dart`

감사 체크리스트:

- [ ] 어떤 socket이 `anyIPv4`에 bind되는지 정리한다.
- [ ] 어떤 socket이 ephemeral port fallback을 하는지 정리한다.
- [ ] discovery broadcast 대상 계산 로직을 정리한다.
- [ ] peer projection에 현재 없는 route/interface 필드를 정리한다.
- [ ] 로컬 인스턴스 registry가 multi-instance와 multi-interface에서 충돌할 수 있는 key를 정리한다.
- [ ] Data Port 전용 transport 미분리 상태가 multi-interface에 주는 영향을 정리한다.

## 6. 도메인 모델 설계

### 6.1 NetworkInterfaceId

인터페이스 식별자는 OS별 변동 가능성을 고려해 다음 값을 가진다.

- `name`: OS가 제공하는 interface name. 예: `en0`, `en5`, `Ethernet`, `Wi-Fi`.
- `index`: OS가 제공하면 사용한다.
- `stableId`: 앱 내부에서 name/type/address를 조합해 만드는 비교용 값.
- `displayName`: UI/로그용 이름.

`stableId`는 영구 저장 신뢰 대상으로 쓰지 않는다. 인터페이스는 재부팅/드라이버/VM 상태에 따라 달라질 수 있기 때문이다.

### 6.2 NetworkInterfaceSnapshot

필드:

- `id`
- `name`
- `displayName`
- `typeHint`: ethernet, wifi, loopback, vpn, virtual, bridge, unknown
- `isUp`
- `supportsMulticast`
- `isLoopback`
- `addresses`
- `capturedAt`

도메인에서는 OS API 타입을 직접 들고 있지 않는다.

### 6.3 InterfaceAddress

필드:

- `address`
- `family`: ipv4, ipv6
- `prefixLength`
- `netmask`
- `broadcastAddress`
- `isPrivate`
- `isLinkLocal`
- `isLoopback`

첫 구현은 IPv4만 active candidate로 사용한다. IPv6 주소는 목록에는 보존하되 candidate selection에서는 제외한다.

### 6.4 UdpInterfaceEndpoint

필드:

- `role`: discovery, control, data
- `interfaceId`
- `localAddress`
- `port`
- `bindMode`: any, specificAddress
- `reuseAddress`
- `reusePort`

Discovery receive는 platform별로 `any` bind가 유리할 수 있으나, 송신과 candidate 기록은 interface별 local address를 명시한다.

### 6.5 PeerRouteCandidate

필드:

- `candidateId`
- `peerId`
- `remoteAddress`
- `remoteDiscoveryPort`
- `remoteControlPort`
- `remoteDataPort`
- `remoteDataPortRange`
- `localInterfaceId`
- `localAddress`
- `discoveredBy`: broadcast, multicast, unicastProbe, localRegistry
- `lastSeenAt`
- `rttMs`
- `failureCount`
- `score`
- `status`: new, probing, reachable, degraded, failed, expired

같은 peer가 여러 인터페이스에서 발견되면 peer는 하나로 합치되 route candidate는 여러 개 유지한다.

### 6.6 PeerConnectionPath

필드:

- `peerId`
- `selectedCandidateId`
- `controlLocalEndpoint`
- `controlRemoteEndpoint`
- `dataLocalEndpoint`
- `dataRemoteEndpoint`
- `selectedAt`
- `reason`: lowestRtt, sameSubnet, previouslySuccessful, manualOverride, fallback
- `status`: selected, validating, active, degraded, failed, retired

Control과 Data가 같은 candidate를 쓰는 것이 기본이다. 단, Data Port range나 OS bind 실패 때문에 data endpoint만 다른 local port를 쓸 수 있다.

## 7. Interface Inventory 설계

### 7.1 NetworkInterfaceInventory

인터페이스 목록 수집을 위한 infrastructure 인터페이스를 둔다.

```dart
abstract interface class NetworkInterfaceInventory {
  Future<List<NetworkInterfaceSnapshot>> scan();
}
```

구현:

- `DartIoNetworkInterfaceInventory`
- 테스트용 `FakeNetworkInterfaceInventory`

첫 구현에서 반드시 해야 할 것:

- loopback 제외 정책을 명시한다.
- link-local 제외 정책을 명시한다.
- IPv4 후보만 active discovery candidate로 올린다.
- multicast 지원 여부를 기록한다.
- interface 이름과 address 목록을 debug 로그에 남기되 민감 정보는 남기지 않는다.

### 7.2 Subnet 계산

현재 directed broadcast는 단순히 `a.b.c.255`를 만든다. 이를 다음 구조로 교체한다.

- OS가 prefixLength/netmask를 제공하면 그 값을 사용한다.
- 제공하지 않으면 conservative fallback으로 `/24`를 사용하되 Development 로그에 fallback을 남긴다.
- subnet이 `/31`, `/32`이면 directed broadcast 후보에서 제외한다.
- link-local `169.254.0.0/16`은 기본 제외한다.
- loopback `127.0.0.0/8`은 LAN discovery에서는 제외하고 local registry에만 사용한다.

테스트 케이스:

- `192.168.10.23/24 -> 192.168.10.255`
- `10.20.30.40/16 -> 10.20.255.255`
- `172.16.5.7/20 -> 172.16.15.255`
- `10.0.0.2/31 -> 없음`
- `169.254.1.2/16 -> 제외`

## 8. Discovery 설계

### 8.1 Discovery 송신 전략

각 유효 IPv4 인터페이스별로 다음 후보를 만든다.

- limited broadcast: `255.255.255.255`
- directed broadcast: subnet 기반 broadcast
- multicast group: `239.255.42.99`
- local registry: same-machine only

송신 시 `DiscoveryProbeSentOnInterface` 이벤트를 publish한다.

송신 payload에는 다음 필드를 추가한다.

- `messageId`
- `instanceId`
- `deviceId`
- `controlPort`
- `dataPort`
- `dataPortRange`
- `capabilities`
- `sourceInterfaceId` 또는 `sourceInterfaceHint`
- `sourceAddress`
- `sentAtEpochMs`

주의:

- `sourceAddress`는 민감 정보가 아니라 네트워크 연결 후보 정보다.
- 단, public IP가 들어갈 가능성은 낮지만 Debug/Development 로그 목적을 명확히 분리한다.

### 8.2 Discovery 수신 전략

수신 datagram에서 다음 정보를 route candidate로 만든다.

- datagram remote address
- datagram source port
- packet의 control/data endpoint
- 수신한 local socket/interface 정보

Dart `RawDatagramSocket`에서 datagram이 어떤 local interface로 들어왔는지 직접 얻기 어렵다면, 1차 구현에서는 다음 순서로 추정한다.

1. remote address와 local interface subnet이 같은 후보를 찾는다.
2. 후보가 하나면 해당 local interface로 매핑한다.
3. 후보가 여러 개면 모든 후보를 tentative candidate로 만든다.
4. 이후 Control probe RTT 결과로 실제 후보를 정한다.

### 8.3 Peer projection

`PeerNode`에는 단일 `address/port`만 유지하되, application layer에는 별도 projection을 둔다.

- `PeerRouteCandidateProjection`
- `PeerNetworkPathProjection`

UI는 peer row에는 대표 경로만 보여주고, 세부 패널에서 후보 목록을 볼 수 있게 한다.

### 8.4 Discovery 상태 머신

`DiscoveryPathStateMachine` 상태:

- `idle`
- `scanningInterfaces`
- `buildingTargets`
- `broadcasting`
- `collectingResponses`
- `candidatesAvailable`
- `degraded`
- `failed`
- `stopped`

주요 이벤트:

- `scanRequested`
- `interfacesScanned`
- `interfaceRejected`
- `broadcastSent`
- `packetReceived`
- `candidateCreated`
- `candidateExpired`
- `stopRequested`
- `transportFailed`

테스트:

- 유효 인터페이스가 2개면 discovery target이 2개 이상 생성된다.
- loopback/link-local은 LAN discovery 후보에서 제외된다.
- 같은 peer가 두 인터페이스에서 발견되면 peer는 하나, candidate는 둘이다.
- protocol mismatch는 candidate를 만들 수 있어도 peer는 incompatible로 표시된다.

## 9. Control/Auth 연결 설계

### 9.1 Control Transport 분리

현재 `AuthTransport`는 Control Port 역할을 한다. multi-interface 지원에서는 이름과 역할을 정리한다.

- `ControlTransport` 인터페이스를 도입한다.
- 기존 `AuthTransport`는 migration alias로 유지하거나 내부 구현명을 교체한다.
- `send(packet, remote, port)`에 `localEndpoint` 또는 `candidateId`를 받을 수 있게 한다.

예:

```dart
Future<void> send(
  ControlPacket packet, {
  required InternetAddress remoteAddress,
  required int remotePort,
  UdpInterfaceEndpoint? localEndpoint,
});
```

### 9.2 특정 local address bind

Control handshake 시 선택 candidate가 있으면 해당 local address에 bind한 socket을 사용한다.

정책:

- 기본은 `specificAddress` bind를 시도한다.
- 실패하면 `anyIPv4` fallback을 시도하되, candidate status를 `degraded`로 표시한다.
- fallback 사실을 Debug 로그와 MessageBus event로 남긴다.
- OS가 허용하지 않는 경우를 플랫폼별로 분기한다.

### 9.3 Candidate validation

Discovery로 발견된 candidate는 바로 authenticated session으로 쓰지 않고 Control probe로 검증한다.

검증 절차:

1. `PeerRouteCandidateFound`
2. `ControlProbeRequested`
3. candidate local endpoint로 LinkRequest 전송
4. challenge/response 성공
5. RTT와 성공 시간을 candidate에 기록
6. `PeerPathSelected`

실패 절차:

1. timeout
2. candidate `failureCount += 1`
3. 다음 candidate 선택
4. 모든 candidate 실패 시 peer link failed

### 9.4 PeerConnectionPath 상태 머신

상태:

- `none`
- `candidateAvailable`
- `probing`
- `selected`
- `authenticating`
- `authenticated`
- `degraded`
- `failed`
- `retired`

이벤트:

- `candidateDiscovered`
- `probeStarted`
- `probeSucceeded`
- `probeFailed`
- `authSucceeded`
- `authFailed`
- `pathTimeout`
- `failoverRequested`
- `retireRequested`

테스트:

- 가장 낮은 RTT candidate를 선택한다.
- 이전 성공 candidate가 있으면 같은 조건에서 우선한다.
- selected path 실패 시 다음 candidate로 failover한다.
- 모든 candidate 실패 시 peer link failed가 된다.

## 10. Data Port 전송 설계

### 10.1 DataTransport 도입

Data Port 전용 transport를 추가한다.

```dart
abstract interface class DataTransport {
  Stream<DataDatagram> get packets;

  Future<UdpInterfaceEndpoint> bind({
    required UdpInterfaceEndpoint preferredEndpoint,
  });

  Future<void> send(
    DataPacket packet, {
    required InternetAddress remoteAddress,
    required int remotePort,
    required UdpInterfaceEndpoint localEndpoint,
  });

  Future<void> closeEndpoint(UdpInterfaceEndpoint endpoint);
}
```

역할:

- 전송 세션마다 선택된 candidate의 local interface를 사용한다.
- dataPortRange 안에서만 bind한다.
- 실패 시 range 내 다음 포트를 시도한다.
- OS 임의 포트 fallback은 기본적으로 금지한다.

### 10.2 Control/Data path 일관성

기본 원칙:

- Control 인증에 성공한 candidate와 같은 local interface를 Data에도 사용한다.
- Data bind 실패 시 같은 interface의 다음 data port를 시도한다.
- 같은 interface의 모든 data port가 실패하면 다른 candidate로 전체 path failover를 요청한다.
- Control은 성공했지만 Data가 실패하면 peer는 authenticated 상태를 유지하되 transfer path는 failed/degraded로 표시한다.

### 10.3 DataPathFailoverStateMachine

상태:

- `idle`
- `binding`
- `ready`
- `transferring`
- `degraded`
- `retryingSameInterface`
- `failingOverInterface`
- `failed`
- `completed`

이벤트:

- `bindRequested`
- `bindSucceeded`
- `bindFailed`
- `packetLossExceeded`
- `rttDegraded`
- `sameInterfaceRetrySucceeded`
- `sameInterfaceRetryFailed`
- `alternateCandidateAvailable`
- `failoverSucceeded`
- `failoverFailed`
- `transferCompleted`

테스트:

- data port bind 실패 시 같은 interface의 다음 port를 시도한다.
- 같은 interface range exhausted 시 alternate candidate로 failover한다.
- failover 후 transfer state가 다른 peer의 transfer state를 덮지 않는다.
- excessive loss는 degraded event를 발생시킨다.

## 11. Path Selection 정책

### 11.1 점수화 기준

candidate score는 낮을수록 좋게 한다.

가중치:

- 같은 subnet: -30
- 최근 성공 경로: -25
- 낮은 RTT: `rttMs / 10`
- 실패 횟수: `failureCount * 50`
- degraded 이력: +25
- virtual/vpn interface: 기본 +10, 단 사용자 override가 있으면 0
- link-local: 후보 제외
- loopback: local registry 전용 후보

### 11.2 자동 선택

자동 선택 절차:

1. reachable candidate만 선택한다.
2. 같은 subnet 후보를 우선한다.
3. 이전 성공 후보를 우선한다.
4. RTT가 낮은 후보를 선택한다.
5. 동점이면 interface stableId 정렬로 결정성을 보장한다.

### 11.3 수동 override

첫 구현에서는 UI 수동 override를 만들지 않는다. 다만 도메인 모델은 manual selection reason을 허용한다.

후속 UI에서 가능한 옵션:

- 자동
- 특정 interface 우선
- 특정 interface 제외
- VPN/가상 어댑터 포함

이 설정은 외부 파일에 바로 저장하지 않고, 앱 설정 저장소에 명시적으로 저장한다.

## 12. MessageBus 이벤트 설계

새 event 타입:

- `NetworkInterfaceAppEvent`
- `PeerRouteCandidateAppEvent`
- `PeerPathAppEvent`
- `DataPathAppEvent`

공통 metadata:

- `eventId`
- `occurredAt`
- `correlationId`
- `source`
- `severity`

도메인 필드:

- `interfaceId`
- `interfaceName`
- `localAddress`
- `peerId`
- `candidateId`
- `pathId`
- `portRole`
- `port`
- `reasonCode`

이벤트 이름 예:

- `networkInterfaceScanned`
- `networkInterfaceRejected`
- `discoveryTargetBuilt`
- `peerRouteCandidateFound`
- `peerRouteCandidateExpired`
- `peerPathSelected`
- `peerPathDegraded`
- `peerPathFailed`
- `peerPathFailoverStarted`
- `dataPathBound`
- `dataPathBindFailed`
- `dataPathFailoverSucceeded`

로그 레벨 기준:

- Product: 사용자가 인지해야 할 연결 실패, 모든 경로 실패
- Debug: candidate 선택, failover, bind 실패, RTT degradation
- Development: interface scan 결과, subnet 계산, packet codec 문제

## 13. 데이터 저장과 projection

### 13.1 메모리 우선

candidate와 path는 기본적으로 runtime projection이다. 재시작 후에도 반드시 유지해야 하는 정보가 아니므로 DB 저장을 최소화한다.

저장 후보:

- peer별 마지막 성공 interface stableId
- peer별 마지막 성공 remote endpoint
- peer별 평균 RTT 요약

저장 제외:

- raw packet
- token/session key
- 파일 경로 전체
- OS 상세 adapter identifier 중 개인정보 가능성이 있는 값

### 13.2 PeerRepository 변경

기존 cached peer 저장이 단일 address/port만 저장한다면 다음 중 하나로 단계적 변경한다.

1. MVP: 대표 endpoint만 저장하고 candidate는 runtime only.
2. 확장: 별도 `peer_route_candidates` 테이블 추가.

이번 계획의 첫 구현은 1번을 기본으로 한다.

## 14. 테스트 전략

### 14.1 단위 테스트

추가 테스트:

- subnet broadcast 계산
- interface filtering
- route candidate merge
- path selection score
- failover state machine
- data port allocator with interface
- MessageBus event metadata

### 14.2 Application 테스트

fake inventory와 fake transport를 사용한다.

시나리오:

- 2개 interface에서 같은 peer 발견
- 첫 번째 candidate control timeout, 두 번째 candidate 성공
- control 성공 후 data bind 실패, 같은 interface 다음 data port 성공
- 같은 interface data range exhausted, 다른 interface failover
- virtual interface 제외 정책
- local registry peer는 loopback candidate로만 생성

### 14.3 Infrastructure 테스트

실제 OS socket 테스트는 최소화한다.

자동화 후보:

- `RawUdpDiscoveryTransport.broadcastTargetsForAddresses`
- `RawUdpDiscoveryTransport`가 invalid/reusePort fallback을 처리하는지
- `RawUdpControlTransport` bind fallback 정책
- `RawUdpDataTransport` range bind 정책

### 14.4 수동 테스트

수동 체크리스트:

- macOS: Ethernet + Wi-Fi 동시 연결
- macOS: Thunderbolt Bridge + Ethernet
- Windows: Ethernet + Wi-Fi
- Windows: Hyper-V/Parallels adapter 존재 시 제외/포함 정책
- Linux: Ethernet + Wi-Fi + Docker bridge
- 같은 subnet 2 NIC 환경
- 서로 다른 subnet 2 NIC 환경
- 한 NIC 방화벽 차단 후 다른 NIC failover
- 전송 중 NIC 비활성화 후 실패/복구 동작

## 15. 구현 단계

### Phase 003-001. 네트워크 인터페이스 도메인 모델과 inventory

기능:

- `NetworkInterfaceSnapshot`
- `InterfaceAddress`
- `NetworkInterfaceInventory`
- subnet/broadcast 계산
- interface filtering policy

테스트:

- IPv4 broadcast 계산
- loopback/link-local 제외
- fake inventory scan
- unsupported interface reason

완료 기준:

- discovery/controller가 OS API를 직접 보지 않고 inventory abstraction을 사용할 수 있다.

### Phase 003-002. Discovery target builder

기능:

- interface별 discovery target 생성
- limited broadcast, directed broadcast, multicast 분리
- source interface hint 포함
- MessageBus event publish

테스트:

- 2 NIC에서 target이 각각 생성된다.
- `/16`, `/20`, `/24` broadcast가 정확하다.
- multicast unsupported interface는 multicast target에서 제외된다.

완료 기준:

- discovery 송신 후보가 인터페이스별로 설명 가능하다.

### Phase 003-003. Peer route candidate projection

기능:

- `PeerRouteCandidate`
- candidate merge
- same peer multi-candidate 보존
- candidate TTL/expiry

테스트:

- 같은 peer 두 후보 병합
- duplicate packet은 candidate update
- expired candidate 제거
- incompatible peer candidate 처리

완료 기준:

- peer 하나가 여러 route candidate를 가질 수 있다.

### Phase 003-004. Control path selection과 probe

기능:

- `PeerConnectionPathStateMachine`
- candidate score
- Control probe
- selected path projection
- failover 시작 조건

테스트:

- 낮은 RTT 선택
- 첫 candidate timeout 후 다음 candidate 성공
- 모든 candidate 실패
- 이전 성공 candidate 우선

완료 기준:

- 인증 세션은 어떤 route candidate로 수립됐는지 알 수 있다.

### Phase 003-005. Control transport local bind 확장

기능:

- `ControlTransport` 도입
- local endpoint 지정 send
- specific local address bind
- `anyIPv4` fallback과 degraded event

테스트:

- local endpoint 지정 시 해당 endpoint 사용
- bind 실패 fallback
- fallback 시 candidate degraded
- 기존 AuthTransport 호환 경로 유지

완료 기준:

- Control/Auth 송신이 OS 라우팅만이 아니라 선택 candidate를 기준으로 동작할 수 있다.

### Phase 003-006. Data Port 전용 transport와 interface bind

기능:

- `DataTransport`
- `DataDatagram`
- dataPortRange bind
- local interface endpoint 사용
- transfer controller data path 연결

테스트:

- range 내 bind
- range exhausted failure
- selected control path와 같은 interface 사용
- data packet 송수신 fake transport

완료 기준:

- 실제 파일 chunk가 Data Port 전용 transport를 통해 흐른다.

### Phase 003-007. Data path failover

기능:

- `DataPathFailoverStateMachine`
- packet loss/rtt degraded 감지
- same interface retry
- alternate interface failover
- transfer session 상태 보존

테스트:

- same interface retry 성공
- alternate candidate failover 성공
- failover 실패 시 transfer failed
- 1:N 전송에서 한 peer failover가 다른 peer를 오염시키지 않는다.

완료 기준:

- 전송 중 선택 경로가 실패해도 가능한 후보가 있으면 복구할 수 있다.

### Phase 003-008. UI projection과 진단

기능:

- peer detail에 route candidate 요약 표시
- active path 표시
- Debug 로그/진단 이벤트 표시
- Product 메시지는 최소화

테스트:

- projection provider 단위 테스트
- UI widget smoke
- 민감 정보 표시 금지 snapshot

완료 기준:

- 사용자가 연결 실패가 peer 문제인지 특정 인터페이스 문제인지 구분할 수 있다.

### Phase 003-009. 플랫폼 체크리스트와 수동 검증

기능:

- macOS/Windows/Linux multi-NIC checklist
- 방화벽 안내
- known limitation
- release gate 업데이트

테스트:

- 자동 테스트 전부 통과
- 수동 체크리스트 문서화

완료 기준:

- 베타 전에 multi-interface 리스크를 추적 가능하다.

## 16. 구현 세부 체크리스트

### 16.1 모델

- [ ] `NetworkInterfaceId`를 만든다.
- [ ] `NetworkInterfaceSnapshot`을 만든다.
- [ ] `InterfaceAddress`를 만든다.
- [ ] `UdpInterfaceEndpoint`를 만든다.
- [ ] `PeerRouteCandidate`를 만든다.
- [ ] `PeerConnectionPath`를 만든다.
- [ ] `InterfaceTypeHint` enum을 만든다.
- [ ] `RouteCandidateStatus` enum을 만든다.
- [ ] `PeerPathStatus` enum을 만든다.

### 16.2 순수 정책

- [ ] subnet broadcast 계산기를 만든다.
- [ ] interface filtering policy를 만든다.
- [ ] discovery target builder를 만든다.
- [ ] route candidate merge policy를 만든다.
- [ ] candidate scoring policy를 만든다.
- [ ] path selection policy를 만든다.
- [ ] failover policy를 만든다.

### 16.3 상태 머신

- [ ] `NetworkInterfaceInventoryStateMachine`을 만든다.
- [ ] `DiscoveryPathStateMachine`을 만든다.
- [ ] `PeerRouteCandidateStateMachine`을 만든다.
- [ ] `PeerConnectionPathStateMachine`을 만든다.
- [ ] `DataPathFailoverStateMachine`을 만든다.

### 16.4 Infrastructure

- [ ] `DartIoNetworkInterfaceInventory`를 만든다.
- [ ] discovery send target을 interface별로 만든다.
- [ ] Control transport local bind를 지원한다.
- [ ] Data transport local bind를 지원한다.
- [ ] Data Port range bind 실패를 명확히 반환한다.
- [ ] platform별 socket option 차이를 문서화한다.

### 16.5 Application

- [ ] DiscoveryController가 inventory를 사용한다.
- [ ] PeerAuthController가 selected path를 사용한다.
- [ ] TransferController가 DataPath를 사용한다.
- [ ] Peer route candidate projection provider를 만든다.
- [ ] Active path provider를 만든다.
- [ ] failover event를 MessageBus로 publish한다.

### 16.6 Presentation

- [ ] peer detail에 active interface를 표시한다.
- [ ] debug panel에 candidate 목록을 표시한다.
- [ ] path degraded 상태를 표시한다.
- [ ] Product UI에는 과도한 네트워크 내부 정보를 노출하지 않는다.

## 17. 완료 기준

이 계획은 다음 조건을 만족하면 완료로 본다.

- 앱이 모든 유효 IPv4 인터페이스에서 discovery target을 만든다.
- 같은 peer가 여러 인터페이스에서 발견되면 후보가 모두 보존된다.
- Control 인증은 선택된 route candidate를 기준으로 수행된다.
- Data 전송은 Data Port 전용 transport와 선택된 interface endpoint를 사용한다.
- 선택 path 실패 시 다른 후보로 failover할 수 있다.
- 상태 머신과 MessageBus로 discovery/path/failover 흐름이 관찰 가능하다.
- 자동 테스트로 multi-interface 핵심 절차가 고정되어 있다.
- 실제 multi-NIC 장비 검증 항목은 수동 체크리스트에 분리되어 있다.

## 18. 주요 리스크

- Dart/OS API가 datagram 수신 local interface를 직접 제공하지 않을 수 있다.
- Windows의 UDP socket reuse/bind 정책이 macOS/Linux와 다르다.
- VPN/가상 어댑터가 실제 LAN peer discovery를 방해할 수 있다.
- 여러 NIC가 같은 subnet에 있으면 candidate 추정이 모호해질 수 있다.
- Data Port range와 firewall 정책이 interface별로 다르게 동작할 수 있다.
- 전송 중 failover는 chunk ordering, ack, retransmission 상태와 충돌할 수 있다.

대응:

- 수신 local interface를 직접 알 수 없으면 subnet 기반 tentative candidate를 만들고 Control probe로 검증한다.
- Windows는 `reusePort` 의존을 피하고 sender/receiver socket 정책을 별도로 둔다.
- virtual/vpn adapter는 기본 감점하고, 후속 UI에서 포함/제외 정책을 제공한다.
- failover는 같은 transfer session 안에서 상태 머신으로만 전이한다.

## 19. 문서화 기준

구현이 진행되면 다음 문서를 함께 갱신한다.

- `.tasks/phase003/plan.md`
- `.tasks/phase002/README.md`와 phase002 후속 메모
- `AGENTS.md`의 네트워크 인터페이스 정책
- `README.md`의 네트워크 요구사항
- 플랫폼별 베타 체크리스트

문서에는 다음을 명확히 남긴다.

- 지원하는 인터페이스 유형
- 제외되는 인터페이스 유형
- 방화벽 포트
- 자동 선택 정책
- 실패 시 사용자에게 보여줄 메시지 기준
- 수동 검증이 필요한 항목