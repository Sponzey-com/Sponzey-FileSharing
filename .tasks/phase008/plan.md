# UID 기반 Peer Identity와 고정 Active Route Lease 개발 계획

## 1. Project Goal

Sponzey FileSharing은 같은 로컬 네트워크의 Desktop 앱 인스턴스끼리 UDP 기반으로 peer를 찾고, 인증된 peer에게 파일을 빠르고 안정적으로 전송하는 앱이다.

이번 계획의 목표는 기존의 흔들리는 경로 선택 구조를 정리하고, 다음 전제와 원칙을 기준으로 peer 연결과 파일 전송 경로를 안정화하는 것이다.

- 하나의 PC 사용자 세션에는 하나의 Sponzey FileSharing 앱 인스턴스만 실행된다고 전제한다.
- 앱 인스턴스는 실행 시 내부 `instanceUid`를 하나 생성한다.
- `instanceUid`는 peer identity의 핵심 식별자이며, IP 주소, 포트, 네트워크 인터페이스 이름은 peer identity가 아니라 route candidate 속성이다.
- UDP discovery는 모든 사용 가능한 Ethernet 계열 인터페이스에서 수행하되, 같은 `instanceUid`에서 온 응답은 같은 peer의 여러 route candidate로만 처리한다.
- 인증과 route handshake가 성공해 active route lease가 만들어지면, 같은 `instanceUid`의 다른 route candidate가 들어와도 active route를 흔들지 않는다.
- active route lease는 명시적 종료, heartbeat/probe timeout, 인증 세션 종료, socket failure 같은 상태 전이로만 내려간다.
- 파일 전송은 전송 시작 시점의 active route lease snapshot을 사용하며, 전송 중 새 route candidate가 들어와도 자동으로 경로를 바꾸지 않는다.

최종적으로 해결해야 하는 사용자 문제는 다음과 같다.

- Parallels VM과 host 사이에서 같은 peer가 여러 IP 또는 포트로 보이며 UI와 전송 경로가 흔들리는 문제
- 파일 전송 중 discovery 또는 route probe 갱신 때문에 `routeLeaseId`가 바뀌고 전송이 중단되는 문제
- 같은 peer의 여러 경로 후보가 active route를 덮어써서 송신/수신 대상이 달라지는 문제
- 경로 선택 알고리즘이 특정 환경, 특정 IP 대역, 특정 VM 제품에 종속되는 문제

## 2. Current Implementation Assessment

현재 구현은 이미 다음 기반을 갖고 있다.

- Discovery, Control, Data 채널이 분리되어 있다.
- `PeerRouteCandidate`, `PeerConnectionPath`, `PeerPathRegistry`가 존재한다.
- 파일 전송은 `TransferRouteSnapshot`을 통해 전송 시작 시점의 경로 정보를 저장한다.
- route lease 검증은 `TransferOutgoingRouteLeaseCommand`로 분리되어 있다.
- 전송 data frame routing은 송신/수신 방향별로 분리되는 방향으로 개선되어 있다.
- 모든 Ethernet 계열 인터페이스에서 peer discovery와 route candidate 수집을 하려는 구조가 있다.

하지만 현재 구현에는 다음 구조적 문제가 남아 있다.

- `instanceUid`가 peer identity의 절대 기준으로 충분히 고정되어 있지 않다.
- 같은 peer에서 들어온 route candidate가 active route lease를 흔들 수 있다.
- active route lease와 route candidate의 lifecycle이 명확히 분리되어 있지 않다.
- `routeLeaseId`가 local interface, local address, remote address뿐 아니라 remote port 변화에도 민감하게 반응할 수 있다.
- discovery 갱신, route probe 갱신, 인증 session 갱신이 active route lease를 언제 바꿀 수 있는지 명확한 상태 전이 규칙이 부족하다.
- 파일 전송 중 새 candidate가 들어왔을 때 무시해야 하는지, 후보로만 저장해야 하는지, failover 후보로 검증해야 하는지 구분이 부족하다.
- UI는 peer identity와 route candidate를 섞어서 보여줄 가능성이 있어 사용자에게 peer가 바뀐 것처럼 보일 수 있다.

이번 계획에서는 기존 “새 route candidate가 들어오면 active path가 갱신될 수 있는 알고리즘”을 제거하고, “UID로 peer를 고정하고 active route lease는 명시적 상태 전이로만 바뀌는 알고리즘”으로 바꾼다.

### 2.1 Current Plan Strengths

현재 계획의 강점은 다음과 같다.

- peer identity와 route candidate를 분리해야 한다는 최종 방향이 명확하다.
- active route lease를 파일 전송의 기준으로 삼는 방향이 AGENTS.md의 route lease 원칙과 일치한다.
- Discovery, Control, Data 채널의 책임 분리 원칙을 유지한다.
- 전송 중 route snapshot을 유지해 endpoint가 흔들리지 않게 하는 목표가 명확하다.
- 자동 route switch를 별도 phase 전까지 금지해 현재 장애 범위를 줄인다.

### 2.2 Current Plan Gaps

계획을 실행 가능한 개발 문서로 쓰기 위해 다음 보강이 필요하다.

- 현재 코드에서 어떤 기존 경로 선택 알고리즘을 먼저 중단할지 순서가 더 명확해야 한다.
- `instanceUid`, peer identity, route candidate, active route lease, transfer route snapshot의 유스케이스 입력과 출력이 명시되어야 한다.
- Tidy First로 먼저 분리할 command, registry, state machine 경계가 명시되어야 한다.
- Field Debug Log와 Development Log가 혼재되지 않도록 로그 목적과 기본 노출 기준을 나눠야 한다.
- 각 phase가 기존 동작을 깨뜨리는지 확인할 최소 회귀 테스트가 명시되어야 한다.
- 자동화 테스트와 수동 host/VM 검증의 책임 경계가 명확해야 한다.

### 2.3 Architecture Risks

다음 위험은 구현 전에 반드시 통제한다.

- peer id 문자열 형식을 바꾸면 기존 transfer history, diagnostics, test fixture가 깨질 수 있다.
- route candidate key를 변경하면 기존 `PeerPathRegistry`의 selected path 조회와 충돌할 수 있다.
- active route lease를 고정하면 장애 발생 시 재연결이 늦어질 수 있다.
- 기존 discovery controller, peer auth controller, transfer controller가 route 상태 변경 책임을 나눠 갖고 있으면 상태 전이가 중복될 수 있다.
- route lease 상태 머신을 추가하면서 기존 boolean 상태나 registry 상태를 동시에 유지하면 서로 다른 truth source가 생길 수 있다.
- UI가 route candidate와 peer identity를 동시에 구독하면 같은 peer가 중복 표시될 수 있다.

### 2.4 Review Priority

리뷰와 구현은 다음 순서로 진행한다.

