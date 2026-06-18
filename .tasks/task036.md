# task036 - TCP Peer File Send Provider Composition

## Goal

`TcpPeerFileSendCommand`를 provider 그래프에 추가해 controller 연결 시 동일한 TCP data channel registry와 outgoing sender command를 사용할 수 있도록 한다.

## Scope

- [x] `TcpPeerFileSendCommand` provider를 추가한다.
- [x] provider가 `TcpOutgoingConnectedChannelLookupCommand`를 명시적으로 주입한다.
- [x] provider가 `tcpOutgoingTransferStreamSendCommandProvider`를 sender port로 사용한다.
- [x] provider가 기존 file service, connector override와 함께 테스트 가능해야 한다.

## Architecture Notes

- provider는 infrastructure composition 계층에 둔다.
- command는 전역 singleton으로 직접 조회하지 않고 provider에서 생성한다.
- controller 연결은 이 provider를 통해 수행한다.

## TDD Checklist

- [x] provider에서 `TcpPeerFileSendCommand`를 읽을 수 있는 테스트를 작성한다.
- [x] connected outbound session을 registry provider에 등록하고 provider command가 sender까지 호출되는 테스트를 작성한다.

## Implementation Checklist

- [x] `tcpPeerFileSendCommandProvider`를 추가한다.
- [x] provider test에 connected outbound session 등록 후 파일 송신 호출 검증을 추가한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task036.md lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added `tcpPeerFileSendCommandProvider`.
  - Verified provider command uses the shared TCP data channel registry and outgoing stream sender provider.
