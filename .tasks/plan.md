# TCP Data Channel 전환 개발 계획

## 0. Plan Review Update Summary

이 문서는 기존 UDP Data channel 안정화 계획을 대체하는 현재 phase의 기준 계획이다. 기존 계획의 유효한 방향인 Discovery, Control, Data 책임 분리와 active route 안정화 원칙은 유지한다. 변경되는 핵심은 파일 payload의 기본 Data channel을 UDP frame에서 TCP stream으로 전환하는 것이다.

이번 계획에서 보강하고 현재 구현 루프에서 반영 중인 기준은 다음과 같다.

- AGENTS.md, README.md, README.ko.md는 UDP Discovery/Control과 TCP Data payload 방향으로 정렬한다.
- TCP 연결 이후 peer 연결 상태의 source of truth를 TCP session state로 고정한다.
- discovery candidate, route candidate, active route lease, TCP data session의 책임과 변경 가능 범위를 분리한다.
- 각 phase를 Tidy First, TDD, 구현, 검증, 리뷰가 가능한 단위로 재정렬한다.
- 외부 설정 파일 추가 금지, bootstrap 시점 최초 수신, 이후 명시적 인자 전달 원칙을 TCP port, timeout, frame size, mode 선택에 적용한다.
- Product Log, Field Debug Log, Development Log의 용도와 금지 로그를 TCP 전환 기준으로 고정한다.
- TCP session state machine과 transfer stream state machine의 이벤트, 금지 전이, 실패 상태를 명시한다.
- 도메인, 애플리케이션, 인프라, 프레젠테이션 경계를 검증 가능한 체크리스트로 추가한다.

## 1. Project Goal

이번 개발의 목표는 Sponzey FileSharing의 파일 데이터 전송 채널을 UDP 기반 data frame 전송에서 TCP 기반 peer data session으로 전환하는 것이다.

Discovery와 인증/control 흐름은 기존 로컬 네트워크 자동 탐색 구조를 유지한다. 그러나 실제 파일 byte stream은 검증된 peer와 맺은 TCP data channel을 통해 송신하고, 상대 peer가 맺은 TCP data channel에서는 수신한다.

최종 목표는 다음과 같다.

- UDP Discovery는 peer 검색과 route candidate 수집만 담당한다.
- UDP Control은 인증, TCP data channel 협상, 전송 시작/취소/완료 같은 제어 메시지만 담당한다.
- TCP Data Channel은 인증된 peer 간 파일 payload 전송만 담당한다.
- peer와 TCP data channel이 연결되어 있는 동안 discovery candidate 만료, route candidate 변경, UDP source port 변경, 더 나은 후보 발견은 해당 peer의 active connection을 변경하거나 만료시키지 않는다.
- 데이터 채널 연결 후 peer 연결 상태, 전송 가능 여부, 실패 판단은 TCP session 상태를 기준으로 진행한다.
- TCP 연결이 끊어진 경우에만 명시적인 상태 전이를 통해 disconnected, reconnecting, failed, reconnectRequired 상태로 내려간다.
- 파일 전송은 "내가 붙은 TCP data channel"로 송신하고, "상대가 붙은 TCP data channel"에서 수신한다.
- 한 peer에 대해 하나의 안정된 TCP data session을 유지하고, 해당 session 위에서 여러 transfer job을 순차 또는 병렬 정책에 따라 처리한다.
- 기존 UDP chunk, ACK/NACK, sliding window, retransmission 중심의 data transfer 알고리즘은 TCP 기본 경로에서 제거한다.

이번 계획은 성능보다 먼저 안정성을 목표로 한다. TCP로 전환하면 OS TCP stack이 순서 보장, 재전송, 흐름 제어를 담당하므로 애플리케이션 레벨에서는 session framing, backpressure, 파일 검증, 연결 lifecycle, 장애 복구에 집중한다.

이번 계획의 최종 사용자 관점 성공 기준은 다음과 같다.

- macOS host와 Parallels Windows VM이 서로 peer를 찾은 뒤 TCP data channel을 자동으로 연결한다.
- 연결된 peer는 discovery stale, route candidate 만료, UDP source port 변화 때문에 전송 중 끊기지 않는다.
- 사용자가 파일을 드롭하면 별도 승인 없이 인증된 peer의 TCP data channel로 전송된다.
- 수신자는 기본 저장 경로에 임시 파일을 만들고, digest 검증 후 최종 파일로 이동한다.
- 실패 시 UI는 "TCP 연결 실패", "TCP 연결 종료", "저장 실패", "검증 실패"처럼 실제 원인에 맞는 메시지를 보여준다.

## 2. Current Implementation Assessment

현재 구현은 다음 구조를 갖고 있다.

- UDP Discovery transport가 여러 Ethernet 계열 인터페이스에서 peer candidate를 수집한다.
- UDP Control transport가 인증, handshake, transfer init 계열 packet을 처리한다.
- UDP Data channel은 raw binary data frame, ACK/NACK, window, retry, loss, RTT를 직접 관리한다.
- `PeerPathRegistry`가 검증된 active route lease를 보관한다.
- `TransferRouteSnapshot`이 전송 시작 시점 route 정보를 캡처한다.
- 송신/수신 transfer runner와 transfer session state machine이 UDP data frame 기준으로 분리되어 있다.

현재 구조의 강점은 다음과 같다.

- Discovery, Control, Data 책임이 이미 분리되어 있다.
- peer identity와 route candidate를 분리하는 방향이 잡혀 있다.
- active route lease를 전송 시작 기준으로 사용하는 구조가 있다.
- 송신/수신 runner 분리와 MessageBus event 기반 관찰 구조가 이미 존재한다.
- 전체 테스트가 transfer, discovery, auth, path registry를 폭넓게 커버한다.

현재 구조의 한계는 다음과 같다.

- UDP data frame 전송은 앱 레벨에서 ACK/NACK, out-of-order buffer, retransmission, congestion/window, timeout을 모두 관리해야 한다.
- VM bridge, host-only network, multi-interface 환경에서는 discovery/control route와 data socket bind address가 어긋날 수 있다.
- discovery candidate TTL과 active data route lifecycle이 엮이면 전송 중 경로 만료 메시지가 발생할 수 있다.
- 파일 payload 전송에 필요한 신뢰성 로직이 많아져 controller, runner, transport 간 상태 동기화 리스크가 커진다.
- 전송 중 route failover 또는 candidate refresh가 payload 경로 안정성을 깨뜨릴 수 있다.

이번 계획은 UDP data channel의 신뢰성 알고리즘을 개선하는 것이 아니라, 기본 파일 payload 채널을 TCP로 바꾸어 데이터 전송 안정성을 네트워크 계층에 위임한다.

### 2.1 현재 계획의 강점

- Discovery, Control, Data channel의 책임 분리 방향이 명확하다.
- active route lease가 discovery candidate와 별개로 안정되어야 한다는 목표가 유지되어 있다.
- 송신 runner와 수신 runner를 분리해야 한다는 기존 구조 개선 방향과 TCP 전환 목표가 충돌하지 않는다.
- TCP 전환 후에도 peer identity와 route candidate를 분리하는 원칙을 유지한다.
- 테스트 기준이 domain, application, infrastructure, presentation 계층별로 배치될 수 있다.

### 2.2 현재 남은 부족한 부분

- AGENTS.md와 README 계열 문서는 TCP Data 기본 경로로 정렬되었으므로, 이후 변경은 이 기준을 유지해야 한다.
- TCP data session과 기존 active route lease의 관계는 "route lease는 connect input, TCP session은 data connection source of truth"로 고정한다.
- 이번 phase의 MVP는 direction별 TCP channel이다. full-duplex single channel 통합은 별도 phase 계획과 테스트 없이는 진행하지 않는다.
- TCP stream frame parser, partial/coalesced read, digest 검증은 release gate와 테스트로 계속 유지해야 한다.
- TCP transfer UI는 UDP Window, Retry, Loss, RTT와 legacy Route 줄을 숨기도록 정리되었으므로 회귀 테스트를 유지한다.
- socket close와 transfer failure는 분리한다. socket close/error만 peer TCP session close reason으로 기록하고, 개별 transfer failure는 peer session 전체 종료로 자동 승격하지 않는다.

