# Task 004 - Control path selection과 candidate probe

## 목표

Discovery에서 수집한 route candidate를 바로 인증 세션으로 사용하지 않고, Control probe를 통해 실제 연결 가능한 candidate를 검증하고 최적 path를 선택한다.

이 태스크는 peer 연결 절차를 “candidate 발견 -> probe -> path 선택 -> 인증”으로 명확히 분리한다.

## 연관 문서

- [plan.md - Candidate validation](plan.md#93-candidate-validation)
- [plan.md - PeerConnectionPath 상태 머신](plan.md#94-peerconnectionpath-상태-머신)
- [plan.md - Path Selection 정책](plan.md#11-path-selection-정책)
- [task003.md](task003.md)

## 선행 조건

- [task003.md](task003.md)의 `PeerRouteCandidate` projection이 있어야 한다.
- phase002의 PeerLink/Auth 상태 머신과 JWT challenge/response 흐름이 있어야 한다.

## 포함 기능

### 기능 1. path selection score 정책

- 같은 subnet, 이전 성공 경로, RTT, failureCount, degraded 이력, virtual/vpn type hint를 점수화한다.
- deterministic tie-breaker를 둔다.
- active candidate만 선택한다.

### 기능 2. PeerConnectionPath 모델과 상태 머신

- selected candidate와 Control/Data endpoint를 담는 `PeerConnectionPath`를 만든다.
- `PeerConnectionPathStateMachine`을 만든다.
- candidate probe, probe success/failure, auth success/failure, failover request를 전이로 표현한다.

### 기능 3. Control probe orchestration

- candidate별 LinkRequest 또는 probe를 시도한다.
- timeout/failure 시 다음 candidate로 넘어간다.
- 성공 시 RTT와 selected path를 기록한다.
- 모든 candidate 실패 시 peer link failed로 처리한다.

## 구현 체크리스트

- [x] `PeerConnectionPath` 모델을 정의했다.
- [x] `PeerPathStatus` enum을 정의했다.
- [x] `PeerPathSelectionReason` enum을 정의했다.
- [x] candidate score policy를 만들었다.
- [x] same subnet 우선 정책을 구현했다.
- [x] previous success 우선 정책을 구현했다.
- [x] RTT 낮은 candidate 우선 정책을 구현했다.
- [x] failureCount/degraded penalty를 구현했다.
- [x] virtual/vpn 기본 penalty를 구현했다.
- [x] deterministic tie-breaker를 구현했다.
- [x] `PeerConnectionPathStateMachine`을 만들었다.
- [x] probe started/succeeded/failed 전이를 구현했다.
- [x] auth succeeded/failed 전이를 구현했다.
- [x] failover requested 전이를 구현했다.
- [x] PeerAuthController가 selected path를 기록할 수 있는 application API를 준비했다.
- [x] MessageBus에 `PeerPathSelected`, `PeerPathFailed`, `PeerPathFailoverStarted` 이벤트를 추가했다.

## 테스트

- [x] 낮은 RTT candidate가 선택되는 테스트를 작성했다.
- [x] 같은 subnet candidate가 우선되는 테스트를 작성했다.
- [x] 이전 성공 candidate가 우선되는 테스트를 작성했다.
- [x] failureCount가 높은 candidate가 후순위가 되는 테스트를 작성했다.
- [x] virtual/vpn candidate가 기본 감점되는 테스트를 작성했다.
- [x] 동점 candidate 정렬이 결정적인 테스트를 작성했다.
- [x] 첫 candidate timeout 후 다음 candidate가 probe되는 테스트를 작성했다.
- [x] 모든 candidate 실패 시 peer link failed가 되는 테스트를 작성했다.
- [x] probe 성공 시 RTT가 candidate에 반영되는 테스트를 작성했다.
- [x] selected path event가 MessageBus로 publish되는 테스트를 작성했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위/Application 테스트가 통과한다.
- [x] candidate 선택 기준이 UI 문구가 아니라 도메인 정책으로 표현된다.
- [x] probe 실패가 인증 실패와 구분된다.
- [x] selected path payload에 민감 정보가 없다.

## 완료 기준

- peer 인증 전에 어떤 route candidate를 사용할지 검증하고 선택할 수 있다.
- 후보 실패 시 다음 후보로 넘어가는 절차가 상태 머신과 테스트로 고정된다.
- 후속 Control transport local bind가 selected path를 입력으로 받을 수 있다.

## 메모

- 실제 socket local bind 변경은 task005에서 수행한다.
- 이 태스크에서는 fake transport 기반 orchestration을 우선 구현한다.