1. 현재 route 선택 흐름을 읽고 active route를 바꾸는 코드 경로를 모두 식별한다.
2. 동작 변경 없이 command와 registry 경계를 먼저 분리한다.
3. `instanceUid` 기반 peer identity 테스트를 작성한다.
4. route candidate upsert가 active route를 변경하지 않는 테스트를 작성한다.
5. active route lease 상태 머신을 테스트로 고정한다.
6. discovery, auth, transfer controller가 새 경계를 사용하도록 연결한다.
7. UI와 diagnostics를 마지막에 정리한다.

## 3. Target Model

### 3.1 Identity Model

`instanceUid`는 실행 중인 앱 인스턴스를 구분하는 내부 식별자다.

- 앱 시작 시 한 번 생성한다.
- 프로세스가 살아 있는 동안 변경하지 않는다.
- 외부 설정 파일에 저장하지 않는다.
- ID/PW와 독립적이다.
- password, token, session key에서 파생하지 않는다.
- discovery, control handshake, diagnostics에서 peer correlation 용도로 사용한다.
- 자기 자신이 보낸 packet을 구분하는 self packet suppression 기준으로 사용한다.

Peer identity는 다음 값으로 정의한다.

- user id
- instance uid
- protocol compatibility
- optional display metadata

Peer identity는 다음 값으로 정의하지 않는다.

- IP address
- UDP source port
- network interface name
- broadcast 또는 multicast 수신 경로
- device name 단독 값

### 3.2 Route Candidate Model

Route candidate는 같은 peer로 연결할 수 있을 가능성이 있는 네트워크 경로다.

Route candidate는 다음 값을 포함한다.

- peer identity reference
- local interface id
- local address
- remote address
- observed control port
- discovery source
- last seen time
- probe result
- RTT
- failure count
- compatibility
- receive availability

Route candidate는 active route가 아니다. candidate는 발견된 가능성일 뿐이며, 인증 또는 route handshake가 성공해야 active route lease로 승격될 수 있다.

### 3.3 Active Route Lease Model

Active route lease는 실제 연결과 파일 전송에 사용할 수 있는 검증된 경로다.

Active route lease는 다음 조건을 만족해야 한다.

- peer identity의 `instanceUid`가 일치한다.
- route candidate가 probe 또는 control handshake를 통과했다.
- 인증 session이 유효하다.
- control endpoint가 검증되어 있다.
- data endpoint 협상이 가능하거나 전송 시작 시 협상할 수 있다.
- 상태가 `active` 또는 이에 준하는 verified 상태다.

Active route lease는 다음 경우에만 변경된다.

- 현재 lease가 명시적으로 종료된다.
- heartbeat 또는 probe timeout으로 suspect 상태가 되고, 이후 expired로 전이된다.
- 인증 session이 종료된다.
- socket failure가 route 상태 머신을 통해 lease를 만료시킨다.
- 사용자가 명시적으로 재연결 또는 경로 재선택을 요청한다.
- failover 설계가 별도 task에서 구현되고, 새 route candidate가 검증에 성공한다.

Active route lease는 다음 경우에 변경되지 않는다.

- 같은 `instanceUid`에서 새 discovery packet이 들어온 경우
- 같은 `instanceUid`에서 다른 IP의 candidate가 추가된 경우
- 같은 `instanceUid`에서 control source port가 바뀐 packet이 들어온 경우
- 기존 active route가 정상인데 더 낮은 RTT candidate가 발견된 경우
- UI refresh 또는 peer list sort가 발생한 경우

### 3.4 Transfer Route Snapshot Model

파일 전송은 active route lease를 직접 계속 참조하지 않고, 전송 시작 시점의 route snapshot을 사용한다.

Route snapshot에는 다음 값이 포함되어야 한다.

- peer id
- instance uid
- active route lease id
- local interface id
- local address
- remote address
- control remote port
- negotiated data endpoint
- route selected time
- route verified time

전송 중에는 새 candidate가 들어와도 snapshot을 바꾸지 않는다. 전송 중 route가 완전히 죽으면 자동 경로 변경을 하지 않고 controlled failure 또는 명시적 재시도 정책으로 처리한다.

## 4. Architecture Direction

이번 계획의 아키텍처 방향은 AGENTS.md를 우선 기준으로 한다.

개발 원칙은 다음 순서로 적용한다.

1. Tidy First: 동작 변경 전 route identity, route candidate, active lease 관련 command와 registry 경계를 먼저 분리한다.
2. TDD: 각 동작 변경은 실패하는 테스트를 먼저 작성한 뒤 구현한다.
3. Clean Architecture: 순수 판단 규칙은 domain 또는 application command에 둔다.
4. Layered Architecture: UDP, 파일 시스템, 플랫폼 API 접근은 infrastructure에만 둔다.
5. State Machine: discovery, route lease, auth, transfer처럼 절차가 있는 흐름은 명시 상태와 이벤트로 표현한다.
6. MessageBus: 여러 컴포넌트가 관찰해야 하는 발생 사실만 이벤트로 발행한다.

이번 계획에서 “리팩터링”은 다음 두 종류로만 허용한다.

- 동작 변경 전 Tidy First: 테스트 없이 읽기 쉬운 rename, command extraction, dependency injection boundary 정리처럼 동작이 바뀌지 않는 변경
- 동작 변경 후 cleanup: 테스트가 통과한 뒤 중복 제거, 이름 정리, 계층 위반 제거

다음 리팩터링은 금지한다.

- route 안정화와 무관한 대규모 UI 구조 변경
- 파일 전송 프로토콜 성능 변경과 route identity 변경을 한 task에 섞는 변경
- 인증 정책 변경과 route lease 변경을 한 task에 섞는 변경
- 새 외부 설정 파일 도입을 동반하는 변경

### 4.1 Domain Layer

Domain layer는 Flutter, Riverpod, UDP socket, filesystem에 의존하지 않는다.

Domain layer에 둘 수 있는 항목은 다음과 같다.

- peer identity 값 객체
- instance uid 값 객체
- route candidate 값 객체
- active route lease 값 객체
- route lease 상태 enum 또는 sealed state
- route lease state machine
- route candidate selection policy
- self packet 판단 규칙
- route equivalence 판단 규칙

Domain layer에 두지 않을 항목은 다음과 같다.

- UDP bind
- RawDatagramSocket
- Riverpod provider
- UI state
- filesystem path
- platform-specific network interface enumeration

### 4.2 Application Layer

Application layer는 유스케이스와 상태 조합을 담당한다.

Application layer의 책임은 다음과 같다.

- discovery packet을 peer identity와 route candidate로 변환한다.
- self packet을 제거한다.
- 같은 `instanceUid`의 route candidate를 peer identity 아래로 병합한다.
- active route lease가 없는 peer에 대해서만 자동 handshake를 시작한다.
- active route lease가 있는 peer에 대해서는 새 candidate를 후보 목록에만 저장한다.
- route lease state machine event를 처리한다.
- transfer start 시 active route lease snapshot을 만든다.
- transfer 중 route 갱신 이벤트가 전송 snapshot을 바꾸지 않도록 보장한다.
- MessageBus로 이미 발생한 사실을 발행한다.

