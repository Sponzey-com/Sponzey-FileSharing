# 송수신 안정성 향상을 위한 레이어 분리 개발 계획

## 1. Project Goal

Sponzey FileSharing의 이번 개발 목표는 UDP 기반 파일 송수신을 구조적으로 안정화하는 것이다. 최종 결과는 빠른 전송 자체보다 먼저 "송신 데이터와 수신 데이터가 절대 섞이지 않고, 각 transfer session이 독립적으로 실패·재시도·완료되는 구조"다.

이번 계획의 성공 기준은 다음과 같다.

- 파일 전송의 송신 절차와 수신 절차가 별도 상태 머신과 별도 session runner로 관리된다.
- Control channel은 인증, 연결, 전송 협상, 완료, 취소만 담당한다.
- Data channel은 인증된 transfer session의 raw binary frame만 담당한다.
- UI controller는 사용자 명령과 상태 표시 projection만 담당하고 packet/frame 처리를 직접 수행하지 않는다.
- route lease, transfer session, file writer, retry timer, ACK/NACK 상태가 direction별로 독립 관리된다.
- 같은 peer와 동시에 양방향 파일 전송을 수행해도 송신 상태와 수신 상태가 서로 오염되지 않는다.
- 개발자는 task 문서 없이도 이 plan만 읽고 단계별 구현, 테스트, 리뷰 기준을 이해할 수 있다.

이번 계획의 비기능 목표는 다음과 같다.

- 로컬 네트워크 신뢰성: 모든 검증된 Ethernet 계열 route lease를 안전하게 사용한다.
- 전송 안정성: packet loss, duplicate, out-of-order, timeout, route mismatch를 명시적으로 처리한다.
- 관찰 가능성: Product, Field Debug, Development 로그를 목적별로 분리한다.
- 테스트 가능성: 외부 소켓, 파일시스템, 타이머, 플랫폼 API는 테스트 더블로 대체 가능해야 한다.
- 유지보수성: Layered Architecture, Clean Architecture, Tidy First, TDD를 계획과 구현의 기본 작업 단위로 고정한다.

## 2. Current Plan Assessment

### 2.1 기존 계획의 강점

- 송신과 수신 책임을 분리해야 한다는 핵심 방향이 맞다.
- `OutgoingTransferSessionRunner`, `IncomingTransferSessionRunner`, `TransferControlPacketDispatcher`, `TransferDataFrameDispatcher`, `TransferSessionRegistry`, `TransferRouteGuard` 같은 구조 후보가 명확하다.
- ACK/NACK, retry, window, digest, storage prepare, route mismatch를 별도 책임으로 분해하려는 방향이 적절하다.
- Product 로그에서 packet별 로그를 제거하고 Debug/Development 로그로 분리하려는 방향이 맞다.
- 같은 transfer id의 양방향 동시 전송을 명시적으로 검증하려는 목표가 있다.

### 2.2 부족한 부분

- 구현 단계가 리뷰 가능한 단위로 충분히 고정되어 있지 않다.
- 각 Phase에 목적, 범위, 변경 위치, TDD 기준, 설정 규칙, 로그 규칙, 상태 관리 기준, 검증 방법, 완료 기준이 모두 포함되어 있지 않다.
- `AGENTS.md`의 필수 원칙이 계획의 완료 게이트로 충분히 반영되어 있지 않다.
- 설정 관리와 런타임 환경 처리 방식이 별도 섹션으로 강제되어 있지 않다.
- 상태 머신의 이벤트, 실패 상태, 종료 상태, 금지 전이가 단계별로 충분히 연결되어 있지 않다.
- 의존성 방향 검증 항목이 구체적이지 않다.
- Tidy First가 "기능 변경 전 작은 정돈"으로 실행되는 방법이 단계별로 드러나지 않는다.
- 로그 정책이 어느 단계에서 어떤 로그를 추가하거나 제거해야 하는지 명확하지 않다.
- 외부 시스템 접근이 boundary layer에만 존재해야 한다는 검증 기준이 부족하다.

### 2.3 아키텍처상 위험한 부분

- 하나의 transfer controller가 packet dispatch, data frame dispatch, file I/O, retry timer, UI projection을 모두 소유하면 송신/수신 데이터 혼재가 재발한다.
- transfer id만으로 session을 찾으면 같은 peer와 양방향 전송 시 ACK와 CHUNK가 반대 방향 context로 들어갈 수 있다.
- route lease snapshot 없이 현재 peer 상태를 매번 조회하면 전송 중 active route가 바뀌어 data endpoint가 흔들릴 수 있다.
- 파일 writer와 network handler가 같은 객체에 있으면 storage failure와 network failure가 같은 failure path로 섞인다.
- Product 로그에 packet별 정보를 남기면 UDP 전송 성능과 로그 가독성이 동시에 악화된다.
- 런타임 중간에 외부 설정 파일이나 환경 값을 재조회하면 전송 session 재현성이 깨진다.

### 2.4 테스트가 어려워지는 지점

- socket, file writer, timer, progress projection이 한 controller에 있으면 단위 테스트가 통합 테스트처럼 커진다.
- ACK/NACK decision이 UI state update와 함께 있으면 상태 전이를 독립 검증하기 어렵다.
- route guard가 session runner 안에 흩어지면 route mismatch 재현 테스트가 어렵다.
- MessageBus event가 command처럼 쓰이면 테스트에서 실제 실행 경로를 추적하기 어렵다.
- 외부 환경 값이 전역 조회되면 테스트마다 독립적인 config를 주입하기 어렵다.

### 2.5 이번 업데이트에서 해결한 방향

- 계획 문서를 실행 가능한 Phase 형식으로 재구성한다.
- 각 Phase에 `Goal`, `Scope`, `Required Changes`, `Architecture Notes`, `TDD Requirements`, `Configuration Rules`, `Logging Rules`, `State Management`, `Validation`, `Done Criteria`, `Risks`를 포함한다.
- 설정, 로그, 상태 머신, 의존성 방향, 금지 패턴, 리뷰 체크리스트를 별도 섹션으로 고정한다.
- 모호한 표현을 "무엇을, 어디서, 어떤 기준으로, 어떻게 검증할지"가 드러나는 문장으로 바꾼다.

## 3. Architecture Direction

### 3.1 Layered Architecture 기준

계층 책임은 다음과 같이 고정한다.

- `domain`: transfer 상태 모델, 상태 전이 규칙, ACK/NACK range 규칙, retry decision, receive completeness decision, digest verification decision, 값 객체.
- `application`: use case, session runner, dispatcher, registry, route guard, progress aggregator, failure mapper, MessageBus event 발행.
- `infrastructure`: UDP transport, packet/frame codec, file reader/writer, digest adapter, platform storage path resolver, diagnostics exporter.
- `presentation`: drag and drop 입력, peer 선택, queue 표시, retry/cancel 호출, 오류 문구 표시.
- `core`: logger, message bus abstraction, error model처럼 계층 공통 기반.
- `app`: bootstrap, provider 조립, routing, theme처럼 조립 코드.

