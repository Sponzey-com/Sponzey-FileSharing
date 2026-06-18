# task037 - TCP Listener Subscription Provider Composition

## Goal

TCP listener port와 incoming listener stream subscription coordinator를 provider 그래프에 추가해 controller가 concrete `RawTcpDataListener`에 의존하지 않고 TCP stream frame 수신을 시작할 수 있는 조립 경계를 만든다.

## Scope

- [x] TCP data listener provider를 추가한다.
- [x] TCP incoming listener stream subscription coordinator provider family를 추가한다.
- [x] subscription coordinator provider가 listener provider와 stream frame event coordinator provider를 공유하도록 한다.
- [x] provider override로 listener/logger를 테스트 더블로 대체 가능해야 한다.

## Architecture Notes

- provider는 infrastructure composition 계층에 둔다.
- listener concrete 생성은 provider 내부에만 둔다.
- subscription lifecycle start/stop은 controller 또는 이후 orchestration task에서 명시적으로 호출한다.
- destination directory는 기존 coordinator provider와 동일하게 family 인자로 전달한다.

## TDD Checklist

- [x] listener provider를 통해 `TcpDataListenerPort`를 읽을 수 있는 테스트를 작성한다.
- [x] subscription coordinator provider가 같은 listener provider 인스턴스를 참조하는 테스트를 작성한다.
- [x] subscription coordinator provider가 같은 stream frame event coordinator provider 인스턴스를 참조하는 테스트를 작성한다.

## Implementation Checklist

- [x] `tcpDataListenerProvider`를 추가한다.
- [x] `tcpIncomingListenerStreamSubscriptionCoordinatorProvider` family를 추가한다.
- [x] provider 테스트를 확장한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task037.md lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added TCP data listener provider and listener stream subscription coordinator provider.
  - Verified subscription composition shares the same listener and stream frame event coordinator instances from the provider graph.