Application layer에서 금지할 항목은 다음과 같다.

- UDP socket 직접 접근
- platform network interface 직접 조회
- 파일 chunk 직접 읽기와 쓰기
- UI 조건문에 의존한 상태 전이
- 전역 singleton에서 환경 값을 재조회해 흐름 변경

### 4.3 Infrastructure Layer

Infrastructure layer는 외부 시스템 구현을 담당한다.

Infrastructure layer의 책임은 다음과 같다.

- UDP discovery 송수신
- UDP control 송수신
- UDP data 송수신
- network interface enumeration
- socket bind와 close
- filesystem read/write
- platform storage path 조회
- packet codec

Infrastructure layer는 application layer의 command나 domain state machine을 우회하지 않는다.

### 4.4 Presentation Layer

Presentation layer는 사용자 표시와 입력만 담당한다.

UI는 다음 기준을 따른다.

- peer list는 `instanceUid` 기준으로 하나의 peer만 보여준다.
- route candidate 목록은 diagnostics 또는 상세 화면에서만 표시한다.
- active route가 고정되어 있으면 discovery 갱신 때문에 peer card가 흔들리지 않는다.
- transfer target은 peer identity 기준으로 보여주고 내부적으로 active route lease snapshot을 사용한다.
- route candidate가 추가되어도 기존 connected 표시를 변경하지 않는다.
- active route lease가 suspect, expired, disconnected로 전이될 때만 연결 상태를 변경한다.

### 4.5 Usecase Contracts

각 유스케이스는 명시적 입력과 출력을 가진다. 숨은 전역 상태 조회로 결과가 바뀌면 안 된다.

Peer identity resolve usecase:

- Input: local instance uid, observed packet identity fields, observed transport metadata
- Output: self packet drop decision 또는 peer identity
- Boundary: packet decode는 infrastructure, identity decision은 domain/application

Route candidate upsert usecase:

- Input: peer identity, local interface id, local address, remote address, observed remote port, discovery source, observed time
- Output: candidate added, candidate updated, incompatible candidate rejected 중 하나
- Boundary: network interface enumeration은 infrastructure, candidate merge decision은 domain/application

Active route lease acquire usecase:

- Input: peer identity, candidate, auth session context, probe result, current active lease state
- Output: no-op, probing started, active lease created, rejected 중 하나
- Boundary: UDP probe 실행은 infrastructure, lease transition은 state machine

Active route lease refresh usecase:

- Input: active lease, observed candidate, heartbeat/probe event
- Output: no-op, lease remains active, suspect, expired 중 하나
- Boundary: observed packet 수집은 infrastructure, refresh decision은 application command

Transfer route snapshot usecase:

- Input: peer identity, active route lease, auth session, transfer request
- Output: immutable transfer route snapshot 또는 failure
- Boundary: transfer controller는 snapshot을 받아 context에 저장하고, 이후 endpoint 변경을 위해 registry를 재조회하지 않는다.

Disconnect handling usecase:

- Input: authenticated disconnect event, current active lease, timestamp
- Output: closed, ignored unauthenticated event, no-op 중 하나
- Boundary: packet authentication은 control/auth boundary, lease transition은 state machine

## 5. Legacy Algorithm Removal Plan

이번 변경에서는 다음 기존 알고리즘을 제거하거나 비활성화한다.

### 5.1 Discovery가 active route를 직접 흔드는 흐름 제거

현재 또는 과거 구조에서 discovery packet이 들어올 때마다 selected path를 바꿀 수 있는 흐름을 제거한다.

새 규칙은 다음과 같다.

- discovery packet은 route candidate를 추가하거나 갱신한다.
- active route lease가 없을 때만 handshake 후보가 된다.
- active route lease가 있으면 discovery packet은 active route를 바꾸지 않는다.

### 5.2 Route score 재계산이 active route를 즉시 교체하는 흐름 제거

RTT, failure count, interface score가 더 좋은 후보를 발견해도 즉시 active route를 바꾸지 않는다.

새 규칙은 다음과 같다.

- score는 후보 정렬과 diagnostics에만 사용한다.
- active route 교체는 현재 lease가 suspect 또는 expired로 전이된 뒤에만 수행한다.
- 전송 중에는 자동 route 교체를 하지 않는다.

### 5.3 Remote port 변화가 route 만료로 이어지는 흐름 제거

같은 `instanceUid`, 같은 local interface, 같은 local address, 같은 remote address라면 observed control port가 바뀌어도 같은 route family로 본다.

새 규칙은 다음과 같다.

- remote port는 candidate observation 속성이다.
- active route lease identity의 절대 기준은 `instanceUid`, local interface, local address, remote address다.
- remote port 변화는 control endpoint 갱신 후보로만 기록한다.
- 전송 중에는 이미 협상된 route snapshot을 유지한다.

### 5.4 UI가 route candidate 단위로 peer를 보여주는 흐름 제거

UI peer list는 route candidate 개수만큼 peer를 보여주면 안 된다.

새 규칙은 다음과 같다.

- peer card는 `instanceUid` 기준으로 1개만 표시한다.
- active route summary는 peer card에 최소한으로 표시한다.
- candidate 목록은 diagnostics로 분리한다.

### 5.5 파일 전송 중 active route 재조회 의존 제거

파일 전송 중 매 packet 또는 chunk마다 현재 selected path를 재조회해 endpoint를 바꾸는 흐름을 제거한다.

새 규칙은 다음과 같다.

- 전송 시작 시 route snapshot을 만든다.
- 전송 중 data frame은 snapshot의 endpoint를 사용한다.
- active route lease가 expired event를 받으면 controlled failure로 처리한다.
- 자동 failover는 별도 phase 전까지 금지한다.

## 6. Implementation Phases

### Phase 0. 현재 Route 흐름 감사와 Tidy First 경계 분리

Goal:

- 동작 변경 전에 현재 route selection, active path update, transfer route validation 경로를 모두 식별한다.
- 이후 phase에서 변경할 수 있도록 command, registry, state machine 경계를 작게 분리한다.

Scope:

- discovery packet handling
- peer auth handshake route selection
- peer path registry mutation
- transfer start route snapshot
- transfer 중 route lease validation
- diagnostics export route fields

Required Changes:

- active route를 변경하는 모든 호출 지점을 목록화한다.
- discovery observation이 active route 변경으로 이어지는 직접 경로를 표시한다.
- transfer controller가 전송 중 현재 selected path를 재조회하는 지점을 표시한다.
- route identity 비교 로직을 command로 분리되어 있지 않은 곳에서 분리한다.
- 동작을 바꾸지 않는 범위에서 이름, command boundary, test fixture를 정리한다.
- task 문서에는 구현 코드 조각을 넣지 않고 변경 대상, 테스트 기준, 완료 기준만 기록한다.