### 2.3 아키텍처상 위험한 부분

- TCP socket 구현이 application 또는 presentation 계층으로 새어 나오면 테스트 더블 주입이 어려워진다.
- TCP 연결 상태와 UDP discovery presence를 하나의 enum으로 합치면 "discovery offline이지만 TCP connected"인 정상 상태를 표현할 수 없다.
- Control packet에 파일 payload를 임시로 싣는 우회 구현은 이후 제거하기 어렵다.
- TCP stream parser가 frame size 제한 없이 buffer를 누적하면 메모리 고갈 위험이 생긴다.
- peer당 persistent TCP session과 transfer별 runner lifecycle을 분리하지 않으면 하나의 transfer 실패가 다른 transfer를 오염시킨다.

### 2.4 테스트가 어려워질 수 있는 부분

- Dart IO `Socket`을 직접 runner에 주입하면 partial read, close, backpressure, write failure를 단위 테스트로 재현하기 어렵다.
- TCP negotiation과 auth session 검증이 같은 메서드에 섞이면 인증 실패와 socket 실패를 분리해 검증하기 어렵다.
- UI가 TCP session state를 직접 조합하면 discovery stale과 TCP connected가 동시에 존재하는 상태를 테스트하기 어렵다.
- frame codec이 infrastructure에만 있고 domain/application test seam이 없으면 transfer runner test가 실제 socket에 가까운 통합 테스트로 비대해진다.

### 2.5 구현 순서 판단

현실적인 작업 순서는 다음과 같다.

1. 문서와 guardrail을 TCP Data channel 기준으로 정렬한다.
2. 동작 변경 없이 UDP Data channel과 future TCP Data channel 경계를 분리한다.
3. TCP state machine과 frame codec을 테스트로 먼저 고정한다.
4. TCP listener/connect negotiation을 fake transport로 application test에서 검증한다.
5. loopback TCP transport를 infrastructure test로 검증한다.
6. 파일 송수신 runner를 TCP stream으로 연결한다.
7. UI와 diagnostics를 TCP 상태 기준으로 전환한다.
8. UDP Data 기본 경로를 제거하거나 legacy fallback으로 격리한다.

## 3. AGENTS.md Alignment and Required Guardrail Update

AGENTS.md는 이 계획과 맞도록 "UDP Discovery/Control, TCP Data payload" 방향으로 정렬되어 있다. 이 계획은 사용자의 명시 요구에 따라 파일 데이터 통신만 TCP로 전환하고, Discovery와 Control은 UDP 기반 구조를 유지한다.

AGENTS.md를 우선 기준으로 삼기 위해 다음 기준을 계속 유지한다.

- Discovery는 계속 UDP다.
- Control은 현재 구현을 유지하되 TCP data channel 협상 메시지를 추가한다.
- Data는 더 이상 UDP chunk 기본 경로가 아니라 TCP stream 기본 경로다.
- UDP data frame 구현은 migration 동안 feature flag 또는 legacy adapter로 유지할 수 있으나, 기본 제품 경로에서 제거한다.
- AGENTS.md의 Product-Specific Guardrails 중 "Data channel의 대량 파일 chunk는 raw binary payload" 원칙은 TCP stream framing에도 적용한다.
- "UDP 전송 성능을 해치는 per-packet 로그 금지" 원칙은 "TCP stream segment 또는 frame별 product/info 로그 금지"로 확장한다.
- "패킷 손실, 중복, 재전송, 타임아웃, 순서 어긋남" 항목은 TCP Data 기본 경로에서는 OS TCP stack이 담당하는 계층과 application frame parser가 담당하는 계층을 나누어 검증한다.
- "route lease에는 data endpoint가 포함되어야 한다"라는 기존 관점은 TCP 전환 후 "verified TCP data session endpoint가 diagnostics에 안전하게 표시되어야 한다"로 대체한다.

이번 plan은 AGENTS.md의 Layered Architecture, Clean Architecture, Tidy First, TDD, 설정 최소화, 3단계 로그 정책, 상태 머신, MessageBus 원칙을 그대로 따른다.

문서 정리 Done Criteria:

- AGENTS.md가 UDP Discovery, UDP Control, TCP Data의 목표 구조를 설명한다.
- README와 README.ko.md가 TCP Data channel 전환 또는 현재 개발 방향을 혼동 없이 설명한다.
- 기존 UDP Data channel guardrail은 legacy/fallback 범위로 내려간다.
- 문서 변경은 런타임 동작을 바꾸지 않으므로 테스트 생략 가능하나, 문서 테스트가 있다면 관련 문서 테스트를 갱신한다.

## 4. Target Architecture

### 4.1 Channel Responsibility

Discovery Channel:

- UDP broadcast/multicast/unicast candidate discovery만 수행한다.
- peer identity, instance uid, discovery group tag, control port, optional tcp data listener hint만 교환한다.
- 인증 토큰, session key, 파일명, 파일 크기, 파일 payload를 싣지 않는다.
- 발견된 candidate는 active TCP data session을 직접 바꾸지 않는다.

Control Channel:

- 인증 handshake를 담당한다.
- TCP data channel negotiation을 담당한다.
- TCP listener endpoint offer, connect request, connect accept, connect reject, reconnect request를 담당한다.
- transfer metadata negotiation을 담당한다.
- transfer cancel, transfer complete, transfer failed 같은 제어 상태를 전달한다.
- 대량 파일 payload를 싣지 않는다.

TCP Data Channel:

- 인증된 peer session에만 연결된다.
- 파일 payload와 최소 frame header만 전달한다.
- Phase 1부터 Phase 6까지는 direction별 persistent TCP channel을 기본 경로로 구현한다.
- outbound TCP channel은 송신 transfer frame만 처리하고, inbound TCP channel은 수신 transfer frame만 처리한다.
- 하나의 full-duplex TCP connection에서 송신과 수신을 모두 multiplex하는 방식은 이번 phase 범위에서 구현하지 않는다.
- TCP 연결이 active인 동안 discovery/control route candidate 변경은 연결 상태에 영향을 주지 않는다.

### 4.1.1 Single Source of Truth

TCP 전환 후 상태 판단 기준은 다음과 같이 고정한다.

- Peer identity source of truth: `userId + instanceUid`
- Candidate source of truth: discovery/control에서 관찰된 route candidate store
- Authentication source of truth: peer auth session state
- Data connection source of truth: TCP data peer session state
- Transfer source of truth: transfer stream state machine과 transfer job projection

금지 사항:

- discovery presence가 TCP data peer session을 직접 closed로 바꾸면 안 된다.
- route candidate TTL이 TCP data peer session을 직접 reconnecting으로 바꾸면 안 된다.
- UI projection이 여러 source를 임의 조합해 connected/disconnected를 계산하면 안 된다.
- transfer job 실패가 peer TCP session 실패로 자동 승격되면 안 된다.

### 4.2 TCP Session Direction Rule

사용자가 요구한 방향 규칙은 다음과 같이 해석한다.

- 내가 상대 peer의 TCP listener에 연결한 socket은 내 outbound data channel이다.
- 상대 peer가 내 TCP listener에 연결한 socket은 내 inbound data channel이다.
- 양쪽 모두 동시에 connect할 수 있으므로 duplicate connection arbitration이 필요하다.
- peer당 하나의 canonical TCP data session을 만들기 위해 `instanceUid`와 deterministic tie-breaker를 사용한다.
- 단순 MVP에서는 양방향 각각 하나의 TCP socket을 허용할 수 있다. 이 경우 outbound socket은 송신 전용, inbound socket은 수신 전용이다.
- 안정화 목표를 위해 이번 phase에서는 "directional TCP channels"를 기준으로 구현한다. full-duplex single session 통합은 현재 phase의 금지 범위이며, 별도 계획과 테스트가 작성되기 전에는 수행하지 않는다.