의존 방향은 다음을 넘지 않는다.

- `presentation -> application`
- `application -> domain`
- `infrastructure -> application interface 또는 domain`
- `app -> 모든 concrete wiring`
- `domain -> 외부 프레임워크 의존 금지`

### 3.2 Clean Architecture 경계

도메인과 애플리케이션은 외부 시스템을 직접 호출하지 않는다.

- UDP socket 접근은 infrastructure transport에만 둔다.
- 파일시스템 접근은 infrastructure file service에만 둔다.
- 플랫폼 저장 경로/권한 접근은 infrastructure platform adapter에만 둔다.
- UI widget state는 presentation에만 둔다.
- Riverpod provider 직접 참조는 app/presentation/controller 조립 경계로 제한한다.
- session runner는 필요한 dependency를 생성자 인자 또는 use case input으로 받는다.

### 3.3 목표 컴포넌트

`TransferFacadeController`:

- UI가 호출하는 얇은 facade다.
- `sendDroppedFiles`, `retryTransfer`, `cancelTransfer` 같은 사용자 명령만 받는다.
- Control packet switch와 Data frame switch를 갖지 않는다.
- Queue projection을 제공한다.

`TransferControlPacketDispatcher`:

- `ControlTransport.packets`에서 transfer control packet만 처리한다.
- 인증 packet은 auth 담당 흐름으로 넘기거나 무시한다.
- transfer packet 처리 전에 self packet, authenticated session, route lease를 검증한다.
- file chunk, file writer, retransmission window를 다루지 않는다.

`TransferDataFrameDispatcher`:

- `DataTransport.frames`에서 raw binary DataFrame만 처리한다.
- frame type에 따라 outgoing registry 또는 incoming registry를 선택한다.
- 알 수 없는 transfer id는 session을 생성하지 않고 debug decision만 기록한다.
- route mismatch는 해당 session failure event로 전달한다.

`OutgoingTransferSessionRunner`:

- 단일 송신 transfer session만 담당한다.
- file reader, send window, pending ACK, retransmission queue, RTT estimator, outgoing digest, finish handshake를 소유한다.
- receiver temp path, receive writer, incoming chunk buffer를 알지 않는다.

`IncomingTransferSessionRunner`:

- 단일 수신 transfer session만 담당한다.
- storage prepare, temp writer, received chunk set, ACK/NACK batch, incoming digest, finalize, partial cleanup을 소유한다.
- sender file reader, sender retransmission queue, pending ACK map을 알지 않는다.

`TransferSessionRegistry`:

- outgoing registry와 incoming registry를 분리한다.
- key는 `direction + transferId + peerId + authSessionId`로 구성한다.
- cleanup, lookup, duplicate registration, late packet discard를 한곳에서 처리한다.

`TransferRouteGuard`:

- session 생성 시 route lease snapshot을 검증한다.
- control endpoint와 data endpoint가 같은 검증 route에 속하는지 판단한다.
- wildcard address는 bind address로만 허용하고 remote route identity로 승격하지 않는다.
- loopback route는 같은 장비 다중 인스턴스 검증 외에는 우선 active route로 승격하지 않는다.

`TransferProgressAggregator`:

- packet별 progress update를 UI나 MessageBus로 직접 내보내지 않는다.
- bytes, speed, retry, loss, RTT, ETA를 일정 주기로 집계한다.
- Product 로그를 발생시키지 않는다.

`TransferFailureMapper`:

- 내부 reason code와 사용자 메시지를 분리한다.
- sender failure와 receiver failure를 다른 code namespace로 유지한다.
- network, route, storage, digest, cancel, timeout을 서로 다른 reason code로 표현한다.

## 4. Development Principles

### 4.1 Tidy First

각 Phase는 기능 변경 전에 작은 정돈을 먼저 수행한다.

- 이름이 모호한 값 객체, enum, method를 변경 범위 안에서 먼저 정리한다.
- 테스트 seam을 만들기 위한 interface 추출은 기능 변경보다 먼저 한다.
- unrelated cleanup은 하지 않는다.
- 한 Phase에서 public behavior 변경과 대규모 파일 이동을 동시에 하지 않는다.
- 리팩터링 commit과 기능 변경 commit을 가능한 한 분리한다.

### 4.2 TDD

런타임 동작이 바뀌는 모든 Phase는 TDD 순서를 따른다.

1. 변경할 동작을 실패하는 테스트로 표현한다.
2. 실패 원인이 계획한 behavior gap인지 확인한다.
3. 가장 작은 구현으로 테스트를 통과시킨다.
4. Tidy First 기준으로 중복과 계층 위반을 정리한다.
5. 변경 범위 테스트와 전체 관련 테스트를 다시 실행한다.

문서 변경, 주석 변경, 단순 파일 이동은 테스트 생략 가능하다. 그 외에는 domain, application, infrastructure, widget 테스트 중 최소 하나를 추가하거나 갱신한다.

### 4.3 MessageBus

MessageBus는 이미 발생한 사실만 전달한다.

- command 전달 금지.
- packet 처리 명령 전달 금지.
- 상태 전이를 암묵적으로 실행하는 event 사용 금지.
- mutable UI state payload 금지.
- payload는 불변 값 객체로 정의한다.
- event publish와 subscription lifecycle을 테스트한다.

허용 event 예:

- `TransferSessionCreated`
- `TransferSessionStateChanged`
- `TransferRouteBound`
- `TransferStoragePrepared`
- `TransferStoragePrepareFailed`
- `TransferDataStarted`
- `TransferProgressSampled`
- `TransferRetryScheduled`
- `TransferIntegrityVerified`
- `TransferIntegrityFailed`
- `TransferCompleted`
- `TransferFailed`
- `TransferCanceled`

## 5. Implementation Phases

### Phase 1. 책임 지도와 baseline gate 고정

Goal:

- 현재 파일 전송 controller의 책임을 변경 없이 분류하고, 이후 분리 작업의 baseline을 만든다.

Scope:

- 송신 처리, 수신 처리, control packet 처리, data frame 처리, file I/O, route 검증, progress projection, logging 위치를 목록화한다.
- 런타임 동작 변경은 하지 않는다.

Required Changes:

- 현재 transfer 흐름의 handler 목록을 task 문서에 기록한다.
- context map, timer, subscription, registry, lookup key, file writer, file reader 소유 위치를 기록한다.
- 기존 테스트 중 transfer 관련 baseline 테스트 목록을 확정한다.
- 누락된 baseline 테스트가 있으면 behavior 변경 없이 characterization test를 추가한다.

Architecture Notes:

- 이 Phase에서는 계층 이동을 하지 않는다.
- 새 domain model 추가가 필요하면 behavior 변경 없는 값 객체 또는 enum만 허용한다.

TDD Requirements:

- 기존에 재현된 문제를 최소 2개 characterization test로 고정한다.
- 양방향 동시 전송, unknown frame discard, route mismatch 중 최소 하나를 현재 동작 기준 테스트로 기록한다.

