# 고속 UDP Data Channel 전환 개발 계획

## 0. 문서 상태

이 문서는 현재 구현 상태를 기준으로 한 다음 우선순위 계획이다.

기존 `.tasks/phase004/plan.md`는 peer 연결과 멀티 Ethernet active path 안정화를 1차 목표로 둔다. 해당 목표는 유지한다. 다만 현재 제품에서 사용자가 체감하는 가장 큰 문제는 파일 전송이 Control/Auth 채널 위의 JSON/base64 chunk로 동작해 UDP임에도 매우 느리다는 점이다.

따라서 이 문서는 `phase004` 이후의 후속 범위를 현재 실행 계획으로 끌어올려, 파일 chunk 전송을 Data Port 전용 고속 UDP 채널로 전환하는 계획을 정의한다.

이 문서의 기준은 다음과 같다.

- AGENTS.md의 Layered Architecture, Clean Architecture, Tidy First, TDD, 상태 머신, MessageBus 원칙을 반드시 따른다.
- Discovery, Control, Data 채널 책임을 섞지 않는다.
- UDP를 사용한다는 사실만으로 빠르지 않다. 빠른 UDP 전송은 binary payload, 큰 in-flight window, batch ACK, 낮은 per-packet CPU/I/O 비용, 명시적 재전송 정책이 같이 있어야 한다.
- 외부 설정 파일을 늘리지 않는다. 필요한 값은 `AppConfig`, 생성자 인자, provider override, 유스케이스 입력값으로 전달한다.
- macOS, Windows, Ubuntu 22.04 LTS 이상 Linux에서 같은 구조로 동작해야 한다.
- 대용량 전송 성능은 네트워크 코드만의 문제가 아니다. hash 선계산, per-packet 로그, socket bind/close 반복, UI state 과다 갱신, writer flush 남발도 같은 수준의 병목으로 취급한다.

## 1. 현재 문제 진단

### 1.1 현재 전송 경로

현재 `TransferController`는 파일 chunk를 `AuthPacketType.transferChunk`로 만들어 `ControlTransport`를 통해 보낸다.

현재 흐름은 다음과 같다.

1. Discovery로 peer를 찾는다.
2. Control/Auth handshake로 같은 ID/PW 기반 인증을 완료한다.
3. `TRANSFER_INIT`을 Control 채널로 보낸다.
4. 수신 측이 `TRANSFER_INIT_ACK`를 Control 채널로 보낸다.
5. 송신 측이 파일 chunk를 `TRANSFER_CHUNK` AuthPacket에 base64 문자열로 넣어 Control 채널로 보낸다.
6. 수신 측은 `TRANSFER_CHUNK_ACK`, `TRANSFER_WINDOW_UPDATE`, `TRANSFER_COMPLETE_ACK`를 Control 채널로 보낸다.

이 구조는 기능 검증에는 유리하지만, 실제 파일 전송 성능에는 맞지 않는다.

### 1.2 느린 원인

현재 구조의 핵심 병목은 다음과 같다.

- Control/Auth 채널에 대량 파일 payload가 흐른다.
- chunk payload가 raw bytes가 아니라 base64 문자열이다.
- packet 전체가 JSON encode/decode된다.
- MTU 회피 때문에 chunk 크기가 작아졌다.
- chunk 수가 많아져 ACK, WindowUpdate, 재전송 timer, 로그, UI state update 비용이 커진다.
- per-packet 로그가 product/info 레벨로 남으면 파일 I/O와 문자열 처리 비용이 전송 루프를 압박한다.
- 수신과 송신 파일 I/O는 최근 reader/writer 유지로 개선했지만, 아직 네트워크 payload 구조 자체가 느리다.
- `DataTransport`와 `RawUdpDataTransport`는 존재하지만 `TransferController`의 실제 chunk 송수신 경로에 연결되어 있지 않다.
- 기존 `DataPacket`도 JSON/base64 구조라 그대로 사용하면 Control 채널 분리는 되지만 “고속” 요구를 만족하기 어렵다.

### 1.3 잘못된 방향

다음 접근은 금지한다.

- Data Port로 옮기되 기존 JSON/base64 `DataPacket`을 그대로 대량 chunk 전송에 사용하는 방식
- UDP socket만 바꾸고 chunk 크기, ACK 정책, window 정책, 로그 정책을 그대로 두는 방식
- OS 환경 변수나 외부 설정 파일로 chunk/window 값을 런타임 중간에 바꾸는 방식
- per-packet product log 또는 per-packet MessageBus event를 유지하는 방식
- per-packet 파일 open/close, socket open/close, isolate spawn을 전송 루프에 넣는 방식
- 인증되지 않은 peer가 Data channel chunk를 넣을 수 있게 두는 방식
- selected active path를 무시하고 `0.0.0.0` 또는 임의 endpoint로만 전송하는 방식
- 속도 문제를 무조건 chunk size 증가만으로 해결하려는 방식
- 전송 시작 전에 전체 파일을 반드시 한 번 더 읽어 hash를 선계산하는 방식

## 2. 목표

### 2.1 제품 목표

같은 로컬 네트워크의 인증된 peer 간 파일 전송은 Data Port 전용 UDP 채널로 수행한다.

사용자가 기대하는 동작은 다음과 같다.

- 파일을 보내면 Control/Auth 절차는 짧게 끝나고 실제 파일 byte는 Data Port로 흐른다.
- 수신 노드는 승인 대기 없이 인증된 peer의 파일을 기본 저장 경로에 저장한다.
- 같은 peer의 active path가 있으면 해당 interface의 local address와 remote data endpoint를 사용한다.
- Ethernet, USB Ethernet, Thunderbolt Ethernet, 내부 bridge, VM bridge 같은 연결 가능한 경로에서 동작한다.
- 전송 상태는 빠르게 갱신되지만 UI와 로그가 전송 속도를 떨어뜨리지 않는다.
- 손실, 중복, 순서 뒤섞임, 재전송, timeout이 상태 머신과 테스트로 고정된다.
- 전송 시작 전 준비 시간이 파일 크기에 비례해 길어지지 않는다. 큰 파일도 metadata 협상 후 곧바로 streaming read/send를 시작한다.

