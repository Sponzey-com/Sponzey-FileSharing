# Task 003 - Peer route candidate projection과 lifecycle

## 목표

같은 peer가 여러 네트워크 인터페이스에서 발견될 때 peer 자체는 하나로 유지하되, 연결 가능한 route candidate는 모두 보존하고 lifecycle을 관리한다.

이 태스크는 Discovery packet 수신 결과를 단일 `PeerNode.address/port`에 즉시 덮어쓰지 않고, 후속 Control probe와 path selection이 사용할 후보 목록으로 저장하는 구조를 만든다.

## 연관 문서

- [plan.md - PeerRouteCandidate](plan.md#65-peerroutecandidate)
- [plan.md - Discovery 수신 전략](plan.md#82-discovery-수신-전략)
- [plan.md - Peer projection](plan.md#83-peer-projection)
- [task002.md](task002.md)

## 선행 조건

- [task001.md](task001.md)의 interface 모델이 있어야 한다.
- [task002.md](task002.md)의 discovery source hint와 target builder가 있어야 한다.

## 포함 기능

### 기능 1. PeerRouteCandidate 모델

- candidateId, peerId, remote endpoint, local interface, local address를 표현한다.
- discoveredBy, lastSeenAt, rttMs, failureCount, score, status를 표현한다.
- Discovery packet 정보와 datagram 정보로 candidate를 만들 수 있어야 한다.

### 기능 2. candidate merge와 TTL

- 같은 peer/같은 interface/같은 remote endpoint 후보는 update로 처리한다.
- 같은 peer/다른 interface 후보는 별도 candidate로 유지한다.
- 오래된 candidate는 expired로 전이한다.
- incompatible peer도 candidate는 기록할 수 있으나 active path selection에서는 제외한다.

### 기능 3. projection provider

- `PeerNode` 대표 projection과 route candidate projection을 분리한다.
- UI와 controller가 peer별 candidate 목록을 조회할 수 있게 한다.
- local registry peer는 loopback candidate로만 생성한다.

## 구현 체크리스트

- [x] `PeerRouteCandidate` 모델을 정의했다.
- [x] `RouteCandidateStatus` enum을 정의했다.
- [x] `RouteCandidateDiscoverySource` enum을 정의했다.
- [x] candidateId 생성 규칙을 정했다.
- [x] Discovery packet과 datagram에서 candidate를 만드는 factory/policy를 만들었다.
- [x] sourceInterfaceHint가 없을 때 tentative candidate를 만들 수 있다.
- [x] 같은 peer의 여러 candidate를 보존하는 collection 모델을 만들었다.
- [x] duplicate candidate update 정책을 만들었다.
- [x] candidate TTL/expiry 정책을 만들었다.
- [x] incompatible peer candidate를 active selection에서 제외하는 flag를 둔다.
- [x] local registry entry를 loopback candidate로 변환한다.
- [x] `PeerRouteCandidateProjection`을 추가했다.
- [x] 기존 `PeerNode` projection과 route candidate projection의 책임을 분리했다.
- [x] MessageBus에 `PeerRouteCandidateFound`, `PeerRouteCandidateUpdated`, `PeerRouteCandidateExpired` 이벤트를 추가했다.

## 테스트

- [x] 같은 peer가 두 interface에서 발견되면 candidate가 둘 생기는 테스트를 작성했다.
- [x] 같은 candidate의 duplicate hello는 update로 처리되는 테스트를 작성했다.
- [x] candidate TTL 초과 시 expired가 되는 테스트를 작성했다.
- [x] expired candidate가 active selection에서 제외되는 테스트를 작성했다.
- [x] protocol mismatch peer가 incompatible candidate로 표시되는 테스트를 작성했다.
- [x] source hint가 없는 packet에서 tentative candidate가 생성되는 테스트를 작성했다.
- [x] local registry entry가 loopback candidate로 생성되는 테스트를 작성했다.
- [x] peer 대표 projection은 하나만 유지되는 테스트를 작성했다.
- [x] MessageBus candidate event publish 테스트를 작성했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위/Application 테스트가 통과한다.
- [x] 같은 peer의 후보가 단일 address/port에 의해 사라지지 않는다.
- [x] route candidate payload에 token, password, session key, 파일 경로가 없다.
- [x] 기존 DiscoveryController 테스트가 깨지지 않는다.

## 완료 기준

- 같은 peer의 다중 interface 후보를 모두 보존할 수 있다.
- 후속 Control path selection이 peer별 후보 목록을 기반으로 probe할 수 있다.
- UI가 peer 대표 정보와 candidate 세부 정보를 분리해서 조회할 수 있다.

## 메모

- DB 영구 저장은 최소화한다. candidate는 우선 runtime projection으로 관리한다.
- 대표 `PeerNode.address/port`는 가장 최근 또는 선택된 path의 요약으로만 사용한다.