Configuration Rules:

- 외부 설정 파일을 추가하지 않는다.
- 테스트 config는 전역 환경 조회가 아니라 명시적 test fixture 인자로 전달한다.

Logging Rules:

- 새 Product 로그를 추가하지 않는다.
- 로그 변경이 필요하면 기존 로그 위치와 목적을 Product, Field Debug, Development로 분류만 한다.

State Management:

- 현재 boolean/flag 조합을 목록화하고, 상태 머신으로 대체해야 할 후보를 표시한다.

Validation:

- 프로젝트 표준 정적 분석을 실행한다.
- transfer 관련 기존 테스트를 실행한다.
- 문서에 책임 지도와 분리 대상이 남아 있어야 한다.

Done Criteria:

- 책임 지도 작성 완료.
- 분리할 public behavior와 보존할 public behavior가 구분됨.
- baseline test가 통과함.

Risks:

- 이 단계를 생략하면 이후 분리 작업에서 behavior 회귀를 구분할 기준이 사라진다.

### Phase 2. TransferSessionKey와 direction-aware registry 도입

Goal:

- 송신과 수신 session이 같은 transfer id를 사용해도 상태가 섞이지 않도록 key와 registry를 분리한다.

Scope:

- session key, outgoing registry, incoming registry, cleanup ownership, late packet discard.

Required Changes:

- `TransferSessionKey`를 `direction`, `transferId`, `peerId`, `authSessionId`를 포함하는 값 객체로 정의한다.
- outgoing session registry와 incoming session registry를 별도 타입으로 분리한다.
- frame lookup table은 direction을 포함하거나 frame type으로 direction을 결정한 뒤 registry를 조회한다.
- cleanup은 registry API를 통해 한 번만 수행한다.
- transfer id 단독 lookup을 제거하거나 deprecated wrapper로 격리한다.

Architecture Notes:

- key와 registry의 순수 규칙은 domain 또는 application에 둔다.
- registry는 UI state를 보관하지 않는다.
- registry는 socket, file system, platform API를 직접 호출하지 않는다.

TDD Requirements:

- 같은 transfer id로 outgoing과 incoming session을 동시에 등록하는 테스트를 먼저 작성한다.
- outgoing cleanup이 incoming session을 제거하지 않는 테스트를 작성한다.
- incoming cleanup이 outgoing session을 제거하지 않는 테스트를 작성한다.
- unknown frame이 session을 암묵적으로 생성하지 않는 테스트를 작성한다.

Configuration Rules:

- registry 동작은 외부 환경 값에 의존하지 않는다.
- timeout 값이 필요하면 constructor 인자 또는 policy 객체로 주입한다.

Logging Rules:

- duplicate registration은 Field Debug 로그로 reason code와 redacted transfer id만 남긴다.
- 정상 lookup 성공은 Product 로그를 남기지 않는다.

State Management:

- registry entry lifecycle은 `registered`, `closing`, `removed` 상태로 표현한다.
- removed entry에 late packet이 도착하면 no-op decision으로 처리하고 테스트한다.

Validation:

- registry unit test 통과.
- 양방향 동시 session 등록 application test 통과.
- 기존 transfer tests 통과.

Done Criteria:

- transfer id 단독으로 mutable session state를 찾는 production path가 제거됨.
- wrong-direction frame이 반대 registry를 수정하지 않는 테스트가 있음.

Risks:

- 기존 transfer id lookup을 한 번에 제거하면 회귀가 크다. compatibility adapter를 두고 Phase 후반에 제거한다.

### Phase 3. Control packet dispatcher 분리

Goal:

- transfer control packet 처리를 facade/controller에서 분리해 Control channel 책임을 명확히 한다.

Scope:

- `TRANSFER_INIT`, `TRANSFER_INIT_ACK`, `TRANSFER_COMPLETE`, `TRANSFER_COMPLETE_ACK`, `TRANSFER_ABORT`.

Required Changes:

- `TransferControlPacketDispatcher`를 application 계층에 추가한다.
- `ControlTransport.packets` subscription 소유권을 dispatcher 또는 coordinator로 이동한다.
- dispatcher는 packet type, self packet, auth session, route lease, transfer direction을 검증한다.
- dispatcher는 session runner에 application event를 전달하고 file I/O를 직접 수행하지 않는다.
- auth packet은 transfer dispatcher에서 처리하지 않는다.

Architecture Notes:

- packet decode는 infrastructure transport 책임이다.
- dispatcher는 decoded packet을 application event로 변환한다.
- dispatcher는 UI projection을 직접 갱신하지 않는다.
- dispatcher는 MessageBus에 command를 발행하지 않는다.

TDD Requirements:

- transfer control packet만 처리하는 테스트를 작성한다.
- auth packet이 dispatcher에서 무시되는 테스트를 작성한다.
- unauthenticated `TRANSFER_INIT`이 거부되는 테스트를 작성한다.
- stale session packet이 active session을 변경하지 않는 테스트를 작성한다.
- `TRANSFER_ABORT`가 해당 direction session만 종료하는 테스트를 작성한다.

Configuration Rules:

- dispatcher는 환경 변수를 읽지 않는다.
- auth/session/route dependency는 생성자 인자 또는 명시적 context로 받는다.

Logging Rules:

- Product: transfer control handshake 실패, abort, 완료만 세션 단위로 기록한다.
- Field Debug: packet decision summary를 `type`, `direction`, `reasonCode`, redacted ids로 기록한다.
- Development: 테스트 fixture trace에만 세부 event order를 허용한다.

State Management:

- control handshake는 sender/receiver state machine의 input event로만 반영한다.
- dispatcher 내부에 별도 boolean 플래그로 handshake 상태를 저장하지 않는다.

Validation:

- dispatcher application tests 통과.
- auth controller tests 통과.
- transfer controller compatibility tests 통과.

Done Criteria:

- facade/controller에 transfer control packet switch가 남아 있지 않음.
- Control dispatcher가 file chunk, temp writer, retransmission queue에 접근하지 않음.

Risks:

- auth packet과 transfer packet이 같은 underlying packet model을 공유하므로 type 분류 실패가 생길 수 있다. type별 test table을 만든다.

### Phase 4. Data frame dispatcher 분리

Goal:

- Data channel frame routing을 독립 dispatcher로 분리해 DATA_CHUNK와 DATA_ACK가 절대 같은 session 상태를 수정하지 않게 한다.

Scope:

- `DATA_START`, `DATA_CHUNK`, `DATA_ACK`, `DATA_NACK`, `DATA_WINDOW_UPDATE`, `DATA_FINISH`, `DATA_ABORT`.

Required Changes:

- `TransferDataFrameDispatcher`를 application 계층에 추가한다.
- `DataTransport.frames` subscription 소유권을 dispatcher 또는 coordinator로 이동한다.
- frame type으로 target registry direction을 결정한다.
- route guard를 호출해 source endpoint와 expected route를 검증한다.
- unknown transfer id는 debug decision만 남기고 폐기한다.

Architecture Notes:

- raw binary frame decode는 infrastructure codec 책임이다.
- dispatcher는 file writer와 file reader를 직접 호출하지 않는다.
- dispatcher는 packet별 MessageBus event를 발행하지 않는다.

TDD Requirements:

- `DATA_CHUNK`가 incoming session으로만 전달되는 테스트를 작성한다.
- `DATA_ACK`가 outgoing session으로만 전달되는 테스트를 작성한다.
- `DATA_NACK`가 outgoing retransmission input으로만 전달되는 테스트를 작성한다.
- `DATA_ABORT`가 direction과 session 존재 여부를 확인하는 테스트를 작성한다.
- route mismatch frame이 해당 session failure event로 전달되는 테스트를 작성한다.

Configuration Rules:

- dispatcher는 runtime environment를 읽지 않는다.
- data frame size, ACK policy 같은 값은 tuning policy 객체로 주입한다.

Logging Rules:

- Product: malformed 또는 unknown frame은 기본적으로 기록하지 않는다. session failure로 이어질 때만 warning/error를 남긴다.
- Field Debug: unknown transfer id, wrong direction, route mismatch decision을 summary로 남긴다.
- Development: frame sequence detail은 development-only logger에서만 허용한다.

State Management:

- dispatcher는 state machine을 소유하지 않고 session runner에 input event만 전달한다.
- wrong-direction input은 상태 전이 없이 reject decision으로 종료한다.

Validation:

- data dispatcher tests 통과.
- raw UDP data transport frame tests 통과.
- 양방향 동시 전송 fake transport test 통과.

Done Criteria:

- DATA_CHUNK가 outgoing context를 수정하는 production path가 없음.
- DATA_ACK가 incoming context를 수정하는 production path가 없음.
- unknown frame이 새 session을 만들지 않음.

Risks:

- 기존 compatibility `DataPacket` fallback과 raw `DataFrame` 경로가 섞일 수 있다. fallback path는 별도 adapter로 격리하고 default path가 아님을 테스트한다.

### Phase 5. OutgoingTransferSessionRunner 분리

Goal:

- 송신 세션 실행을 독립 객체로 분리해 file read, send window, ACK/NACK, retransmission, completion을 송신 전용 상태로 관리한다.

Scope:

- sender file reader, send window, pending ACK, retransmission queue, retry timer, RTT/loss estimate, finish handshake.

Required Changes:

- `OutgoingTransferSessionRunner`를 application 계층에 추가한다.
- file reader는 infrastructure interface로 주입한다.
- data sender는 `DataTransport` 추상 interface로 주입한다.
- control sender는 transfer control sender interface로 주입한다.
- retry timer는 injectable scheduler 또는 clock abstraction으로 주입한다.
- runner는 snapshot/event를 발행하고 UI state를 직접 수정하지 않는다.

Architecture Notes:

- runner는 Riverpod provider를 직접 읽지 않는다.
- runner는 file system path를 직접 검증하지 않는다. file reader adapter가 open/read failure를 반환한다.
- runner는 receiver storage path를 알지 않는다.
- runner는 route lease snapshot을 입력으로 받고 global peer 상태를 재조회하지 않는다.

TDD Requirements:

- accepted init ack 이후 data endpoint bind가 시작되는 테스트를 작성한다.
- rejected init ack 이후 data frame이 전송되지 않는 테스트를 작성한다.
- ACK 수신 시 pending chunk가 제거되는 테스트를 작성한다.
- NACK 수신 시 retransmission queue에 chunk가 추가되는 테스트를 작성한다.
- timeout 시 retry budget과 retry queue가 갱신되는 테스트를 작성한다.
- retry budget 초과 시 failed 상태로 전이되는 테스트를 작성한다.
- 모든 ACK 수신 후 finish frame/control이 전송되는 테스트를 작성한다.
- cancel 시 reader, timer, pending queue가 정리되는 테스트를 작성한다.

Configuration Rules:

- chunk size, window size, retry interval, retry limit은 constructor policy로 주입한다.
- runner가 전역 config 또는 환경 변수를 직접 조회하지 않는다.
- 테스트는 tuning policy를 명시적으로 생성해 주입한다.

Logging Rules:

- Product: session start, completed, canceled, failed만 기록한다.
- Field Debug: retry batch summary, ACK/NACK range summary, route endpoint summary를 기록한다.
- Development: chunk sequence detail은 development-only trace에서만 기록한다.

State Management:

- 송신 상태는 최소 `created`, `waitingForReceiverPrepare`, `bindingDataEndpoint`, `sendingStartFrame`, `sendingChunks`, `waitingForChunkAcks`, `sendingFinish`, `waitingForFinishAck`, `completed`, `canceling`, `canceled`, `failed`를 가진다.
- 금지 전이는 error 또는 no-op decision으로 반환하고 테스트한다.
- `completed`, `canceled`, `failed`는 종료 상태다.

Validation:

- outgoing runner unit tests 통과.
- fake transport 기반 송신 flow application test 통과.
- progress event가 packet 수보다 적게 발생하는 테스트 통과.

Done Criteria:

- 송신 file reader, pending ACK, retransmission queue가 facade/controller에 남아 있지 않음.
- 송신 runner가 수신 writer 또는 incoming buffer에 접근하지 않음.
- 송신 state machine 전이 테스트가 있음.

Risks:

- 송신 runner 분리 중 기존 UI progress가 끊길 수 있다. progress aggregator adapter를 먼저 붙이고 UI projection 변경은 별도 Phase에서 처리한다.

### Phase 6. IncomingTransferSessionRunner 분리

Goal:

- 수신 세션 실행을 독립 객체로 분리해 storage prepare, temp write, ACK/NACK, digest verification, finalize를 수신 전용 상태로 관리한다.

Scope:

- receiver storage prepare, temp writer, received chunk set, out-of-order handling, ACK/NACK batch, final digest, temp cleanup.

Required Changes:

- `IncomingTransferSessionRunner`를 application 계층에 추가한다.
- storage service와 file writer는 infrastructure interface로 주입한다.
- data ACK/NACK sender는 transport abstraction으로 주입한다.
- digest verifier는 adapter interface로 주입한다.
- 수신 준비가 완료되기 전에는 accepted init ack를 보내지 않는다.
- write failure는 receiver failure로 기록하고 sender에는 control/data failure event로 전달한다.

Architecture Notes:

- runner는 sender file reader 또는 sender retransmission queue를 알지 않는다.
- runner는 platform storage path resolver를 직접 호출하지 않고 storage prepare use case 결과를 받는다.
- runner는 UI state를 직접 수정하지 않는다.

TDD Requirements:

- storage prepare 전 accepted init ack가 전송되지 않는 테스트를 작성한다.
- storage prepare 실패 시 rejected init ack가 전송되고 data frame이 수락되지 않는 테스트를 작성한다.
- DATA_CHUNK write 성공 시 received set과 ACK batch가 갱신되는 테스트를 작성한다.
- duplicate chunk가 재저장되지 않는 테스트를 작성한다.
- out-of-order chunk가 buffer/received decision을 오염시키지 않는 테스트를 작성한다.
- digest mismatch 시 failed 상태로 전이되는 테스트를 작성한다.
- finalize 성공 시 completed 상태로 전이되는 테스트를 작성한다.
- cancel 또는 failure 시 temp file cleanup이 호출되는 테스트를 작성한다.