Directional TCP channel 기준:

- `OutboundTcpDataChannel`: local app이 remote peer listener로 connect한 channel. local transfer sender가 사용한다.
- `InboundTcpDataChannel`: remote peer가 local listener로 connect한 channel. local transfer receiver가 사용한다.
- 한 peer와 두 channel이 모두 active이면 peer connection status는 `dataConnected`다.
- 하나만 active이면 status는 `partiallyConnected`이며 송신 또는 수신 가능 여부를 direction별로 표시한다.

MVP 결정:

- Phase 1부터 Phase 5까지는 direction별 TCP channel을 기준으로 구현한다.
- outbound channel은 송신 전용으로 사용한다.
- inbound channel은 수신 전용으로 사용한다.
- single full-duplex TCP channel 통합은 별도 phase 없이는 수행하지 않는다.
- 양쪽이 동시에 connect하여 outbound/inbound가 각각 생기는 것은 정상 상태로 본다.
- 같은 direction에서 중복 channel이 생기면 deterministic tie-breaker로 하나만 유지한다. tie-breaker는 `localInstanceUid < remoteInstanceUid`, connect started time, channel id 순으로 비교한다.

### 4.3 Peer Connection State Source

TCP data channel 연결 이후 peer 상태의 source of truth는 다음 순서로 결정한다.

1. Auth session state
2. TCP data session state
3. Control channel liveness
4. Discovery presence

TCP data session이 active이면 discovery stale/offline은 UI에 "discovery stale" 진단으로만 표시하고 peer connection을 끊지 않는다.

TCP data session이 closed/error이면 discovery candidate와 control handshake를 이용해 reconnect를 시도할 수 있다.

### 4.4 State Machines

`TcpDataPeerSessionState`:

- `idle`: 인증 전 또는 data session 없음
- `listening`: local TCP listener 준비됨
- `negotiating`: control channel로 TCP endpoint 협상 중
- `connectingOutbound`: remote TCP listener로 connect 중
- `awaitingInbound`: remote peer의 inbound connect 대기 중
- `partiallyConnected`: 송신 또는 수신 한 방향만 연결됨
- `connected`: 송신/수신에 필요한 TCP channel 준비됨
- `draining`: active transfer 종료 후 close 준비 중
- `reconnecting`: socket close/error 이후 재협상 중
- `closed`: 명시 종료됨
- `failed`: 복구 불가 실패

허용 이벤트:

- `AuthSessionEstablished`
- `TcpListenerBound`
- `TcpListenerBindFailed`
- `TcpEndpointOffered`
- `TcpEndpointAccepted`
- `OutboundConnectStarted`
- `OutboundConnectSucceeded`
- `OutboundConnectFailed`
- `InboundConnectAccepted`
- `TcpChannelAuthenticated`
- `TcpChannelClosed`
- `TcpChannelError`
- `ReconnectRequested`
- `PeerSessionClosed`

금지 전이:

- `connected -> idle` 직접 전이 금지
- discovery candidate 만료만으로 `connected -> reconnecting` 전이 금지
- route candidate 추가만으로 `connected -> negotiating` 전이 금지
- UI refresh로 state 변경 금지
- transfer 실패만으로 peer TCP session close 금지. 단 socket failure가 원인일 때만 close 가능

`TcpTransferStreamState`:

- `created`
- `metadataSent`
- `metadataAccepted`
- `streaming`
- `flushing`
- `verifying`
- `completed`
- `canceled`
- `failed`

TCP에서는 chunk ACK/NACK 상태가 기본 경로에서 사라진다. 대신 stream frame parse, file write, digest verify, backpressure, socket close를 상태 전이로 관리한다.

### 4.5 Use Case Inputs and Outputs

각 유스케이스는 명시적 입력과 출력을 가져야 한다.

`NegotiateTcpDataChannelUseCase`:

- Input: local peer context, authenticated peer session id, selected route candidate summary, bootstrap TCP config
- Output: negotiation command, expected direction, timeout policy, correlation id

`AcceptTcpDataChannelUseCase`:

- Input: inbound socket metadata, data session hello frame, current auth session lookup result
- Output: accept/reject decision, peer session state transition, safe debug reason code

`StartTcpFileTransferUseCase`:

- Input: peer id, transfer id, source file descriptor, authenticated TCP outbound channel id, receive policy snapshot
- Output: transfer stream runner command, transfer job created event, failure if no outbound TCP channel

`ReceiveTcpFileTransferUseCase`:

- Input: inbound TCP frame stream, transfer metadata frame, save policy snapshot
- Output: temp file prepare command, incoming transfer state, failure if storage unavailable

각 유스케이스는 외부 환경 값을 직접 조회하지 않는다. 필요한 값은 bootstrap config, session context, command input, 생성자 인자로 전달한다.

### 4.6 Interface Boundaries

Application layer interface:

- `TcpDataListenerPort`: local listener lifecycle abstraction
- `TcpDataConnectorPort`: outbound connection abstraction
- `TcpDataChannelPort`: read/write/close abstraction for an established channel
- `TcpDataFrameCodecPort`: frame encode/decode abstraction if codec detail is injected
- `TransferFileReaderPort`
- `TransferFileWriterPort`
- `TransferDigestPort`
- `ClockPort`
- `TimerSchedulerPort`

Infrastructure implementation:

- Dart IO `ServerSocket` based listener
- Dart IO `Socket` based connector/channel
- File system reader/writer
- Digest implementation
- Platform network endpoint resolver if needed

Review rule:

- application tests must be able to replace every interface above with a fake or test double.

## 5. Data Protocol Direction

TCP stream은 packet boundary가 없으므로 application frame을 명시해야 한다.

기본 frame 구조:

- magic: protocol marker
- version
- frameType
- headerLength
- payloadLength
- transferId
- peerSessionId
- flags
- headerJson 또는 compact binary metadata
- payload bytes

Frame type:

- `DATA_SESSION_HELLO`
- `DATA_SESSION_ACCEPT`
- `TRANSFER_START`
- `TRANSFER_DATA`
- `TRANSFER_END`
- `TRANSFER_CANCEL`
- `TRANSFER_ERROR`
- `PING`
- `PONG`

설계 기준:

- 파일 payload는 raw bytes로 전송한다.
- 파일 payload를 JSON/base64로 감싸지 않는다.
- frame parser는 partial read, coalesced read, split header, split payload를 모두 처리해야 한다.
- frame parser는 최대 header size와 최대 payload frame size를 검사한다.
- transferId는 stream 내에서 독립 session을 식별한다.
- peerSessionId는 인증된 TCP data peer session을 식별한다.
- 파일명, 파일 크기, digest, relative display path 등 metadata는 `TRANSFER_START`에만 담는다.
- 실제 저장 경로 전체는 network frame에 싣지 않는다.

## 6. Implementation Phases

### Phase 0. 문서 Guardrail 정렬과 Baseline 고정

Goal:

- 구현 전 AGENTS.md, README, 현재 plan의 TCP Data channel 방향을 충돌 없이 정렬한다.

Scope:

- 문서와 테스트 baseline만 다룬다.
- 런타임 동작을 변경하지 않는다.
- 기존 `.tasks/phase008` 내용은 보존하고 루트 `.tasks/plan.md`를 현재 우선 계획으로 둔다.

Required Changes:

- AGENTS.md가 "Discovery와 Control은 UDP, Data payload는 현재 phase에서 TCP로 전환" 방향을 유지하는지 확인하고, 충돌 문구가 있으면 갱신한다.
- Product-Specific Guardrails에 TCP Data channel 기본 경로와 UDP Data legacy/fallback 범위를 추가한다.
- README와 README.ko.md에 TCP Data channel 전환 방향을 간단히 반영한다.
- 변경 전 `git status --short`로 기존 task 이동/삭제 상태를 확인하고, 문서 변경과 무관한 파일을 되돌리지 않는다.

