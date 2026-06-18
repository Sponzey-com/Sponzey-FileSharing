# Task 017. TCP Transport Stream Frame Send and Receive

## 1. Task Purpose

- [x] 이 태스크의 목적은 TCP data channel에서 hello 이후 payload stream frame을 송수신할 수 있도록 raw transport 경계를 확장하는 것이다.
- [x] TCP stream frame 값 객체는 domain에 두고, codec과 transport는 해당 값을 사용한다.
- [x] listener는 channel별 첫 frame을 hello로 처리하고, 이후 frame은 payload stream frame으로 처리한다.

## 2. Scope

### Included

- [x] TCP stream frame domain model을 추가하고 codec이 이를 사용하도록 정리한다.
- [x] raw TCP listener에 stream frame/error stream을 추가한다.
- [x] raw TCP connector에 stream frame send 메서드를 추가한다.
- [x] loopback TCP에서 hello 이후 chunk frame을 수신하는 테스트를 추가한다.

### Excluded

- [x] 파일 reader/writer와 transfer runner 연결은 포함하지 않는다.
- [x] MessageBus event 발행은 포함하지 않는다.
- [x] UI transfer queue 변경은 포함하지 않는다.

## 3. TDD Plan

- [x] raw transport loopback stream frame 테스트를 먼저 작성한다.
- [x] hello 이후 chunk frame이 같은 channel id로 수신되는지 테스트한다.
- [x] malformed stream frame이 hello error와 분리된 stream frame error로 격리되는지 테스트한다.

## 4. Completion Report

Completion summary:

- `TcpDataStreamFrame`과 `TcpDataStreamFrameType`을 domain 계층에 추가하고 TCP stream codec이 해당 모델을 사용하도록 정리했다.
- raw TCP listener가 첫 frame은 session hello로, 이후 frame은 payload stream frame으로 해석하도록 분기했다.
- raw TCP connector에 `sendFrame`을 추가해 TCP socket으로 payload frame을 전송할 수 있게 했다.
- malformed payload frame은 `frameErrors`로 격리하고 hello error stream과 섞이지 않도록 했다.

Changed files:

- `lib/domain/transfer/tcp_data_stream_frame.dart`
- `lib/application/transfer/tcp_data_channel_ports.dart`
- `lib/infrastructure/transfer_data/tcp_data_stream_frame_codec.dart`
- `lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`
- `test/infrastructure/transfer_data/tcp_data_stream_frame_codec_test.dart`
- `test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`

Validation commands:

- `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart test/infrastructure/transfer_data/tcp_data_stream_frame_codec_test.dart --reporter compact`

Remaining risks:

- stream frame을 application transfer runner로 dispatch하는 작업은 후속 task에서 진행해야 한다.