### 2.2 성능 목표

성능 목표는 기능 완료 기준에 포함한다.

- 1차 목표: JSON/base64 Control 전송 대비 체감 속도를 명확히 개선한다.
- 2차 목표: 같은 장비 또는 VM bridge 환경에서 수 MB/s 이상을 안정적으로 달성한다.
- 3차 목표: 실제 유선 LAN에서 release build 기준 20 MB/s 이상을 목표로 한다.
- 장기 목표: OS와 NIC 상태가 허용하는 범위에서 50 MB/s 이상을 목표로 한다.

테스트 환경마다 물리 네트워크, VM bridge, 방화벽, 백신, OS socket buffer가 다르므로 절대 속도는 수동 benchmark로 기록한다. 자동 테스트는 real network throughput 대신 packet size, ACK 빈도, chunk 경로 분리, 재전송 correctness, event/log 제한을 검증한다.

### 2.3 구조 목표

채널 책임은 다음처럼 분리한다.

- Discovery: peer 검색, presence, non-auth discovery group tag
- Control: 인증, 전송 협상, data endpoint 교환, 전송 취소, 완료 요약
- Data: 인증된 transfer session의 file chunk, data ACK, data NACK, data window update, data finish

Control 채널은 대량 chunk를 절대 싣지 않는다. 기존 `TRANSFER_CHUNK`, `TRANSFER_CHUNK_ACK`, `TRANSFER_CHUNK_NACK`, `TRANSFER_WINDOW_UPDATE`는 호환 기간 이후 제거하거나 legacy fallback으로만 둔다.

### 2.4 명시적 비목표

이번 전환의 목적은 먼저 “빠른 UDP Data Channel”을 제품 기본 경로로 만드는 것이다. 다음 항목은 설계에서 막지 않되, 1차 완료 범위에 넣지 않는다.

- WAN/NAT traversal
- 외부 relay 서버
- 사용자 승인 기반 수신 workflow
- file payload encryption 전체 구현
- jumbo frame 전용 최적화
- OS별 커널 socket buffer 튜닝 자동화
- 전송 중 런타임 외부 설정 reload

## 3. 아키텍처 방향

### 3.1 계층별 책임

`domain`:

- transfer session state machine
- reliability model
- chunk window model
- ACK/NACK/SACK rule
- retry policy
- flow control decision
- performance budget value object
- protocol version and capability value object
- transfer integrity policy

`application`:

- `TransferController` 또는 후속 `TransferSessionController`
- transfer use case orchestration
- Control negotiation 후 Data session 시작
- MessageBus event publish
- UI projection용 state 생성
- active path와 data endpoint 선택
- transfer data auth context lifecycle
- data endpoint lease orchestration
- diagnostics ring buffer snapshot orchestration

`infrastructure`:

- `RawUdpDataTransport`
- binary data frame codec
- UDP socket bind/send/receive
- file reader/writer implementation
- platform-specific bind policy
- benchmark/smoke helper
- data socket lease implementation
- data session dispatcher implementation
- streaming digest implementation

`presentation`:

- 사용자에게 전송 상태, 속도, 실패 원인, 재시도 가능 여부 표시
- debug diagnostics에서는 data endpoint와 path 상태 표시
- raw packet 또는 민감 값 노출 금지

의존성 규칙:

- `DataFrameCodec`은 infrastructure 구현이지만, frame field 의미와 state transition rule은 domain/application 테스트로 고정한다.
- socket, file, timer, hash 구현체는 domain에 들어가지 않는다.
- UI는 data transport 구현체를 직접 호출하지 않고 application controller 상태와 command만 사용한다.
- protocol capability와 version 판단은 문자열 분기보다 명시적 값 객체로 다룬다.

### 3.2 상태 머신

Data channel 전송은 명시적 상태 머신으로 관리한다.

송신 상태:

- `idle`
- `preparingFile`
- `controlNegotiating`
- `bindingDataPort`
- `dataStarting`
- `sending`
- `draining`
- `finishing`
- `completed`
- `failed`
- `cancelled`

수신 상태:

- `idle`
- `controlAccepted`
- `bindingDataPort`
- `waitingDataStart`
- `receiving`
- `verifying`
- `finalizing`
- `completed`
- `failed`
- `cancelled`

허용되지 않는 전이는 테스트로 막는다.

예시는 다음과 같다.

- `sending` 전에는 `DATA_CHUNK`를 보내면 안 된다.
- `waitingDataStart` 전에는 파일 writer에 chunk를 쓰면 안 된다.
- `verifying` 이후에는 새 chunk를 받으면 duplicate 또는 late packet으로 처리한다.
- `failed` 이후 수신한 ACK/NACK/chunk는 상태를 되살리지 않는다.

### 3.3 MessageBus 이벤트

MessageBus는 명령 실행 경로가 아니다. 이미 발생한 사실만 publish한다.

필요 이벤트:

- `transferDataPortBound`
- `transferDataSessionStarted`
- `transferDataProgressUpdated`
- `transferDataWindowChanged`
- `transferDataLossDetected`
- `transferDataRetransmissionQueued`
- `transferDataPathFailed`
- `transferDataPathFailoverRequested`
- `transferDataCompleted`
- `transferDataFailed`

금지 이벤트:

- per-packet `DATA_CHUNK_RECEIVED`
- per-packet `DATA_CHUNK_SENT`
- 전체 file path, token, password, session key가 포함된 event

Progress event는 최소 200ms 이상 throttle하거나 byte delta 기준으로 aggregate한다.

## 4. Data Channel Protocol

### 4.1 Control 협상

Control 채널은 전송 시작 전에 data endpoint를 협상한다.

Control `TRANSFER_INIT` 필드:

- protocolVersion
- transferId
- fileName
- fileSize
- optional initial fingerprint, 빠른 중복 감지용이며 무결성 필수값이 아님
- chunkSize proposal
- chunkCount proposal
- selectedPathId
- senderDataEndpoint 후보
- capabilities
- sentAt