Architecture Notes:

- 문서 변경은 아키텍처 기준을 명확히 하기 위한 Tidy First 작업이다.
- AGENTS.md와 plan.md가 충돌하면 AGENTS.md 기준이 우선이므로, 이 phase가 끝나기 전에는 TCP 구현을 시작하지 않는다.

TDD Requirements:

- 런타임 동작이 바뀌지 않으므로 필수 테스트는 없다.
- 문서 테스트가 존재하면 TCP Data channel 방향 문구를 반영해 갱신한다.

Configuration Rules:

- 새 외부 설정 파일을 추가하지 않는다.
- 문서에서 runtime 중간 설정 변경 방식을 제안하지 않는다.

Logging Rules:

- 로그 변경 없음.

State Management:

- 상태 머신 구현 없음.

Validation:

- `rg -n "UDP 기반|파일 데이터 통신은 UDP|TCP Data|Data channel" AGENTS.md README.md README.ko.md .tasks/plan.md`로 충돌 문구가 AGENTS.md와 README에 남아 있지 않은지 확인한다.
- 문서 테스트가 존재하면 해당 테스트 실행.

Done Criteria:

- AGENTS.md와 plan.md 사이에 TCP Data channel 방향 충돌이 없다.
- README가 사용자에게 Discovery/Control/Data 역할을 오해시키지 않는다.
- 구현자가 Phase 1을 시작할 수 있는 기준 문서가 준비된다.

Risks:

- 문서만 바꾸고 구현을 시작하지 않으면 사용자 기대가 앞서갈 수 있다. README에는 "현재 개발 방향"과 "현재 릴리즈 동작"을 구분한다.

### Phase 1. TCP Data Channel Boundary 설계와 기존 UDP Data 경로 격리

Goal:

- TCP data channel 전환을 위한 interface와 state model을 먼저 추가하고, 기존 UDP data channel 구현과 분리한다.

Scope:

- Phase 1 당시에는 런타임 동작을 가능한 한 유지한다.
- Phase 1 당시에는 새 TCP 구현을 기본 경로로 연결하지 않고 boundary만 만든다.
- application/domain boundary를 먼저 만든다.

Required Changes:

- `domain/network` 또는 `domain/transfer`에 `TcpDataPeerSessionState`, `TcpDataChannelDirection`, `TcpDataChannelId`, `TcpDataSessionId` 값 객체를 추가한다.
- `application/transfer`에 `DataChannelSessionRegistry` interface를 정의한다.
- 기존 UDP data endpoint registry와 이름 충돌이 없도록 `UdpDataEndpointManager`와 `TcpDataChannelManager` 개념을 분리한다.
- transfer controller가 data channel 종류를 직접 알지 않도록 use case boundary를 만든다.
- 기존 UDP Data channel을 호출하는 entry point를 식별하고 `UdpDataChannelAdapter` 이름으로 격리한다.
- Phase 1 당시 TCP 기본 경로 활성화 여부를 명시하는 `DataChannelMode` 값을 application boundary에 추가한다. 이 값은 bootstrap 시점 주입 또는 테스트 주입으로만 설정한다.

Architecture Notes:

- domain은 Dart IO socket에 의존하지 않는다.
- TCP socket 구현은 infrastructure에만 둔다.
- application은 interface와 state transition만 다룬다.
- Riverpod provider는 app/application wiring 경계에만 둔다. domain 값 객체가 provider를 참조하지 않는다.

TDD Requirements:

- TCP data peer session state machine 전이 테스트를 먼저 작성한다.
- discovery 만료 이벤트가 `connected` TCP session을 변경하지 않는 테스트를 작성한다.
- route candidate 추가가 active TCP session을 변경하지 않는 테스트를 작성한다.
- application test에서 fake `TcpDataChannelRegistry`를 주입해 transfer controller가 TCP 구현체를 직접 알지 않는지 검증한다.

Configuration Rules:

- 새 외부 설정 파일을 만들지 않는다.
- TCP port 기본값은 `AppConfig` 또는 bootstrap-time config로만 받는다.
- 테스트는 port 값을 생성자 인자 또는 provider override로 주입한다.
- `DataChannelMode`를 runtime 중간에 바꾸는 command, UI, 환경 변수 reload를 추가하지 않는다.

Logging Rules:

- Product: TCP data session bind/connect 실패만 기록한다.
- Debug: peer id, session id 축약값, local/remote endpoint, state transition을 기록한다.
- Development: frame parser 상세 로그는 테스트 또는 개발 빌드에서만 허용한다.

State Management:

- TCP peer session state machine을 추가한다.
- boolean 조합으로 `isTcpConnected`, `isListening`, `isConnecting`을 흩어놓지 않는다.

Validation:

- `flutter test test/domain test/application`
- `flutter analyze`

Done Criteria:

- TCP state model과 registry interface가 존재한다.
- 기존 UDP data tests가 깨지지 않는다.
- 새 TCP state tests가 실패 후 구현으로 통과한다.
- `domain`에 Dart IO, Flutter, Riverpod import가 없다.
- transfer controller가 concrete UDP/TCP transport class를 직접 참조하지 않는다.

Risks:

- 기존 UDP 용어와 TCP 용어가 섞이면 리뷰가 어려워진다. 이름에 `Udp`와 `Tcp` prefix를 명확히 붙인다.

### Phase 2. TCP Listener와 Endpoint Negotiation 추가

Goal:

- 인증된 peer가 TCP data channel endpoint를 control channel로 협상할 수 있게 한다.

Scope:

- TCP listener bind와 endpoint offer/accept만 구현한다.
- 파일 payload 전송은 아직 하지 않는다.

Required Changes:

- infrastructure에 `TcpDataListener`를 추가한다.
- infrastructure에 `TcpDataConnector`를 추가한다.
- control packet에 `DATA_CHANNEL_OFFER`, `DATA_CHANNEL_CONNECT`, `DATA_CHANNEL_ACCEPT`, `DATA_CHANNEL_REJECT` 유형을 추가한다.
- authenticated peer만 TCP endpoint negotiation을 시작하도록 application use case를 추가한다.
- TCP listener는 모든 connectable Ethernet interface에서 bind 전략을 검토한다.
- MVP에서는 wildcard bind `0.0.0.0` listener와 observed route address connect를 우선 사용한다.
- local listener가 ephemeral port로 bind되면 실제 bound port를 control packet에 넣는다.
- offered endpoint와 observed control route가 다를 경우, connect candidate 목록을 만들되 TCP connected 상태의 기존 peer를 흔들지 않는다.
- inbound connection은 `DATA_SESSION_HELLO` 검증 전에는 authenticated data channel로 승격하지 않는다.

Architecture Notes:

- TCP bind/connect는 infrastructure에만 둔다.
- control packet parsing은 infrastructure/control에 둔다.
- negotiation decision은 application command에 둔다.
- `ServerSocket`과 `Socket`은 infrastructure implementation 밖으로 노출하지 않는다.

TDD Requirements:

- 인증되지 않은 peer의 TCP offer가 거부되는 테스트.
- 인증된 peer가 TCP endpoint offer를 받으면 connect command가 생성되는 테스트.
- TCP listener bind 실패가 peer session을 `failed` 또는 `reconnecting`으로 전이시키는 테스트.
- discovery candidate 만료가 TCP negotiation 중인 peer를 끊지 않는 테스트.
- duplicate outbound connection이 deterministic tie-breaker로 정리되는 테스트.
- inbound connection이 hello 검증 전에는 transfer target으로 노출되지 않는 테스트.

Configuration Rules:

- TCP listener port는 bootstrap 시점 config 또는 `0` ephemeral bind를 사용한다.
- 런타임 중 환경 변수 재조회로 port를 바꾸지 않는다.
- 외부 설정 파일에 listener port를 쓰지 않는다.

Logging Rules:

- Product: listener bind 실패, connect 실패, negotiation reject만 기록한다.
- Debug: negotiated endpoint와 route candidate correlation을 축약해 기록한다.
- Development: control packet payload 상세는 민감정보 없이 개발 로그로만 허용한다.

State Management:

- `negotiating`, `connectingOutbound`, `awaitingInbound`, `partiallyConnected`, `connected` 전이를 테스트로 고정한다.

Validation:

- fake TCP connector/listener로 application test를 작성한다.
- loopback integration test로 listener와 connector가 연결되는지 검증한다.

Done Criteria:

- 인증된 peer 사이에서 TCP socket 연결이 성립한다.
- TCP socket 연결 여부가 peer connection projection에 반영된다.
- discovery route refresh로 TCP session이 재협상되지 않는다.
- fake listener/connector application test와 loopback infrastructure test가 모두 통과한다.

Risks:

- 양쪽 peer가 동시에 connect하면 duplicate channel이 생길 수 있다. Phase 2에서는 direction별 channel 허용 또는 deterministic arbitration 중 하나를 문서화하고 테스트한다.

### Phase 3. TCP Data Session Handshake와 Peer Connection Source 전환

Goal:

- TCP channel이 연결된 뒤 peer 연결 상태를 TCP session 기준으로 판단하도록 전환한다.

Scope:

- 파일 전송 전 data session hello/accept까지만 구현한다.
- peer UI와 transfer 가능 여부가 TCP session state를 기준으로 동작하게 한다.

Required Changes:

- TCP stream 첫 frame으로 `DATA_SESSION_HELLO`를 보낸다.
- hello에는 peer id, instance uid, auth session id, protocol version, data protocol version을 포함한다.
- session key 또는 인증 증명은 control auth session에서 파생한 일회성 data session proof로 검증한다.
- `PeerConnectionProjection` 또는 유사 projection에서 `connected` 기준을 active route lease가 아니라 authenticated TCP data session으로 변경한다.
- active TCP session이 있으면 route candidate TTL 만료는 diagnostics에만 표시한다.
- peer list UI에 표시되는 연결 상태는 TCP session state projection 하나를 통해 계산한다.
- 기존 active route lease는 TCP connect를 시작하기 위한 route selection input으로 격하한다. TCP connected 후에는 data connection source of truth가 아니다.

Architecture Notes:

- proof 생성/검증은 infrastructure crypto adapter 또는 application auth command 경계에서 처리한다.
- UI는 TCP socket 구현체를 직접 참조하지 않는다.
- data session proof는 password, raw token, reusable verifier를 포함하지 않는다.

TDD Requirements:

- valid hello/accept가 `connected` 상태로 전이되는 테스트.
- wrong peer id, wrong auth session id, wrong protocol version이 reject되는 테스트.
- TCP connected 상태에서 discovery offline이 들어와도 peer projection이 disconnected로 내려가지 않는 테스트.
- TCP close event가 들어와야만 peer projection이 disconnected/reconnecting으로 내려가는 테스트.
- active TCP session이 있을 때 `PeerPresence.offline`이 들어와도 send 가능 상태가 유지되는 테스트.
- auth session 종료가 들어오면 TCP data session이 draining 또는 closed로 전이되는 테스트.

Configuration Rules:

- data protocol version은 코드 상수로 두되 bootstrap 이후 변경하지 않는다.
- 외부 입력으로 protocol version을 런타임 중 바꾸지 않는다.

Logging Rules:

- Product: data session authentication failure, protocol mismatch.
- Debug: session established/closed, close reason, reconnect scheduled.
- Development: frame handshake parse detail.

State Management:

- `connected` 상태에서는 route candidate event를 no-op으로 처리한다.
- `TcpChannelClosed` 또는 `TcpChannelError`만 reconnect 계열 전이를 만들 수 있다.

Validation:

- `flutter test test/application/network test/application/auth`
- TCP loopback smoke test.

Done Criteria:

- 피어 연결 상태가 TCP session 기준으로 표시된다.
- active TCP session 동안 route 만료 문구가 전송 실패 사유로 나오지 않는다.
- diagnostics에는 discovery state와 TCP data session state가 분리되어 표시된다.

Risks:

- 기존 UI가 active route lease status를 직접 읽는 경우가 남아 있으면 상태 문구가 충돌할 수 있다. projection을 한 곳으로 모은다.

### Phase 4. TCP File Stream 송신/수신 구현

Goal:

- 파일 payload를 TCP data channel을 통해 송신하고 수신 저장 경로에 자동 저장한다.

Scope:

- 기본 파일 1개 전송을 우선 구현한다.
- 다중 파일은 transfer queue가 같은 TCP session 위에서 순차 처리한다.
- UDP data frame 송수신은 기본 경로에서 사용하지 않는다.

Required Changes:

- `TcpOutgoingTransferStreamRunner`를 추가한다.
- `TcpIncomingTransferStreamRunner`를 추가한다.
- `TRANSFER_START`, `TRANSFER_DATA`, `TRANSFER_END` frame codec을 구현한다.
- frame parser는 partial read와 coalesced read를 처리한다.
- file reader는 stream backpressure를 존중한다.
- file writer는 temp file에 쓰고 digest 검증 후 final path로 rename한다.
- transfer progress는 bytes sent/read 기준으로 집계한다.
- 기존 UDP ACK/NACK, window, retransmission UI 문구는 TCP 전송에서는 숨기거나 TCP 기준 문구로 바꾼다.
- sender는 TCP write buffer backpressure를 기다리는 동안 transfer를 failed로 처리하지 않는다.
- receiver는 `TRANSFER_START` 검증 전에는 파일을 생성하지 않는다.
- receiver는 temp file write, flush, digest verify, atomic rename 순서로 완료한다.
- `TRANSFER_END` 수신 전 socket이 닫히면 receiver transfer를 network failure로 표시하고 temp file을 cleanup한다.

Architecture Notes:

- file I/O는 infrastructure file service에 둔다.
- transfer runner는 file reader/writer interface를 주입받는다.
- TCP stream read/write 구현은 infrastructure에 둔다.
- application runner는 frame write/read command를 호출하고 TCP transfer state machine 전이를 수행한다.
- frame codec은 socket과 독립적으로 테스트 가능해야 한다.
- file writer는 frame parser를 알지 않는다.

TDD Requirements:

- partial TCP reads가 하나의 frame으로 조립되는 codec test.
- 여러 frame이 한 번에 들어와도 순서대로 dispatch되는 codec test.
- sender가 `TRANSFER_START -> DATA* -> END` 순서로 frame을 쓰는 test.
- receiver가 temp file에 쓰고 digest 검증 후 final file로 이동하는 test.
- storage failure가 receiver failure로만 분류되는 test.
- TCP socket close mid-transfer가 network failure로 분류되는 test.
- `TRANSFER_START` 없이 `TRANSFER_DATA`가 오면 reject되는 test.
- digest mismatch가 sender와 receiver에 검증 실패로 반영되는 test.
- Korean filename과 긴 filename이 metadata frame에서 안전하게 round-trip되는 test.

Configuration Rules:

- frame max payload size는 bootstrap config 또는 domain tuning policy로 명시 주입한다.
- 런타임 중 config 파일 reload로 frame size를 바꾸지 않는다.

Logging Rules:

- Product: transfer started/completed/failed/canceled.
- Debug: transfer id 축약값, byte count, duration, throughput, close reason.
- Development: frame boundary, parser state, backpressure wait는 개발 로그로만.
- frame별 product/info 로그 금지.

State Management:

- TCP transfer stream state machine을 사용한다.
- socket event가 직접 UI state를 변경하지 않고 runner state transition을 거친다.

Validation:

- small file, medium file, Korean filename, duplicate filename 저장 테스트.
- loopback TCP integration test.
- 기존 UDP transfer tests는 legacy path로 유지하거나 TCP 기준으로 migration한다.
- transfer 완료 후 원본과 수신 파일 digest 비교.

Done Criteria:

- 인증된 peer에게 TCP로 파일 1개를 송신하고 상대 기본 저장 경로에 저장한다.
- 전송 중 discovery candidate 만료가 transfer 실패를 만들지 않는다.
- 수신 파일 digest가 송신 원본과 일치한다.
- TCP 전송 UI에 UDP Window, Retry, Loss 수치가 표시되지 않는다.

Risks:

- TCP stream framing bug는 파일 corruption으로 이어질 수 있다. digest verification을 release gate로 둔다.

### Phase 5. Transfer Queue와 동시 송수신 정책 전환

Goal:

- TCP data channel 위에서 여러 전송 job과 양방향 전송을 안정적으로 처리한다.

Scope:

- 같은 peer에게 여러 파일을 드롭하면 순차 전송한다.
- 양쪽 peer가 동시에 파일을 보내는 경우 direction별 channel 또는 multiplex 정책에 따라 독립 처리한다.

Required Changes:

- peer당 outbound queue를 둔다.
- inbound stream registry를 별도로 둔다.
- 같은 TCP session에서 transferId별 frame dispatch를 분리한다.
- UI drag/drop은 전송 버튼 없이 즉시 enqueue한다.
- 동일 파일 중복 드롭은 UI 또는 application command에서 debounce한다.
- transfer job key는 `direction + transferId + peerId + tcpSessionId`로 구성한다.
- outbound queue와 inbound registry는 같은 mutable map을 공유하지 않는다.

Architecture Notes:

- queue state machine은 domain/application에 둔다.
- TCP transport는 frame stream만 제공하고 queue 정책을 알지 않는다.
- MessageBus는 queue event를 publish할 수 있지만 enqueue command를 대신 실행하지 않는다.

TDD Requirements:

- 같은 peer에 3개 파일 enqueue 시 순차 완료되는 테스트.
- A->B와 B->A 동시 전송이 서로 상태를 오염시키지 않는 테스트.
- 한 transfer 실패가 같은 peer TCP session 전체를 끊지 않는 테스트.
- socket failure는 active transfer들을 network failure로 전이시키는 테스트.
- 같은 transferId가 반대 direction에서 들어와도 session이 섞이지 않는 테스트.
- 같은 파일이 빠르게 여러 번 드롭될 때 debounce 또는 duplicate policy가 동작하는 테스트.

Configuration Rules:

- peer당 동시 transfer 수는 코드 기본값 또는 bootstrap config로만 설정한다.
- 사용자 설정으로 runtime 중간에 concurrency를 바꾸지 않는다.

Logging Rules:

- Product: batch started/completed/partial failed.
- Debug: queue length, active transfer count, session id.
- Development: frame dispatch detail only in dev logs.

State Management:

- transfer queue state와 TCP peer session state를 분리한다.
- transfer queue failure가 peer session failure를 의미하지 않는다.

Validation:

- bidirectional TCP integration test.
- multi-file queue test.
- UI widget test for drag/drop immediate enqueue.

Done Criteria:

- 같은 peer와 동시에 송신/수신이 가능하다.
- transfer state가 direction별로 분리되어 표시된다.
- peer TCP session이 유지되는 동안 route 만료 오류가 나타나지 않는다.
- 한 transfer 실패 후 같은 peer에게 다음 파일을 다시 보낼 수 있다.

Risks:

- multiplex를 너무 빨리 도입하면 parser와 queue 복잡도가 증가한다. 첫 구현은 순차 outbound queue와 direction별 inbound 처리로 제한한다.

### Phase 6. UDP Data Legacy 제거와 Diagnostics 정리

Goal:

- 기본 제품 경로에서 UDP data frame 전송 의존성을 제거하고 TCP 기준 diagnostics로 정리한다.

Scope:

- UDP discovery/control은 유지한다.
- UDP data transport는 기본 provider wiring에서 제거하고, 기존 테스트 보존이 필요한 경우에만 legacy adapter로 격리한다.
- UI, 로그, diagnostics 문구를 TCP 기준으로 변경한다.

Required Changes:

- transfer failure reason에서 UDP route lease 만료 중심 문구를 제거한다. TCP job의 route 계열 내부 오류는 TCP data channel failure로 분류한다.
- peer diagnostics와 diagnostics export에 TCP listener, outbound channel, inbound channel, session state, direction, safe endpoint summary, last close reason을 표시한다.
- UDP ACK/NACK/window/loss/RTT UI 항목과 legacy route snapshot 줄은 TCP transfer에서는 숨긴다.
- TCP throughput, elapsed time, bytes sent/received, socket close reason을 표시한다.
- release gate, README, README.ko.md에 TCP data channel 구조를 문서화한다.
- `TransferFailureMapper`에서 UDP route lease 만료 문구가 TCP transfer path에 노출되지 않도록 분리한다.
- diagnostics export에는 TCP session state, direction, last close reason, safe endpoint summary만 포함한다.

Architecture Notes:

- diagnostics export는 민감정보를 redaction한다.
- full path, token, password, session key는 export하지 않는다.
- UI는 TCP session projection을 사용하고 infrastructure diagnostics object를 직접 읽지 않는다.

TDD Requirements:

- TCP transfer UI가 UDP window/loss 정보를 표시하지 않는 widget test.
- TCP transfer UI가 legacy route snapshot과 UDP route lease 원문을 표시하지 않는 widget test.
- diagnostics export가 TCP session state를 포함하고 민감정보를 제외하는 test.
- diagnostics export가 TCP session last close reason을 포함하는 test.
- legacy UDP data code가 기본 transfer path에서 호출되지 않는 application test.

Configuration Rules:

- legacy fallback을 둘 경우 `AppConfig.allowLegacyUdpDataFallback`로만 선택한다.
- `AppConfig.allowLegacyUdpDataFallback`의 production 기본값은 `false`이며, legacy UDP controller test나 호환성 검증처럼 명시된 bootstrap/test override에서만 `true`로 둘 수 있다.
- runtime 중간에 TCP/UDP data mode를 변경하지 않는다.

Logging Rules:

- Product: TCP data mode startup, listener failure, transfer failure.
- Debug: TCP diagnostics summary.
- Development: legacy fallback activation detail.

State Management:

- legacy UDP data 상태와 TCP data 상태를 하나의 enum에 섞지 않는다.
- migration 동안 adapter boundary로 분리한다.

Validation:

- `flutter analyze`
- `flutter test`
- `flutter test test/docs/release_gate_test.dart --reporter compact`
- macOS host to Parallels Windows VM manual smoke
- Windows VM to macOS host manual smoke
- same-machine two-instance loopback smoke if supported

Done Criteria:

- 기본 파일 전송은 TCP data channel만 사용한다.
- route candidate 만료와 discovery stale이 TCP 전송을 중단하지 않는다.
- diagnostics가 TCP 기준으로 원인을 설명한다.
- README, README.ko.md, AGENTS.md가 TCP Data channel 기본 경로와 일치한다.
- release gate가 active route lease가 아니라 TCP data session stability를 기준으로 한다.

Risks:

- AGENTS.md와 README가 UDP data channel을 기본으로 설명하면 구현과 문서가 충돌한다. Phase 6에서 문서를 반드시 갱신한다.

## 7. TDD Strategy

테스트는 다음 순서로 작성한다.

1. Domain state machine tests
2. Application negotiation tests with fake listener/connector
3. Infrastructure TCP frame codec tests
4. TCP loopback integration tests
5. Transfer controller tests
6. UI projection tests
7. Manual host/VM smoke tests

필수 테스트 항목:

- TCP connected peer는 discovery stale/offline만으로 disconnected가 되지 않는다.
- TCP connected peer는 route candidate 만료만으로 reconnect하지 않는다.
- TCP socket close가 발생해야 peer data session이 reconnecting으로 전이된다.
- authenticated session이 없으면 TCP data session hello가 거부된다.
- wrong instance uid hello는 거부된다.
- partial TCP read에서도 frame parser가 정확히 복원한다.
- coalesced TCP read에서도 frame parser가 여러 frame을 순서대로 복원한다.
- 전송된 파일 digest와 저장된 파일 digest가 일치한다.
- 송신 실패와 수신 실패가 서로 다른 transfer job에만 반영된다.
- 양방향 동시 전송에서 frame이 다른 direction session에 섞이지 않는다.
- 유스케이스가 명시적 input/output을 가지며 전역 환경을 읽지 않는다.
- 외부 API, 파일시스템, 네트워크 접근은 infrastructure fake로 대체 가능하다.
- Product 로그에는 frame별 로그가 포함되지 않는다.
- Development 로그는 프로덕션 기본 동작에 포함되지 않는다.

테스트 실행 기준:

- Phase 0: 문서 테스트가 있는 경우 해당 테스트만 실행한다.
- Phase 1: `flutter test test/domain test/application`
- Phase 2: `flutter test test/application/network test/infrastructure`
- Phase 3: `flutter test test/application/auth test/application/network test/presentation`
- Phase 4: `flutter test test/infrastructure/transfer_data test/application/transfer`
- Phase 5: `flutter test test/application/transfer test/presentation/transfers`
- Phase 6: `flutter analyze`와 전체 `flutter test`

수동 smoke 기준:

- macOS host와 Parallels Windows VM을 같은 ID/PW로 로그인한다.
- 양쪽이 peer를 발견하고 TCP data session connected 상태가 된다.
- macOS에서 Windows로 파일 1개를 드롭해 전송한다.
- Windows에서 macOS로 파일 1개를 드롭해 전송한다.
- 각 전송의 수신 파일 digest가 원본과 일치한다.
- 전송 중 discovery stale 또는 candidate 만료가 발생해도 TCP transfer가 중단되지 않는다.

## 8. Configuration and Runtime Environment Policy

- 새 YAML, JSON, dotenv 설정 파일을 추가하지 않는다.
- TCP data port, frame size, connect timeout, idle timeout은 bootstrap 시점 config 또는 명시적 생성자 인자로만 주입한다.
- 프로세스 실행 중 환경 변수, 외부 파일, mutable singleton을 다시 읽어 TCP 동작을 바꾸지 않는다.
- 테스트는 provider override 또는 생성자 인자로 값을 주입한다.
- 사용자 설정으로 저장할 수 있는 항목과 runtime bootstrap config를 구분한다.
- TCP listener port가 `0`이면 OS ephemeral port를 사용하고, control negotiation으로 실제 port를 peer에게 전달한다.
- TCP data channel mode는 bootstrap 이후 변경할 수 없다.
- legacy UDP data fallback은 `AppConfig.allowLegacyUdpDataFallback`에만 존재하며 production 기본값은 false이다. 이 값은 provider override, 생성자 인자, bootstrap config로 최초 1회 주입하고 런타임 중간에 변경하지 않는다.
- 전송별 timeout, target peer, source file, save policy snapshot은 유스케이스 input으로 전달한다.
- 저장 가능한 사용자 설정은 기본 수신 경로와 UI 표시 선호처럼 보안/연결 의미가 없는 항목으로 제한한다.
- auth session, data session proof, TCP session key는 메모리에만 유지하고 파일, keychain, credential manager에 저장하지 않는다.

## 9. Logging Strategy

Product Log:

- TCP listener start failed
- TCP data session established
- TCP data session closed unexpectedly
- transfer started
- transfer completed
- transfer failed
- transfer canceled

Field Debug Log:

- TCP negotiation state transition
- local/remote endpoint summary
- peer id/session id 축약값
- reconnect attempt count
- close reason code
- throughput summary

Development Log:

- frame parser state
- partial read buffer size
- frame type dispatch
- backpressure wait
- test-only fake socket events

금지:

- 파일 원문 로그
- password, token, session key 로그
- 전체 저장 경로 로그
- frame별 product/info 로그
- TCP byte segment별 로그

로그 검증 기준:

- Product Log는 사용자가 영향을 받는 session 시작, 실패, 복구, 완료만 남긴다.
- Field Debug Log는 현장 재현에 필요한 state transition과 endpoint summary를 남기되 민감정보를 포함하지 않는다.
- Development Log는 frame parser와 fake socket detail을 포함할 수 있지만 프로덕션 기본 로그에 포함되지 않는다.
- 로그 payload에는 full path 대신 basename 또는 redacted path만 들어간다.
- session id와 peer id는 전체 값이 아니라 진단 가능한 축약값으로 기록한다.

## 10. Dependency and Boundary Rules

- `domain`은 Dart IO, Flutter, Riverpod, 파일시스템, socket에 의존하지 않는다.
- `application`은 TCP listener/connector interface만 의존한다.
- `infrastructure`가 Dart IO `ServerSocket`, `Socket`을 구현한다.
- `presentation`은 TCP 구현체를 직접 알지 않는다.
- `app` bootstrap이 concrete provider를 조립한다.
- MessageBus는 event publish에만 사용하고 command 실행 경로를 숨기지 않는다.
- 외부 API, DB, 파일시스템, 네트워크 접근은 infrastructure boundary에만 존재한다.
- domain state machine은 순수 함수 또는 값 객체 메서드로 테스트 가능해야 한다.
- use case는 입력 command와 출력 result/effect를 명시해야 한다.
- provider 또는 singleton 직접 조회로 hidden dependency를 만들지 않는다.

## 11. Prohibited Implementation Patterns

- TCP 연결이 살아 있는데 discovery TTL로 peer를 offline 처리하는 구현 금지.
- TCP 연결이 살아 있는데 새 route candidate가 active connection을 바꾸는 구현 금지.
- 파일 payload를 UDP control packet으로 보내는 구현 금지.
- 파일 payload를 JSON/base64로 감싸는 기본 구현 금지.
- socket callback에서 UI state를 직접 변경하는 구현 금지.
- 전역 singleton에서 auth/session/config를 조회하는 구현 금지.
- 런타임 중 외부 설정 파일을 reload하여 TCP 동작을 변경하는 구현 금지.
- 송신 runner와 수신 runner가 같은 mutable buffer를 공유하는 구현 금지.
- transfer failure 하나가 peer TCP session 전체를 무조건 끊는 구현 금지.
- TCP parser가 frame size limit 없이 payload를 누적하는 구현 금지.
- TCP session state와 discovery presence를 하나의 boolean `isConnected`로 합치는 구현 금지.
- control packet에 파일 payload를 임시로 싣는 구현 금지.
- frame parser에서 파일 writer를 직접 호출하는 구현 금지.
- TCP 연결 성공 전 peer를 전송 가능으로 표시하는 구현 금지.
- 테스트에서 환경 변수나 외부 설정 파일을 몰래 바꿔 동작을 제어하는 방식 금지.

## 12. Risk and Mitigation

Risk: TCP connection이 NAT, firewall, VM bridge 정책에 막힐 수 있다.

- Mitigation: TCP listener bind 실패와 connect 실패를 diagnostics에 명확히 표시한다.
- Mitigation: control channel로 observed endpoint와 offered endpoint를 모두 기록한다.
- Mitigation: host/VM 양방향 smoke test를 release gate에 포함한다.

Risk: 양쪽 peer가 동시에 connect하여 중복 TCP channel이 생긴다.

- Mitigation: Phase 2에서 direction별 channel 허용 또는 deterministic tie-breaker를 테스트로 고정한다.

Risk: TCP stream parser 오류가 파일 corruption을 만든다.

- Mitigation: digest verification을 필수 완료 조건으로 둔다.
- Mitigation: partial/coalesced read codec test를 추가한다.

Risk: 기존 UDP data code와 TCP data code가 동시에 동작해 중복 전송된다.

- Mitigation: data mode selection boundary를 하나로 만들고 기본 transfer path가 TCP adapter만 호출하는 테스트를 작성한다.

Risk: TCP connected 상태와 discovery offline 표시가 사용자에게 혼동을 준다.