Architecture Notes:

- 이 phase는 behavior change를 하지 않는다.
- domain/application/infrastructure 경계 위반을 발견하면 바로 고치지 않고 task로 분리한다.
- 단순 extraction은 기존 테스트가 통과해야 완료된다.

TDD Requirements:

- 기존 테스트를 먼저 실행해 기준 상태를 기록한다.
- 동작 변경 없는 extraction은 기존 테스트 통과로 검증한다.
- 발견된 변경 필요사항은 다음 phase의 실패 테스트로 옮긴다.

Configuration Rules:

- 새 설정 파일을 만들지 않는다.
- 분석을 위해 환경 변수나 runtime flag를 추가하지 않는다.

Logging Rules:

- Product 로그 변경 없음.
- Field Debug 로그 변경 없음.
- Development 로그는 테스트 helper 내부에서만 필요한 경우 추가한다.

State Management:

- 기존 상태 전이 흐름을 문서화한다.
- boolean 조합으로 route state를 판단하는 위치를 표시한다.

Validation:

- active route mutation call site 목록이 task 문서에 존재한다.
- transfer route validation call site 목록이 task 문서에 존재한다.
- `flutter analyze`가 통과한다.
- 변경 범위에 맞는 기존 테스트가 통과한다.

Done Criteria:

- 다음 phase에서 제거할 legacy route update 흐름이 명확히 식별되어 있다.
- Tidy First 변경과 behavior change가 섞이지 않았다.

Risks:

- 현재 코드 흐름이 controller 여러 곳에 분산되어 누락될 수 있다.
- 누락을 줄이기 위해 `select`, `markFailed`, `expireLease`, `selectedForPeer`, `routeSnapshot` 검색 결과를 리뷰한다.

### Phase 1. Instance UID와 Peer Identity 경계 고정

Goal:

- 앱 인스턴스의 `instanceUid`를 peer identity의 핵심 기준으로 도입한다.
- IP, port, interface가 peer identity에 섞이는 흐름을 제거한다.

Scope:

- domain peer identity 모델
- bootstrap 시 instance uid 생성
- discovery packet payload
- self packet suppression
- peer id 생성 규칙

Required Changes:

- `instanceUid` 값 객체 또는 명시 모델을 domain/application 경계에 추가한다.
- 앱 bootstrap에서 프로세스 생명주기 동안 유지되는 `instanceUid`를 생성한다.
- `instanceUid`는 외부 파일에 저장하지 않는다.
- discovery packet에 `instanceUid`를 포함한다.
- control handshake packet에 `instanceUid`를 포함한다.
- 기존 device id 또는 device name 기반 self 판단을 `instanceUid` 기반으로 보강한다.
- peer id는 `userId + instanceUid` 조합을 기본으로 정리한다.
- 같은 `userId`라도 `instanceUid`가 다르면 별도 peer로 본다.
- 같은 `instanceUid`라도 IP가 다르면 같은 peer의 route candidate로 본다.

Architecture Notes:

- 순수 식별 규칙은 domain 또는 application command로 둔다.
- packet codec과 UDP 송수신은 infrastructure에 둔다.
- Flutter provider는 instance uid를 주입하는 조립 역할만 한다.

TDD Requirements:

- 같은 `instanceUid`와 다른 IP는 같은 peer identity로 병합된다.
- 다른 `instanceUid`와 같은 IP는 다른 peer로 구분된다.
- 자기 `instanceUid`가 들어온 packet은 peer list와 route candidate에 진입하지 않는다.
- `instanceUid`는 password나 token에서 파생되지 않는다.
- bootstrap 이후 `instanceUid`는 변경되지 않는다.

Configuration Rules:

- `instanceUid`는 외부 설정 파일에 저장하지 않는다.
- 실행 중 환경 변수나 설정 파일 재조회로 `instanceUid`를 바꾸지 않는다.
- 테스트는 생성된 값을 숨겨 바꾸지 말고 명시적으로 주입한다.

Logging Rules:

- Product: instance uid 원문을 남기지 않는다.
- Debug: 짧게 축약된 uid prefix만 남긴다.
- Development: self packet drop과 peer merge 판단을 추적할 수 있게 남긴다.

State Management:

- instance identity는 앱 프로세스 lifecycle 상태와 함께 관리한다.
- peer identity merge는 임의 map update가 아니라 명시 command로 처리한다.

Validation:

- 두 개의 fake IP에서 같은 `instanceUid` discovery를 받으면 peer가 1개만 생성된다.
- 자기 packet은 peer 목록에 나타나지 않는다.
- `flutter test test/application` 관련 identity 테스트가 통과한다.

Done Criteria:

- UI peer list에서 같은 `instanceUid`가 route 개수만큼 중복 표시되지 않는다.
- discovery/control/data packet self suppression 기준이 `instanceUid`를 사용한다.

Risks:

- 기존 history나 diagnostics가 peer id 문자열 형식에 의존할 수 있다.
- 기존 테스트가 device id 기반 peer id를 기대할 수 있다.

### Phase 2. Route Candidate Registry 재정의

Goal:

- 같은 peer의 여러 네트워크 경로를 route candidate로만 저장하고 active route를 직접 흔들지 않도록 한다.

Scope:

- route candidate collection
- candidate merge policy
- candidate TTL
- discovery observation handling
- diagnostics candidate display

Required Changes:

- route candidate key를 `peer instance uid + local interface + local address + remote address` 중심으로 재정의한다.
- observed remote port는 candidate observation 속성으로 관리한다.
- candidate upsert는 active route lease를 변경하지 않는다.
- discovery source별로 candidate freshness와 last seen time을 관리한다.
- candidate expiration은 candidate 상태만 바꾸고 active lease 변경은 별도 state machine event로 처리한다.
- route candidate score는 selection 후보 계산에만 사용하고 active route 교체에 직접 사용하지 않는다.

Architecture Notes:

- candidate equivalence 판단은 domain/application command로 분리한다.
- infrastructure discovery transport는 packet을 전달할 뿐 candidate merge를 직접 수행하지 않는다.
- diagnostics는 candidate 목록과 active lease를 분리해서 표시한다.

TDD Requirements:

- 같은 `instanceUid`, 같은 local/remote address, 다른 remote port는 같은 candidate로 갱신된다.
- 같은 `instanceUid`, 다른 local address는 다른 candidate가 된다.
- active lease가 있는 상태에서 새 candidate가 들어와도 selected active route가 바뀌지 않는다.
- candidate TTL 만료가 active lease를 직접 삭제하지 않는다.

Configuration Rules:

