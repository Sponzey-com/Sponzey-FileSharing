# task008 - Sender Pipeline DataTransport 전환, Pacing, Streaming Read/Digest

## 목적

송신 경로를 Control chunk 전송에서 DataTransport binary frame 전송으로 옮긴다. sender는 파일을 streaming read하면서 digest를 계산하고, sliding window와 pacing으로 UDP datagram을 밀어 넣는다.

## 진행 현황

- [x] sender는 `OutgoingTransferReader`를 session 동안 유지하고 binary `DATA_CHUNK` frame으로 전송한다.
- [x] transfer 시작 전 전체 sha256 선계산 없이 streaming digest를 누적하고 `DATA_FINISH`에 포함한다.
- [x] Control channel로 file chunk를 보내지 않는 테스트와 fake DataTransport 기반 완료 테스트를 추가했다.
- [x] window 제한, ACK/SACK bitmap 처리, NACK 재전송 queue, send failure 처리를 연결했다.
- [x] 관련 검증: `flutter test test/application/transfer test/infrastructure/transfer`, `flutter analyze`

## 기능 범위

### 1. Sender session pipeline

- [x] sender는 file reader를 transfer session 동안 열어둔다.
- [x] sender는 file chunk를 raw bytes로 읽고 binary `DATA_CHUNK` frame으로 보낸다.
- [x] sender는 transfer 시작 전에 전체 파일을 hash 선계산용으로 한 번 더 읽지 않는다.
- [x] sender는 streaming digest를 누적하고 `DATA_FINISH`에 최종 digest를 포함한다.
- [x] 모든 chunk가 ACK되기 전에는 `DATA_FINISH`를 완료 처리하지 않는다.

### 2. Sliding window와 ACK/SACK 처리

- [x] sender는 initial window보다 많은 chunk를 한 번에 무제한 보내지 않는다.
- [x] ACK/SACK 수신 시 완료 chunk를 in-flight에서 제거한다.
- [x] NACK 수신 시 해당 chunk만 retransmission queue에 넣는다.
- [x] out-of-order ACK/SACK에도 완료 상태가 정확해야 한다.
- [x] repeated timeout은 congestion window 감소로 이어진다.

### 3. Pacing과 event loop 보호

- [x] sender는 `maxPacketsPerTick`, `maxBytesPerTick`, `eventLoopYieldInterval` 기준으로 micro-batch send를 한다.
- [x] ACK가 멈추면 window/pacing이 무제한 증가하지 않는다.
- [x] `RawDatagramSocket.send` partial/failure는 retry, pacing 감소, failure reason 중 하나로 처리한다.
- [x] UI state update와 MessageBus progress event는 전송 루프에서 throttle한다.

## 구현 지침

- sender 절차는 상태 머신 transition을 사용한다.
- file reader open/close는 session lifecycle과 연결한다.
- chunk별 독립 Timer를 만들지 않는다.
- pacing 값은 외부 설정 파일이나 런타임 env reload로 바꾸지 않는다.
- fake DataTransport로 deterministic unit test를 먼저 만든다.
- 실제 Raw UDP smoke는 task011 release gate에서 별도 확인한다.

## 예상 변경 위치

- [x] `lib/application/transfer/transfer_controller.dart`
- [x] `lib/application/transfer/data_sender_session.dart`
- [x] `lib/domain/transfer/`
- [x] `lib/infrastructure/transfer/transfer_file_service.dart`
- [x] `test/application/transfer/`
- [x] `test/infrastructure/transfer/`

## 테스트

- [x] 단일 파일이 fake DataTransport로 completed가 된다.
- [x] sender가 initial window보다 많은 chunk를 한 번에 보내지 않는다.
- [x] ACK 수신 후 다음 window가 pump된다.
- [x] NACK 수신 시 해당 chunk만 재전송된다.
- [x] out-of-order ACK/SACK에도 완료 상태가 정확하다.
- [x] `DATA_FINISH` 전 모든 chunk가 ACK되어야 한다.
- [x] sender는 전송 시작 전에 전체 파일을 두 번 읽지 않는다.
- [x] ACK가 멈추면 sender pacing/window가 무제한 증가하지 않는다.
- [x] send partial/failure는 성공으로 처리되지 않는다.
- [x] progress event가 per-packet으로 발생하지 않는다.

## 검증 명령

- [x] `flutter test test/application/transfer`
- [x] `flutter test test/infrastructure/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] 신규 sender pipeline은 DataTransport binary frame을 사용한다.
- [x] ControlTransport로 file chunk를 보내지 않는다.
- [x] sender streaming digest와 `DATA_FINISH` 계약이 구현되어 있다.
- [x] pacing과 window가 UDP burst를 제한한다.

## 리스크와 주의사항

- 속도를 위해 window를 무작정 키우지 않는다. packet loss 폭증을 막는 것이 우선이다.
- file read, digest, encode, send 순서가 UI isolate를 장시간 막지 않게 한다.
- receiver pipeline이 완성되기 전에는 fake transport 중심으로 검증한다.