Configuration Rules:

- default receive directory는 bootstrap 또는 사용자 설정 repository에서 application input으로 전달한다.
- runner는 환경 변수나 외부 설정 파일을 읽지 않는다.
- overwrite policy와 temp suffix policy는 explicit policy 객체로 전달한다.

Logging Rules:

- Product: storage prepare failure, digest mismatch, finalize failure, completed만 기록한다.
- Field Debug: storage decision, ACK/NACK batch summary, out-of-order summary를 기록한다.
- Development: chunk write order detail은 development-only trace로 제한한다.

State Management:

- 수신 상태는 최소 `offered`, `preparingStorage`, `readyForData`, `receiving`, `bufferingOutOfOrder`, `verifying`, `finalizing`, `completed`, `canceling`, `canceled`, `failed`를 가진다.
- `readyForData` 이전 DATA_CHUNK는 reject 또는 buffer 금지 decision으로 처리한다.
- `completed`, `canceled`, `failed`는 종료 상태다.

Validation:

- incoming runner unit tests 통과.
- fake transport 기반 수신 flow application test 통과.
- storage permission failure injection test 통과.

Done Criteria:

- temp writer, received set, ACK batch가 facade/controller에 남아 있지 않음.
- 수신 runner가 송신 retransmission queue에 접근하지 않음.
- 수신 state machine 전이 테스트가 있음.

Risks:

- storage prepare와 init ack 순서가 바뀌면 sender가 너무 빨리 data frame을 보낼 수 있다. accepted ack 전송 조건을 테스트로 고정한다.

### Phase 7. Route guard와 endpoint snapshot 고정

Goal:

- control route, data route, active route lease가 전송 중 흔들리지 않도록 session 단위 snapshot과 검증 규칙을 고정한다.

Scope:

- route lease snapshot, data endpoint validation, wildcard bind handling, loopback handling, route expiry.

Required Changes:

- `TransferRouteGuard`를 application 계층에 추가한다.
- session 생성 시 active route lease snapshot을 필수 입력으로 받는다.
- advertised data endpoint와 observed control endpoint가 route lease와 충돌하는지 검증한다.
- wildcard local address는 bind address로만 허용한다.
- remote address가 `0.0.0.0`이면 route identity로 사용하지 않는다.
- route expiry event가 들어오면 해당 session state machine에 `RouteExpired` input을 전달한다.

Architecture Notes:

- route candidate 수집은 discovery/application 경계 책임이다.
- route guard는 socket을 열지 않는다.
- route guard는 peer repository를 직접 조회하지 않는다. 필요한 route snapshot은 input으로 받는다.

TDD Requirements:

- valid route snapshot이 data endpoint를 통과시키는 테스트를 작성한다.
- remote wildcard endpoint를 거부하는 테스트를 작성한다.
- same peer의 다른 route candidate가 active session을 오염시키지 않는 테스트를 작성한다.
- route expired input이 해당 session만 failed 또는 reconnect-needed 상태로 전이시키는 테스트를 작성한다.

Configuration Rules:

- route preference는 특정 IP 대역, VM 제품, NIC 이름에 의존하지 않는다.
- route validation policy는 constructor로 주입한다.

Logging Rules:

- Product: route mismatch로 transfer가 실패할 때 warning을 남긴다.
- Field Debug: route candidate id, active route id, local/remote address summary, reason code를 남긴다.
- Development: route scoring detail은 development-only로 제한한다.

State Management:

- route lease 상태는 `candidate`, `probing`, `verified`, `expired`, `rejected`로 표현한다.
- transfer session은 `verified` route만 시작할 수 있다.

Validation:

- route guard unit tests 통과.
- host/VM 양방향 transfer smoke에서 route summary가 일관되는지 확인한다.

Done Criteria:

- transfer 시작 path에 route lease snapshot이 필수다.
- data transfer 중 global peer route를 재조회해 endpoint를 바꾸는 production path가 없다.

Risks:

- route guard를 너무 엄격하게 만들면 정상 VM bridge route가 거부될 수 있다. route decision debug summary를 함께 기록한다.

### Phase 8. Progress aggregation, failure mapping, logging 정렬

Goal:

- 전송 성능을 해치지 않으면서 사용자가 이해할 수 있는 상태와 개발자가 추적 가능한 진단 정보를 제공한다.

Scope:

- progress aggregation, failure reason code, user message mapping, Product/Field Debug/Development log 분리.

Required Changes:

- `TransferProgressAggregator`를 application 계층에 추가한다.
- packet별 UI update를 제거하고 time-based 또는 byte-threshold snapshot으로 변경한다.
- `TransferFailureMapper`를 application 계층에 추가한다.
- failure code namespace를 sender/receiver/network/route/storage/digest/cancel/timeout으로 분리한다.
- Product 로그에서 packet별 send/receive, chunk별 ACK/NACK, chunk별 retry를 제거한다.

Architecture Notes:

- progress aggregator는 transport를 직접 호출하지 않는다.
- failure mapper는 UI widget을 알지 않는다.
- logger abstraction은 기존 `AppLogger`, `AppLogLevel`, `AppLogCategory`를 사용한다.

TDD Requirements:

- progress event가 chunk count보다 적게 발생하는 테스트를 작성한다.
- same failure code가 sender/receiver에서 다른 사용자 메시지로 변환되는 테스트를 작성한다.
- Product logger에 packet-level log가 기록되지 않는 테스트를 작성한다.
- Debug logger에 decision summary가 기록되는 테스트를 작성한다.

Configuration Rules:

- progress throttle interval은 explicit policy로 주입한다.
- logger level은 bootstrap config에서 최초 1회만 결정한다.
- 런타임 중간에 환경 변수로 logger level을 바꾸지 않는다.

Logging Rules:

- Product: session start, completed, canceled, failed, security-relevant reject만 남긴다.
- Field Debug: route decision, state transition summary, retry summary, ACK/NACK range summary를 남긴다.
- Development: frame sequence detail, benchmark sample, fake transport trace를 development mode에서만 남긴다.

State Management:

- progress snapshot은 session state의 derived value로 취급한다.
- progress update가 state transition을 발생시키지 않는다.

Validation:

- logging tests 통과.
- progress aggregation tests 통과.
- transfer smoke 중 로그 크기가 packet 수에 선형 증가하지 않는지 확인한다.

Done Criteria:

- Product/info level에 packet별 로그가 없음.
- failure reason code와 사용자 메시지가 분리됨.
- UI progress update가 packet별로 발생하지 않음.

Risks:

- 로그를 줄이다가 현장 진단력이 낮아질 수 있다. Field Debug decision summary는 session 단위로 충분히 남긴다.

