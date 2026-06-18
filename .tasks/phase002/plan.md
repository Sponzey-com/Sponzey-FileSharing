# Sponzey FileSharing 상세 개발 계획

이 문서는 Sponzey FileSharing의 실제 구현을 진행하기 위한 상세 개발 계획이다.

기준 문서:

- [README.md](../../README.md)
- [AGENTS.md](../../AGENTS.md)
- [root plan.md](../../plan.md)
- [phase001 task index](../phase001/README.md)
- [phase002 task index](README.md)

## 1. 핵심 전제

Sponzey FileSharing은 같은 로컬 네트워크에 있는 데스크톱 앱 인스턴스들이 외부 서버 없이 서로를 찾고, 인증하고, 파일을 전송하는 분산형 파일 공유 앱이다.

반드시 지켜야 할 구현 전제는 다음과 같다.

- Layered Architecture, Clean Architecture, Tidy First, TDD를 적용한다.
- 내부 절차와 상태 관리는 상태 머신으로 진행한다.
- 계층 간 비동기 사건 전달은 MessageBus로 진행한다.
- UDP 기반으로 동일 네트워크 내 Peer 검색과 연동을 수행한다.
- Peer 검색, Peer 연동, 데이터 통신은 목적별 UDP 포트를 분리해서 운영한다.
- 외부 설정 파일은 최소화한다.
- 환경 상수는 최초 부트스트랩에서만 받고, 이후에는 명시적 인자와 주입으로 전달한다.
- 로그는 Product, Debug, Development 목적 기준으로 분리한다.

## 2. 제품 목표

### 2.1 사용자 목표

- 같은 네트워크 안의 다른 사용자를 자동으로 찾는다.
- 인증된 사용자에게만 파일을 보낸다.
- 단일 파일, 다중 파일, 1:N 배포를 처리한다.
- 전송 중 상태, 실패, 재시도, 취소, 완료를 명확히 볼 수 있다.
- 외부 서버, 클라우드, 웹 브라우저 없이 데스크톱 앱만으로 동작한다.

### 2.2 기술 목표

- UDP의 낮은 지연을 활용하되, 손실과 중복을 앱 프로토콜에서 보완한다.
- Peer 검색, 인증/연동, 파일 데이터 전송의 책임을 포트와 프로토콜 수준에서 분리한다.
- 상태 머신으로 절차를 명시해 예외 흐름과 실패 복구를 테스트 가능하게 만든다.
- MessageBus로 내부 사건을 전달하되, 명령 실행 경로와 도메인 규칙을 숨기지 않는다.
- 플랫폼별 파일 시스템과 보안 저장소는 infrastructure 계층에 가둔다.
- 대용량 파일 전송 중에도 UI 반응성을 유지하도록 네트워크, 파일 IO, 해시/암호화 작업의 실행 경계를 분리한다.

## 3. 범위

### 3.1 포함 범위

- Flutter Desktop 앱
- 로컬 계정 생성과 로그인
- UDP Peer 검색
- UDP Peer 연동과 인증
- UDP 데이터 통신 기반 파일 전송
- 단일 파일 전송
- 다중 파일 전송
- 1:N 전송 큐
- 수신 정책
- 전송 이력
- Product, Debug, Development 로그 레벨
- macOS, Windows, Linux를 고려한 구조

### 3.2 제외 범위

- 중앙 서버
- 웹 앱
- 모바일 앱
- 인터넷 원격 전송
- NAT traversal
- 클라우드 저장소
- 조직 관리자 콘솔
- 실시간 공동 편집
- 파일 버전 관리

## 4. 아키텍처 원칙

### 4.1 계층 구성

```text
lib/
  app/
    app_config.dart
    bootstrap wiring
    router
    theme
  core/
    errors
    logger
    message_bus
    state_machine base types
  domain/
    entities
    value_objects
    state machines
    pure policies
  application/
    auth
    discovery
    transfer
    settings
    orchestration controllers
  infrastructure/
    udp
    auth
    database
    platform
    repositories
    file transfer IO
  presentation/
    screens
    widgets
    view projections
```

### 4.2 의존 방향

- `domain`은 어떤 Flutter, Riverpod, Drift, UDP socket 구현에도 의존하지 않는다.
- `application`은 도메인 규칙을 조합하고 상태 머신을 실행한다.
- `infrastructure`는 UDP, DB, 파일 시스템, 보안 저장소 같은 외부 세부사항을 구현한다.
- `presentation`은 application 상태를 표시하고 사용자 명령을 application으로 전달한다.
- MessageBus는 이벤트 전달만 담당한다. 유스케이스 호출을 대체하지 않는다.

### 4.3 설정 원칙

포트, timeout, interval, chunk size 같은 환경 상수는 `AppConfig` 또는 부트스트랩 시점의 명시적 설정 객체로 받는다.

금지한다:

- 실행 중 외부 설정 파일 재로드
- 중간 단계에서 환경 변수 주입
- 전역 mutable singleton에 설정 저장
- UI 또는 infrastructure에서 임의로 설정값 변경

허용한다:

- `bootstrap(config: AppConfig(...))`
- 테스트용 명시적 config 주입
- 유스케이스 인자로 전달되는 사용자 선택값
- DB에 저장되는 사용자 설정과 시스템 환경 상수의 명확한 분리

### 4.4 동시성 원칙

대용량 파일 전송, UDP 수신 루프, 체크섬 계산, 암호화 작업은 UI isolate를 막지 않아야 한다.

단계별 동시성 목표:

```text
MVP
  - UI isolate에서 application state와 화면 표시를 담당한다.
  - UDP transport는 비동기 stream 경계로 격리한다.
  - 파일 읽기/쓰기는 chunk 단위 streaming으로 처리해 전체 파일을 메모리에 올리지 않는다.

Stabilization
  - 네트워크 수신/파싱 루프를 별도 worker 또는 isolate 경계로 분리한다.
  - 파일 chunk 읽기, 파일 해시 계산, checksum 검증을 별도 worker 후보로 분리한다.

Performance
  - 암호화/복호화가 병목이 되면 crypto worker를 분리한다.
  - 1:N 전송에서는 파일 해시와 chunk metadata를 재사용하되 mutable buffer 공유를 금지한다.
```

원칙:

- 상태 머신은 isolate 내부 구현에 의존하지 않는다.
- worker는 명령을 받아 결과 이벤트를 돌려주는 경계로 둔다.
- MessageBus는 isolate 간 raw transport가 아니라 application event 전달 경계로 사용한다.
- file payload 전체를 MessageBus event에 싣지 않는다.
- chunk payload는 Data Port transport 경계에서만 다룬다.