- candidate TTL과 probe interval은 기존 `AppConfig` 또는 명시 주입 값만 사용한다.
- 런타임 중 외부 파일 재로드로 TTL을 바꾸지 않는다.

Logging Rules:

- Product: candidate 발견/만료는 기본적으로 남기지 않는다.
- Debug: candidate added, updated, expired를 축약 peer id와 route summary로 남긴다.
- Development: candidate merge reason을 남긴다.

State Management:

- candidate state는 `fresh`, `probing`, `reachable`, `degraded`, `expired`, `failed`, `incompatible`처럼 명시 상태로 유지한다.
- candidate 상태가 active lease 상태를 직접 변경하지 않는다.

Validation:

- Parallels host/VM 환경에서 같은 peer가 여러 후보로 들어와도 UI peer card는 1개다.
- diagnostics에는 후보 목록이 보이고 active route는 별도로 표시된다.

Done Criteria:

- discovery storm 또는 port 갱신으로 active route가 바뀌지 않는다.
- route candidate registry 단위 테스트가 모든 merge 규칙을 고정한다.

Risks:

- candidate key 재정의가 기존 path id 기대 테스트를 깨뜨릴 수 있다.
- diagnostics bundle schema가 바뀔 수 있다.

### Phase 3. Active Route Lease State Machine 강화

Goal:

- active route lease는 상태 머신으로만 생성, 유지, 만료, 종료되게 한다.

Scope:

- route lease state machine
- route lease registry
- handshake success to lease activation
- heartbeat/probe timeout
- explicit disconnect
- session termination

Required Changes:

- active route lease 상태를 명확히 정의한다.
- 최소 상태는 `none`, `probing`, `active`, `suspect`, `expired`, `closed`로 둔다.
- handshake 성공 시 candidate를 active lease로 승격한다.
- active lease가 있는 peer는 새 candidate로 자동 교체하지 않는다.
- heartbeat 또는 route probe 실패가 누적되면 `suspect`로 전이한다.
- timeout 또는 명시 종료가 발생하면 `expired` 또는 `closed`로 전이한다.
- `expired` 이후에만 새 candidate selection과 re-handshake가 가능하다.
- 전송 중에는 active lease 교체가 아니라 transfer session에 failure event를 전달한다.

Architecture Notes:

- 순수 전이 규칙은 domain 또는 application state machine으로 둔다.
- timer, UDP probe, socket failure는 infrastructure event 또는 application event로 주입한다.
- MessageBus는 route lease event를 알리는 용도로만 사용한다.

TDD Requirements:

- active lease가 없는 peer만 candidate에서 handshake를 시작한다.
- active lease가 있는 peer에 새 candidate가 들어와도 active lease가 유지된다.
- active lease가 `suspect`가 되어도 즉시 다른 candidate로 바뀌지 않는다.
- active lease가 `expired`가 된 뒤에만 새 candidate가 선택된다.
- explicit disconnect는 active lease를 `closed`로 전이한다.
- transfer 중 route expired event는 transfer failure로 연결된다.

Configuration Rules:

- heartbeat interval, timeout, retry count는 bootstrap config 또는 명시 주입 값으로만 사용한다.
- 중간에 외부 설정으로 timeout을 바꾸지 않는다.

Logging Rules:

- Product: active route connected, disconnected, expired만 남긴다.
- Debug: state transition과 reason code를 남긴다.
- Development: invalid transition을 남긴다.

State Management:

- 모든 route lease 변경은 state machine event로만 수행한다.
- boolean 조합으로 connected, probing, failed를 흩어놓지 않는다.

Validation:

- same UID new candidate during active lease scenario가 active route를 바꾸지 않는 테스트가 통과한다.
- heartbeat timeout scenario가 route lease를 expired로 내리고 peer identity는 유지한다.

Done Criteria:

- `PeerPathRegistry` 또는 route lease registry에서 active route 변경 경로가 한 곳으로 모인다.
- active route 자동 교체 알고리즘이 제거된다.

Risks:

- 기존 자동 재연결 체감 속도가 일시적으로 느려질 수 있다.
- expired 이후 re-handshake UX를 명확히 표시해야 한다.

### Phase 4. Transfer Route Snapshot 고정

Goal:

- 파일 전송은 active route lease snapshot으로만 수행하고, 전송 중 route candidate 갱신에 영향을 받지 않게 한다.

Scope:

- transfer start route snapshot
- outgoing transfer context
- incoming transfer context
- route validation
- data endpoint negotiation
- transfer failure policy

Required Changes:

- transfer start 시 active route lease snapshot을 필수로 만든다.
- outgoing transfer context는 snapshot의 local/remote address와 data endpoint를 사용한다.
- incoming transfer context도 observed control endpoint와 active lease를 대조한 뒤 snapshot을 만든다.
- 전송 중 새 discovery packet, 새 candidate, score 변경은 transfer context를 바꾸지 않는다.
- 전송 중 active route lease expired event가 오면 controlled failure로 전이한다.
- 자동 failover는 이번 계획 범위에서 제외한다.
- route lease id 문자열이 바뀌더라도 같은 route family이면 전송을 중단하지 않는다.
- remote IP 또는 local interface가 바뀌면 다른 route로 보고 전송을 중단한다.

Architecture Notes:

- transfer route equivalence 판단은 application command로 유지한다.
- data socket bind와 packet send는 infrastructure에 둔다.
- transfer controller는 command 결과를 적용하는 adapter 역할로 줄인다.

TDD Requirements:

- transfer 중 같은 `instanceUid`의 다른 candidate가 들어와도 transfer endpoint가 바뀌지 않는다.
- transfer 중 같은 route family의 observed port가 바뀌어도 전송이 계속된다.
- transfer 중 remote address가 바뀌면 controlled failure가 발생한다.
- route expired event가 발생하면 transfer는 failed로 전이하고 재시도 가능 메시지를 남긴다.
- outgoing과 incoming이 동시에 진행되어도 route snapshot과 frame routing이 섞이지 않는다.

Configuration Rules:

- transfer 중 외부 설정 reload로 endpoint나 chunk policy가 바뀌지 않는다.
- transfer job 생성 시점의 policy snapshot을 사용한다.

Logging Rules:

- Product: transfer start, completion, failure만 남긴다.
- Debug: route snapshot summary와 failure reason을 남긴다.
- Development: route equivalence decision을 남긴다.

State Management:

- transfer session state machine이 route expired event를 처리한다.
- transfer 진행 상태는 active route registry를 직접 재조회하지 않는다.

Validation:

- host to Parallels VM 전송 중 discovery 갱신이 들어와도 전송이 완료된다.
- Parallels VM to host 전송도 동일하게 완료된다.
- 양방향 동시 전송이 완료된다.

Done Criteria:

- transfer 중 selected active route 변경이 전송 endpoint를 바꾸지 않는다.
- route expired와 route refresh가 다른 결과를 내는 테스트가 존재한다.

