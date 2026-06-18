# Task 002 - Discovery target builder와 subnet 기반 broadcast

## 목표

모든 유효 IPv4 인터페이스를 기준으로 Discovery 송신 target을 생성하고, directed broadcast 계산을 실제 subnet/prefix 기준으로 개선한다.

현재 `/24`에 가까운 단순 directed broadcast 계산을 순수 정책으로 분리하고, interface별 limited broadcast, directed broadcast, multicast target을 명확히 만든다.

## 연관 문서

- [plan.md - Subnet 계산](plan.md#72-subnet-계산)
- [plan.md - Discovery 송신 전략](plan.md#81-discovery-송신-전략)
- [task001.md](task001.md)

## 선행 조건

- [task001.md](task001.md)의 interface snapshot, address, endpoint 모델이 있어야 한다.
- Discovery Port와 packet schema는 phase002 기준을 유지한다.

## 포함 기능

### 기능 1. subnet/broadcast 계산 정책

- IPv4 address와 prefixLength/netmask로 network broadcast를 계산한다.
- `/31`, `/32`는 directed broadcast를 만들지 않는다.
- link-local, loopback은 LAN directed broadcast에서 제외한다.
- prefixLength가 없을 때 conservative fallback 정책을 둔다.

### 기능 2. DiscoveryTargetBuilder

- interface snapshot 목록을 받아 interface별 target 목록을 만든다.
- target type을 limitedBroadcast, directedBroadcast, multicast로 구분한다.
- multicast unsupported interface는 multicast target에서 제외한다.
- 중복 target은 제거하되, 어떤 interface에서 나온 target인지 추적 가능하게 한다.

### 기능 3. Discovery packet source hint 확장

- Discovery packet에 sourceInterfaceId/sourceInterfaceHint, sourceAddress를 넣을 수 있게 한다.
- source hint는 후보 추적용이며 인증/보안 판단의 근거로 쓰지 않는다.
- packet codec은 하위 호환 가능한 optional field로 확장한다.

## 구현 체크리스트

- [x] subnet broadcast 계산기를 순수 함수 또는 value object로 만들었다.
- [x] `/24`, `/16`, `/20` broadcast 계산을 지원한다.
- [x] `/31`, `/32`에서 directed broadcast를 생성하지 않는다.
- [x] link-local과 loopback 주소를 directed broadcast에서 제외한다.
- [x] prefixLength/netmask가 없을 때 fallback 정책을 명시했다.
- [x] `DiscoveryTarget` 모델을 만들었다.
- [x] `DiscoveryTargetType` enum을 만들었다.
- [x] `DiscoveryTargetBuilder`를 만들었다.
- [x] interface별 limited broadcast target을 생성한다.
- [x] interface별 directed broadcast target을 생성한다.
- [x] interface별 multicast target을 생성한다.
- [x] multicast unsupported interface는 multicast target을 만들지 않는다.
- [x] target dedupe가 interface 추적 정보를 잃지 않도록 했다.
- [x] `DiscoveryPacket`에 source interface/source address optional field를 추가했다.
- [x] `DiscoveryPacket.decode`가 기존 packet을 계속 읽을 수 있다.
- [x] Discovery 송신 controller가 builder 결과를 사용할 수 있는 effect/API를 준비했다.

## 테스트

- [x] `192.168.10.23/24 -> 192.168.10.255` 테스트를 작성했다.
- [x] `10.20.30.40/16 -> 10.20.255.255` 테스트를 작성했다.
- [x] `172.16.5.7/20 -> 172.16.15.255` 테스트를 작성했다.
- [x] `/31`, `/32`에서 directed broadcast가 없는 테스트를 작성했다.
- [x] link-local 주소가 제외되는 테스트를 작성했다.
- [x] loopback 주소가 제외되는 테스트를 작성했다.
- [x] 유효 interface 2개에서 target이 interface별로 생성되는 테스트를 작성했다.
- [x] multicast 미지원 interface에서 multicast target이 제외되는 테스트를 작성했다.
- [x] target dedupe 후에도 source interface 정보가 보존되는 테스트를 작성했다.
- [x] Discovery packet source hint encode/decode 테스트를 작성했다.
- [x] 기존 phase002 discovery packet 테스트가 깨지지 않는지 확인했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위 테스트가 통과한다.
- [x] directed broadcast 계산이 `RawUdpDiscoveryTransport` 내부에 흩어져 있지 않다.
- [x] discovery target 생성은 socket 없이 테스트 가능하다.
- [x] 로그에는 source address/interface 정보만 남고 민감 정보는 남지 않는다.

## 완료 기준

- 모든 유효 IPv4 interface에 대해 discovery target을 설명 가능하게 만들 수 있다.
- `/24`가 아닌 subnet에서도 directed broadcast 계산이 정확하다.
- 후속 DiscoveryController가 target builder를 사용해 interface별 probe를 보낼 수 있다.

## 메모

- 실제 datagram 송신 방식 변경은 다음 task에서 controller/transport에 연결한다.
- OS가 prefixLength를 제공하지 않는 경우의 fallback은 Development 로그로 추적한다.