## 5. UDP 포트 분리 전략

### 5.1 포트 역할

UDP 포트는 목적별로 분리한다.

```text
Discovery Port
  목적: Peer 검색, presence broadcast, heartbeat
  방향: broadcast, multicast 가능성, unicast response
  목표 기본값: 38400

Control Port
  목적: Peer 연동, 인증, 세션 협상, 전송 제어 메시지
  방향: unicast request/response
  목표 기본값: 38401

Data Port
  목적: 파일 chunk 데이터 송수신, ack/nack 또는 data-plane 보조 메시지
  방향: unicast datagram stream
  목표 기본값: 38410
  확장 범위: 38410~38430
```

루트 `plan.md`의 목표 포트 체계는 `38400/udp`, `38401/udp`, `38410~38430/udp`이다. 현재 코드에 `discoveryPort`, `authPort`가 존재하고 기본값이 다를 수 있으므로, 구현 시에는 기존 동작을 갑자기 깨지 말고 명시적 migration으로 정리한다.

Migration 기준:

- `authPort`는 역할상 `controlPort`로 이름을 바꾼다.
- 한 번에 public API를 깨기 어렵다면 `authPort`를 deprecated alias로 잠시 유지한다.
- `dataPort` 또는 `dataPortRange`를 추가한다.
- MVP는 단일 `dataPort`로 시작할 수 있다.
- 1:N 병렬 전송과 성능 안정화 단계에서는 `dataPortRange` 기반 세션별 data endpoint 할당을 검토한다.
- 포트 기본값 변경은 테스트와 release note에 명시한다.

### 5.2 포트 분리 이유

- Peer 검색 broadcast와 파일 데이터 전송이 서로를 방해하지 않게 한다.
- 인증과 세션 제어 메시지를 데이터 chunk 폭주로부터 분리한다.
- 로그, 계측, 장애 분석에서 채널별 문제를 구분할 수 있다.
- 방화벽 안내와 플랫폼 권한 요청을 목적별로 설명할 수 있다.
- 테스트에서 각 채널을 독립적으로 fake 또는 loopback 구현으로 검증할 수 있다.

### 5.3 포트 바인딩 정책

- 앱 시작 시 Discovery, Control 포트는 명시적으로 바인딩한다.
- Data Port는 MVP에서는 앱 시작 시 단일 포트를 바인딩하고, data port range를 도입한 뒤에는 세션 생성 시 명시적 allocator를 통해 할당한다.
- 바인딩 실패 시 AppLifecycle 상태 머신은 `networkUnavailable` 또는 `portConflict` 상태로 전이한다.
- 포트 충돌은 자동으로 임의 포트로 우회하지 않는다. 사용자가 예측할 수 없는 Peer 검색 실패를 만들기 때문이다.
- 테스트와 개발용 다중 인스턴스 실행은 명시적 config로 포트 세트를 다르게 주입한다.
- 런타임 중간에 포트를 바꾸지 않는다. 포트 변경은 앱 재시작 또는 네트워크 엔진 재초기화 절차로만 처리한다.
- Data Port range에서 특정 포트 할당에 실패하면 allocator가 같은 range 안에서 명시적으로 다음 후보를 시도할 수 있다. 이 동작은 config에 선언된 range 안에서만 허용하고, OS 임의 포트 할당으로 숨기지 않는다.

### 5.4 채널별 메시지

Discovery Port:

- `DiscoveryHello`
- `DiscoveryAnnounce`
- `DiscoveryHeartbeat`
- `DiscoveryGoodbye`
- `DiscoveryProbe`
- `DiscoveryProbeResponse`

Control Port:

- `LinkRequest`
- `LinkChallenge`
- `LinkResponse`
- `LinkAccepted`
- `LinkRejected`
- `SessionRefresh`
- `TransferOffer`
- `TransferAccept`
- `TransferReject`
- `TransferCancel`
- `TransferComplete`
- `TransferFailed`

Data Port:

- `DataStart`
- `DataChunk`
- `DataAck`
- `DataNack`
- `DataWindowUpdate`
- `DataFinish`
- `DataAbort`

Data Port range를 쓰는 단계에서는 `TransferAccept`에 실제 사용할 `dataEndpoint`와 `dataPortLeaseId`를 포함한다.

### 5.5 공통 패킷 헤더

모든 UDP 메시지는 공통 헤더를 가져야 한다.

```text
protocolVersion
messageType
messageId
correlationId
sourcePeerId
targetPeerId
sessionId
timestamp
ttl 또는 expiresAt
payloadChecksum
headerChecksum
flags
```

Discovery 메시지는 `targetPeerId`가 비어 있을 수 있다. Control과 Data 메시지는 원칙적으로 인증 또는 세션 문맥을 가져야 한다.

주의:

- 공통 헤더는 작은 크기를 유지한다.
- binary codec과 JSON codec 중 하나를 선택하기 전까지는 codec interface를 먼저 고정한다.
- packet parser는 malformed input, 초과 payload length, 알 수 없는 messageType을 안전하게 거부해야 한다.

## 6. 상태 머신 설계

### 6.1 상태 머신 적용 대상

상태 머신은 다음 절차에 반드시 적용한다.

- App lifecycle
- UDP port lifecycle
- Peer discovery
- Peer link and auth
- Transfer queue
- Outgoing transfer session
- Incoming transfer session
- Receive policy decision
- Retry and recovery

### 6.2 공통 상태 머신 규칙

- 상태는 enum, sealed class, 값 객체로 명시한다.
- 전이는 `transition(event)` 또는 명확한 메서드로 한 곳에서 처리한다.
- 불가능한 전이는 테스트로 고정하고, no-op, warning, failure 중 하나로 명시 처리한다.
- 상태 전이 함수는 가능한 순수하게 유지한다.
- 소켓 송신, 파일 쓰기, DB 저장, 로그 출력 같은 부작용은 application 또는 infrastructure에서 명시 실행한다.
- UI는 상태를 표시할 뿐 전이 규칙을 가지지 않는다.

### 6.3 AppLifecycleStateMachine

목적:

- 앱 시작부터 네트워크 준비, 로그인, 종료까지 최상위 절차를 관리한다.

상태:

```text
initial
loadingConfig
initializingStorage
bindingPorts
networkReady
requiresLogin
authenticated
running
shuttingDown
stopped
failed
```

주요 전이:

- `initial -> loadingConfig`
- `loadingConfig -> initializingStorage`
- `initializingStorage -> bindingPorts`
- `bindingPorts -> networkReady`
- `networkReady -> requiresLogin`
- `requiresLogin -> authenticated`
- `authenticated -> running`
- `running -> shuttingDown`
- `shuttingDown -> stopped`
- any state -> `failed`

검증:

- 포트 바인딩 실패 시 `running`으로 전이하지 않는다.
- 로그인 전에는 transfer command를 받을 수 없다.
- 종료 시 discovery goodbye와 active transfer cancel 절차가 수행된다.

### 6.4 UdpPortStateMachine

목적:

- Discovery, Control, Data 포트 각각의 바인딩과 수신 루프 상태를 관리한다.

상태:

```text
unbound
binding
bound
listening
degraded
closing
closed
failed
```

전이 이벤트:

- `bindRequested`
- `bindSucceeded`
- `bindFailed`
- `listenStarted`
- `receiveError`
- `recoverRequested`
- `closeRequested`
- `closeCompleted`

검증:

- `unbound`에서만 bind를 시작할 수 있다.
- `closed` 후에는 같은 인스턴스를 재사용하지 않는다.
- `receiveError`가 반복되면 `degraded` 후 recovery 정책으로 넘어간다.

### 6.5 DiscoveryStateMachine

목적:

- 동일 네트워크의 peer 검색, heartbeat, stale/offline 판정을 관리한다.

상태:

```text
idle
starting
announcing
listening
scanning
active
degraded
stopping
stopped
failed
```

주요 이벤트:

- `startRequested`
- `portReady`
- `announceSent`
- `helloReceived`
- `heartbeatReceived`
- `peerBecameStale`
- `peerBecameOffline`
- `probeRequested`
- `stopRequested`
- `socketError`

Peer 상태:

```text
unknown
seen
online
stale
offline
blocked
incompatible
```

검증:

- 동일 peer의 중복 hello는 peer record update로 처리한다.
- protocolVersion 불일치 peer는 `incompatible`로 표시한다.
- heartbeat timeout 후 `stale`, 추가 timeout 후 `offline`로 전이한다.
- discovery stop 후에는 heartbeat timer가 남지 않는다.

### 6.6 PeerLinkStateMachine

목적:

- 발견된 peer와 인증된 연결을 만드는 절차를 관리한다.

상태:

```text
discovered
linkRequested
challengeReceived
challengeSent
authenticating
authenticated
rejected
expired
disconnected
failed
```

주요 이벤트:

- `linkRequested`
- `challengeIssued`
- `challengeReceived`
- `tokenCreated`
- `tokenReceived`
- `tokenVerified`
- `tokenRejected`
- `linkAccepted`
- `linkRejected`
- `sessionExpired`
- `disconnectRequested`
- `controlTimeout`

검증:

- discovered 전에는 link request를 보낼 수 없다.
- token verified 전에는 transfer offer를 보낼 수 없다.
- expired session은 transfer command를 거부한다.
- replay 의심 token은 rejected 또는 failed로 전이한다.

### 6.7 TransferQueueStateMachine

목적:

- 여러 전송 작업의 대기, 실행, 일시 실패, 취소, 완료를 관리한다.

상태:

```text
empty
queued
dispatching
running
throttled
draining
completed
failed
cancelled
```

주요 이벤트:

- `jobAdded`
- `jobRemoved`
- `dispatchRequested`
- `jobStarted`
- `jobProgressed`
- `jobCompleted`
- `jobFailed`
- `jobRetryScheduled`
- `cancelRequested`
- `queueDrained`

검증:

- 인증되지 않은 peer로 job을 dispatch하지 않는다.
- 1:N job은 대상별 child session으로 분리한다.
- 한 대상의 실패가 다른 대상의 성공 상태를 덮어쓰지 않는다.

### 6.8 OutgoingTransferStateMachine

목적:

- 송신 측 파일 전송 세션의 제어 절차와 데이터 전송 상태를 관리한다.

상태:

```text
created
offering
waitingForAccept
preparingFile
sendingStart
sendingChunks
waitingForAcks
retrying
finishing
completed
cancelling
cancelled
failed
```

주요 이벤트:

- `offerSent`
- `offerAccepted`
- `offerRejected`
- `filePrepared`
- `dataStartSent`
- `chunkSent`
- `ackReceived`
- `nackReceived`
- `windowUpdated`
- `retryTimeout`
- `maxRetryExceeded`
- `finishAckReceived`
- `cancelRequested`

검증:

- filePrepared 전에는 data chunk를 보내지 않는다.
- offerAccepted 전에는 data port 전송을 시작하지 않는다.
- ack 범위 밖 chunk는 무시하거나 protocol error로 처리한다.
- max retry 초과 시 failed로 전이한다.

### 6.9 IncomingTransferStateMachine

목적:

- 수신 측 전송 제안, 정책 판단, 파일 저장, chunk 조립을 관리한다.

상태:

```text
offered
policyChecking
waitingForUserApproval
accepted
preparingDestination
receivingStart
receivingChunks
requestingRetransmit
verifying
completed
rejecting
rejected
cancelling
cancelled
failed
```

주요 이벤트:

- `offerReceived`
- `policyAllowed`
- `policyRequiresApproval`
- `policyDenied`
- `userAccepted`
- `userRejected`
- `destinationPrepared`
- `dataStartReceived`
- `chunkReceived`
- `chunkDuplicateReceived`
- `chunkMissingDetected`
- `checksumVerified`
- `checksumFailed`
- `senderCancelled`

검증:

- policyAllowed 또는 userAccepted 전에는 파일을 생성하지 않는다.
- destinationPrepared 전에는 chunk를 쓰지 않는다.
- checksum failure는 completed가 아니라 failed 또는 retransmit으로 처리한다.
- 임의 경로 쓰기를 허용하지 않는다.

## 7. MessageBus 설계

### 7.1 목적

MessageBus는 여러 컴포넌트가 같은 사건을 관찰해야 할 때 사용한다.

예:

- Peer 발견
- Peer offline
- 인증 성공
- 인증 실패
- 전송 작업 생성
- 전송 진행률 변경
- 전송 실패
- 로그성 진단 이벤트
- 네트워크 degraded

MessageBus는 명령 실행 수단이 아니다. 파일 전송 시작 같은 명령은 application controller 또는 use case 메서드로 호출한다.

### 7.2 위치

권장 구조:

```text
lib/core/message_bus/
  app_event.dart
  message_bus.dart
  in_memory_message_bus.dart

lib/application/.../
  controllers publish events through MessageBus interface

lib/infrastructure/.../
  low-level events converted to application events
```

대안:

- `core`에 인터페이스와 기본 in-memory 구현을 둔다.
- infrastructure 구현이 필요해지면 구체 구현을 `infrastructure/message_bus`로 옮긴다.

### 7.3 이벤트 타입

문자열 이벤트 이름을 금지하고 명시 타입을 사용한다.

```text
AppEvent
  AppLifecycleEvent
  UdpPortEvent
  DiscoveryEvent
  PeerLinkEvent
  TransferQueueEvent
  TransferSessionEvent
  SecurityEvent
  DiagnosticsEvent
```

이벤트 payload는 불변이어야 한다.

공통 필드:

```text
eventId
occurredAt
correlationId
source
severity
```

도메인별 필드:

```text
peerId
sessionId
transferId
jobId
portRole
messageId
reasonCode
```

### 7.4 Publish 규칙

- 이미 발생한 사실만 publish한다.
- publish 결과에 따라 핵심 명령 성공 여부가 바뀌면 안 된다.
- subscriber 실패는 MessageBus 정책에 따라 수집하고 로그로 남기되 전체 앱을 중단하지 않는다.
- 보안 이벤트와 실패 이벤트는 Product 로그 후보로도 검토한다.

### 7.5 Subscribe 규칙

- 구독 생명주기는 소유자가 명확해야 한다.
- controller, projection, diagnostics collector는 dispose 시 반드시 unsubscribe한다.
- UI 위젯이 MessageBus 구현체를 직접 구독하지 않는다. UI는 application provider 상태를 구독한다.
- 테스트는 구독 해제 후 이벤트가 전달되지 않음을 확인한다.

### 7.6 MessageBus와 상태 머신의 관계

권장 흐름:

```text
사용자 명령
  -> Application Controller
  -> StateMachine.transition(command event)
  -> 필요한 SideEffect 실행
  -> 상태 저장
  -> MessageBus.publish(fact event)
  -> Projection, Logger, History updater가 관찰
```

금지 흐름:

```text
사용자 명령
  -> MessageBus.publish(command-like event)
  -> 어딘가의 subscriber가 몰래 상태 변경
```

## 8. UDP Peer 검색 계획

### 8.1 Discovery 요구사항

- 앱 실행 후 Discovery Port를 바인딩한다.
- 로그인 또는 장치 identity 준비 후 자기 존재를 announce한다.
- 같은 서브넷에 probe 또는 broadcast hello를 보낸다.
- 수신 peer는 response 또는 heartbeat로 응답한다.
- peer record는 마지막 수신 시간과 protocolVersion을 포함한다.
- 일정 시간 응답이 없으면 stale, offline으로 전이한다.

### 8.2 Discovery packet

필수 필드:

```text
protocolVersion
packetType
messageId
sourcePeerId
displayName
deviceName
controlPort
dataPort
dataPortRange
capabilities
timestamp
signature 또는 checksum
```

주의:

- Discovery packet에는 비밀번호, 토큰, 파일 경로를 넣지 않는다.
- controlPort와 dataPort 또는 dataPortRange를 광고해 peer가 이후 unicast 통신 대상을 알 수 있게 한다.
- MVP가 단일 Data Port를 쓰더라도 packet schema는 range 확장을 방해하지 않게 둔다.
- protocolVersion이 다르면 UI에 incompatible로 표시한다.

### 8.3 Discovery 보안 기준

- Discovery는 공개 presence 성격이므로 민감 정보를 포함하지 않는다.
- 발견되었다는 사실만으로 인증된 peer가 되지 않는다.
- Discovery packet spoofing 가능성을 고려해 인증 전 기능은 제한한다.
- Peer ID는 재시작마다 바뀌는 runtime id와 장기 device id를 구분한다.

### 8.4 Discovery 테스트

- packet encode/decode
- protocolVersion mismatch
- duplicate peer update
- stale/offline timeout
- goodbye 수신 시 offline 처리
- malformed packet 무시
- discovery stop 후 timer와 stream 정리

## 9. UDP Peer 연동과 인증 계획

### 9.1 Control channel 역할

Control Port는 peer 연동과 전송 제어를 담당한다.

- link request
- challenge exchange
- token exchange
- session open
- transfer offer
- transfer accept/reject
- transfer cancel
- transfer completion
- retry coordination

### 9.2 인증 절차

기준 흐름:

```text
1. A discovers B through Discovery Port.
2. A sends LinkRequest to B Control Port.
3. B creates challenge and sends LinkChallenge.
4. A signs using password-derived material and returns LinkResponse.
5. B verifies token, nonce, jti, expiration.
6. Optional mutual authentication is performed if policy requires it.
7. B sends LinkAccepted with session negotiation parameters or LinkRejected.
8. Both sides negotiate or finalize an ephemeral session key.
9. A stores PeerAuthSession in memory and persistence policy where appropriate.
10. Both sides publish PeerLinkAuthenticated or PeerLinkRejected.
```

### 9.3 인증 상태 관리

- `PeerLinkStateMachine`이 모든 인증 전이를 관리한다.
- 인증 성공 전에는 transfer offer를 보낼 수 없다.
- 세션 만료 시 transfer command는 reject된다.
- refresh가 필요하면 Control Port에서 session refresh 절차를 시작한다.

### 9.4 인증 테스트

- 정상 challenge/response
- 잘못된 password-derived signature
- expired token
- nonce reuse
- jti replay
- incompatible protocol
- link timeout
- reject 후 transfer offer 금지
- mutual auth required인데 상대 인증 누락
- session key negotiation 실패
- 인증 성공 후 session ttl 만료

### 9.5 세션 키와 데이터 암호화

루트 `plan.md`의 목표는 인증 후 세션 키 기반 파일 데이터 암호화를 적용하는 것이다. MVP에서 모든 암호화 최적화를 끝내지 못하더라도, 프로토콜과 상태 머신은 암호화 적용을 전제로 설계한다.

권장 흐름:

```text
1. Control Port에서 challenge nonce를 교환한다.
2. password-derived JWT로 peer를 인증한다.
3. 인증 성공 후 ephemeral key exchange를 수행한다.
4. HKDF 또는 동급 KDF로 session key를 파생한다.
5. Data Port의 파일 chunk는 session key 기반 AEAD로 보호한다.
6. 세션 종료, 만료, 실패 시 메모리의 session key를 폐기한다.
```

