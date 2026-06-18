# Task 003 - 연결 가능한 interface 후보 정책과 local candidate 추론

## 목표

멀티 Ethernet 연결을 위해 “사용 가능한 모든 연결 경로”를 후보로 보존하는 정책을 도메인/애플리케이션 레벨에 만든다.

물리 Ethernet만 쓰는 것이 아니라 USB/Thunderbolt Ethernet, 내부 Ethernet bridge, VM bridge를 연결 후보로 포함한다. VPN, tunnel, host-only virtual adapter, link-local, 일반 loopback은 기본 자동 연결 후보에서 제외하거나 낮은 우선순위로 둔다.

## 연관 문서

- [plan.md - 4.1 Interface 후보 정책](plan.md#41-interface-후보-정책)
- [plan.md - 4.2 수신 local interface 판별](plan.md#42-수신-local-interface-판별)
- [plan.md - 5.3 Discovery candidate runtime 연결](plan.md#53-discovery-candidate-runtime-연결)

## 선행 조건

- [task001.md](task001.md)의 interface fixture 감사가 완료되어 있어야 한다.
- `NetworkInterfaceSnapshot`, `InterfaceAddress`, `InterfaceTypeHint`, `PeerRouteCandidate` 모델을 확인해야 한다.
- 외부 설정 파일 없이 정책을 코드와 주입값으로 표현해야 한다.

## 포함 기능

### 기능 1. 연결 후보 interface policy

- active IPv4를 가진 물리 Ethernet, USB Ethernet, Thunderbolt Ethernet을 1순위로 둔다.
- 내부 Ethernet bridge, VM bridge, OS bridge를 2순위 연결 후보로 둔다.
- Wi-Fi와 unknown LAN interface는 fallback으로 둔다.
- VPN, tunnel, host-only virtual adapter, link-local, 일반 loopback은 기본 자동 후보에서 제외한다.
- local registry 검증용 loopback은 별도 source로 허용한다.

### 기능 2. remote address 기반 local candidate 추론

- Discovery datagram의 remote address와 현재 interface snapshot으로 가능한 local address 후보를 계산한다.
- 같은 subnet에 걸리는 interface가 여러 개면 모두 candidate로 만든다.
- 수신 NIC를 단정할 수 없는 경우에도 후보를 하나로 줄이지 않는다.
- subnet 정보가 없으면 안전한 fallback 정책을 사용한다.

### 기능 3. candidate metadata와 score 준비

- candidate에 interface type hint, local address, remote endpoint, discovery source를 보존한다.
- bridge/ethernet/unknown/VPN 후보의 점수 정책에 필요한 metadata를 준비한다.
- unknown candidate는 any bind fallback으로만 쓰도록 표시한다.

## 구현 체크리스트

- [x] `ConnectableInterfacePolicy` 또는 동등한 순수 정책을 만들었다.
- [x] bridge interface가 virtual로 일괄 제외되지 않도록 했다.
- [x] host-only/tunnel/VPN adapter를 기본 자동 후보에서 제외하는 기준을 만들었다.
- [x] local registry loopback 후보와 LAN discovery 후보를 분리했다.
- [x] remote IPv4와 local IPv4 subnet 비교 정책을 만들었다.
- [x] 같은 subnet 후보가 여러 개일 때 모두 반환한다.
- [x] subnet/prefix가 없을 때 fallback 후보를 만든다.
- [x] unknown local address 후보의 bind mode를 any로 표현한다.
- [x] 정책은 외부 설정 파일 없이 인자/provider override로 테스트 가능하다.

## 테스트

- [x] 물리 Ethernet 후보가 1순위로 선택되는 단위 테스트를 작성했다.
- [x] USB/Thunderbolt Ethernet 후보가 연결 후보로 유지되는 테스트를 작성했다.
- [x] 내부 bridge/VM bridge 후보가 연결 후보로 유지되는 테스트를 작성했다.
- [x] VPN/tunnel/host-only 후보가 기본 자동 후보에서 제외되거나 낮은 점수를 받는 테스트를 작성했다.
- [x] remote `192.168.10.20`과 local `192.168.10.5/24`가 candidate로 매칭되는 테스트를 작성했다.
- [x] 같은 subnet local interface 2개가 candidate 2개로 유지되는 테스트를 작성했다.
- [x] subnet 정보가 없을 때 fallback candidate가 만들어지는 테스트를 작성했다.
- [x] link-local, loopback, IPv6-only interface가 active LAN candidate에서 제외되는 테스트를 작성했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] domain/application network 정책 테스트가 통과한다.
- [x] 정책 코드가 Flutter UI, socket, 파일 시스템에 의존하지 않는다.
- [x] bridge/VPN/virtual 구분 기준이 테스트 fixture로 설명된다.
- [x] Debug diagnostics에 필요한 metadata가 민감 정보 없이 준비된다.

## 구현 결과

- `ConnectableInterfacePolicy`를 추가해 remote IPv4와 local IPv4 subnet을 비교하고, 연결 가능한 local interface 후보를 순수 도메인 정책으로 산출한다.
- Ethernet, USB/Thunderbolt Ethernet은 primary 후보로 유지하고, bridge는 secondary 후보로 유지하며, Wi-Fi/unknown LAN은 fallback 후보로 둔다.
- VPN, tunnel, host-only virtual, loopback, link-local, IPv6-only interface는 기본 자동 후보에서 제외한다.
- subnet prefix/netmask가 없으면 `/24` fallback으로 same-subnet 후보를 계산한다.
- local 후보를 확정할 수 없는 경우 `0.0.0.0` + `UdpInterfaceBindMode.any` unknown fallback 후보를 만든다.
- `PeerRouteCandidate`는 `bindMode`를 보존하고, 후보 key에 `localAddress`와 `bindMode`를 포함해 같은 NIC의 복수 IPv4 주소를 별도 경로로 유지한다.
- `PeerRouteCandidateProjection.ingestDiscoveryPacketCandidates`를 추가해 한 peer의 여러 local interface 후보를 한 번에 projection 할 수 있게 했다.
- local registry loopback 후보는 `RouteCandidateDiscoverySource.localRegistry`와 `InterfaceTypeHint.loopback`으로 LAN discovery 후보와 분리했다.
- `PeerConnectionPath.fromCandidate`는 후보의 `bindMode`를 control/data endpoint에 그대로 반영한다.
- `RawUdpDiscoveryTransport.selectPreferredInterfaces`는 Ethernet 하나로 축소하지 않고 Ethernet, bridge, Wi-Fi, unknown LAN 전체를 discovery 대상 후보로 유지한다.
- debug diagnostics row에 `type`과 `bind`를 추가하되 password, token, session key 같은 민감 정보는 포함하지 않는다.

## 실행 결과

- `flutter test test/domain/network/connectable_interface_policy_test.dart test/domain/network/peer_route_candidate_test.dart test/application/discovery/peer_route_candidate_projection_test.dart test/infrastructure/discovery/raw_udp_discovery_transport_test.dart test/application/network/network_diagnostics_provider_test.dart`
- `flutter analyze`
- `flutter test`

전체 테스트는 통과했다. `flutter test` 중 Drift multiple database debug warning이 출력되지만 테스트 실패는 아니며, task003 변경 범위의 실패는 없다.

## 완료 기준

- 연결 가능한 Ethernet 계열 interface 후보가 정책적으로 보존된다.
- 같은 peer의 여러 경로를 만들 수 있는 local candidate 추론이 가능하다.
- 이후 Discovery runtime projection이 OS 수신 NIC 정보 없이도 후보를 생성할 수 있다.