### Phase 9. Facade controller 축소와 UI 명령 경계 정리

Goal:

- UI controller를 사용자 명령 진입점과 queue projection 전용으로 축소한다.

Scope:

- drag and drop, retry, cancel, selected peer, transfer queue projection, duplicate submission guard.

Required Changes:

- facade는 `sendDroppedFiles`, `retryTransfer`, `cancelTransfer`, `selectPeer` 같은 명령만 노출한다.
- packet/frame subscription을 dispatcher/coordinator로 이동한다.
- drag/drop 즉시 전송은 중복 이벤트 방지 key를 사용한다.
- retry는 새 session을 만들기 전에 이전 terminal state를 검증한다.
- cancel은 해당 session runner에 cancel input을 전달한다.
- UI는 failure code를 직접 해석하지 않고 mapped message만 표시한다.

Architecture Notes:

- presentation은 application facade만 호출한다.
- UI widget은 transport, registry, runner, file writer를 직접 알지 않는다.
- projection model은 application에서 만들고 presentation은 표시만 한다.

TDD Requirements:

- drag/drop 이벤트가 transfer command를 한 번만 발생시키는 widget/application test를 작성한다.
- 같은 파일이 빠르게 여러 번 drop되어도 duplicate guard가 동작하는 테스트를 작성한다.
- retry가 terminal failed/canceled state에서만 허용되는 테스트를 작성한다.
- cancel이 해당 session direction만 취소하는 테스트를 작성한다.
- 송신 card와 수신 card가 다른 direction label을 갖는 테스트를 작성한다.

Configuration Rules:

- UI에서 환경 변수나 외부 설정 파일을 읽지 않는다.
- 사용자 설정 값은 repository/use case를 통해 application input으로 전달한다.

Logging Rules:

- Product: 사용자 cancel과 retry 시작만 세션 단위로 기록한다.
- Field Debug: duplicate drop suppressed decision을 summary로 기록한다.
- Development: widget event trace는 development-only로 제한한다.

State Management:

- UI state는 transfer state machine의 projection이다.
- UI local boolean으로 network/transfer 절차 상태를 새로 만들지 않는다.

Validation:

- widget tests 통과.
- 기존 로그인/peer/transfer 화면 smoke 통과.
- macOS 클릭/포커스 회귀가 없는지 수동 확인한다.

Done Criteria:

- facade/controller에 packet/frame switch가 없음.
- UI가 transport 또는 session registry를 직접 참조하지 않음.
- drag/drop 중복 전송 방지 테스트가 있음.

Risks:

- facade 축소 중 presentation provider wiring이 깨질 수 있다. app composition 변경은 별도 작은 patch로 묶는다.

### Phase 10. End-to-end smoke, benchmark, release gate 정리

Goal:

- 구조 분리 후 실제 송수신 안정성과 성능을 재현 가능한 검증 절차로 고정한다.

Scope:

- local two-instance smoke, host/VM bidirectional transfer, storage failure injection, benchmark result, release checklist.

Required Changes:

- local fake/in-process smoke와 실제 UDP smoke를 분리한다.
- host -> VM, VM -> host 양방향 전송 checklist를 작성한다.
- transfer 완료 기준에 receiver file digest verification을 포함한다.
- benchmark 결과에는 route type, OS, build mode, file size, average speed, retry count, loss, RTT를 기록한다.
- release gate 문서에 실패 시 필요한 diagnostics artifact를 정의한다.

Architecture Notes:

- smoke script는 application behavior를 검증하되 production code에 테스트용 branch를 넣지 않는다.
- benchmark를 위해 runtime 중간 환경값을 삽입하지 않는다.
- 필요한 test-only dependency는 test harness에만 둔다.

TDD Requirements:

- benchmark 자체는 단위 테스트가 아니라 smoke 기준으로 관리한다.
- smoke에서 실패한 bug는 다음 수정 전에 deterministic test로 축소한다.
- 양방향 동시 전송 regression test를 전체 test suite에 포함한다.

Configuration Rules:

- smoke config는 프로세스 시작 인자로 전달한다.
- 실행 중 환경 변수 재조회, 외부 설정 파일 reload, mutable singleton patching을 금지한다.

Logging Rules:

- Product smoke는 Product 로그만으로 사용자 영향 이벤트를 확인한다.
- Field Debug smoke는 route/session/decision summary를 artifact로 저장한다.
- Development benchmark는 packet detail 없이 aggregate sample만 기록한다.

State Management:

- smoke는 sender/receiver terminal state가 `completed`인지 검증한다.
- 실패 smoke는 `failed`, `canceled`, `timeout`, `routeMismatch`, `storageFailure` 중 하나의 명시 상태로 끝나야 한다.

Validation:

- 프로젝트 표준 정적 분석 통과.
- 전체 테스트 통과.
- 같은 장비 두 인스턴스 양방향 전송 성공.
- macOS host와 Parallels Windows VM 양방향 전송 성공.
- receiver digest와 sender digest 일치.
- retry/cancel/manual failure smoke 결과 기록.

Done Criteria:

- release gate 체크리스트가 문서화됨.
- 양방향 전송 smoke 결과가 기록됨.
- benchmark 기준값이 기록됨.
- 실패 시 필요한 diagnostics artifact 위치가 문서화됨.

Risks:

- VM/network 환경은 자동화가 제한될 수 있다. 자동화 가능한 부분과 수동 gate를 분리해 기록한다.

## 6. TDD Strategy

### 6.1 테스트 계층

Domain tests:

- 상태 머신 허용 전이와 금지 전이를 검증한다.
- ACK/NACK range, retry decision, window advance, duplicate/out-of-order decision을 순수 함수로 검증한다.
- 도메인 테스트는 외부 프레임워크, 파일시스템, 네트워크, UI를 사용하지 않는다.

Application tests:

- dispatcher, registry, session runner, route guard, progress aggregator, failure mapper를 fake dependency로 검증한다.
- use case는 명시적 input과 output을 가진다.
- MessageBus publish는 이미 발생한 사실만 전달하는지 검증한다.

Infrastructure tests:

- UDP transport, packet codec, data frame codec, file reader/writer, storage path resolver를 검증한다.
- 외부 의존성은 test double 또는 임시 디렉터리로 대체한다.
- malformed packet, bind failure, partial send, storage permission failure를 검증한다.

Presentation tests:

- UI는 application projection을 표시하고 command를 호출하는지만 검증한다.
- UI가 protocol decision이나 route decision을 수행하지 않는지 검증한다.

### 6.2 필수 regression tests

- 같은 transfer id의 outgoing/incoming session 동시 존재.
- DATA_CHUNK wrong-direction reject.
- DATA_ACK wrong-direction reject.
- storage prepare 실패 시 sender data frame 미전송.
- route mismatch 시 해당 transfer만 실패.
- abort가 반대 방향 transfer를 종료하지 않음.
- duplicate drop이 중복 transfer를 만들지 않음.
- Product logger에 packet-level 로그가 남지 않음.
- bootstrap 이후 외부 환경 값 재조회 없음.