구현 우선순위:

- MVP: 인증 토큰, nonce, jti, 짧은 TTL, 세션 문맥을 먼저 고정한다.
- Transfer MVP: 파일 단위 checksum과 chunk checksum을 먼저 적용한다.
- Security hardening: AEAD 기반 chunk 암호화와 ephemeral key exchange를 완성한다.
- 이후: SRP, SPAKE2 같은 PAKE 계열 인증을 검토한다.

금지:

- password 원문을 session key로 직접 사용
- password hash를 그대로 네트워크 서명키로 사용
- raw token 또는 session key를 DB나 로그에 저장
- 인증 전 파일 metadata 이상의 민감 정보를 전송

세션 키 상태는 `PeerLinkStateMachine` 또는 별도 `SecureSessionStateMachine`으로 관리한다.

상태 후보:

```text
none
negotiating
established
refreshing
expired
revoked
failed
destroyed
```

검증:

- established 전에는 encrypted data 전송 금지
- expired 후 transfer offer 거부
- failed 또는 destroyed 후 key material 접근 금지
- 앱 종료 시 active session key 폐기

## 10. UDP 데이터 통신 계획

### 10.1 Data channel 역할

Data Port는 파일 chunk 전송을 담당한다. Control Port와 분리해 데이터 전송 폭주가 인증, 취소, 실패 보고를 막지 않게 한다.

### 10.2 전송 단위

개념 모델:

```text
TransferJob
  jobId
  sourcePeerId
  targetPeerIds
  files
  createdAt
  queuePolicy

TransferSession
  sessionId
  jobId
  targetPeerId
  state
  retryPolicy

TransferFile
  fileId
  relativeName
  size
  checksum
  chunkSize
  chunkCount

TransferChunk
  sessionId
  fileId
  chunkIndex
  offset
  length
  payloadChecksum
```

### 10.3 데이터 전송 흐름

```text
1. Sender sends TransferOffer through Control Port.
2. Receiver checks auth session and receive policy.
3. Receiver sends TransferAccept with data parameters.
4. Sender sends DataStart through Data Port.
5. Sender sends DataChunk packets using window policy.
6. Receiver records received chunks and sends DataAck/DataNack.
7. Sender retransmits missing chunks.
8. Receiver verifies file checksum.
9. Receiver sends TransferComplete through Control Port.
10. Sender marks session completed.
```

### 10.4 신뢰성 보강

MVP 기준:

- chunk index 기반 재조립
- ack/nack 기반 누락 복구
- retry timeout
- max retry count
- checksum verification
- cancel propagation

고도화 기준:

- Selective Repeat ARQ
- sliding window
- adaptive window size
- RTT estimator
- congestion backoff
- partial resume
- per-peer throughput measurement

권장 최종 방향은 `Selective Repeat ARQ + Sliding Window`이다. Stop-and-wait는 구현 확인용 spike에서는 허용되지만 제품 구조의 목표로 삼지 않는다.

핵심 규칙:

- 수신자는 chunk bitmap 또는 set으로 수신 여부를 기록한다.
- 송신자는 window 안의 chunk를 연속 전송한다.
- ACK는 누적 ack만으로 제한하지 않고 selective ack 정보를 포함할 수 있어야 한다.
- NACK는 누락 chunk 범위를 요청할 수 있어야 한다.
- timeout은 고정값에서 시작하되 RTT estimator로 조정한다.
- 재전송이 반복되면 window size를 줄이고 Debug 로그에 degraded 상태를 남긴다.
- transfer 완료 전 파일 전체 checksum을 검증한다.
- 이어받기는 MVP 필수는 아니지만 chunk map 저장 구조를 방해하지 않게 설계한다.

Chunk payload 기준:

- 기본 payload는 MTU 1500 이내를 목표로 보수적으로 잡는다.
- 초기 권장값은 header, checksum, 암호화 tag를 제외한 `1024B~1200B` 범위다.
- chunk size는 `AppConfig` 또는 transfer negotiation 값으로 주입한다.
- 실행 중 임의 변경하지 않는다.

### 10.5 데이터 테스트

- 단일 파일 정상 전송
- chunk 순서 뒤섞임
- chunk 중복 수신
- 일부 chunk 손실 후 retransmit
- checksum mismatch
- selective ack 기반 부분 재전송
- window 축소와 recovery
- MTU를 넘는 payload 거부 또는 분할
- 수신자 cancel
- 송신자 cancel
- max retry 초과
- 1:N 전송에서 일부 peer 실패와 일부 peer 성공

## 11. 수신 정책 계획

### 11.1 정책 종류

```text
autoAcceptAll
askEveryTime
autoAcceptAllowedPeers
rejectUnknownPeers
```

### 11.2 정책 판단 순서

```text
1. peer auth session 확인
2. allowed peer 여부 확인
3. file metadata 검증
4. 저장 경로 정책 확인
5. 파일명 충돌 정책 확인
6. 사용자 승인 필요 여부 판단
7. accept, waitForApproval, reject 중 하나로 전이
```

### 11.3 저장 경로 규칙

- 임의 절대 경로 쓰기를 금지한다.
- 기본 수신 폴더 또는 사용자가 선택한 허용 폴더 아래에만 저장한다.
- 파일명 충돌은 rename, overwrite deny, ask policy 중 하나로 처리한다.
- 수신 완료 전 임시 파일로 쓰고 검증 후 최종 파일명으로 이동한다.

## 12. 로그와 진단 계획

### 12.1 로그 레벨 목적

Product:

- 앱 시작/종료
- 포트 바인딩 실패
- 인증 실패 또는 거절
- 전송 실패
- 저장 실패

Debug:

- discovery heartbeat
- peer stale/offline 전이
- control message timeout
- retry 발생
- data throughput summary

Development:

- 상태 머신 전이 상세
- packet encode/decode 상세
- fake transport 테스트 흐름
- MessageBus publish/subscriber 상세

### 12.2 로그 금지 항목

- password
- raw token
- signing key
- 파일 원문
- 전체 파일 경로
- 개인 식별 정보 원문

### 12.3 진단 이벤트

MessageBus를 통해 다음 진단 이벤트를 발행한다.

- `NetworkPortBound`
- `NetworkPortBindFailed`
- `DiscoveryPeerSeen`
- `DiscoveryPeerOffline`
- `PeerAuthSucceeded`
- `PeerAuthFailed`
- `TransferSessionStarted`
- `TransferSessionRetried`
- `TransferSessionCompleted`
- `TransferSessionFailed`

