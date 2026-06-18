# task028 - TCP Outgoing Transfer Stream Sender Command

## Goal

송신 파일을 TCP data channel의 stream frame으로 전송하는 command를 구현한다. 전송 순서는 metadata frame, chunk frames, complete frame이며 모두 이미 연결된 TCP channel로만 전송한다.

## Scope

- [x] `TcpDataConnectorPort`에 stream frame 송신 계약을 명시한다.
- [x] TCP sender command가 metadata frame을 먼저 전송한다.
- [x] 파일 chunk는 기존 `TransferFileService.openOutgoingReader`를 사용해 순차 읽기 후 chunk frame으로 전송한다.
- [x] 모든 chunk 전송 후 complete frame을 전송한다.
- [x] 성공/실패와 관계없이 outgoing reader를 닫는다.

## Architecture Notes

- command는 파일 시스템과 connector port를 함께 사용하므로 `lib/infrastructure/transfer`에 둔다.
- command는 이미 연결된 `TcpDataChannelId`만 입력으로 받고, discovery/control/route lease를 변경하지 않는다.
- sender metadata에는 receiver 저장 경로를 포함하지 않는다.
- TCP 전송 중에는 peer route 변경 절차를 수행하지 않는다.
- per-frame product log나 MessageBus event는 추가하지 않는다.

## TDD Checklist

- [x] metadata, chunk, complete frame 순서가 고정되는 테스트를 작성한다.
- [x] reader가 한 번만 열리고 완료 후 닫히는 테스트를 작성한다.
- [x] connector send 실패 시 reader를 닫고 명시 issue code를 반환하는 테스트를 작성한다.
- [x] `TcpDataConnectorPort`를 통해 송신하며 concrete connector 타입에 의존하지 않는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpDataConnectorPort.sendFrame`을 추가하고 `RawTcpDataConnector`가 구현하도록 한다.
- [x] `TcpOutgoingTransferStreamSendCommand`와 result 타입을 추가한다.
- [x] command는 `TransferFileService.prepareOutgoingFile`, `openOutgoingReader`, `TcpIncomingTransferMetadataCodec`, `TcpDataConnectorPort.sendFrame`을 사용한다.
- [x] sequence는 metadata `0`, chunk `1..N`, complete `N + 1`로 고정한다.
- [x] 실패 시 `tcp_outgoing_stream_send_failed` issue code를 반환한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command_test.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task028.md lib/application/transfer/tcp_data_channel_ports.dart lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart lib/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart test/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added `TcpDataConnectorPort.sendFrame` so TCP stream send logic depends on the application port instead of the concrete connector.
  - Added TCP outgoing stream sender command with metadata, chunk, and complete frame ordering.
  - Reader cleanup is guaranteed in success and failure paths.
