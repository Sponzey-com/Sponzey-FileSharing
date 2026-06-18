# task033 - TCP Incoming Listener Stream Subscription Coordinator

## Goal

`TcpDataListenerPort.frames`와 `frameErrors`를 구독해 `TcpIncomingStreamFrameEventCoordinator`로 전달하고, 처리 결과를 관찰 가능한 stream으로 내보내는 subscription coordinator를 추가한다.

## Scope

- [x] listener frame stream을 구독하고 coordinator `handleFrame`으로 전달한다.
- [x] listener frame error stream을 구독하고 coordinator `handleFrameError`로 전달한다.
- [x] 처리 결과를 result stream으로 발행한다.
- [x] `start`는 중복 구독을 만들지 않는다.
- [x] `stop`은 모든 subscription을 해제한다.

## Architecture Notes

- subscription coordinator는 application 계층에 둔다.
- socket 구현체나 filesystem에 의존하지 않는다.
- 구독 생명주기는 명시적인 `start`/`stop`으로 관리한다.
- frame 처리 실패는 result stream에 `tcp_incoming_frame_pipeline_failed`로 변환한다.

## TDD Checklist

- [x] frame stream 이벤트가 coordinator 결과로 발행되는 테스트를 작성한다.
- [x] frame error stream 이벤트가 runner 없이 issue result로 발행되는 테스트를 작성한다.
- [x] `start`를 두 번 호출해도 중복 결과가 발생하지 않는 테스트를 작성한다.
- [x] `stop` 이후 이벤트가 결과로 발행되지 않는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpIncomingListenerStreamSubscriptionCoordinator`를 추가한다.
- [x] `results` broadcast stream을 제공한다.
- [x] `start` 중복 호출을 no-op 처리한다.
- [x] `stop`이 subscription과 result stream 생명주기를 정리한다.

## Validation

- [x] `flutter test test/application/transfer/tcp_incoming_listener_stream_subscription_coordinator_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task033.md lib/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart test/application/transfer/tcp_incoming_listener_stream_subscription_coordinator_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added a listener stream subscription coordinator for TCP stream frames and frame errors.
  - The coordinator owns subscription lifecycle explicitly and publishes processing results through a broadcast stream.
  - Duplicate `start` calls do not create duplicate stream subscriptions.