## 13. 데이터 저장 계획

### 13.1 저장 대상

- 로컬 사용자 계정 metadata
- password hash
- allowed peer
- app settings
- transfer history
- receive policy

### 13.2 저장하지 않는 대상

- 평문 password
- raw auth token
- 세션 임시 key
- 파일 payload
- 민감 로그 원문

### 13.3 DB와 보안 저장소 분리

- SQLite: 일반 metadata, history, settings
- Secure storage: 민감 secret, 장기 device secret 후보
- Memory only: short-lived session token, nonce cache 일부

## 14. UI 계획

### 14.1 화면 구성

- Login
- Dashboard
- Peers
- Transfers
- History
- Settings

### 14.2 UI 표시 원칙

- UI는 application state projection을 표시한다.
- UI에서 직접 UDP transport를 호출하지 않는다.
- transfer status는 상태 머신 상태를 사용자 문구로 변환해 표시한다.
- 실패는 사용자 조치 가능 여부를 포함해 보여준다.

### 14.3 주요 사용자 흐름

첫 실행:

```text
계정 생성
-> 로그인
-> 포트 바인딩 확인
-> discovery 시작
-> peer 목록 표시
```

파일 전송:

```text
peer 선택
-> 인증 또는 기존 세션 확인
-> 파일 선택
-> transfer offer
-> 수신 정책 처리
-> data transfer
-> 완료 또는 실패 표시
```

1:N 전송:

```text
여러 peer 선택
-> 대상별 인증 상태 확인
-> parent job 생성
-> 대상별 child transfer session 생성
-> peer별 결과 집계
```

## 15. 테스트 전략

### 15.1 테스트 기본 원칙

- TDD 기준으로 실패 테스트를 먼저 만든다.
- 도메인 상태 머신은 순수 단위 테스트로 검증한다.
- MessageBus는 구독, 해제, 순서, subscriber 실패를 테스트한다.
- UDP transport는 fake socket 또는 loopback 가능한 얇은 경계로 테스트한다.
- UI 테스트는 application state를 주입해 표시 상태를 검증한다.

### 15.2 테스트 분류

Domain tests:

- 상태 머신 전이
- 정책 판단
- 전송 chunk 계산
- retry policy

Application tests:

- controller command 처리
- state projection
- MessageBus publish
- 인증 후 전송 허용
- 인증 전 전송 거부

Infrastructure tests:

- UDP packet codec
- raw UDP transport
- repository persistence
- secure storage adapter
- file write strategy

Widget tests:

- peer list state 표시
- transfer progress 표시
- failure action 표시
- settings form validation

Smoke tests:

- 앱 부트스트랩
- 포트 바인딩
- loopback discovery
- loopback transfer MVP

## 16. 단계별 구현 계획

## Phase 001. 현재 기반 정리와 규칙 고정

목표:

- 기존 구현을 계층 기준으로 확인한다.
- AppConfig, logger, controller, transport의 현재 경계를 문서 기준과 맞춘다.
- `.tasks/phase001`의 완료 상태와 실제 코드 상태를 맞춘다.

작업:

- [ ] README, AGENTS, `.tasks/phase002/plan.md` 기준을 확인한다.
- [ ] 현재 `lib/app/app_config.dart`의 포트 정의를 점검한다.
- [ ] 루트 `plan.md`의 목표 포트 체계와 현재 코드 기본값 차이를 확인한다.
- [ ] `authPort`를 장기적으로 `controlPort`로 부를지 migration 계획을 세운다.
- [ ] `dataPort` 추가 필요 범위를 식별한다.
- [ ] 단일 `dataPort`와 `dataPortRange` 중 MVP 적용 범위를 결정한다.
- [ ] 기존 tests가 어느 계층까지 커버하는지 표로 정리한다.

완료 기준:

- 개발 기준이 문서화되어 있다.
- 다음 phase에서 바로 MessageBus와 state machine foundation을 구현할 수 있다.

## Phase 002. State Machine Foundation

목표:

- 내부 절차를 enum과 boolean 조합이 아니라 상태 머신으로 표현할 기반을 만든다.

작업:

- [ ] 상태 머신 공통 타입을 설계한다.
- [ ] transition result 타입을 정의한다.
- [ ] invalid transition 처리 정책을 정한다.
- [ ] AppLifecycleStateMachine 테스트를 먼저 작성한다.
- [ ] UdpPortStateMachine 테스트를 먼저 작성한다.
- [ ] DiscoveryStateMachine 테스트를 먼저 작성한다.
- [ ] PeerLinkStateMachine 테스트를 먼저 작성한다.
- [ ] TransferQueueStateMachine 테스트를 먼저 작성한다.
- [ ] OutgoingTransferStateMachine 테스트를 먼저 작성한다.
- [ ] IncomingTransferStateMachine 테스트를 먼저 작성한다.

권장 파일:

```text
lib/domain/state_machine/
lib/domain/discovery/
lib/domain/peer_link/
lib/domain/transfer/
test/domain/...
```

완료 기준:

- 주요 절차의 상태와 전이가 테스트로 고정된다.
- UI나 transport 없이 상태 전이 규칙을 검증할 수 있다.

## Phase 003. MessageBus Foundation

목표:

- 내부 사건 전달을 MessageBus로 표준화한다.

작업:

- [ ] `AppEvent` base type을 만든다.
- [ ] 이벤트 공통 metadata를 정의한다.
- [ ] `MessageBus` interface를 만든다.
- [ ] in-memory 구현을 만든다.
- [ ] typed subscribe 또는 filtered stream 전략을 정한다.
- [ ] unsubscribe/dispose 정책을 구현한다.
- [ ] subscriber exception 처리 정책을 구현한다.
- [ ] MessageBus 테스트를 작성한다.

필수 테스트:

- [ ] publish 순서 유지
- [ ] 타입별 구독
- [ ] 구독 해제 후 미전달
- [ ] subscriber 실패가 다른 subscriber를 막지 않음
- [ ] correlationId 전달

완료 기준:

- application controller가 MessageBus interface를 주입받아 event를 publish할 수 있다.
- UI는 MessageBus를 직접 구독하지 않는다는 기준이 테스트와 구조로 유지된다.

## Phase 004. UDP Port Model과 AppConfig 정리

목표:

- Discovery, Control, Data 포트 분리를 config와 코드 구조에 반영한다.

작업:

- [ ] `AppConfig`에 `discoveryPort`, `controlPort`, `dataPort` 개념을 명확히 둔다.
- [ ] 루트 `plan.md`의 목표 포트인 `38400`, `38401`, `38410~38430`과 현재 코드의 `232xx` 기본값 사이 migration 결정을 문서화한다.
- [ ] 기존 `authPort`는 호환 이름으로 둘지, `controlPort`로 변경할지 결정하고 deprecated 기간을 정한다.
- [ ] `UdpPortRole` 값을 정의한다.
- [ ] `UdpEndpointConfig` 값을 정의한다.
- [ ] `DataPortAllocator` 또는 단일 `dataPort` 전략 중 MVP 선택을 확정한다.
- [ ] 포트 바인딩 실패를 상태 머신 이벤트로 변환한다.
- [ ] 테스트용 config factory를 만든다.

검증:

- [ ] production config는 세 포트를 모두 가진다.
- [ ] 테스트 config는 명시적으로 포트를 주입한다.
- [ ] runtime 중간 config 변경 경로가 없다.
- [ ] 포트 충돌은 명확한 failure로 표시된다.
- [ ] 명시된 range 밖의 OS 임의 포트 할당이 없다.

완료 기준:

- discovery/control/data 포트 책임이 코드와 문서에서 일치한다.

## Phase 005. Discovery Port 구현 고도화

목표:

- 동일 네트워크 peer 검색을 Discovery Port에서 안정적으로 수행한다.

작업:

- [ ] Discovery packet schema를 확정한다.
- [ ] packet codec 테스트를 작성한다.
- [ ] broadcast hello 송신을 구현한다.
- [ ] probe/response 흐름을 구현한다.
- [ ] heartbeat 송수신을 구현한다.
- [ ] stale/offline timer를 상태 머신과 연결한다.
- [ ] peer record projection을 application에서 관리한다.
- [ ] peer 발견/상태 변경 이벤트를 MessageBus로 publish한다.

검증:

- [ ] malformed packet 무시
- [ ] duplicate peer update
- [ ] incompatible protocol 표시
- [ ] goodbye 처리
- [ ] stop 후 timer 정리

완료 기준:

- 앱 실행 시 같은 서브넷 peer가 발견된다.
- 발견 peer는 인증 전 상태로만 표시된다.

## Phase 006. Control Port 기반 Peer Link/Auth

목표:

- Discovery로 찾은 peer와 Control Port를 통해 인증된 연결을 만든다.

작업:

- [ ] Control packet schema를 확정한다.
- [ ] link request/challenge/response/accepted/rejected codec 테스트를 작성한다.
- [ ] PeerLinkStateMachine과 controller를 연결한다.
- [ ] password-derived JWT 검증 흐름을 연결한다.
- [ ] mutual authentication 필요 여부와 정책값을 확정한다.
- [ ] ephemeral session key negotiation 인터페이스를 설계한다.
- [ ] session expiration과 refresh 정책을 구현한다.
- [ ] session key lifecycle 상태를 상태 머신에 반영한다.
- [ ] 인증 성공/실패 이벤트를 MessageBus로 publish한다.
- [ ] 인증 전 transfer offer 거부 테스트를 작성한다.

검증:

- [ ] 정상 인증
- [ ] 잘못된 token
- [ ] expired token
- [ ] replay token
- [ ] timeout
- [ ] rejected peer
- [ ] session key negotiation failure
- [ ] session key 폐기

완료 기준:

- 인증된 peer만 transfer command 대상이 될 수 있다.
- 인증 성공 후 데이터 전송에 필요한 session context가 명확히 생성된다.

## Phase 007. Data Port 기반 Transfer MVP

목표:

- 단일 peer에게 단일 파일을 Data Port로 전송한다.

작업:

- [ ] Data packet schema를 확정한다.
- [ ] TransferOffer는 Control Port로 전송한다.
- [ ] TransferAccept 이후 DataStart를 Data Port로 전송한다.
- [ ] 파일을 chunk로 나누는 pure service를 만든다.
- [ ] DataChunk 송수신을 구현한다.
- [ ] chunk ack를 구현한다.
- [ ] checksum 검증을 구현한다.
- [ ] 암호화 적용 전이라도 chunk codec이 AEAD metadata를 수용할 수 있는 구조인지 확인한다.
- [ ] 임시 파일 저장 후 완료 시 final path로 이동한다.
- [ ] 파일 전체를 메모리에 올리지 않는 streaming read/write를 적용한다.
- [ ] 진행률 이벤트를 MessageBus로 publish한다.

검증:

- [ ] 단일 파일 정상 전송
- [ ] 인증 전 전송 거부
- [ ] 수신 정책 거부
- [ ] checksum mismatch 실패
- [ ] 대용량 파일에서 메모리 사용량이 파일 크기에 비례해 폭증하지 않음
- [ ] cancel 처리

완료 기준:

- 같은 장비 loopback 또는 동일 LAN 두 장비에서 단일 파일 전송이 된다.

## Phase 008. UDP 신뢰성 보강

목표:

- 손실, 중복, 순서 어긋남이 있어도 전송을 복구한다.

작업:

- [ ] ack/nack 범위를 정의한다.
- [ ] selective ack 표현을 정의한다.
- [ ] missing chunk detector를 구현한다.
- [ ] retry timeout과 max retry를 구현한다.
- [ ] RTT estimator를 적용한다.
- [ ] sliding window MVP를 구현한다.
- [ ] window shrink/recovery 정책을 구현한다.
- [ ] throughput 측정을 추가한다.
- [ ] retry/degraded 이벤트를 MessageBus로 publish한다.

검증:

- [ ] chunk drop fault injection
- [ ] duplicate chunk
- [ ] out-of-order chunk
- [ ] delayed ack
- [ ] selective ack 기반 재전송
- [ ] window size별 처리량 비교
- [ ] max retry exceeded
- [ ] receiver restart 또는 disconnect 후보 시나리오

완료 기준:

- 제어 가능한 손실 조건에서 재전송으로 완료 가능하다.
- 실패 시 원인이 history와 log에 남는다.

## Phase 009. 다중 파일과 1:N 전송

목표:

- 여러 파일과 여러 대상 peer를 전송 큐로 관리한다.

작업:

- [ ] parent TransferJob과 child TransferSession 모델을 확정한다.
- [ ] 다중 파일 metadata offer를 구현한다.
- [ ] 대상별 session state를 독립적으로 관리한다.
- [ ] queue concurrency limit을 설정한다.
- [ ] 파일 hash와 metadata 재사용 전략을 정한다.
- [ ] 1:N 전송 시 data port range 또는 단일 data port multiplexing 전략을 확정한다.
- [ ] peer별 실패와 성공을 분리해 집계한다.
- [ ] UI projection을 만든다.

