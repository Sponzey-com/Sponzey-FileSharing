# task005 - DataEndpointManager, DataSocketLease, DataSessionDispatcher, OS Bind Policy

## 목적

Data Port는 transfer마다 임의로 열고 닫으면 port 충돌, late packet, multi-transfer dispatch 문제가 발생한다. 이 태스크는 selected active path를 기준으로 data endpoint lease를 만들고, 수신 frame을 transfer session으로 routing하는 lifecycle 기반 인프라를 구축한다.

## 진행 현황

- [x] `DataEndpointManager`, `DataSocketLease`, `DataSessionDispatcher`, bind option policy를 추가했다.
- [x] data port range fallback, exhausted failure, unknown transfer drop, Windows `reusePort` 금지 테스트를 추가했다.
- [x] 실제 controller Data bind는 selected control endpoint 기반으로 수행하고 wildcard bind ACK는 송신자가 접근 가능한 source address로 보정한다.
- [x] 관련 검증: `flutter test test/infrastructure/transfer_data test/application/transfer`, `flutter analyze`

## 기능 범위

### 1. DataEndpointManager와 DataSocketLease

- [x] selected local address와 `AppConfig.dataPortRange`를 기준으로 bind 가능한 data socket lease를 생성한다.
- [x] lease에는 local endpoint, port, owner transfer/session, openedAt, close reason을 포함한다.
- [x] 같은 local address에서 port 충돌 시 range 안의 다음 port를 시도한다.
- [x] range가 모두 실패하면 명확한 failure reason을 반환한다.
- [x] OS ephemeral fallback은 금지한다.

### 2. DataSessionDispatcher

- [x] 수신 datagram의 sessionHash, transferId, frameType을 기준으로 session handler를 찾는다.
- [x] unknown transferId frame은 drop하고 debug decision으로 남긴다.
- [x] closed lease로 들어온 late packet은 session을 되살리지 않는다.
- [x] 동시에 여러 transfer가 있을 때 session 상태가 섞이지 않는다.
- [x] 하나의 local data socket을 여러 session이 공유하는 경우 dispatch 테스트를 먼저 만족한다.

### 3. OS별 bind policy

- [x] macOS, Linux, Windows의 UDP bind option 차이를 정책 객체로 분리한다.
- [x] Windows에서 `reusePort` 또는 지원되지 않는 option으로 `errno=10022`가 나지 않도록 한다.
- [x] Linux에서 port occupied 상황과 fallback lease 획득을 테스트한다.
- [x] bind 실패 로그에는 OS errno, selected local address, port range summary를 포함하되 민감 정보는 제외한다.

## 구현 지침

- endpoint selection은 discovery에서 처음 본 IP가 아니라 handshake로 검증된 `PeerConnectionPath`의 local/remote endpoint 쌍을 기준으로 한다.
- VM bridge, internal bridge, physical Ethernet이 동시에 있어도 특정 IP 하나만 정답이라고 가정하지 않는다.
- DataEndpointManager는 외부 설정 파일을 읽지 않는다. port range는 `AppConfig` 또는 명시 인자로 받는다.
- socket lifecycle은 dispose/close 테스트가 있어야 한다.
- UI는 이 구현체를 직접 호출하지 않는다. application controller가 lease orchestration을 담당한다.

## 예상 변경 위치

- [x] `lib/infrastructure/transfer/`
- [x] `lib/infrastructure/discovery/` 또는 path model 참조부
- [x] `lib/app/app_config.dart`
- [x] `test/infrastructure/transfer/`
- [x] `test/application/transfer/`

## 테스트

- [x] selected endpoint에 data socket lease가 bind된다.
- [x] 첫 data port 사용 중이면 같은 range의 다음 port를 사용한다.
- [x] range exhausted 시 명확한 failure가 난다.
- [x] 서로 다른 selected local address는 같은 data port 번호를 각각 사용할 수 있다.
- [x] unknown transferId frame은 dispatcher에서 drop된다.
- [x] closed lease로 들어온 late packet은 ignored로 기록된다.
- [x] Windows bind policy는 지원되지 않는 socket option을 무조건 켜지 않는다.
- [x] bind failure log는 payload, token, key material, full path를 포함하지 않는다.

## 검증 명령

- [x] `flutter test test/infrastructure/transfer`
- [x] `flutter test test/application/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] Data endpoint lease와 dispatcher가 명시적 lifecycle로 동작한다.
- [x] data port range 정책이 테스트로 고정되어 있다.
- [x] OS별 bind option 차이가 정책 객체로 분리되어 있다.
- [x] multi-interface 환경에서 selected local endpoint를 유지할 수 있다.

## 리스크와 주의사항

- `0.0.0.0` bind만으로 모든 문제를 해결하려 하지 않는다.
- Windows invalid argument 문제를 외부 설정으로 우회하지 않는다.
- socket을 chunk마다 열고 닫지 않는다.