Control `TRANSFER_INIT_ACK` 필드:

- accepted
- receiverDataEndpoint
- receiverDataPortLeaseId
- acceptedChunkSize
- acceptedWindowSize
- receiverBufferBudget
- transferSessionId
- transferKeyId 또는 dataAuthContext id
- save policy summary
- reject reason

Control 협상 규칙:

- 파일 chunk 자체는 Control packet에 넣지 않는다.
- receiver가 data port bind에 실패하면 `TRANSFER_INIT_ACK accepted=false`와 reason code를 보낸다.
- receiver는 `AppConfig.dataPortRange` 안에서만 data port를 bind한다.
- sender는 receiver data endpoint를 받은 뒤 `DATA_START`를 보낸다.
- negotiation timeout과 data start timeout은 다른 reason code로 구분한다.
- `TRANSFER_INIT`은 대용량 파일을 미리 모두 읽어야만 만들 수 있는 필드를 필수로 요구하지 않는다.
- 최종 무결성 digest는 sender가 파일을 streaming read하면서 계산하고 `DATA_FINISH`에 포함한다.
- receiver는 writer에 append하면서 동일하게 streaming digest를 계산하고 `DATA_FINISH`의 digest와 비교한다.
- 보안 정책상 전송 시작 전에 hash가 꼭 필요한 모드가 생기면 별도 capability로 분리한다. 기본 고속 경로에 선계산을 넣지 않는다.

### 4.2 Binary Data Frame

고속 전송용 file chunk는 JSON이 아니라 binary frame으로 encode한다.

기존 `DataPacket`은 초기 설계와 테스트 자산으로 남길 수 있지만, 대량 chunk 전송에는 `DataFrame` 또는 `DataPacketCodecV2`를 도입한다.

권장 frame 구조:

```text
0      4   magic "SZDF"
4      1   version
5      1   frameType
6      2   flags
8      4   headerLength
12     4   payloadLength
16     8   sessionHash
24     16  transferIdBytes
40     8   sequence
48     8   chunkIndex
56     4   windowStart
60     4   windowSize
64     4   ackBase
68     4   ackBitmapWordCount
72     N   ackBitmapWords
..     M   payload raw bytes
..     16  authTag or checksum tag
```

초기 구현에서 frame을 더 작게 시작해도 된다. 단, 다음 조건은 반드시 만족해야 한다.

- payload는 raw bytes다.
- base64를 사용하지 않는다.
- JSON encode/decode를 사용하지 않는다.
- transferId, session context, chunk index, payload length를 frame 안에서 검증할 수 있어야 한다.
- malformed frame은 crash 없이 drop하고 debug 로그만 남긴다.
- file payload 원문은 로그에 남기지 않는다.
- 모든 multi-byte numeric field는 network byte order, 즉 big-endian으로 encode한다.
- `RawDatagramSocket.send` 결과가 encoded datagram length와 다르면 전송 성공으로 간주하지 않는다.

### 4.3 인증된 Data Frame

Data channel은 인증된 Control session 이후에만 열린다.

Data frame 검증 원칙:

- raw password, JWT, auth token, session key 자체를 Data frame에 넣지 않는다.
- Control/Auth 성공 후 파생한 transfer-scoped key 또는 verifier context를 사용한다.
- frame에는 sessionHash, transferId, sequence, chunkIndex, payloadLength, authTag를 둔다.
- authTag는 최소 HMAC-SHA256 truncated tag 또는 AEAD tag를 사용한다.
- tag 검증 실패 frame은 discard하고 NACK 또는 failure policy에 따른다.
- 인증되지 않은 peer의 frame은 transfer state에 진입하지 못한다.
- transfer-scoped key는 Control/Auth 세션 성공 후 transfer별 nonce, local node id, remote node id, transferId, selected path id를 포함해 파생한다.
- transfer-scoped key는 메모리에만 존재하며 transfer 완료, 실패, 취소, timeout, peer offline 시점에 폐기한다.
- 동일 ID/PW 또는 JWT 값을 discovery tag, data auth tag, long-lived verifier로 재사용하지 않는다.

1차 구현에서 암호화까지 포함하면 범위가 커질 수 있다. 그 경우 우선순위는 다음과 같다.

1. 인증된 transfer session context 없이는 frame 수신 불가
2. frame integrity tag 검증
3. payload encryption

암호화가 후속으로 밀리더라도 integrity/auth boundary는 설계에서 제거하지 않는다.

### 4.4 Session Key Lifecycle

Data channel key 관리는 Control/Auth 절차의 일부로 취급한다. UI, Discovery, 파일 시스템 구현은 key material을 알면 안 된다.

규칙:

- password 원문은 Data Channel 계획 범위 밖으로 전달하지 않는다.
- JWT 또는 인증 토큰 문자열을 Data frame 검증 키로 직접 사용하지 않는다.
- Control/Auth 성공 결과는 `AuthenticatedPeerSession` 또는 동등한 application 값 객체로 표현한다.
- transfer 시작 시 `TransferDataAuthContext`를 생성하고 transferId와 selected path에 묶는다.
- `TransferDataAuthContext`는 application 계층에서 lifecycle을 소유하고, infrastructure codec에는 frame sign/verify에 필요한 최소 인터페이스만 전달한다.
- key id, session hash, transfer short id는 로그에 축약형으로만 남긴다.
- key 생성, 사용, 폐기는 state machine transition과 테스트로 고정한다.

테스트 기준:

- 동일 peer라도 transferId가 다르면 data auth context가 다르다.
- transfer 완료 후 late data frame은 기존 key로 검증되지 않는다.
- discovery group tag만으로 data frame을 만들 수 없다.
- key material이 product/debug log에 남지 않는다.

### 4.5 MTU와 chunk size

UDP는 빠르지만 큰 datagram을 무조건 보내면 IP fragmentation과 손실률이 올라간다.

기본 정책:

- 기본 datagram 크기는 Ethernet MTU 1500 이하를 목표로 한다.
- IPv4 UDP payload는 일반적으로 1472 bytes 이하가 안전하다.
- binary header와 authTag를 제외한 file payload는 초기값 1200~1300 bytes 범위에서 시작한다.
- JSON/base64 제거 후 512 bytes 제한은 폐기한다.
- `Message too long` 또는 OS send failure가 발생하면 chunk size를 낮추고 reason code를 남긴다.
- 외부 설정 파일로 chunk size를 바꾸지 않는다.
- benchmark build에서만 실험값을 provider override로 주입할 수 있다.
- datagram send 실패, 부분 send, payload size downgrade는 aggregate metric과 debug log로 남긴다.

후속 최적화:

- selected interface MTU를 알 수 있으면 MTU probe를 한다.
- jumbo frame은 자동 가정하지 않는다.
- loopback과 VM bridge에서 큰 datagram을 쓰는 최적화는 profile별 feature로 분리하고 기본값으로 두지 않는다.

## 5. Reliability와 Flow Control

### 5.1 Sliding Window

Data channel은 stop-and-wait 또는 작은 window로 구현하면 안 된다.

기본 방향:

- selective repeat sliding window 사용
- 초기 window는 최소 128 packets 이상 검토
- receiver advertised window를 유지
- sender는 receiver window와 local congestion window 중 작은 값을 사용
- ACK 수신마다 window를 조금 늘리고, loss/timeout 시 줄인다
- window 상태는 transfer job에 aggregate 값으로만 반영한다

초기 값 예시:

- payload bytes: 1200
- initial congestion window: 128 packets
- max congestion window: 2048 packets
- receiver buffer budget: 8 MB 이상
- ACK interval: 16~64 packets 또는 2~10 ms
- retransmission scan interval: 5~20 ms

이 값은 코드 상수 또는 `AppConfig` bootstrap 값으로만 들어간다. 런타임 중 외부 설정 변경으로 주입하지 않는다.

### 5.2 Batch ACK와 SACK

per-chunk ACK는 고속 전송을 막는다.

수신 측 ACK 정책:

- 매 chunk마다 ACK를 보내지 않는다.
- cumulative ack base를 유지한다.
- out-of-order 수신 범위는 bitmap 또는 range list로 SACK한다.
- ACK는 packet count 또는 짧은 timer 기준으로 batch한다.
- duplicate chunk는 즉시 ACK하지 않고 다음 ACK batch에 포함할 수 있다.
- 마지막 chunk 수신 또는 gap 해소 시 즉시 ACK를 보낼 수 있다.

송신 측 처리:

- cumulative ack base 이하 chunk는 완료 처리한다.
- SACK bitmap에 포함된 chunk는 완료 처리한다.
- gap chunk는 retransmission queue로 보낸다.
- duplicate ACK 또는 repeated gap은 congestion signal로 처리한다.

### 5.3 NACK와 Retransmission

NACK는 필요한 경우에만 사용한다.

정책:

- receiver가 gap을 감지하면 NACK range를 batch로 보낸다.
- sender는 timeout scan으로도 missing chunk를 재전송한다.
- chunk별 Timer 수천 개를 만들지 않는다.
- transfer session별 retransmission scheduler를 둔다.
- in-flight chunk metadata는 map 또는 ring buffer로 관리한다.
- retransmission 한도를 초과하면 transfer failed가 된다.
- 실패 reason에는 path, transfer id short, missing count, retry count를 남긴다.

### 5.4 Backpressure

수신 측 file writer와 out-of-order buffer가 밀리면 sender에게 window를 줄여야 한다.

정책:

- receiver buffer budget을 넘기면 advertised window를 줄인다.
- file writer가 contiguous write를 따라가지 못하면 data ACK interval을 조정한다.
- UI update와 MessageBus event는 전송 루프에서 분리한다.
- 수신 writer는 close 시 flush하고, chunk마다 flush하지 않는다.
- sender는 OS socket send 결과를 확인하고, 부분 send 또는 반복 실패를 congestion signal로 처리한다.
- sender는 무제한 tight loop로 datagram을 밀어 넣지 않는다. session tick 또는 micro-batch 단위로 event loop에 양보한다.
- receiver는 session별 buffer budget과 전체 process buffer budget을 함께 적용한다.
- 여러 transfer가 동시에 돌 때 한 transfer가 전체 out-of-order buffer를 독점하지 못하게 한다.

### 5.5 Sender Pacing

UDP는 send 호출이 빠르게 반환되더라도 실제 네트워크와 수신 버퍼가 감당한다는 뜻이 아니다. 따라서 sender는 window만으로 제어하지 않고 pacing을 별도로 둔다.

정책:

- send loop는 `maxPacketsPerTick`, `maxBytesPerTick`, `eventLoopYieldInterval` 중 최소 조건을 따른다.
- ACK가 없는데도 window만 남았다는 이유로 무한 전송하지 않는다.
- RTT, loss, receiver advertised window, local send failure를 pacing 입력으로 사용한다.
- pacing 값은 외부 파일이나 런타임 환경 변수로 바꾸지 않는다. `AppConfig` 초기값 또는 테스트 주입값으로만 들어간다.
- pacing 실패는 throughput 저하보다 packet loss 폭증을 더 큰 문제로 본다.

테스트 기준:

- ACK가 멈추면 sender가 window를 무한히 확장하지 않는다.
- socket send partial/failure가 발생하면 retry 또는 failure reason으로 반영된다.
- 1,000개 chunk 전송에서도 event loop starvation이 발생하지 않는다.

### 5.6 Diagnostics Ring Buffer

운영 중 문제를 볼 수 있어야 하지만, per-packet product log는 전송 성능을 망친다. 세부 패킷 흐름은 개발/디버그용 ring buffer로 보관한다.

정책:

- transfer session별 최근 N개 frame event만 메모리 ring buffer에 저장한다.
- 저장 항목은 timestamp, direction, frame type, sequence, chunk index, ack base, bitmap summary, datagram size, endpoint short, decision code 정도로 제한한다.
- payload, full path, password, token, key material은 저장하지 않는다.
- 실패 시 product log에는 요약만 남기고, debug diagnostics에서 ring buffer snapshot을 확인할 수 있게 한다.
- ring buffer는 bounded memory이며 전송 성능을 위해 문자열 포맷팅을 늦게 수행한다.

## 6. Multi Interface와 Data Path

### 6.1 Active Path 사용

Data channel은 연결 완료된 active `PeerConnectionPath`를 기준으로 열린다.

규칙:

- Control/Auth 성공 path가 있으면 해당 local endpoint를 data bind에도 사용한다.
- receiver는 selected path의 local address에 data port를 bind한다.
- sender는 selected path의 local address에 data sender socket을 bind한다.
- receiver data endpoint는 Control `TRANSFER_INIT_ACK`로 전달한다.
- sender는 receiver discovery/control address가 아니라 ACK에 포함된 receiver data endpoint로 보낸다.
- active path가 stale/offline이면 새 transfer를 시작하지 않는다.
- 같은 peer에 여러 active path가 있으면 transfer session은 하나의 primary path를 선택하되, alternate path 후보를 session context에 보관한다.
- primary path 선택은 discovery에서 처음 보인 IP가 아니라 handshake로 검증된 `PeerConnectionPath`의 local/remote endpoint 쌍을 기준으로 한다.
- VM bridge, 내부 bridge, 물리 Ethernet이 동시에 있어도 “같은 컴퓨터라서 하나의 IP만 맞다”는 가정을 하지 않는다.
- data endpoint와 control endpoint가 달라도 정상 동작해야 한다.

### 6.2 Data Port Range

Data Port는 `AppConfig.dataPortRange` 안에서만 사용한다.

규칙:

- 기본 range는 `38410~38430/udp`다.
- bind 실패 시 같은 interface에서 다음 port를 시도한다.
- range가 모두 실패하면 transfer negotiation 실패로 처리한다.
- OS ephemeral fallback은 금지한다.
- 방화벽 안내에는 Discovery `38400`, Control `38401`, Data `38410~38430`을 명확히 표시한다.

### 6.3 Data Endpoint Lifecycle

Data Port는 transfer별로 아무렇게나 socket을 열고 닫는 구조가 아니라 endpoint lease와 dispatcher로 관리한다.

구성:

- `DataEndpointManager`: selected local address와 `AppConfig.dataPortRange`를 기준으로 bind 가능한 socket lease를 만든다.
- `DataSocketLease`: local endpoint, port, owner transfer/session, close lifecycle을 명시한다.
- `DataSessionDispatcher`: 수신 datagram의 sessionHash/transferId/frameType을 보고 올바른 transfer session으로 dispatch한다.
- `DataPathRegistry`: peer id, selected path id, local endpoint, remote data endpoint, last seen, failure reason을 관리한다.

규칙:

- socket은 chunk마다 만들지 않는다.
- 동시에 여러 transfer가 있으면 transferId/sessionHash로 multiplex한다.
- 하나의 local data socket을 여러 session이 공유할 수 있는지는 구현 단계에서 결정하되, 공유 시 dispatcher 테스트가 먼저 필요하다.
- endpoint lease가 닫힌 뒤 들어온 late packet은 session을 되살리지 않고 drop한다.
- bind 실패는 OS별 errno와 selected local address, port range summary를 debug log로 남긴다.
- Windows에서 `reusePort`가 지원되지 않거나 invalid argument가 나는 경우를 별도 bind policy로 처리한다. 단, 외부 설정으로 우회하지 않는다.

테스트 기준:

- 같은 selected local address에서 port 충돌 시 다음 data port lease를 획득한다.
- 서로 다른 selected local address는 같은 data port 번호를 각각 사용할 수 있다.
- lease close 후 late packet은 ignored로 기록된다.
- dispatcher는 unknown transferId frame을 drop한다.
- Windows bind policy는 지원되지 않는 socket option을 무조건 켜지 않는다.

### 6.4 Failover

초기 Data channel 전환은 failover를 완성하지 않아도 된다. 하지만 설계에서 막으면 안 된다.

1차:

- active path data bind 실패 시 transfer 시작 실패
- transfer 중 data timeout이 지속되면 failed
- diagnostics에 data path failure reason 표시

2차:

- alternate active candidate가 있으면 data path failover 요청
- sender와 receiver가 `DATA_PATH_SWITCH` 또는 Control renegotiation으로 새 endpoint 교환
- missing chunk만 재전송
- 기존 data endpoint는 닫거나 draining 상태로 둔다

## 7. 구현 단계

### 7.1 Tidy First와 현재 경로 고정

- [ ] 현재 Control/Auth 기반 chunk 전송 경로를 테스트로 명확히 고정한다.
- [ ] Control 채널에 `TRANSFER_CHUNK`가 흐르는 테스트를 “현재 legacy behavior”로 분리한다.
- [ ] 새 Data channel 테스트는 legacy behavior와 구분한다.
- [ ] 현재 reader/writer 유지 변경이 유지되는지 테스트를 보존한다.
- [ ] per-packet product/info 로그가 전송 성능에 영향을 주지 않도록 로그 테스트를 유지한다.

완료 기준:

- 현재 문제가 무엇인지 테스트 이름만 보고도 알 수 있다.
- 이후 Data channel 전환 중 기존 호환 테스트와 신규 목표 테스트가 충돌하지 않는다.

### 7.2 Data Protocol 도메인 모델

- [ ] `lib/domain/transfer`에 data session 상태 모델을 정의한다.
- [ ] `DataTransferSessionStateMachine`을 만든다.
- [ ] `DataWindow`, `ChunkAckRange`, `SelectiveAckBitmap`, `RetransmissionPlan` 값 객체를 만든다.
- [ ] window 증가/감소 규칙을 domain 테스트로 고정한다.
- [ ] duplicate/out-of-order/missing chunk 판단을 domain 테스트로 고정한다.
- [ ] forbidden transition을 domain 테스트로 고정한다.