검증:

- [ ] 여러 파일 순차 전송
- [ ] 1:N 전송 일부 성공 일부 실패
- [ ] 하나의 peer cancel이 다른 peer에 영향 없음
- [ ] queue cancel
- [ ] queue drain

완료 기준:

- 사용자가 여러 peer에게 파일 묶음을 보낼 수 있다.

## Phase 010. 수신 정책, 이력, 로그 고도화

목표:

- 수신 승인과 이력/로그를 실사용 가능하게 만든다.

작업:

- [ ] ReceivePolicy 상태 머신을 만든다.
- [ ] allowed peer 기반 자동 승인 정책을 구현한다.
- [ ] ask every time UI 흐름을 구현한다.
- [ ] transfer history 저장을 구현한다.
- [ ] 실패 reason code를 표준화한다.
- [ ] Product/Debug/Development 로그 기준을 코드에 반영한다.

검증:

- [ ] unknown peer reject
- [ ] allowed peer auto accept
- [ ] user approval accept/reject
- [ ] history persistence
- [ ] sensitive data logging 없음

완료 기준:

- 사용자는 수신 정책을 이해하고 제어할 수 있다.
- 전송 결과를 나중에 확인할 수 있다.

## Phase 011. 플랫폼 안정화와 패키징

목표:

- macOS, Windows, Linux 데스크톱에서 포트, 파일 저장, 권한, 패키징 이슈를 정리한다.

작업:

- [ ] macOS network permission 확인
- [ ] Windows firewall 안내 확인
- [ ] Linux UDP broadcast 동작 확인
- [ ] Discovery, Control, Data Port별 방화벽 안내 문구를 정리한다.
- [ ] 파일 저장 경로 정책 확인
- [ ] 한글, 공백, 긴 경로, 유니코드 파일명 전송을 검증한다.
- [ ] 앱 종료 시 소켓과 파일 핸들 정리
- [ ] release build smoke test
- [ ] 베타 체크리스트 작성

검증:

- [ ] macOS 실행 smoke
- [ ] Windows 실행 smoke
- [ ] Linux 실행 smoke
- [ ] 두 장비 간 discovery
- [ ] 두 장비 간 file transfer

완료 기준:

- 베타 배포 전 기능 검증 체크리스트가 통과한다.

## 17. 구현 순서 우선순위

가장 먼저 구현해야 하는 순서:

1. 상태 머신 foundation
2. MessageBus foundation
3. UDP 포트 모델 정리
4. Discovery Port peer 검색
5. Control Port peer link/auth
6. Data Port 단일 파일 전송
7. 재전송과 신뢰성 보강
8. 다중 파일과 1:N 전송
9. 수신 정책과 이력
10. 플랫폼 안정화

이 순서를 지켜야 하는 이유:

- 상태 머신이 먼저 있어야 절차가 흩어지지 않는다.
- MessageBus가 먼저 있어야 discovery/auth/transfer 이벤트가 같은 방식으로 전달된다.
- 포트 모델이 먼저 정리되어야 discovery/control/data 구현이 뒤섞이지 않는다.
- 인증이 먼저 완성되어야 데이터 전송을 안전하게 열 수 있다.
- 단일 파일 전송이 안정화된 뒤 다중 파일과 1:N 전송으로 확장해야 한다.

## 18. Definition of Done

각 기능은 다음 조건을 만족해야 완료로 본다.

- 상태 머신 전이가 테스트로 검증되어 있다.
- MessageBus 이벤트 발행이 필요한 경우 테스트로 검증되어 있다.
- 인증 전 접근이 차단된다.
- 실패와 취소 경로가 정의되어 있다.
- 로그에 민감 정보가 남지 않는다.
- 설정값은 부트스트랩 또는 명시적 인자로 주입된다.
- 계층 의존 방향을 위반하지 않는다.
- 관련 테스트가 통과한다.
- 사용자 화면에 성공, 진행 중, 실패 상태가 표시된다.

## 19. 주요 리스크와 대응

### 19.1 UDP 손실과 네트워크 차이

리스크:

- 네트워크 장비나 OS 설정에 따라 broadcast 수신이 제한될 수 있다.
- UDP 손실률이 높으면 전송 시간이 급격히 늘 수 있다.

대응:

- probe와 heartbeat를 분리한다.
- retry policy와 RTT estimator를 테스트 가능하게 만든다.
- Debug 로그에 포트별 수신/송신 요약을 남긴다.

### 19.2 포트 충돌

리스크:

- 동일 장비에서 여러 인스턴스를 실행하면 기본 포트가 충돌할 수 있다.

대응:

- production은 자동 우회하지 않고 명확한 오류를 보여준다.
- 테스트와 개발은 명시적 config로 포트 세트를 다르게 주입한다.

### 19.3 상태 관리 복잡도 증가

리스크:

- transfer, auth, discovery 상태가 UI와 transport에 흩어질 수 있다.

대응:

- 모든 절차는 상태 머신을 먼저 정의한다.
- UI는 projection만 본다.
- MessageBus는 이미 발생한 사실만 전달한다.

### 19.4 MessageBus 남용

리스크:

- command를 이벤트처럼 publish해 실행 경로가 숨겨질 수 있다.

대응:

- command는 controller/use case 메서드로 호출한다.
- MessageBus event 이름은 과거형 사실로 명명한다.
- 상태 전이 테스트에서 command 경로를 검증한다.

### 19.5 보안 정보 노출

리스크:

- 인증 토큰, 파일 경로, 사용자 정보가 로그나 discovery packet에 들어갈 수 있다.

대응:

- packet schema 테스트에 금지 필드 검증을 추가한다.
- logger wrapper에서 민감 정보 직접 출력 금지 기준을 둔다.
- Product 로그는 최소화한다.

## 20. 문서 업데이트 규칙

다음 변경이 있으면 `.tasks/phase002/plan.md`를 갱신한다.

- UDP 포트 역할 변경
- 패킷 schema 변경
- 상태 머신 상태 또는 전이 변경
- MessageBus 이벤트 타입 변경
- 인증 절차 변경
- 전송 reliability 정책 변경
- phase 우선순위 변경

문서와 코드가 충돌하면 코드만 고치지 말고 문서도 같이 갱신한다.