- Mitigation: UI에는 "TCP 연결됨", diagnostics에는 "discovery stale"처럼 계층을 분리해 표시한다.

Risk: 대용량 파일에서 UI progress가 너무 자주 갱신된다.

- Mitigation: progress aggregator가 일정 주기로 sampling하고 per-frame UI update를 금지한다.

Risk: AGENTS.md와 구현 방향이 다시 충돌한다.

- Mitigation: Phase 0에서 AGENTS.md를 먼저 정렬하고, 이후 PR/review checklist에 "AGENTS.md와 plan.md 충돌 없음"을 포함한다.

Risk: TCP listener가 일부 플랫폼 방화벽에서 차단된다.

- Mitigation: listener bind 성공, inbound accept 여부, outbound connect 실패 reason을 Field Debug diagnostics에 분리해 기록한다.
- Mitigation: Windows Defender Firewall, macOS firewall 상황은 manual smoke checklist에 명시한다.

Risk: TCP stream이 연결되어 있지만 application frame handshake가 실패한다.

- Mitigation: TCP socket connected와 data session authenticated를 다른 상태로 유지한다.
- Mitigation: `TcpChannelAuthenticated` 전에는 transfer frame을 받지 않는다.

Risk: 기존 UDP Data path 제거 중 release가 불안정해진다.

- Mitigation: Phase 6 전까지 legacy adapter를 격리 유지하되 기본 경로에서는 호출되지 않는 테스트를 둔다.

## 13. Review Checklist

- 도메인 계층이 socket, Flutter, Riverpod, 파일시스템에 의존하지 않는가?
- TCP listener/connector가 infrastructure에만 있는가?
- TCP connected 상태에서 discovery TTL 만료가 peer connection을 끊지 않는 테스트가 있는가?
- TCP socket close/error가 peer connection 상태 전이를 발생시키는 테스트가 있는가?
- transfer runner가 송신/수신 방향별로 분리되어 있는가?
- frame parser가 partial read와 coalesced read를 처리하는가?
- 파일 digest 검증이 완료 기준에 포함되어 있는가?
- Product 로그에 frame별 또는 byte별 로그가 없는가?
- 설정 값이 bootstrap 이후 암묵적으로 재조회되지 않는가?
- MessageBus가 command 실행 경로로 사용되지 않는가?
- UI가 route candidate와 TCP connection status를 혼동하지 않는가?
- 유스케이스 입력과 출력이 명시되어 있는가?
- 외부 환경 값이 프로그램 시작 이후 암묵적으로 재조회되지 않는가?
- 설정 값이 프로세스 중간에 삽입되거나 변경되지 않는가?
- 외부 API, DB, 파일시스템, 네트워크 접근이 infrastructure boundary에만 있는가?
- 테스트 더블로 TCP listener, connector, channel, file reader, file writer, clock을 대체할 수 있는가?
- 로그가 Product, Field Debug, Development 목적에 맞게 분리되어 있는가?
- Development 로그가 프로덕션 기본 동작에 포함되지 않는가?
- 복잡한 내부 흐름이 boolean flag 조합이 아니라 명시적 상태 전이로 표현되어 있는가?
- 리팩터링과 기능 변경이 가능한 한 별도 commit 또는 별도 phase로 분리되어 있는가?
- TCP connected 상태에서 discovery stale/offline이 transfer failure로 이어지지 않는 테스트가 있는가?

## 14. Definition of Done

TCP data channel 전환은 다음 조건을 모두 만족해야 완료다.

- 인증된 peer 사이에 TCP data session이 자동으로 연결된다.
- 파일 payload는 TCP data channel로 전송된다.
- UDP data frame은 기본 전송 경로에서 사용되지 않는다.
- TCP 연결이 active인 동안 discovery candidate 만료와 route candidate 변경은 peer 연결 상태와 transfer route를 변경하지 않는다.
- TCP socket close/error가 발생했을 때만 peer data session이 reconnecting 또는 failed로 내려간다.
- macOS host -> Parallels Windows VM 전송이 성공한다.
- Parallels Windows VM -> macOS host 전송이 성공한다.
- 전송 완료 파일 digest가 원본과 일치한다.
- `flutter analyze`가 통과한다.
- 관련 domain/application/infrastructure/widget 테스트가 통과한다.
- 전체 `flutter test`가 통과한다.
- AGENTS.md, README.md, README.ko.md가 Discovery/Control/Data channel 책임과 현재 TCP Data 기본 경로를 일관되게 설명한다.
- diagnostics export에서 민감정보가 redaction된다.
- 수동 host/VM smoke 결과가 release note 또는 release run 문서에 남는다.

## 15. Next Actions

### Current Local Gate Snapshot

2026-06-18 기준 로컬에서 자동화 가능한 검증은 통과했다.

- `flutter test --reporter compact`: 통과
- `flutter analyze`: 통과
- `flutter test test/docs/agent_guardrails_test.dart test/docs/platform_guide_test.dart test/docs/release_gate_test.dart test/docs/release_run_records_test.dart --reporter compact`: 통과
- `git diff --check`: 통과
- `.tasks/task001.md`부터 현재 task 문서는 미완료 기능 체크박스를 남기지 않는다. Stop condition처럼 진행상태가 아닌 항목은 일반 bullet로 유지한다.
- `.tasks/release_runs/README.md`는 수동 release run 기록에 필요한 TCP data session, digest, diagnostics, 양방향 host/VM 필드를 포함한다.

아직 완료되지 않은 release gate는 실제 실행 환경이 필요한 수동 검증이다.

- macOS host -> Parallels Windows VM TCP Data Channel 전송 smoke
- Parallels Windows VM -> macOS host TCP Data Channel 전송 smoke
- 수동 smoke 결과를 `.tasks/release_runs/<tag>.md` 또는 release note 초안에 기록

1. 전체 `flutter test`와 `flutter analyze`를 계속 release gate 이전 필수 조건으로 실행한다.
2. macOS host -> Parallels Windows VM TCP Data Channel 전송 smoke를 실행하고 receiver digest를 확인한다.
3. Parallels Windows VM -> macOS host TCP Data Channel 전송 smoke를 실행하고 receiver digest를 확인한다.
4. diagnostics export에서 TCP session state, direction, safe endpoint summary, last close reason, redaction 상태를 확인한다.
5. 수동 smoke 결과를 `.tasks/release_runs/<tag>.md` 또는 release note 초안에 기록한다.
6. 실패가 발생하면 route candidate가 아니라 TCP data session state와 last close reason을 기준으로 원인을 분류한다.

## 16. Task Breakdown Policy

개별 task 파일은 다음 규칙으로 작성한다.

- 한 task에는 기능 2~3개, 테스트, 검증을 하나의 리뷰 가능한 묶음으로 포함한다.
- task는 반드시 체크박스를 포함한다.
- task는 선행 조건, 변경 파일 후보, TDD 순서, 검증 명령, 완료 기준을 포함한다.
- task는 AGENTS.md의 Tidy First 원칙에 따라 정돈 작업과 기능 변경을 구분한다.
- task는 외부 설정 파일 추가, runtime config reload, hidden singleton 조회를 금지 사항으로 포함한다.
- task 완료 전 최소 `flutter analyze` 또는 변경 범위 테스트를 실행한다.

권장 task 순서:

- `task001`: Phase 0 문서 guardrail 정렬
- `task002`: TCP state model과 state machine domain tests
- `task003`: DataChannel abstraction과 UDP/TCP boundary 분리
- `task004`: TCP listener/connector interface와 fake application tests
- `task005`: TCP control negotiation packet과 use case
- `task006`: TCP data session hello/accept handshake
- `task007`: TCP frame codec partial/coalesced read
- `task008`: TCP outgoing/incoming single file stream
- `task009`: queue, bidirectional transfer, duplicate drop policy
- `task010`: UI와 diagnostics TCP projection 전환
- `task011`: UDP Data 기본 경로 제거, release gate, host/VM smoke
