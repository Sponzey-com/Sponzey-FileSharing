# Task 016. TCP Data Stream Frame Codec and Capability

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP data channel에서 파일 payload를 운반할 length-prefixed binary stream frame을 추가하는 것이다.
- [x] 기존 UDP `DataFrame`/ACK/NACK 알고리즘과 TCP stream frame을 섞지 않는다.
- [x] control 협상에서 TCP data stream 지원 여부를 표현할 수 있도록 protocol capability를 추가한다.

## 2. Scope

### Included

- [x] `tcpDataStreamV1` transfer capability를 도메인 프로토콜에 추가한다.
- [x] TCP stream frame type, frame value, codec을 infrastructure transfer_data 계층에 추가한다.
- [x] metadata/chunk/complete frame round-trip과 malformed frame 거부 테스트를 추가한다.

### Excluded

- [x] 실제 파일 reader/writer와 TCP socket write/read 연결은 포함하지 않는다.
- [x] UDP data frame 제거는 포함하지 않는다.
- [x] UI 변경은 포함하지 않는다.

## 3. TDD Plan

- [x] capability wire list 테스트를 먼저 작성한다.
- [x] TCP metadata/chunk/complete frame encode/decode 테스트를 먼저 작성한다.
- [x] wrong magic, unsupported version, invalid payload length를 거부하는 테스트를 먼저 작성한다.

## 4. Completion Report

Completion summary:

- `tcpDataStreamV1` capability를 추가해 control 협상에서 TCP stream data path를 표현할 수 있게 했다.
- TCP payload용 `TcpDataStreamFrameCodec`을 추가해 metadata/chunk/complete/cancel/error frame을 length-prefixed binary envelope로 직렬화한다.
- wrong magic, unsupported version, body length mismatch를 codec 경계에서 거부하도록 고정했다.

Changed files:

- `lib/domain/transfer/data_transfer_protocol.dart`
- `lib/infrastructure/transfer_data/tcp_data_stream_frame_codec.dart`
- `test/domain/transfer/data_transfer_protocol_tcp_test.dart`
- `test/infrastructure/transfer_data/tcp_data_stream_frame_codec_test.dart`

Validation commands:

- `flutter test test/domain/transfer/data_transfer_protocol_tcp_test.dart test/infrastructure/transfer_data/tcp_data_stream_frame_codec_test.dart --reporter compact`

Remaining risks:

- TCP stream frame을 transfer runner에 연결하는 작업은 후속 task에서 별도로 진행해야 한다.
