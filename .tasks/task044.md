# task044 - TCP Inbound Hello Subscription Boundary

## Goal

TCP listener에서 발생하는 accepted socket, hello frame, malformed hello error를 application 계층에서 구독하고 inbound TCP data session registry에 등록한다. 인증 세션 조회와 proof 정책은 별도 port로 분리해 socket 구현, UI, registry가 서로 직접 결합하지 않도록 한다.

## Scope

- [x] accepted connection 이벤트를 pending 상태로 보관한 뒤 matching hello가 오면 inbound session으로 승격한다.
- [x] hello expectation 조회를 `TcpDataHelloExpectationResolverPort`로 분리한다.
- [x] malformed hello error가 오면 pending accepted connection을 제거한다.
- [x] frame stream subscription과 hello stream subscription 생명주기를 하나의 coordinator에서 함께 관리한다.

## TDD Checklist

- [x] subscription start가 accepted/hello/error stream을 모두 구독하는지 테스트한다.
- [x] accepted 후 hello가 오면 resolver와 inbound coordinator를 거쳐 registry 등록 결과가 발행되는지 테스트한다.
- [x] resolver가 거부하면 registry 등록 없이 issue result를 발행하는지 테스트한다.
- [x] stop 이후 accepted/hello/error event가 결과를 발행하지 않는지 테스트한다.

## Implementation Checklist

- [x] `TcpDataHelloExpectationResolverPort`와 resolution value object를 추가한다.
- [x] `TcpIncomingListenerStreamSubscriptionCoordinator`에 inbound hello coordinator와 resolver를 주입한다.
- [x] accepted/hello/helloError subscription을 추가하고 `stop`, `dispose`, `isRunning`에 포함한다.
- [x] provider 조립부에 resolver와 inbound coordinator provider를 추가한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_incoming_listener_stream_subscription_coordinator_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/tcp_data_inbound_listener_event_coordinator_test.dart --reporter compact`
- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task044.md lib/application/transfer/tcp_data_hello_expectation_resolver.dart lib/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart test/application/transfer/tcp_incoming_listener_stream_subscription_coordinator_test.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - TCP listener subscription now covers accepted sockets, hello frames, malformed hello errors, stream frames, and stream frame errors under one lifecycle.
  - Hello expectation resolution is injected through an application port, keeping auth lookup policy outside the raw TCP socket layer.
