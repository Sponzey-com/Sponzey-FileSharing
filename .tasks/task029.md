# task029 - TCP Transfer Pipeline Provider Composition

## Goal

TCP data channel 전환을 실제 앱 조립 단계로 연결하기 위해 registry, metadata prepare adapter, payload writer adapter, outgoing sender command를 Riverpod provider 경계에서 구성한다.

## Scope

- [x] TCP incoming payload writer session registry provider를 추가한다.
- [x] TCP incoming frame context store provider를 추가한다.
- [x] TCP incoming payload writer port provider를 추가한다.
- [x] receiver 저장 경로를 명시 인자로 받는 metadata prepare port family provider를 추가한다.
- [x] TCP outgoing stream sender command provider를 추가한다.

## Architecture Notes

- provider는 infrastructure 조립 코드로 둔다.
- provider는 외부 설정 파일을 읽지 않는다.
- receiver 저장 경로는 provider family 인자로만 전달하고 전역으로 숨기지 않는다.
- registry는 provider graph 안에서 공유되며 전역 singleton으로 직접 조회하지 않는다.
- controller 연결은 다음 task에서 수행한다.

## TDD Checklist

- [x] metadata prepare provider와 payload writer provider가 같은 writer session registry를 공유하는 테스트를 작성한다.
- [x] receiver 저장 경로가 family 인자로 session에 반영되는 테스트를 작성한다.
- [x] outgoing sender command provider가 `TransferFileService`와 `TcpDataConnectorPort` override를 통해 테스트 더블로 대체 가능한지 검증한다.

## Implementation Checklist

- [x] `tcpIncomingTransferPayloadWriterSessionRegistryProvider`를 추가한다.
- [x] `tcpIncomingTransferFrameContextStoreProvider`를 추가한다.
- [x] `tcpIncomingTransferPayloadWriterPortProvider`를 추가한다.
- [x] `tcpIncomingMetadataFramePreparePortProvider` family를 추가한다.
- [x] `tcpOutgoingTransferStreamSendCommandProvider`를 추가한다.
- [x] provider 구성에서 mutable singleton이나 환경 재조회가 없도록 한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task029.md lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added provider composition for TCP incoming writer registry, frame context store, payload writer, metadata prepare adapter, connector, and outgoing sender command.
  - Verified provider overrides can replace file service and connector with test doubles.
  - Receiver save path is passed explicitly through a provider family argument.
