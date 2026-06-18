# Task 006 - Discovery Port 기반 Peer 검색 고도화

## 목표

Discovery Port를 통해 동일 네트워크의 peer를 안정적으로 탐색하고, 발견된 peer를 인증 전 상태로 application projection에 반영한다.

Discovery는 presence와 peer endpoint 광고만 담당하며, 인증 토큰이나 파일 정보를 다루지 않는다.

## 연관 문서

- [phase002 plan.md - UDP Peer 검색 계획](plan.md#8-udp-peer-검색-계획)
- [task002.md](task002.md)
- [task005.md](task005.md)

## 선행 조건

- [task002.md](task002.md)의 Discovery 상태 머신이 있어야 한다.
- [task004.md](task004.md)의 MessageBus가 있어야 한다.
- [task005.md](task005.md)의 UDP 포트 모델이 있어야 한다.

## 포함 기능

### 기능 1. Discovery packet schema와 codec

- Discovery packet에 protocolVersion, packetType, messageId, sourcePeerId, deviceName, displayName, controlPort, dataPort/dataPortRange, capabilities, timestamp를 포함한다.
- malformed packet, unknown type, incompatible version을 안전하게 처리한다.
- packet payload에는 password, token, 파일 경로, 파일 metadata를 넣지 않는다.

### 기능 2. Broadcast/probe/heartbeat transport

- Discovery Port에서 broadcast hello 또는 probe를 보낸다.
- peer response와 heartbeat를 수신한다.
- goodbye 수신 또는 timeout으로 stale/offline 전이를 수행한다.

### 기능 3. Peer registry와 application projection

- peerId, runtime id, device id, lastSeenAt, protocolVersion, endpoint, capabilities를 관리한다.
- duplicate hello는 새 peer 생성이 아니라 기존 peer update로 처리한다.
- peer 상태 변경을 MessageBus event로 publish한다.

## 구현 체크리스트

- [x] Discovery packet 타입을 정의했다.
- [x] Discovery packet codec을 구현했다.
- [x] Discovery packet 금지 필드를 명확히 테스트했다.
- [x] Discovery broadcast hello 송신을 구현했다.
- [x] Discovery probe/response 흐름을 구현했다.
- [x] Heartbeat 송수신을 구현했다.
- [x] Stale/offline timeout을 상태 머신과 연결했다.
- [x] Goodbye 처리 흐름을 구현했다.
- [x] Peer registry가 duplicate peer를 update로 처리한다.
- [x] protocolVersion mismatch peer를 incompatible로 표시한다.
- [x] `DiscoveryPeerSeen`, `DiscoveryPeerUpdated`, `DiscoveryPeerOffline` event를 publish한다.
- [x] stop 시 timer, stream subscription, socket을 정리한다.

## 테스트

- [x] Discovery packet encode/decode 테스트를 작성했다.
- [x] malformed packet 무시 테스트를 작성했다.
- [x] unknown packet type 처리 테스트를 작성했다.
- [x] protocolVersion mismatch 테스트를 작성했다.
- [x] duplicate peer update 테스트를 작성했다.
- [x] heartbeat 수신 시 lastSeenAt 갱신 테스트를 작성했다.
- [x] stale/offline timeout 테스트를 작성했다.
- [x] goodbye 수신 시 offline 처리 테스트를 작성했다.
- [x] discovery stop 후 timer와 stream이 정리되는 테스트를 작성했다.
- [x] MessageBus event publish 테스트를 작성했다.

## 검증

- [ ] 같은 장비 loopback 또는 동일 LAN에서 peer discovery를 확인한다. _(완전 수동 확인 제외)_
- [x] 발견 peer가 인증된 peer로 잘못 표시되지 않는다.
- [x] Discovery 로그에 민감 정보가 없다.
- [x] Control/Data endpoint가 이후 연결에 사용할 수 있는 형태로 projection에 포함된다.

## 진행 결과

- `lib/infrastructure/discovery/discovery_packet.dart`
- `lib/application/discovery/discovery_controller.dart`
- `lib/domain/discovery/discovery_state_machine.dart`
- `test/infrastructure/discovery/discovery_packet_test.dart`
- `test/domain/discovery/discovery_state_machine_test.dart`

## 수동 확인 제외

- 실제 동일 LAN 브로드캐스트 탐색은 네트워크/방화벽 상태에 의존하므로 자동 완료 범위에서 제외했다.

## 완료 기준

- 앱이 동일 네트워크 peer를 Discovery Port로 발견할 수 있다.
- 발견된 peer는 상태 머신과 projection을 통해 online/stale/offline/incompatible 상태로 관리된다.
- 후속 Control Port 인증 작업이 발견 peer endpoint를 사용할 수 있다.