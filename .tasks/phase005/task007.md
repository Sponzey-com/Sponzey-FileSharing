# task007 - Control Negotiation Data Endpoint 교환과 Data Channel Start

## 목적

Control channel은 파일 chunk가 아니라 인증, 전송 협상, data endpoint 교환만 담당해야 한다. 이 태스크는 `TRANSFER_INIT`과 `TRANSFER_INIT_ACK` 계약을 고속 Data Channel 기준으로 바꾸고, sender가 실제 file byte를 receiver data endpoint로 보내기 시작하는 handshake를 만든다.

## 진행 현황

- [x] `TRANSFER_INIT`에 Data protocol/capability/auth context id를 싣고 file chunk와 필수 sha256 선계산을 제거했다.
- [x] receiver는 인증된 init 후 Data endpoint를 bind하고 `TRANSFER_INIT_ACK`로 data address/port/window/chunk size를 반환한다.
- [x] sender는 ACK의 receiver data endpoint로 `DATA_START`와 `DATA_CHUNK`를 보낸다.
- [x] 신규 기본 경로에서 `TRANSFER_CHUNK`가 Control channel로 나가지 않는 테스트를 추가했다.
- [x] 관련 검증: `flutter test test/application/transfer test/infrastructure/control/raw_udp_control_transport_test.dart`, `flutter analyze`

## 기능 범위

### 1. `TRANSFER_INIT` 계약 정리

- [x] `TRANSFER_INIT`은 protocolVersion, transferId, fileName, fileSize, optional fingerprint, chunkSize proposal, chunkCount proposal, selectedPathId, senderDataEndpoint 후보, capabilities, sentAt을 포함한다.
- [x] `TRANSFER_INIT`은 file chunk를 포함하지 않는다.
- [x] `TRANSFER_INIT`은 필수 sha256 선계산을 요구하지 않는다.
- [x] 인증되지 않은 peer의 `TRANSFER_INIT`은 data bind를 시작하지 않는다.

### 2. Receiver data endpoint bind와 ACK

- [x] receiver는 인증된 `TRANSFER_INIT` 수신 후 selected path local address에 data port lease를 bind한다.
- [x] `TRANSFER_INIT_ACK`에는 accepted, receiverDataEndpoint, receiverDataPortLeaseId, acceptedChunkSize, acceptedWindowSize, receiverBufferBudget, transferSessionId, transferKeyId 또는 dataAuthContext id, save policy summary, reject reason을 포함한다.
- [x] data bind 실패 시 accepted=false와 reason code를 보낸다.
- [x] negotiation timeout과 data start timeout을 다른 reason code로 구분한다.

### 3. Data Channel start

- [x] sender는 `TRANSFER_INIT_ACK`의 receiverDataEndpoint로 `DATA_START`를 보낸다.
- [x] sender는 receiver control endpoint로 file byte를 보내지 않는다.
- [x] `DATA_START_ACK` 또는 첫 data ACK로 data path alive를 확인한다.
- [x] transfer-scoped auth context를 Data Channel start 시점에 연결한다.

## 구현 지침

- ControlTransport는 metadata, negotiation, cancel, finish summary만 담당한다.
- `TRANSFER_CHUNK`, `TRANSFER_CHUNK_ACK`, `TRANSFER_WINDOW_UPDATE`는 신규 peer 기본 경로에서 사용하지 않는다.
- selected active path가 stale/offline이면 새 transfer를 시작하지 않는다.
- data endpoint와 control endpoint가 달라도 정상 동작해야 한다.
- 기존 legacy control chunk path는 명시 fallback으로만 남긴다.

## 예상 변경 위치

- [x] `lib/application/transfer/transfer_controller.dart`
- [x] `lib/infrastructure/control/control_transport.dart`
- [x] `lib/domain/transfer/`
- [x] `test/application/transfer/transfer_controller_test.dart`
- [x] `test/infrastructure/control/raw_udp_control_transport_test.dart`

## 테스트

- [x] Control `TRANSFER_INIT_ACK`에 receiver data endpoint가 포함된다.
- [x] receiver data bind 실패 시 accepted=false가 된다.
- [x] sender는 receiver control endpoint가 아니라 data endpoint로 `DATA_START`를 보낸다.
- [x] `TRANSFER_CHUNK`가 신규 Data Channel 전송에서 `ControlTransport`로 전송되지 않는다.
- [x] 인증되지 않은 peer의 `TRANSFER_INIT`은 data bind를 시작하지 않는다.
- [x] 전송 전 파일 전체 hash 선계산 없이도 negotiation이 진행된다.
- [x] transferId가 다르면 auth context가 다르게 생성된다.
- [x] data start timeout은 negotiation timeout과 다른 failure reason으로 표시된다.

## 검증 명령

- [x] `flutter test test/application/transfer/transfer_controller_test.dart`
- [x] `flutter test test/infrastructure/control/raw_udp_control_transport_test.dart`
- [x] `flutter analyze`

## 완료 기준

- [x] Control negotiation이 Data Channel endpoint 교환을 완료한다.
- [x] 신규 전송에서 file chunk는 Control channel로 흐르지 않는다.
- [x] sender는 negotiated receiver data endpoint로 `DATA_START`를 보낸다.
- [x] bind failure, auth failure, data start timeout이 구분된다.

## 리스크와 주의사항

- 기존 연결 안정화 코드를 깨지 않도록 active path 모델을 재사용한다.
- `TRANSFER_INIT` schema 변경은 backward compatibility 테스트와 함께 진행한다.
- Data Channel start만 만들고 full sender/receiver pipeline은 task008, task009에서 완성한다.