테스트:

- [ ] `DATA_START` 전 chunk 수신은 reject된다.
- [ ] cumulative ack와 SACK bitmap이 완료 chunk를 정확히 계산한다.
- [ ] missing gap은 retransmission plan으로 들어간다.
- [ ] timeout 횟수 초과 시 failed transition이 발생한다.
- [ ] receiver buffer budget이 낮으면 advertised window가 줄어든다.

### 7.3 Binary Frame Codec

- [ ] 기존 JSON `DataPacket`과 별도로 binary `DataFrame` 또는 `DataFrameCodec`을 추가한다.
- [ ] frame header는 fixed-size 필드를 우선 사용한다.
- [ ] payload는 `Uint8List` raw bytes로 encode한다.
- [ ] base64를 제거한다.
- [ ] malformed frame decode 실패를 안전하게 처리한다.
- [ ] authTag 또는 checksum tag 필드를 둔다.
- [ ] packet size 계산 helper를 만든다.
- [ ] safe MTU 안에 들어가는 payload size 계산 테스트를 작성한다.
- [ ] numeric field는 big-endian으로 encode/decode한다.
- [ ] partial send 또는 encoded length mismatch를 transport failure로 표현할 수 있게 한다.

테스트:

- [ ] `DATA_CHUNK` frame encode/decode가 raw bytes를 보존한다.
- [ ] JSON/base64 문자열이 frame payload 경로에 사용되지 않는다.
- [ ] header length와 payload length mismatch는 reject된다.
- [ ] unknown frame type은 reject된다.
- [ ] authTag mismatch는 reject된다.
- [ ] encoded datagram이 safe MTU budget을 넘지 않는 기본 chunk size를 검증한다.
- [ ] little-endian으로 잘못 encode된 frame은 protocol test에서 통과하지 못한다.

### 7.4 RawUdpDataTransport V2

- [ ] `DataTransport`가 binary frame 송수신을 지원하도록 확장한다.
- [ ] 기존 JSON `DataPacket` API와 binary frame API를 migration adapter로 분리한다.
- [ ] selected local endpoint bind를 유지한다.
- [ ] data port range retry를 유지한다.
- [ ] receive datagram의 source address, source port, local endpoint를 보존한다.
- [ ] per-packet info log를 금지하고 aggregate debug log만 남긴다.
- [ ] socket close, rebind, dispose lifecycle을 테스트로 고정한다.
- [ ] `DataEndpointManager`, `DataSocketLease`, `DataSessionDispatcher`를 도입한다.
- [ ] sessionHash/transferId 기준 dispatch를 구현한다.
- [ ] Windows/macOS/Linux bind policy 차이를 테스트 가능한 정책 객체로 분리한다.
- [ ] `RawDatagramSocket.send` 반환값을 확인하고 partial/failure metric을 남긴다.

테스트:

- [ ] selected endpoint에 data socket이 bind된다.
- [ ] 첫 data port 사용 중이면 다음 port를 사용한다.
- [ ] range exhausted 시 명확한 failure가 난다.
- [ ] binary frame을 loopback UDP로 송수신한다.
- [ ] malformed frame은 warning/debug 처리되고 stream을 죽이지 않는다.
- [ ] high-volume data frame이 product/info log에 남지 않는다.
- [ ] unknown transferId frame은 dispatcher에서 drop된다.
- [ ] closed lease로 들어온 late packet은 session을 되살리지 않는다.
- [ ] send 반환값이 datagram 길이보다 작으면 성공 처리하지 않는다.

### 7.5 Control Negotiation과 Data Endpoint 교환

- [ ] `TRANSFER_INIT`은 파일 metadata와 data capability만 전달하며 file chunk와 필수 선계산 sha256을 포함하지 않는다.
- [ ] receiver는 `TRANSFER_INIT` 수신 후 data port를 bind한다.
- [ ] `TRANSFER_INIT_ACK`에 receiver data endpoint와 accepted transfer parameters를 포함한다.
- [ ] sender는 ACK를 받은 뒤 data transport를 bind하거나 sender socket을 준비한다.
- [ ] `DATA_START`는 Data channel로 보낸다.
- [ ] `DATA_START_ACK` 또는 첫 data ACK로 data path alive를 확인한다.
- [ ] Control negotiation timeout과 Data start timeout을 분리한다.
- [ ] transfer-scoped `TransferDataAuthContext`를 생성하고 transfer 완료/실패 시 폐기한다.
- [ ] `DATA_FINISH`에 streaming digest를 포함하는 protocol 계약을 고정한다.

테스트:

- [ ] Control `TRANSFER_INIT_ACK`에 receiver data endpoint가 포함된다.
- [ ] receiver data bind 실패 시 accepted=false가 된다.
- [ ] sender는 receiver control endpoint가 아니라 data endpoint로 `DATA_START`를 보낸다.
- [ ] `TRANSFER_CHUNK`가 ControlTransport로 전송되지 않는다.
- [ ] 인증되지 않은 peer의 `TRANSFER_INIT`은 data bind를 시작하지 않는다.
- [ ] 전송 전 파일 전체 hash 선계산 없이도 negotiation이 진행된다.
- [ ] transferId가 다르면 auth context가 다르게 생성된다.

### 7.6 Sender Data Pipeline

- [ ] sender는 file reader를 transfer session 동안 열어둔다.
- [ ] sender는 파일을 streaming read하면서 chunk를 binary frame으로 만들어 data socket에 보낸다.
- [ ] sender는 streaming digest를 동시에 계산하고 `DATA_FINISH`에 포함한다.
- [ ] sender는 window budget만큼 in-flight chunk를 유지한다.
- [ ] sender는 event loop를 막지 않도록 micro-batch send를 한다.
- [ ] sender는 pacing budget을 적용한다.
- [ ] sender는 ACK/SACK를 받아 완료 chunk를 제거한다.
- [ ] sender는 timeout scan으로 missing chunk를 재전송한다.
- [ ] sender는 `DATA_FINISH`를 보내고 receiver finish ack를 기다린다.
- [ ] sender는 socket send partial/failure를 retry, pacing 감소, failure reason 중 하나로 명시 처리한다.