## 7. Configuration and Runtime Environment Policy

설정 정책은 `AGENTS.md`를 우선한다.

- 새 YAML, JSON, dotenv, 임의 설정 파일을 추가하지 않는다.
- 외부 환경 상수는 bootstrap 시점에 최초 1회만 수신한다.
- 프로세스 시작 이후 전역 환경 변수, 외부 설정 파일, mutable singleton을 다시 읽지 않는다.
- 런타임 중간에 환경 설정 값을 삽입하거나 변경하는 방식을 거부한다.
- bootstrap 이후 필요한 값은 명시적 인자, 생성자 인자, context 객체, provider override, use case input으로 전달한다.
- 테스트는 환경을 숨겨 바꾸지 않고 필요한 값을 fixture로 직접 주입한다.
- tuning 값은 전역 상수가 아니라 `TransferTuningPolicy` 같은 불변 policy 객체로 전달한다.
- logger level은 bootstrap config에서 결정하고 session runner가 직접 환경을 읽지 않는다.
- storage path는 user setting repository 또는 bootstrap context를 통해 application에 전달한다.

검증 기준:

- 외부 환경 값이 프로그램 시작 이후 암묵적으로 재조회되지 않는다.
- 설정 값이 프로세스 중간에 삽입되거나 변경되지 않는다.
- use case와 session runner가 config를 전역 조회하지 않는다.
- 테스트 더블로 config와 policy를 대체할 수 있다.

## 8. Logging Strategy

### 8.1 Product Log

목적:

- 사용자 영향이 있는 시작, 실패, 복구, 보안상 중요한 이벤트만 기록한다.

허용:

- transfer session 시작.
- transfer 완료.
- transfer 취소.
- storage prepare 실패.
- route mismatch failure.
- digest mismatch failure.
- 인증되지 않은 transfer request reject.
- 복구 불가능 socket/file error.

금지:

- packet별 send/receive.
- chunk별 ACK/NACK.
- chunk별 retry.
- 파일 원문 경로.
- password, token, session key.
- frame payload.

### 8.2 Field Debug Log

목적:

- 배포 후 현장 문제 재현과 상태 확인에 필요한 decision summary를 기록한다.

허용:

- control packet decision summary.
- data frame decision summary.
- route guard decision.
- state transition summary.
- retry batch summary.
- ACK/NACK range summary.
- storage prepare result.
- duplicate drop suppressed decision.

제한:

- 민감정보는 redacted 값으로만 남긴다.
- 전체 파일 경로 대신 safe display path 또는 path category만 남긴다.

### 8.3 Development Log

목적:

- 개발과 테스트 중 내부 상태 전이를 확인한다.

허용:

- frame sequence detail.
- tuning value detail.
- benchmark aggregate sample.
- fake transport trace.
- state machine transition trace.

제한:

- 프로덕션 기본 동작에 포함하지 않는다.
- payload 원문, token, password, session key, 전체 파일 경로를 남기지 않는다.

## 9. State Machine Strategy

복잡한 내부 절차는 상태 머신으로 관리한다.

### 9.1 Sender state machine

상태:

- `created`
- `waitingForReceiverPrepare`
- `bindingDataEndpoint`
- `sendingStartFrame`
- `sendingChunks`
- `waitingForChunkAcks`
- `sendingFinish`
- `waitingForFinishAck`
- `completed`
- `canceling`
- `canceled`
- `failed`

입력 이벤트:

- `TransferInitAckAccepted`
- `TransferInitAckRejected`
- `DataAckReceived`
- `DataNackReceived`
- `DataWindowUpdateReceived`
- `FinishAckReceived`
- `RouteExpired`
- `SendFrameFailed`
- `TimeoutElapsed`
- `CancelRequested`

종료 상태:

- `completed`
- `canceled`
- `failed`

금지:

- `created -> sendingChunks`
- `sendingChunks -> completed`
- `failed -> sendingChunks`
- `completed -> failed`
- `canceled -> completed`

### 9.2 Receiver state machine

상태:

- `offered`
- `preparingStorage`
- `readyForData`
- `receiving`
- `bufferingOutOfOrder`
- `verifying`
- `finalizing`
- `completed`
- `canceling`
- `canceled`
- `failed`

입력 이벤트:

- `TransferInitReceived`
- `StoragePrepared`
- `StoragePrepareFailed`
- `DataStartReceived`
- `DataChunkReceived`
- `DataFinishReceived`
- `DataAbortReceived`
- `FileWriteFailed`
- `DigestVerified`
- `DigestMismatch`
- `TimeoutElapsed`
- `CancelRequested`

종료 상태:

- `completed`
- `canceled`
- `failed`

금지:

- `offered -> receiving`
- `preparingStorage -> receiving`
- `readyForData -> completed`
- `failed -> finalizing`
- `completed -> receiving`

### 9.3 Route lease state machine

상태:

- `candidate`
- `probing`
- `verified`
- `expired`
- `rejected`

규칙:

- transfer session은 `verified` route lease만 사용할 수 있다.
- `expired` route는 기존 active session에 `RouteExpired` input을 전달한다.
- `rejected` route는 자동 재시도 대상이 아니다.
- route candidate는 peer identity가 아니다.

## 10. Dependency and Boundary Rules

### 10.1 허용 의존성

- presentation은 application facade와 projection만 사용한다.
- application은 domain model과 interface만 사용한다.
- infrastructure는 application interface를 구현하거나 domain value object를 사용한다.
- app은 concrete dependency wiring을 담당한다.

### 10.2 금지 의존성

- domain에서 Flutter, Riverpod, UDP socket, file system, platform API 사용 금지.
- application session runner에서 provider/global singleton 직접 조회 금지.
- presentation에서 UDP transport, file writer, registry 직접 접근 금지.
- infrastructure에서 UI projection 생성 금지.
- MessageBus를 command bus처럼 사용하는 패턴 금지.

### 10.3 경계 검증

- 도메인 계층이 외부 프레임워크에 의존하지 않는지 확인한다.
- 유스케이스가 명시적 입력과 출력을 가지는지 확인한다.
- 외부 API, DB, 파일시스템, 네트워크 접근이 boundary 계층에만 존재하는지 확인한다.
- 테스트 더블로 외부 의존성을 대체할 수 있는지 확인한다.
- 리팩터링과 기능 변경이 가능한 한 분리되어 있는지 확인한다.

## 11. Risk and Mitigation

R1. 큰 리팩터링 중 회귀:

- mitigation: Phase별로 behavior-preserving refactor와 behavior change를 분리한다.
- validation: 각 Phase 종료 시 관련 테스트와 전체 transfer regression test를 실행한다.

R2. 송신/수신 데이터 혼재 재발:

- mitigation: direction-aware key와 별도 registry를 타입 수준에서 강제한다.
- validation: wrong-direction ACK/CHUNK 테스트를 필수로 둔다.

R3. 실제 UDP 환경 문제를 테스트가 못 잡음:

- mitigation: fake transport deterministic test와 실제 host/VM smoke를 분리한다.
- validation: release gate에 양방향 host/VM 전송과 receiver digest 검증을 포함한다.

R4. 로그 축소로 진단력 저하:

- mitigation: Product 로그는 줄이고 Field Debug decision summary를 구조화한다.
- validation: 실패 smoke에서 route/session/failure reason을 로그로 추적할 수 있어야 한다.

R5. 설정 관리 위반:

- mitigation: bootstrap 이후 환경 재조회 금지, policy 객체 주입, test fixture 주입을 리뷰 체크리스트에 넣는다.
- validation: use case/session runner에서 환경 조회 코드가 없는지 리뷰한다.

R6. 성능 저하:

- mitigation: packet별 UI update, packet별 MessageBus event, packet별 Product log를 금지한다.
- validation: progress throttle test와 benchmark smoke를 수행한다.

R7. 상태 플래그 증가:

- mitigation: 2단계 이상 절차는 상태 머신 후보로 보고 enum/sealed state로 표현한다.
- validation: boolean 조합으로 transfer 절차를 표현하는 새 코드를 리뷰에서 거부한다.

## 12. Review Checklist

Architecture:

- [ ] domain이 외부 프레임워크, 파일시스템, 네트워크, 플랫폼 API에 의존하지 않는다.
- [ ] application use case와 session runner는 명시적 입력과 출력을 가진다.
- [ ] infrastructure 접근은 interface 뒤에 숨겨져 있고 테스트 더블로 대체 가능하다.
- [ ] UI는 application facade와 projection만 사용한다.
- [ ] MessageBus가 command path로 사용되지 않는다.

Configuration:

- [ ] 새 외부 설정 파일이 추가되지 않았다.
- [ ] 외부 환경 상수는 bootstrap 시점에만 수신된다.
- [ ] 프로세스 중간 환경 설정 삽입 또는 변경이 없다.
- [ ] session runner와 use case가 전역 환경 값을 재조회하지 않는다.
- [ ] 테스트는 config와 policy를 명시적으로 주입한다.

Logging:

- [ ] Product 로그에 packet별 send/receive가 없다.
- [ ] Field Debug 로그는 decision summary 중심이다.
- [ ] Development 로그가 프로덕션 기본 동작에 포함되지 않는다.
- [ ] password, token, session key, payload, 전체 파일 경로가 로그에 없다.

State Machine:

- [ ] 송신/수신/route 절차가 명시 상태와 이벤트로 표현된다.
- [ ] 금지 전이가 테스트로 고정되어 있다.
- [ ] 종료 상태 이후 late packet이 no-op 또는 reject로 처리된다.
- [ ] UI boolean 조합으로 protocol state를 만들지 않는다.

Testing:

- [ ] 실패 테스트를 먼저 작성했다.
- [ ] 리팩터링과 기능 변경 테스트가 분리되어 있다.
- [ ] wrong-direction frame 테스트가 있다.
- [ ] route mismatch 테스트가 있다.
- [ ] storage failure 테스트가 있다.
- [ ] 양방향 동시 전송 테스트가 있다.

## 13. Definition of Done

이번 plan의 완료 조건은 다음과 같다.

- `TransferFacadeController`가 packet/frame switch를 직접 갖지 않는다.
- `TransferControlPacketDispatcher`와 `TransferDataFrameDispatcher`가 application 계층에 존재하고 테스트된다.
- `OutgoingTransferSessionRunner`와 `IncomingTransferSessionRunner`가 별도 상태 머신과 별도 테스트를 가진다.
- outgoing registry와 incoming registry가 분리된다.
- `TransferSessionKey`에 direction이 포함된다.
- DATA_CHUNK는 incoming session만 변경한다.
- DATA_ACK와 DATA_NACK는 outgoing session만 변경한다.
- storage prepare 실패 시 sender가 data frame을 보내지 않는다.
- route mismatch는 해당 transfer만 실패시킨다.
- abort는 반대 방향 동시 transfer를 종료하지 않는다.
- Product 로그에 packet별 로그가 없다.
- Development 로그가 프로덕션 기본 동작에 포함되지 않는다.
- 외부 환경 값은 bootstrap 이후 재조회되지 않는다.
- 외부 API, DB, 파일시스템, 네트워크 접근은 boundary 계층에만 존재한다.
- 프로젝트 표준 정적 분석이 통과한다.
- 전체 테스트가 통과한다.
- 같은 장비 두 인스턴스 양방향 전송 smoke가 통과한다.
- macOS host와 Parallels Windows VM 양방향 전송 smoke 결과가 기록된다.

## 14. Prohibited Implementation Patterns

다음 구현은 리뷰에서 거부한다.

- 송신과 수신 session을 같은 mutable map에 direction 없이 저장한다.
- transfer id 단독으로 session을 조회한다.
- DATA_CHUNK가 sender pending ACK map을 수정한다.
- DATA_ACK가 receiver received chunk set을 수정한다.
- 알 수 없는 data frame이 새 session을 암묵적으로 생성한다.
- Control channel에 대량 file chunk를 싣는다.
- Discovery packet에 JWT, session key, raw password, reusable verifier를 싣는다.
- session runner가 Riverpod provider, global singleton, environment variable을 직접 읽는다.
- 런타임 중간에 설정 파일을 reload한다.
- 런타임 중간에 환경 변수를 다시 읽어 동작을 바꾼다.
- packet별 Product 로그 또는 packet별 MessageBus event를 생성한다.
- chunk별 file open/flush/close를 기본 구현으로 둔다.
- UI widget에서 protocol state transition을 결정한다.
- boolean flag 조합으로 transfer 절차를 관리한다.
- route candidate를 검증 없이 active route lease처럼 사용한다.
- 특정 IP 대역, VM 제품, NIC 이름을 기준으로 route 우선순위를 하드코딩한다.

## 15. Next Actions

다음 작업은 `.tasks/task001.md`부터 상세 태스크로 분리한다. 각 task는 기능 2~3개, 테스트, 검증, 체크박스를 포함해야 한다.

권장 task 분할:

- `task001.md`: 책임 지도, baseline characterization tests, session key 설계.
- `task002.md`: direction-aware outgoing/incoming registry 분리.
- `task003.md`: control packet dispatcher 분리.
- `task004.md`: data frame dispatcher 분리.
- `task005.md`: outgoing transfer session runner 분리.
- `task006.md`: incoming transfer session runner 분리.
- `task007.md`: route guard와 route lease snapshot 고정.
- `task008.md`: progress aggregator, failure mapper, 로그 정책 적용.
- `task009.md`: facade controller 축소와 UI command boundary 정리.
- `task010.md`: state machine 금지 전이, late packet, cleanup regression 보강.
- `task011.md`: 양방향 smoke, benchmark, release gate 정리.

각 task 작성 형식:

- Goal
- Scope
- Required Changes
- Architecture Notes
- TDD Requirements
- Configuration Rules
- Logging Rules
- State Management
- Validation
- Done Criteria
- Risks
- Progress Checklist
