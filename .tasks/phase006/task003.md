# task003 - Multi Ethernet Discovery target과 receive decision 검증

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- 자동 테스트 기준 구현과 검증은 완료했다.
- macOS host, Parallels Windows VM, Ubuntu 22.04 VM 사이의 실제 양방향 discovery 수동 검증은 아직 수행하지 않았다.
- loopback은 discovery broadcast target으로 만들지 않고, 같은 host multi-instance는 local registry route candidate 경로로만 처리한다.
- stale은 packet receive decision이 아니라 presence TTL/route candidate TTL 만료 decision으로 처리한다.
- 현재 로컬 macOS에는 `bridge100`, `bridge101`, `vmenet0`, `vmenet1`, `vmenet2` 같은 VM bridge 계열 인터페이스가 존재한다.
- 현재 workspace의 `flutter_01.log`에는 discovery 송수신/target/decision 런타임 로그가 없어 실제 host/VM 수동 검증 근거로 사용할 수 없다.

## 목적

모든 사용 가능한 Ethernet 계열 인터페이스에 discovery broadcast를 정상 발산하고, 수신 packet을 route candidate로 안전하게 등록한다. 특정 VM IP, 특정 NIC 이름, 특정 IP 대역을 코드에 넣는 방식은 금지한다.

## 기능 범위

1. interface classifier와 broadcast target 계산 정리
2. discovery send/receive decision code 표준화
3. OS별 socket bind/reuse 회귀 테스트 보강

## 선행 조건

- [x] task002의 peer/route 경계가 정의되어 있다.
- [x] `raw_udp_discovery_transport.dart`, discovery controller, app config의 port 설정을 읽는다.
- [x] macOS, Windows, Linux에서 보고된 bind 오류 이력을 확인한다.

## 제외 범위

- peer connection state machine 변경은 task004에서 처리한다.
- data transfer endpoint 일치성은 task005에서 처리한다.
- release gate 자동화는 task011에서 처리한다.

## 계층별 변경 위치

- domain/application: discovery target, decision code value object
- infrastructure: NetworkInterface enumeration, broadcast target calculation, RawDatagramSocket bind/send/receive
- core: debug log category와 redaction
- test: `test/infrastructure/discovery`, `test/application/discovery`

## 실패 테스트 또는 수동 재현 기준

- [x] 한 interface bind/send 실패가 discovery engine 전체 실패로 전파되는 실패 테스트를 작성한다.
- [x] `10.211.x.x` 또는 `192.168.x.x` 대역을 특별 취급해야만 discovery가 되는 수동 재현 기준을 실패 조건으로 기록한다.
- [x] Windows에서 잘못된 reuse 옵션으로 `errno 10022`가 발생했던 조건을 회귀 테스트 또는 fake socket test로 고정한다.

## diagnostics/log 검토 기준

- [x] discovery start 시 bind address, preferred port, fallback port, reuse option이 로그에 남는지 확인한다.
- [x] interface별 broadcast target 결정에 include/skip reason이 남는지 확인한다.
- [x] receive packet decision에 remote address, group tag match, self decision, malformed decision이 남는지 확인한다.

## 구현 체크리스트

- [x] OS별 interface 정보를 공통 `NetworkInterfaceSnapshot` 형태로 정규화한다.
- [x] broadcast 가능한 IPv4 interface만 discovery send target으로 선택한다.
- [x] down interface, unsupported address, malformed broadcast address는 skip reason과 함께 제외한다.
- [x] loopback은 broadcast target에서 제외하고 local registry multi-instance 경로로만 처리하도록 명시한다.
- [x] point-to-point, link-local, IPv6-only interface 처리 기준을 문서화한다.
- [x] discovery response는 수신된 remote address를 route candidate로 등록하되 active route 승격은 probe에 맡긴다.
- [x] interface 하나의 send 실패는 해당 interface skip/fallback으로 처리하고 engine은 계속 동작한다.
- [x] Windows reuse option 조합을 안전하게 분기한다.
- [x] macOS `errno 48` address in use 회귀를 막는 bind/fallback 정책을 확인한다.
- [x] Linux preferred port 점유 시 fallback bind가 deterministic하게 동작하도록 한다.
- [x] hardcoded IP 대역, VM vendor, NIC name branch가 없음을 점검한다.

## 테스트 체크리스트

- [x] broadcast 가능한 IPv4 interface만 target이 된다.
- [x] skip된 interface는 명확한 skip reason을 가진다.
- [x] loopback target은 broadcast target에 포함되지 않고 local registry 경로로 분리된다.
- [x] interface 하나의 bind/send 실패가 discovery start 실패로 전파되지 않는다.
- [x] Windows reuse 옵션 조합이 `errno 10022`를 만들지 않는 경로로 선택된다.
- [x] Linux preferred port 점유 시 fallback port가 선택된다.
- [x] receive packet decision이 `accepted`, `ignoredSelf`, `groupMismatch`, `malformed`로 구분되고, `stale`은 TTL 만료 경로로 분리된다.
- [x] 특정 IP 대역 문자열을 route selection branch에서 사용하지 않는다.

## 수동 검증 체크리스트

- [ ] macOS host에서 Parallels Windows VM으로 discovery packet이 나가는지 diagnostics로 확인한다.
- [ ] Parallels Windows VM에서 macOS host로 discovery packet이 나가는지 확인한다.
- [ ] macOS host에서 Ubuntu 22.04 VM 또는 Linux 장비로 discovery를 확인한다.
- [ ] 물리 LAN과 VM bridge가 동시에 있을 때 둘 다 후보로 로그에 남는다.
- [ ] 하나의 interface가 실패해도 다른 interface discovery가 계속된다.

## 완료 기준

- [ ] VM IP를 하드코딩하지 않고 host/VM 양방향 discovery가 재현된다.
- [x] 어떤 interface로 broadcast를 보냈고 왜 skip했는지 diagnostics에서 확인할 수 있다.
- [x] OS별 bind/reuse 회귀 테스트가 있다.

## 회귀 금지 조건

- 특정 IP 대역, 특정 VM 제품, 특정 NIC 이름을 조건으로 route를 선택하지 않는다.
- discovery socket 하나의 실패로 전체 engine을 중단하지 않는다.
- discovery packet에 JWT, session key, raw password, file metadata를 싣지 않는다.