Risks:

- 실제 route가 죽었는데 snapshot을 너무 오래 붙잡으면 timeout까지 시간이 걸릴 수 있다.
- 이 문제는 heartbeat/probe timeout 값을 별도 검증으로 조정한다.

### Phase 5. Peer UI와 Diagnostics 정리

Goal:

- UI는 peer identity 기준으로 안정적으로 보이고, route candidate 변화는 diagnostics에서만 확인되게 한다.

Scope:

- Recent peers
- Transfer target selector
- Discovery diagnostics
- Route diagnostics
- Error message

Required Changes:

- peer list는 `instanceUid` 기준으로 하나의 peer card만 표시한다.
- peer card에는 active route summary만 표시한다.
- port는 일반 UI에서 표시하지 않는다.
- route candidate 목록은 diagnostics에만 표시한다.
- active route가 유지 중이면 새 candidate 발견으로 UI 상태가 흔들리지 않는다.
- route expired 또는 disconnected 상태 전이에서만 UI 연결 상태를 바꾼다.
- 전송 실패 메시지는 route refresh와 route expired를 구분해서 표시한다.

Architecture Notes:

- UI는 registry 구현체가 아니라 application provider/view model을 통해 상태를 본다.
- route candidate와 active lease를 분리한 view model을 만든다.

TDD Requirements:

- 같은 peer의 route candidate가 여러 개여도 peer card는 1개다.
- active route가 있는 상태에서 새 candidate가 추가되어도 target selector 선택값이 바뀌지 않는다.
- route expired event 후 UI가 disconnected 또는 reconnecting 상태를 보여준다.
- transfer failure message가 사용자가 이해할 수 있는 문구로 매핑된다.

Configuration Rules:

- UI 표시 정책은 설정 파일로 바꾸지 않는다.
- diagnostics verbosity는 기존 log level 또는 debug mode 기준을 따른다.

Logging Rules:

- UI 이벤트로 product log를 남발하지 않는다.
- diagnostics export에는 active lease와 candidate 목록을 분리해 기록한다.

State Management:

- UI는 peer identity, active route, candidate diagnostics를 별도 상태로 본다.
- UI 조건문에서 route selection을 수행하지 않는다.

Validation:

- Parallels host/VM에서 peer card가 IP 또는 port 갱신으로 깜빡이거나 중복되지 않는다.
- transfer target dropdown이 전송 중 변경되지 않는다.

Done Criteria:

- 사용자 화면은 peer 하나를 안정적으로 보여준다.
- diagnostics는 문제 분석에 필요한 route 후보를 충분히 보여준다.

Risks:

- diagnostics가 부족하면 현장 문제 분석이 어려워질 수 있다.
- 일반 UI와 diagnostics UI의 정보량 경계를 명확히 해야 한다.

### Phase 6. Explicit Disconnect와 Timeout 정책

Goal:

- active route lease는 명시 종료 또는 timeout으로만 내려가게 한다.

Scope:

- heartbeat
- route probe
- explicit disconnect packet
- app shutdown
- peer offline handling
- socket error handling

Required Changes:

- peer가 정상 종료할 때 disconnect signal을 보낸다.
- disconnect signal을 받은 peer는 active route lease를 `closed`로 전이한다.
- heartbeat 또는 probe가 일정 횟수 실패하면 `suspect`로 전이한다.
- `suspect` 상태에서 timeout이 지나면 `expired`로 전이한다.
- `expired` 이후 reconnect selection을 시작한다.
- app shutdown 시 best-effort disconnect를 보낸다.
- disconnect packet은 인증/session context와 연결해 spoofing 위험을 줄인다.

Architecture Notes:

- shutdown hook과 UDP send는 infrastructure 또는 app bootstrap 경계에서 처리한다.
- state transition은 application/domain state machine으로 처리한다.

TDD Requirements:

- explicit disconnect packet이 active lease를 closed로 전이한다.
- unauthenticated disconnect packet은 무시된다.
- heartbeat miss 누적이 suspect로 전이한다.
- timeout이 expired로 전이한다.
- expired 후 candidate selection은 가능하지만 active 상태에서는 불가능하다.

Configuration Rules:

- timeout 값은 `AppConfig` 또는 명시 주입으로만 사용한다.
- 런타임 중 설정 파일 reload로 timeout을 바꾸지 않는다.

Logging Rules:

- Product: disconnect와 expired를 남긴다.
- Debug: heartbeat miss count와 timeout reason을 남긴다.
- Development: ignored disconnect reason을 남긴다.

State Management:

- disconnect, heartbeat miss, timeout은 모두 state machine event로 처리한다.

Validation:

- 앱 하나를 종료하면 다른 앱에서 peer가 일정 시간 뒤 offline 또는 disconnected로 내려간다.
- 정상 종료 signal이 있으면 timeout을 기다리지 않고 내려간다.

Done Criteria:

- connected peer가 종료 후 무기한 남아 있지 않는다.
- active route lease가 discovery packet 유무만으로 삭제되지 않는다.

Risks:

- OS가 앱을 강제 종료하면 disconnect signal이 전송되지 않을 수 있다.
- timeout fallback은 반드시 유지해야 한다.

### Phase 7. Release Gate와 수동 검증

Goal:

- UID 기반 active route 고정 모델이 실제 host/VM/다중 NIC 환경에서 동작함을 검증한다.

Scope:

- automated tests
- local two-instance smoke
- macOS host to Parallels Windows VM
- Parallels Windows VM to macOS host
- simultaneous bidirectional transfer
- diagnostics export

Required Changes:

- release gate에 UID merge 테스트를 포함한다.
- release gate에 active route 고정 테스트를 포함한다.
- release gate에 양방향 동시 전송 테스트를 포함한다.
- 수동 checklist에 host/VM 양방향 전송을 포함한다.
- diagnostics bundle에 peer identity, active route lease, candidate list, transfer snapshot을 포함한다.

Architecture Notes:

- smoke script는 앱 내부 설정을 런타임 중간에 바꾸지 않는다.
- 테스트는 명시 주입된 config와 fake transport를 사용한다.

TDD Requirements:

- unit, application, infrastructure test가 각 계층 책임에 맞게 존재한다.
- 실제 OS 환경은 수동 smoke와 release checklist로 보완한다.

Configuration Rules:

- release smoke를 위해 외부 dotenv 또는 임의 설정 파일을 추가하지 않는다.
- 필요한 값은 command argument 또는 bootstrap config로 명시 전달한다.

Logging Rules:

- release smoke는 Product와 Field Debug 로그를 구분해 수집한다.
- Development 로그는 기본 release artifact에 포함하지 않는다.

State Management:

- smoke 결과는 discovery, auth, route lease, transfer, file verify 단계를 분리해 기록한다.

Validation:

- macOS host to Parallels Windows VM 파일 전송 성공
- Parallels Windows VM to macOS host 파일 전송 성공
- 양방향 동시 전송 성공
- 전송 완료 후 수신 파일 digest 일치
- discovery 갱신 중 active route가 흔들리지 않음

Done Criteria:

- CI 테스트 통과
- 수동 host/VM 양방향 전송 기록 존재
- release 전 diagnostics export 검토 가능

Risks:

- GitHub Actions만으로 실제 Parallels VM 환경을 재현할 수 없다.
- 수동 검증 기록을 누락하면 release 품질 판단이 어려워진다.

## 7. TDD Strategy

이번 계획은 TDD를 기본으로 진행한다.

테스트 우선순위는 다음과 같다.

1. Domain/Application 단위 테스트로 peer identity와 route candidate merge 규칙을 고정한다.
2. Route lease state machine 테스트로 active route lifecycle을 고정한다.
3. Transfer route snapshot 테스트로 전송 중 route 흔들림을 차단한다.
4. Fake UDP network 테스트로 host/VM 유사 다중 candidate 상황을 재현한다.
5. Widget 또는 view model 테스트로 UI peer card 안정성을 검증한다.
6. Infrastructure UDP loopback 테스트로 socket과 codec 회귀를 막는다.

필수 테스트 케이스는 다음과 같다.

- 같은 `instanceUid`, 다른 IP는 peer 1개와 candidate 여러 개로 처리된다.
- 다른 `instanceUid`, 같은 IP는 peer 2개로 처리된다.
- active route가 있는 peer에 새 candidate가 들어와도 active route는 유지된다.
- active route가 expired 되기 전에는 자동 route switch가 발생하지 않는다.
- explicit disconnect는 active route를 closed로 전이한다.
- heartbeat timeout은 active route를 expired로 전이한다.
- transfer 중 route candidate 추가는 transfer endpoint를 바꾸지 않는다.
- transfer 중 같은 route family refresh는 전송을 중단하지 않는다.
- transfer 중 remote address 변경은 controlled failure로 처리된다.
- 양방향 동시 전송에서 outgoing/incoming session state가 섞이지 않는다.

## 8. Configuration and Runtime Environment Policy

이번 계획에서 새 외부 설정 파일은 추가하지 않는다.

허용되는 설정 전달 방식은 다음과 같다.

- app bootstrap 시 `AppConfig`로 전달
- 테스트에서 provider override 또는 생성자 인자로 전달
- 유스케이스 입력값으로 명시 전달
- 사용자 설정이 필요한 경우 기존 settings repository 범위 안에서 저장

금지되는 방식은 다음과 같다.

- 새 dotenv, YAML, JSON 설정 파일 추가
- 실행 중 외부 설정 파일 재로드
- 환경 변수를 중간에 다시 읽어 동작 변경
- mutable global singleton으로 route policy 변경
- 테스트에서 숨은 전역 상태로 설정 변경

`instanceUid`는 외부 설정이 아니다. 프로세스 내부 identity이며 시작 시 한 번 생성되고 프로세스 종료와 함께 사라진다.

## 9. Logging Strategy

로그는 기존 `AppLogger`, `AppLogLevel`, `AppLogCategory`를 사용한다.

Product Log:

- 앱 instance 시작
- peer connected
- peer disconnected
- route expired
- transfer started
- transfer completed
- transfer failed

Field Debug Log:

- peer identity merge
- route candidate added 또는 updated
- active route lease selected
- active route lease ignored new candidate
- route lease state transition
- transfer route snapshot created
- transfer route expired failure

Development Log:

- self packet drop reason
- candidate equivalence decision
- route selection score
- invalid state transition
- test fake network delivery detail

로그 금지 항목:

- password
- password-derived token
- session key
- raw file contents
- 전체 개인 파일 경로
- 불필요한 per-packet product/info 로그

## 10. State Machine Strategy

상태 머신은 다음 흐름에 적용한다.

Peer discovery state:

- unknown
- seen
- stale
- offline

Route candidate state:

- fresh
- probing
- reachable
- degraded
- failed
- expired
- incompatible

Active route lease state:

- none
- probing
- active
- suspect
- expired
- closed

Authentication state:

- unauthenticated
- handshakeStarted
- challengeVerified
- authenticated
- rejected
- expired

Transfer state:

- queued
- preparing
- awaitingReceiver
- sending
- receiving
- verifying
- completed
- failed
- canceled

상태 전이 원칙:

- state transition은 한 곳에서 추적 가능해야 한다.
- UI callback과 socket handler 안에서 직접 상태를 조합하지 않는다.
- invalid transition은 무시하지 않고 명시적으로 no-op, warning, failure 중 하나로 처리한다.
- timeout, retry, failure count는 테스트로 고정한다.

## 11. Dependency and Boundary Rules

의존성 방향은 다음을 따른다.

- presentation -> application
- application -> domain
- infrastructure -> domain 또는 application interface
- app -> 조립 코드

금지하는 의존성은 다음과 같다.

- domain -> Flutter
- domain -> Riverpod
- domain -> UDP socket
- domain -> filesystem
- application -> RawDatagramSocket
- presentation -> infrastructure transport 직접 호출
- infrastructure -> presentation

MessageBus 사용 기준:

- 이미 발생한 discovery observation, route lease transition, transfer state event를 알릴 때 사용한다.
- 명령 실행을 MessageBus에 숨기지 않는다.
- state machine transition은 event 수신 후에도 허용 전이인지 명시 검증한다.

## 12. Risk and Mitigation

Risk: 같은 PC에서 앱 인스턴스를 여러 개 실행하는 경우

- Mitigation: 현재 전제는 PC당 하나의 앱 인스턴스다. 다중 인스턴스 지원은 별도 phase로 분리한다.

Risk: VM bridge와 Wi-Fi가 동시에 보이는 경우

- Mitigation: 두 경로는 같은 peer의 candidate로 유지한다. active lease가 정상인 동안 자동 교체하지 않는다.

Risk: active route가 죽었는데 새 candidate가 더 빨리 살아 있는 경우

- Mitigation: active route가 expired로 전이된 뒤에만 재선택한다. 전송 중 자동 failover는 별도 설계 전까지 금지한다.

Risk: remote port 갱신을 너무 느슨하게 허용하는 경우

- Mitigation: remote port는 identity 기준에서 제외하되, remote address와 local interface는 유지해야 한다.

Risk: UI에서 사용자가 어떤 경로로 연결되었는지 알기 어려운 경우

- Mitigation: 일반 UI에는 안정적인 peer card를 보여주고, diagnostics에 active route와 candidate 목록을 분리 표시한다.

Risk: 로그가 부족해 현장 문제를 파악하기 어려운 경우

- Mitigation: Field Debug 로그에 identity merge, candidate update, active lease ignore reason, transfer snapshot을 남긴다.

