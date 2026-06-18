# task031 - TCP Incoming Coordinator Provider Composition

## Goal

TCP incoming stream frame coordinator가 앱 provider 그래프에서 data channel registry, incoming runner registry, frame context store, metadata prepare pipeline을 공유하도록 조립한다.

## Scope

- [x] TCP data channel session registry provider를 추가한다.
- [x] TCP incoming transfer runner registry provider를 추가한다.
- [x] destination directory를 명시 인자로 받는 TCP incoming pipeline provider family를 추가한다.
- [x] destination directory를 명시 인자로 받는 TCP incoming stream frame coordinator provider family를 추가한다.
- [x] provider 그래프가 전역 singleton이나 환경 재조회 없이 구성되는지 검증한다.

## Architecture Notes

- provider는 infrastructure composition 계층에 둔다.
- runner registry는 application 타입이지만 provider 조립은 infrastructure에서 수행한다.
- destination directory는 provider family 인자로만 전달한다.
- controller/listener subscription 연결은 다음 task에서 수행한다.

## TDD Checklist

- [x] coordinator provider가 data channel registry provider와 같은 객체를 참조하는 테스트를 작성한다.
- [x] coordinator provider가 incoming runner registry provider와 같은 객체를 참조하는 테스트를 작성한다.
- [x] pipeline provider가 명시 destination directory로 metadata prepare port를 구성하는 테스트를 작성한다.

## Implementation Checklist

- [x] `tcpDataChannelSessionRegistryProvider`를 추가한다.
- [x] `tcpIncomingTransferRunnerRegistryProvider`를 추가한다.
- [x] `tcpIncomingStreamFramePipelineCommandProvider` family를 추가한다.
- [x] `tcpIncomingStreamFrameEventCoordinatorProvider` family를 추가한다.
- [x] 기존 provider 테스트를 확장한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task031.md lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added TCP data channel registry and incoming runner registry providers.
  - Added destination-directory scoped pipeline and stream frame coordinator provider families.
  - Verified coordinator composition shares the same provider graph state instead of hidden globals.
