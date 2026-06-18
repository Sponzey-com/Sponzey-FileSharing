# Task 008 - Data Port 기반 단일 파일 전송 MVP와 streaming IO

## 목표

인증된 단일 peer에게 단일 파일을 Data Port로 전송하는 MVP를 구현한다. 파일 전체를 메모리에 올리지 않고 chunk 단위 streaming read/write로 처리한다.

## 연관 문서

- [phase002 plan.md - UDP 데이터 통신 계획](plan.md#10-udp-데이터-통신-계획)
- [task003.md](task003.md)
- [task007.md](task007.md)

## 선행 조건

- [task007.md](task007.md)의 인증 세션과 session context가 있어야 한다.
- [task005.md](task005.md)의 Data Port 모델이 있어야 한다.
- [task003.md](task003.md)의 송수신 전송 상태 머신이 있어야 한다.

## 포함 기능

### 기능 1. TransferOffer와 DataStart 흐름

- Sender는 Control Port로 TransferOffer를 보낸다.
- Receiver는 인증 세션과 수신 정책을 확인하고 TransferAccept/Reject를 보낸다.
- TransferAccept 이후에만 Sender가 Data Port로 DataStart를 보낸다.

### 기능 2. Chunk streaming 송수신

- 파일을 chunk로 나누는 pure service를 만든다.
- 파일 전체를 메모리에 올리지 않고 chunk 단위로 읽는다.
- 수신자는 임시 파일에 chunk를 쓰고 완료 검증 후 final path로 이동한다.

### 기능 3. MVP 무결성, 진행률, 취소

- chunk checksum과 파일 전체 checksum을 검증한다.
- 기본 ack를 구현한다.
- 진행률 event를 MessageBus로 publish한다.
- 송신자/수신자 cancel을 상태 머신과 Control Port에 반영한다.

## 구현 체크리스트

- [x] TransferOffer/Accept/Reject packet 흐름을 구현했다.
- [x] DataStart packet을 구현했다.
- [x] DataChunk packet codec을 구현했다.
- [x] DataAck 기본 흐름을 구현했다.
- [x] 파일 chunk 계산 service를 구현했다.
- [x] streaming file reader를 구현했다.
- [x] streaming temp file writer를 구현했다.
- [x] 임시 파일 완료 후 final path 이동을 구현했다.
- [x] chunk checksum을 검증했다.
- [x] file checksum을 검증했다.
- [x] OutgoingTransferStateMachine을 controller와 연결했다.
- [x] IncomingTransferStateMachine을 controller와 연결했다.
- [x] Transfer progress event를 MessageBus로 publish했다.
- [ ] cancel packet과 상태 전이를 구현했다.
- [x] AEAD metadata 확장을 방해하지 않는 chunk codec 구조인지 확인했다.

## 테스트

- [x] 단일 파일 정상 전송 테스트를 작성했다.
- [x] 인증 전 전송 거부 테스트를 작성했다.
- [x] TransferAccept 전 DataStart 금지 테스트를 작성했다.
- [x] filePrepared 전 chunk 송신 금지 테스트를 작성했다.
- [x] 수신 정책 거부 테스트를 작성했다.
- [x] destinationPrepared 전 chunk write 금지 테스트를 작성했다.
- [x] chunk checksum mismatch 테스트를 작성했다.
- [x] file checksum mismatch 테스트를 작성했다.
- [ ] 송신자 cancel 테스트를 작성했다.
- [ ] 수신자 cancel 테스트를 작성했다.
- [x] 대용량 파일에서 메모리 사용량이 파일 크기에 비례해 폭증하지 않는 검증을 추가했다.
- [x] progress event publish 테스트를 작성했다.

## 검증

- [x] 같은 장비 loopback에서 단일 파일 전송을 확인한다.
- [ ] 동일 LAN 두 장비에서 단일 파일 전송을 확인한다. _(완전 수동 확인 제외)_
- [ ] 전송 중 UI가 멈추지 않는지 확인한다. _(완전 수동 확인 제외)_
- [x] 실패 시 임시 파일이 정리되는지 확인한다.
- [x] 로그에 파일 원문, 전체 경로, token, session key가 남지 않는다.

## 진행 결과

- `lib/infrastructure/transfer_data/data_packet.dart`
- `lib/infrastructure/transfer/transfer_file_service.dart`
- `lib/application/transfer/transfer_controller.dart`
- `test/infrastructure/transfer_data/data_packet_test.dart`
- `test/infrastructure/transfer/transfer_file_service_test.dart`
- `test/application/transfer/transfer_controller_test.dart`

## 남은 비수동 후속

- 실제 전송 컨트롤러는 아직 기존 `AuthTransport` 경로를 재사용한다. `DataPacket` codec과 포트 모델은 준비됐지만, 물리적인 Data Port 전용 transport 분리는 별도 구현이 필요하다.
- 송신자/수신자 cancel packet의 end-to-end 적용은 별도 구현이 필요하다.

## 완료 기준

- 인증된 단일 peer에게 단일 파일을 Data Port로 전송할 수 있다.
- 전송 성공, 실패, 취소, 진행률이 상태와 event로 표현된다.
- 후속 신뢰성 보강이 가능한 chunk/ack 구조가 마련되어 있다.
