# task006 - RawUdpDataTransport Binary Frame 송수신과 Send Failure 처리

## 목적

Binary frame codec과 data endpoint lifecycle을 실제 UDP 송수신 경로에 연결한다. 이 태스크는 `RawUdpDataTransport`가 binary frame을 보내고 받으며, source/local endpoint와 send failure를 정확히 보존하도록 만든다.

## 진행 현황

- [x] `DataTransport.frames`와 `sendFrame` API를 추가하고 legacy JSON packet API와 분리했다.
- [x] `RawUdpDataTransport`가 binary frame을 decode/send하고 malformed datagram에서 stream을 죽이지 않도록 했다.
- [x] `RawDatagramSocket.send` partial/zero send를 실패로 처리하고 bounded retry를 적용했다.
- [x] loopback binary frame 송수신과 safe datagram 크기를 테스트했다.
- [x] 관련 검증: `flutter test test/infrastructure/transfer_data`, `flutter analyze`

## 기능 범위

### 1. Binary frame transport API

- [x] 기존 JSON `DataPacket` API와 binary `DataFrame` API를 migration adapter로 분리한다.
- [x] `sendFrame` 또는 동등 API가 encoded binary frame을 UDP datagram으로 전송한다.
- [x] receive stream은 decoded frame과 source endpoint, local endpoint, receive timestamp를 함께 제공한다.
- [x] malformed datagram은 stream을 죽이지 않고 decode failure decision으로 처리한다.

### 2. Send result와 failure metric

- [x] `RawDatagramSocket.send` 반환값을 확인한다.
- [x] 반환값이 encoded datagram length보다 작으면 성공 처리하지 않는다.
- [x] `Message too long`, address unreachable, socket closed 같은 오류를 reason code로 표현한다.
- [x] 반복 send failure는 pacing/congestion 입력으로 전달 가능해야 한다.

### 3. Aggregate logging

- [x] high-volume data frame 송수신은 product/info log에 남기지 않는다.
- [x] debug log는 endpoint short, frame type, datagram size, reason code 중심으로 aggregate한다.
- [x] payload, full path, token, key material은 로그에 남기지 않는다.
- [x] 전송 루프에서 문자열 포맷팅 비용이 커지지 않도록 주의한다.

## 구현 지침

- Raw UDP transport는 infrastructure 계층에 둔다.
- application 계층에는 transport interface만 노출한다.
- receive loop 예외가 앱 전체 전송 기능을 종료시키지 않도록 failure를 stream event로 표현한다.
- `DataEndpointManager` lease와 통합해 socket 소유권이 명확해야 한다.
- fake transport 테스트와 실제 loopback UDP 테스트를 분리한다.

## 예상 변경 위치

- [x] `lib/infrastructure/transfer/raw_udp_data_transport.dart`
- [x] `lib/infrastructure/transfer/data_transport.dart`
- [x] `lib/infrastructure/transfer/data_frame_codec.dart`
- [x] `test/infrastructure/transfer/raw_udp_data_transport_test.dart`
- [x] `test/infrastructure/transfer/data_frame_codec_test.dart`

## 테스트

- [x] binary frame을 loopback UDP로 송수신한다.
- [x] 수신 event에 source endpoint와 local endpoint가 보존된다.
- [x] malformed datagram은 debug failure로 처리되고 stream을 죽이지 않는다.
- [x] send 반환값이 datagram 길이보다 작으면 failure로 처리한다.
- [x] closed socket send는 명확한 failure reason을 반환한다.
- [x] high-volume data frame이 product/info log에 남지 않는다.
- [x] payload bytes가 로그에 노출되지 않는다.

## 검증 명령

- [x] `flutter test test/infrastructure/transfer/raw_udp_data_transport_test.dart`
- [x] `flutter test test/infrastructure/transfer/data_frame_codec_test.dart`
- [x] `flutter analyze`

## 완료 기준

- [x] Raw UDP transport가 binary frame을 송수신한다.
- [x] send partial/failure가 성공으로 오인되지 않는다.
- [x] source/local endpoint가 session routing에 충분히 보존된다.
- [x] product 로그가 per-packet으로 폭증하지 않는다.

## 리스크와 주의사항

- loopback 테스트가 platform별 port 충돌에 취약할 수 있으므로 deterministic port lease를 사용한다.
- DataTransport가 ControlTransport 책임을 가져오지 않게 한다.
- 이 태스크에서 sender/receiver file pipeline 전체를 완성하지 않는다.