테스트:

- [ ] 단일 파일이 fake DataTransport로 완료된다.
- [ ] sender가 initial window보다 많은 chunk를 한 번에 무제한 보내지 않는다.
- [ ] ACK 수신 후 다음 window가 pump된다.
- [ ] NACK 수신 시 해당 chunk만 재전송된다.
- [ ] out-of-order ACK/SACK에도 완료 상태가 정확하다.
- [ ] `DATA_FINISH` 전 모든 chunk가 ACK되어야 한다.
- [ ] sender는 전송 시작 전에 전체 파일을 두 번 읽지 않는다.
- [ ] ACK가 멈추면 sender pacing/window가 무제한 증가하지 않는다.

### 7.7 Receiver Data Pipeline

- [ ] receiver는 data session writer를 transfer session 동안 열어둔다.
- [ ] receiver는 `DATA_START` 후에만 chunk를 받는다.
- [ ] receiver는 chunkIndex와 payloadLength를 검증한다.
- [ ] receiver는 contiguous chunk를 즉시 writer에 append한다.
- [ ] receiver는 writer append와 동시에 streaming digest를 계산한다.
- [ ] out-of-order chunk는 buffer budget 안에서만 보관한다.
- [ ] session별 buffer budget과 process 전체 buffer budget을 모두 적용한다.
- [ ] gap이 해소되면 buffered chunk를 순서대로 flush한다.
- [ ] receiver는 ACK/SACK를 batch로 보낸다.
- [ ] 모든 chunk 수신 후 writer close, `DATA_FINISH` digest 검증, finalize를 수행한다.

테스트:

- [ ] out-of-order chunk가 정상 파일로 재조립된다.
- [ ] duplicate chunk는 file에 중복 기록되지 않는다.
- [ ] invalid transferId/sessionHash frame은 무시된다.
- [ ] authTag mismatch frame은 무시되거나 failure policy를 따른다.
- [ ] buffer budget 초과 시 window가 줄거나 transfer가 실패한다.
- [ ] finish 후 sha256 mismatch는 completed가 되지 않는다.
- [ ] 여러 transfer가 동시에 있어도 한 transfer가 전체 buffer를 독점하지 못한다.

### 7.8 ACK Scheduler와 Retransmission Scheduler

- [ ] per-chunk ACK를 제거한다.
- [ ] ACK scheduler는 packet count 또는 duration 기준으로 ACK를 묶는다.
- [ ] retransmission scheduler는 chunk별 Timer 대신 session tick으로 동작한다.
- [ ] RTT estimator를 data ACK 기준으로 갱신한다.
- [ ] loss rate와 retry count를 transfer job에 aggregate로 반영한다.
- [ ] timeout/backoff 정책을 state machine 테스트로 고정한다.
- [ ] ACK/SACK frame도 Data channel에서 처리하고 Control channel로 되돌리지 않는다.
- [ ] ACK scheduler는 receiver write/backpressure 상태를 advertised window에 반영한다.

테스트:

- [ ] 100개 chunk 수신 시 ACK packet 수가 chunk 수보다 충분히 적다.
- [ ] ACK interval timer가 마지막 ACK를 flush한다.
- [ ] timeout scan이 missing chunk를 재전송한다.
- [ ] repeated timeout은 congestion window를 줄인다.
- [ ] ACK storm이 발생하지 않는다.
- [ ] receiver buffer pressure가 증가하면 advertised window가 줄어든다.

### 7.9 UI와 Diagnostics

- [ ] Product UI에는 전송률, 진행률, 실패/재시도 상태만 표시한다.
- [ ] Debug diagnostics에는 data endpoint, active path, chunk size, window, loss rate, retry count, RTT를 표시한다.
- [ ] per-packet 로그 UI를 만들지 않는다.
- [ ] Debug diagnostics에는 실패한 transfer의 bounded ring buffer snapshot을 표시할 수 있다.
- [ ] 긴 peer name, 긴 file name, 긴 endpoint에서도 overflow가 나지 않게 한다.
- [ ] 완료된 수신 파일의 전체 경로는 product log에 남기지 않는다.

테스트:

- [ ] 전송률이 0 B/s에 고착되지 않는다.
- [ ] failed state에서 재시도 버튼 조건이 정확하다.
- [ ] 긴 file name과 peer name에서 overflow가 없다.
- [ ] diagnostics는 민감 정보를 노출하지 않는다.
- [ ] diagnostics ring buffer는 payload, full path, password, token, key material을 포함하지 않는다.

### 7.10 Compatibility 제거 계획

- [ ] Data channel이 기본 경로로 안정화되면 Control `TRANSFER_CHUNK` 경로를 legacy fallback으로 낮춘다.
- [ ] legacy fallback은 테스트 전용 또는 protocol mismatch peer 전용으로 제한한다.
- [ ] protocol version capability로 Data channel 지원 여부를 판단한다.
- [ ] 일정 release 이후 legacy chunk path를 제거한다.

완료 기준:

- 신규 peer 간 전송에서 ControlTransport로 file chunk가 흐르지 않는다.
- legacy path는 명시적으로 선택된 경우에만 동작한다.

## 8. 성능 검증 계획

### 8.1 자동 검증

자동 테스트는 deterministic해야 한다.

- [ ] binary frame size test
- [ ] JSON/base64 미사용 test
- [ ] ControlTransport에 chunk가 흐르지 않는 test
- [ ] batch ACK count test
- [ ] retransmission correctness test
- [ ] out-of-order/duplicate/loss test
- [ ] high-volume log suppression test
- [ ] state machine transition test
- [ ] streaming digest test
- [ ] transfer auth context lifecycle test
- [ ] data endpoint lease/dispatcher test
- [ ] sender pacing and partial send handling test
- [ ] diagnostics ring buffer redaction test

### 8.2 로컬 benchmark

benchmark script는 외부 설정 파일 없이 명시 인자로 실행한다.

