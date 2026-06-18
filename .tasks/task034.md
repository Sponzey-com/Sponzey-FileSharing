# task034 - TCP Outgoing Connected Channel Lookup Command

## Goal

파일 송신이 peer route 후보를 다시 고르지 않고 이미 연결된 outbound TCP data channel만 사용하도록, peer/auth 기준으로 connected channel을 찾는 application command를 추가한다.

## Scope

- [x] `peerId + authSessionId`로 outbound TCP data channel을 조회한다.
- [x] connected 상태인 session만 송신 대상으로 허용한다.
- [x] missing, inbound-only, non-connected 상태는 명시 issue code로 거부한다.
- [x] command는 socket, file system, UI에 의존하지 않는다.

## Architecture Notes

- command는 `lib/application/transfer`에 둔다.
- command는 `DataChannelSessionRegistry`만 사용한다.
- 송신 중 route lease나 peer discovery 상태를 변경하지 않는다.
- sender command는 이 command가 반환한 `TcpDataChannelId`만 사용해야 한다.

## TDD Checklist

- [x] connected outbound session의 channel id를 반환하는 테스트를 작성한다.
- [x] missing session은 `missing_tcp_outgoing_data_channel`로 거부하는 테스트를 작성한다.
- [x] inbound session만 있는 경우 outgoing 조회가 거부되는 테스트를 작성한다.
- [x] connected가 아닌 outbound session은 `tcp_outgoing_data_channel_not_connected`로 거부하는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpOutgoingConnectedChannelLookupCommand`를 추가한다.
- [x] result 타입에 `found`, `channelId`, `session`, `issueCode`를 포함한다.
- [x] command는 `TcpDataChannelDirection.outbound` key만 조회한다.
- [x] status는 `TcpDataPeerSessionStatus.connected`만 허용한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_outgoing_connected_channel_lookup_command_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task034.md lib/application/transfer/tcp_outgoing_connected_channel_lookup_command.dart test/application/transfer/tcp_outgoing_connected_channel_lookup_command_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added an application command that resolves only connected outbound TCP data channels.
  - Missing, inbound-only, and non-connected sessions are rejected with explicit issue codes.