Risk: 기존 테스트가 path id exact match에 의존하는 경우

- Mitigation: exact match 검증은 active lease identity 테스트로 유지하고, route family equivalence는 `same instance uid + same local interface + same local address + same remote address + changed remote port` 입력으로 실패 테스트를 먼저 작성한 뒤 허용 동작으로 통과시킨다.

## 13. Review Checklist

리뷰 시 다음을 확인한다.

- peer identity가 IP, port, interface에 의존하지 않는다.
- `instanceUid`가 peer identity와 self packet suppression에 사용된다.
- 같은 `instanceUid`의 여러 route는 candidate로만 저장된다.
- active route lease는 state machine event로만 변경된다.
- discovery packet이 active route를 직접 바꾸지 않는다.
- route score가 active route를 즉시 교체하지 않는다.
- 파일 전송은 route snapshot을 사용한다.
- 전송 중 selected path 재조회가 endpoint 변경으로 이어지지 않는다.
- route expired와 route refresh가 테스트로 구분된다.
- UI는 peer identity 기준으로 하나의 peer를 표시한다.
- diagnostics는 active lease와 candidate list를 분리한다.
- 로그는 Product Log, Field Debug Log, Development Log 목적에 맞게 나뉜다.
- 외부 설정 파일이나 런타임 환경 재조회가 추가되지 않았다.
- domain layer가 Flutter, Riverpod, UDP, filesystem에 의존하지 않는다.
- refactoring과 behavior change가 가능한 한 분리되어 있다.

### 13.1 Mandatory Validation Criteria

다음 검증 기준은 모든 task 리뷰에서 확인한다.

1. 도메인 계층이 Flutter, Riverpod, UDP socket, 파일 시스템, 데이터베이스, 플랫폼 API에 의존하지 않는다.
2. 각 유스케이스는 명시적 입력과 출력을 가지며, 숨은 전역 상태 조회로 결과가 바뀌지 않는다.
3. 외부 환경 값은 프로그램 시작 이후 암묵적으로 재조회되지 않는다.
4. 설정 값은 프로세스 중간에 삽입되거나 변경되지 않는다.
5. 외부 API, DB, 파일 시스템, 네트워크 접근은 infrastructure 또는 app bootstrap 경계에만 존재한다.
6. 테스트 더블로 UDP transport, clock, storage path, file service, settings repository를 대체할 수 있다.
7. 로그는 Product Log, Field Debug Log, Development Log 목적에 맞게 분리되어 있다.
8. Development Log는 프로덕션 기본 동작에 포함되지 않는다.
9. discovery, route lease, authentication, transfer처럼 복잡한 내부 흐름은 flag 조합이 아니라 명시적 상태 전이로 표현된다.
10. Tidy First 정리와 기능 동작 변경은 가능한 한 별도 commit 또는 별도 task로 분리된다.

### 13.2 Review Evidence

각 task 완료 시 리뷰에 필요한 증거는 다음 중 해당 항목을 포함한다.

- 변경한 유스케이스의 입력과 출력 목록
- 변경한 상태 머신의 상태, 이벤트, 전이 조건
- 제거한 legacy route update 흐름
- 추가 또는 갱신한 테스트 파일명
- 실행한 테스트 명령
- Product, Field Debug, Development 로그 변경 여부
- 외부 설정 파일을 추가하지 않았다는 확인
- 수동 host/VM 검증이 필요한 경우 검증 환경과 결과

## 14. Definition of Done

이번 계획의 완료 기준은 다음과 같다.

- 앱 시작 시 `instanceUid`가 생성되고 프로세스 중 변경되지 않는다.
- 같은 `instanceUid`에서 온 여러 IP/포트/인터페이스 응답은 하나의 peer와 여러 candidate로 정리된다.
- active route lease가 있는 동안 새 candidate가 active route를 흔들지 않는다.
- active route lease는 explicit disconnect, timeout, auth/session 종료, socket failure로만 내려간다.
- 파일 전송은 active route snapshot으로 수행된다.
- 전송 중 discovery 갱신 또는 remote port 갱신이 전송을 중단하지 않는다.
- remote address 또는 local interface가 실제로 바뀌면 controlled failure가 발생한다.
- UI peer card는 같은 peer를 중복 표시하지 않는다.
- diagnostics는 active route와 candidate list를 모두 제공한다.
- macOS host to Parallels Windows VM 전송이 성공한다.
- Parallels Windows VM to macOS host 전송이 성공한다.
- 양방향 동시 전송이 성공한다.
- 수신 파일 digest가 원본과 일치한다.
- 관련 unit, application, infrastructure, UI/view model 테스트가 통과한다.

## 15. Prohibited Implementation Patterns

다음 구현은 금지한다.

- IP 주소를 peer identity로 사용하는 구현
- UDP source port 변경을 peer 변경으로 보는 구현
- discovery packet 수신만으로 active route를 교체하는 구현
- 더 좋은 score의 route candidate를 발견하자마자 active route로 바꾸는 구현
- 전송 중 active route를 자동으로 다른 candidate로 갈아타는 구현
- 전송 중 매 chunk마다 current selected path를 재조회해 endpoint를 바꾸는 구현
- UI에서 route selection을 수행하는 구현
- domain layer에서 Flutter, Riverpod, UDP socket, filesystem을 참조하는 구현
- 외부 설정 파일을 추가해 route policy를 바꾸는 구현
- 런타임 중 환경 변수를 다시 읽어 route behavior를 바꾸는 구현
- password, token, session key, raw file content를 로그에 남기는 구현
- per-packet product/info 로그를 기본 경로에 넣는 구현
- MessageBus를 command 실행 경로로 숨기는 구현
- 상태머신 없이 boolean 조합으로 connected, probing, expired를 관리하는 구현

## 16. Next Actions

다음 작업 순서로 진행한다.

1. `instanceUid`와 peer identity 경계 테스트를 먼저 작성한다.
2. route candidate merge policy 테스트를 작성한다.
3. active route lease state machine 테스트를 작성한다.
4. discovery handling에서 active route 직접 교체 흐름을 제거한다.
5. active route lease registry 또는 기존 registry를 상태머신 기반으로 정리한다.
6. transfer route snapshot은 `transfer started -> new candidate observed -> data frame sent` 순서의 테스트로 endpoint가 변경되지 않음을 먼저 실패 테스트로 고정한다.
7. UI peer card를 `instanceUid` 기준으로 안정화한다.
8. diagnostics에 active route와 candidate list를 분리해 표시한다.
9. host/VM 양방향 수동 smoke를 실행한다.
10. release gate에 양방향 전송과 digest 검증을 반영한다.

각 단계는 기능 2~3개, 테스트, 검증 기준을 묶은 task 문서로 분해한다. task 문서에는 구현 코드 조각을 넣지 않고, 목적, 변경 범위, 테스트 기준, 완료 기준만 적는다.
