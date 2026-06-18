# Task 004 - Discovery runtime route candidate projection 연결

## 목표

Discovery packet 수신 결과를 단일 `PeerNode`로만 병합하지 않고, 실제 런타임 `PeerRouteCandidate` projection으로 연결한다.

이 태스크가 끝나면 UI와 coordinator가 peer별 후보 경로 목록을 읽을 수 있어야 한다. 같은 peer가 여러 Ethernet/bridge 경로로 발견되더라도 후보가 덮어써지지 않아야 한다.

## 연관 문서

- [plan.md - 5.3 Discovery candidate runtime 연결](plan.md#53-discovery-candidate-runtime-연결)
- [plan.md - 4.5 연결 오케스트레이션 책임](plan.md#45-연결-오케스트레이션-책임)
- [task003.md](task003.md)

## 선행 조건

- [task002.md](task002.md)의 Discovery 보안 경계가 정리되어 있어야 한다.
- [task003.md](task003.md)의 interface 후보 정책과 local candidate 추론 정책이 있어야 한다.
- 기존 `DiscoveryController` peer list 동작을 유지해야 한다.

## 포함 기능

### 기능 1. runtime candidate store/provider

- `PeerRouteCandidateProjection` 또는 동등한 store를 실제 provider 상태로 둔다.
- `peerRouteCandidateStoreProvider`가 빈 리스트가 아니라 runtime candidate를 읽도록 연결한다.
- candidate list 변경이 diagnostics provider에 반영되도록 한다.

### 기능 2. DiscoveryController candidate ingest

- Discovery packet 수신 시 `PeerNode`와 `PeerRouteCandidate`를 함께 생성한다.
- remote address와 inventory snapshot을 사용해 local 후보를 만든다.
- candidate found/updated/expired를 MessageBus event로 발행한다.
- `DiscoveryController`는 candidate 수집까지만 담당하고 handshake 시작 판단은 coordinator로 넘길 준비를 한다.

### 기능 3. candidate lifecycle과 stale 처리

- candidate TTL을 presence TTL과 조화시킨다.
- expired candidate는 active selection에서 제외한다.
- peer offline/stale 전환 시 candidate와 session 정리 기준을 맞춘다.

## 구현 체크리스트

- [x] runtime `PeerRouteCandidateProjection` provider를 만들었다.
- [x] `peerRouteCandidatesProvider(peerId)`가 실제 runtime store를 읽는다.
- [x] Discovery packet 수신 시 candidate ingest가 실행된다.
- [x] local registry entry는 loopback candidate로 ingest된다.
- [x] candidate found event를 MessageBus로 발행한다.
- [x] candidate updated event를 MessageBus로 발행한다.
- [x] candidate expired event를 MessageBus로 발행한다.
- [x] 기존 peer list projection과 route candidate projection의 책임을 분리했다.
- [x] `DiscoveryController`의 자동 handshake 직접 호출 제거 또는 coordinator 전환 준비를 했다.
- [x] candidate payload에 token, password, verifier, session key, 파일 경로가 없다.

## 테스트

- [x] Discovery packet 수신 시 peer list와 candidate list가 모두 갱신되는 테스트를 작성했다.
- [x] 같은 peer가 두 local interface 후보로 발견되면 candidate 2개가 유지되는 테스트를 작성했다.
- [x] 같은 candidate duplicate 수신은 updated로 처리되는 테스트를 작성했다.
- [x] local registry entry가 loopback candidate로 만들어지는 테스트를 작성했다.
- [x] TTL 초과 candidate가 expired 상태가 되는 테스트를 작성했다.
- [x] expired candidate가 selectable 목록에서 제외되는 테스트를 작성했다.
- [x] MessageBus candidate event publish 테스트를 작성했다.
- [x] 기존 `DiscoveryController` peer 목록 테스트가 통과한다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] discovery/application/network provider 테스트가 통과한다.
- [x] 같은 peer의 여러 route candidate가 단일 address/port로 덮어써지지 않는다.
- [x] diagnostics provider에서 candidate count와 candidate rows를 읽을 수 있다.
- [x] UI는 MessageBus 구현체를 직접 구독하지 않는다.

## 구현 결과

- `PeerRouteCandidateProjectionNotifier`와 `peerRouteCandidateProjectionProvider`를 추가해 route candidate projection을 runtime Riverpod state로 노출한다.
- `peerRouteCandidateStoreProvider`는 더 이상 빈 리스트를 기본값으로 반환하지 않고 runtime projection state를 watch한다.
- `networkInterfaceInventoryProvider`를 추가해 DiscoveryController가 OS inventory 구현 또는 테스트 fake inventory를 명시 주입으로 사용할 수 있게 했다.
- Discovery packet 수신 시 `ConnectableInterfacePolicy`로 remote address 기준 local interface 후보를 계산하고, `PeerRouteCandidateProjection`에 ingest한다.
- local registry entry는 `RouteCandidateDiscoverySource.localRegistry` loopback candidate로 ingest한다.
- candidate id 기준으로 새 후보는 `PeerRouteCandidateFound`, 중복 후보는 `PeerRouteCandidateUpdated`, TTL 만료 후보는 `PeerRouteCandidateExpired` 이벤트를 MessageBus에 발행한다.
- candidate TTL은 `AppConfig.discoveryOfflineAfter`와 맞춰 expire 처리한다.
- interface scan 실패 시 peer 발견 흐름을 막지 않고 unknown any-bind candidate로 fallback한다.
- DiscoveryController의 peer list 병합과 route candidate projection update를 별도 helper로 분리해 다음 task의 `PeerConnectionCoordinator`가 selectable candidate를 사용할 수 있도록 준비했다.
- candidate event payload에는 peer id, candidate id, reason code만 담고 password, token, verifier, session key, 파일 경로를 담지 않는다.

## 실행 결과

- `flutter test test/application/discovery/discovery_controller_test.dart test/application/discovery/peer_route_candidate_projection_test.dart test/application/network/network_diagnostics_provider_test.dart test/core/message_bus/peer_route_candidate_event_test.dart`
- `flutter analyze`
- `flutter test`

전체 테스트는 통과했다. `flutter test` 중 Drift multiple database debug warning이 출력되지만 테스트 실패는 아니며, task004 변경 범위의 실패는 없다.

## 완료 기준

- Discovery runtime에서 peer별 route candidate 목록을 제공한다.
- candidate lifecycle이 presence lifecycle과 충돌하지 않는다.
- 다음 task에서 `PeerConnectionCoordinator`가 selectable candidate를 사용할 수 있다.
