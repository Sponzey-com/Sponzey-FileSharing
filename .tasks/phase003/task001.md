# Task 001 - 네트워크 인터페이스 도메인 모델과 inventory

## 목표

멀티 Ethernet 인터페이스 지원의 기반이 되는 순수 도메인 모델과 interface inventory abstraction을 만든다.

이 태스크의 핵심은 OS가 제공하는 `NetworkInterface` 정보를 application/domain에서 직접 사용하지 않도록 분리하고, 이후 Discovery/Control/Data 경로 선택이 사용할 수 있는 안정적인 값 객체를 정의하는 것이다.

## 연관 문서

- [plan.md - 도메인 모델 설계](plan.md#6-도메인-모델-설계)
- [plan.md - Interface Inventory 설계](plan.md#7-interface-inventory-설계)
- [AGENTS.md - 아키텍처 원칙](../../AGENTS.md)
- [phase002 plan](../phase002/plan.md)

## 선행 조건

- phase002의 상태 머신, MessageBus, UDP 포트 모델이 존재해야 한다.
- 현재 `RawUdpDiscoveryTransport`, `RawUdpAuthTransport`, `DiscoveryController`의 socket bind 방식을 감사할 수 있어야 한다.

## 포함 기능

### 기능 1. 네트워크 인터페이스 값 객체

- `NetworkInterfaceId`를 만든다.
- `NetworkInterfaceSnapshot`을 만든다.
- `InterfaceAddress`를 만든다.
- `InterfaceTypeHint`를 만든다.
- OS API 타입을 domain에 노출하지 않는다.

### 기능 2. UDP interface endpoint 모델

- `UdpInterfaceEndpoint`를 만든다.
- `UdpEndpointConfig`와 충돌하지 않도록 role, localAddress, port, bindMode를 표현한다.
- Discovery/Control/Data 포트 역할과 interface bind 정보를 함께 표현할 수 있게 한다.

### 기능 3. NetworkInterfaceInventory abstraction

- `NetworkInterfaceInventory` interface를 만든다.
- `DartIoNetworkInterfaceInventory` 구현을 만든다.
- 테스트용 fake inventory를 쉽게 만들 수 있는 구조로 둔다.
- loopback, link-local, IPv6, multicast unsupported interface 처리 기준을 분리한다.

## 구현 체크리스트

- [x] `lib/domain/network` 또는 동등한 domain 경로를 정했다.
- [x] `NetworkInterfaceId`를 정의했다.
- [x] `NetworkInterfaceSnapshot`을 정의했다.
- [x] `InterfaceAddress`를 정의했다.
- [x] `InterfaceTypeHint` enum을 정의했다.
- [x] `UdpInterfaceEndpoint`를 정의했다.
- [x] `UdpInterfaceBindMode` 또는 동등한 bind mode enum을 정의했다.
- [x] `NetworkInterfaceInventory` abstraction을 정의했다.
- [x] `DartIoNetworkInterfaceInventory` 구현을 추가했다.
- [x] OS `NetworkInterface` 타입이 domain 모델 밖으로 새지 않도록 했다.
- [x] interface stable id가 영구 저장 신뢰 대상이 아님을 코드/문서에 남겼다.
- [x] IPv6 주소는 보존하되 active discovery candidate에서는 제외하는 기준을 명시했다.
- [x] loopback은 LAN discovery 후보가 아니라 local registry 후보로만 취급하는 기준을 명시했다.
- [x] link-local 주소는 기본 제외 기준으로 처리했다.
- [x] interface scan 결과를 Debug/Development 로그로 남길 수 있는 metadata를 준비했다.

## 테스트

- [x] `NetworkInterfaceId` equality/ordering 테스트를 작성했다.
- [x] `NetworkInterfaceSnapshot`이 OS 타입 없이 생성되는 테스트를 작성했다.
- [x] `InterfaceAddress`가 IPv4/IPv6/link-local/loopback 값을 구분하는 테스트를 작성했다.
- [x] `UdpInterfaceEndpoint`가 Discovery/Control/Data role을 표현하는 테스트를 작성했다.
- [x] fake inventory가 여러 interface snapshot을 반환하는 테스트를 작성했다.
- [x] loopback interface가 LAN discovery 후보에서 제외되는 테스트를 작성했다.
- [x] link-local interface가 기본 후보에서 제외되는 테스트를 작성했다.
- [x] IPv6-only interface가 active IPv4 candidate를 만들지 않는 테스트를 작성했다.
- [x] virtual/vpn/bridge type hint가 policy에서 구분 가능한지 테스트했다.
- [x] domain 모델 테스트가 Flutter, Riverpod, socket 없이 실행되는지 확인했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위 테스트가 통과한다.
- [x] domain 계층이 `dart:io`에 직접 의존하지 않는다.
- [x] inventory 구현만 `dart:io NetworkInterface`를 참조한다.
- [x] 로그와 event metadata에 password, token, session key, 파일 경로가 들어가지 않는다.

## 완료 기준

- 네트워크 인터페이스와 주소가 순수 값 객체로 표현된다.
- application 계층이 fake inventory를 주입받아 multi-interface 테스트를 만들 수 있다.
- 후속 discovery target builder가 OS API를 직접 호출하지 않아도 된다.

## 메모

- 첫 구현은 IPv4 중심으로 한다.
- IPv6는 모델 확장을 막지 않되, discovery/control/data active path에서는 제외한다.
- interface 이름은 OS별로 바뀔 수 있으므로 안정적인 영구 식별자로 오해하지 않도록 한다.