측정 항목:

- file size
- elapsed ms
- throughput MB/s
- chunk size
- datagram size
- ACK count
- retransmission count
- loss rate
- RTT estimate
- selected local endpoint
- remote data endpoint
- OS
- build mode
- CPU usage rough sample
- memory high-water mark
- product/debug log line count
- data socket send failure count
- receiver buffer pressure peak

권장 scenario:

- macOS 동일 장비 2 인스턴스
- macOS host to Windows Parallels bridged VM
- macOS to macOS physical LAN
- Windows to Windows LAN
- Ubuntu 22.04 to macOS LAN
- Ethernet + bridge candidate가 동시에 있는 환경

### 8.3 수동 release gate

- [ ] 10 MB 파일 전송이 timeout 없이 완료된다.
- [ ] 100 MB 파일 전송이 release build에서 안정적으로 완료된다.
- [ ] 전송 중 UI가 멈추지 않는다.
- [ ] 전송 중 로그 파일이 비정상적으로 커지지 않는다.
- [ ] receiver 저장 파일 hash가 source와 일치한다.
- [ ] Windows firewall 차단 시 Data bind/connect 실패 reason이 명확하다.
- [ ] Parallels bridged VM에서 data endpoint가 control endpoint와 다르게 잡혀도 전송된다.
- [ ] 전송 시작 전 준비 시간이 파일 크기에 비례해 과도하게 증가하지 않는다.
- [ ] 같은 파일 2회 이상 반복 전송 시 speed와 loss metric 편차를 기록한다.

## 9. 보안과 안전 기준

- Data frame에는 password, JWT, auth token, session key 원문을 넣지 않는다.
- Data frame 로그에는 payload, 전체 file path, 전체 session id를 남기지 않는다.
- Discovery group tag는 Data authentication에 재사용하지 않는다.
- Control/Auth 성공 전 Data Port를 열 수는 있어도 chunk state로 진입하면 안 된다.
- transfer-scoped context 없이 들어온 Data frame은 drop한다.
- transfer-scoped context는 transfer 완료, 실패, 취소, timeout, peer offline에서 폐기한다.
- Data channel integrity 실패는 silently completed로 처리하지 않는다. drop, NACK, failed 중 하나로 명시 처리한다.
- `DATA_FINISH` digest와 receiver streaming digest가 다르면 finalize하지 않는다.
- malformed frame으로 앱이 종료되면 안 된다.
- file finalize는 streaming digest 검증 후에만 수행한다.
- 수신 저장 위치는 기존 settings/default path 정책을 따른다.

## 10. 완료 기준

이 계획은 다음 조건을 만족하면 완료된다.

- 신규 전송에서 file chunk는 Data Port 전용 UDP channel로 흐른다.
- Control channel에는 file metadata, negotiation, cancel, finish summary만 흐른다.
- Data payload는 raw binary frame이며 JSON/base64가 아니다.
- ACK는 batch/SACK 기반이고 per-chunk ACK가 아니다.
- sender/receiver는 열린 file reader/writer를 세션 동안 유지한다.
- sender/receiver는 대용량 파일을 전송 시작 전에 별도 hash 선계산용으로 한 번 더 읽지 않는다.
- sender pacing과 receiver backpressure가 구현되어 packet loss 폭증을 방지한다.
- Data endpoint lease와 dispatcher가 transfer/session lifecycle을 명시적으로 관리한다.
- selected active path의 local endpoint와 remote data endpoint가 사용된다.
- packet loss, duplicate, out-of-order, timeout, retry가 테스트로 검증된다.
- transfer progress와 diagnostics는 aggregate로 갱신된다.
- product/info 로그는 per-packet data log를 남기지 않는다.
- debug diagnostics는 bounded ring buffer로 실패 원인을 추적할 수 있고 민감 정보를 노출하지 않는다.
- `flutter analyze`와 관련 domain/application/infrastructure/widget 테스트가 통과한다.
- macOS, Windows, Ubuntu 22.04 LTS 이상 Linux에서 최소 수동 전송 검증을 통과한다.

## 11. 우선순위

1. Data channel 목표 테스트 작성
2. Binary DataFrame codec 도입
3. Transfer-scoped auth context와 streaming digest 계약 도입
4. Data endpoint lease, dispatcher, bind policy 도입
5. DataTransport binary frame 송수신 확장
6. Control negotiation에 receiver data endpoint 포함
7. Sender pipeline을 DataTransport와 pacing 기반으로 이동
8. Receiver pipeline을 DataTransport와 backpressure 기반으로 이동
9. Batch ACK/SACK와 retransmission scheduler 도입
10. Control `TRANSFER_CHUNK` legacy fallback 격리
11. UI/diagnostics aggregate와 ring buffer 정리
12. benchmark와 manual release gate 수행

## 12. 다음 태스크 분리 기준

이 계획을 task 파일로 나눌 때는 한 파일에 기능 2~3개, 테스트, 검증을 한 묶음으로 둔다.

권장 태스크:

- `task001.md`: 현재 control chunk 경로 고정, 실패 목표 테스트, legacy 분리 기준
- `task002.md`: domain data session state machine, window/retry 모델
- `task003.md`: binary DataFrame codec, MTU budget, protocol version/capability
- `task004.md`: transfer-scoped auth context, key lifecycle, streaming digest 계약
- `task005.md`: DataEndpointManager, DataSocketLease, DataSessionDispatcher, OS bind policy
- `task006.md`: RawUdpDataTransport binary frame 송수신과 send failure 처리
- `task007.md`: Control negotiation data endpoint 교환과 Data channel start
- `task008.md`: sender pipeline DataTransport 전환, pacing, streaming read/digest
- `task009.md`: receiver pipeline DataTransport 전환, backpressure, streaming write/digest
- `task010.md`: batch ACK/SACK, retransmission scheduler, RTT/loss metrics
- `task011.md`: UI diagnostics, ring buffer, benchmark, release gate

각 태스크는 반드시 체크박스, 기능 범위, 테스트, 검증 기준을 포함한다.
