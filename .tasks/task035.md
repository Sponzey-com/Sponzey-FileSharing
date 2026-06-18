# task035 - TCP Peer File Send Orchestration Command

## Goal

peer/auth 기준으로 연결된 outbound TCP data channel을 찾고, 찾은 channel로만 파일 송신 command를 호출하는 orchestration command를 추가한다.

## Scope

- [x] TCP stream sender를 port로 추상화한다.
- [x] connected outbound channel lookup 성공 시 해당 channel id로만 sender를 호출한다.
- [x] channel lookup 실패 시 sender를 호출하지 않고 issue code를 반환한다.
- [x] sender 실패 issue를 orchestration result로 보존한다.

## Architecture Notes

- orchestration command는 infrastructure composition 성격이지만 socket/file 구현체 대신 registry와 sender port에 의존한다.
- peer discovery, route lease, UDP data path를 변경하지 않는다.
- 전송 중 channel 변경이나 route 재선택을 수행하지 않는다.
- controller 연결은 별도 task에서 수행한다.

## TDD Checklist

- [x] connected outbound channel로 sender가 호출되는 테스트를 작성한다.
- [x] missing channel이면 sender가 호출되지 않는 테스트를 작성한다.
- [x] sender 실패 issue가 반환되는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpOutgoingTransferStreamSenderPort`를 추가하고 기존 sender command가 구현하도록 한다.
- [x] `TcpPeerFileSendCommand`와 result 타입을 추가한다.
- [x] command는 `TcpOutgoingConnectedChannelLookupCommand`를 사용한다.
- [x] command는 lookup 결과 channel id만 sender에 전달한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_peer_file_send_command_test.dart test/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task035.md lib/infrastructure/transfer/tcp_outgoing_transfer_stream_send_command.dart lib/infrastructure/transfer/tcp_peer_file_send_command.dart test/infrastructure/transfer/tcp_peer_file_send_command_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added a sender port for TCP outgoing stream transfer.
  - Added peer file send orchestration that uses only the connected outbound TCP channel from the data channel registry.
  - Missing channel and sender failure paths return explicit issue codes without route reselection.
