# task040 - TransferController TCP Incoming Listener Lifecycle

## Goal

`TransferController` 초기화 시 TCP incoming listener subscription을 시작해, 이미 구성된 TCP incoming stream frame pipeline이 실제 runtime lifecycle에 연결되도록 한다. TCP 수신 frame은 기존 UDP data frame route lease 상태와 섞이지 않고 TCP data channel registry와 incoming runner registry를 통해 처리되어야 한다.

## Scope

- [x] `TransferController._initialize`에서 TCP incoming listener subscription coordinator를 시작한다.
- [x] TCP incoming coordinator에는 부트스트랩/설정 repository에서 얻은 기본 수신 경로를 명시적으로 전달한다.
- [x] `TransferController._dispose`에서 TCP incoming listener subscription을 중지한다.
- [x] TCP listener subscription 시작 실패는 transfer controller 초기화 실패로 노출한다.
- [x] 기존 UDP control/data subscription은 유지한다.
- [x] 기본 수신 경로를 준비하지 못해도 기존 UDP transfer engine 초기화는 실패시키지 않는다.

## Architecture Notes

- controller는 TCP socket이나 stream frame codec을 직접 다루지 않는다.
- controller는 `tcpIncomingListenerStreamSubscriptionCoordinatorProvider(destinationDirectory)`를 통해 application coordinator만 시작한다.
- 기본 수신 경로는 프로세스 중간 환경 재조회 없이 기존 `settingsRepositoryProvider`와 `appStoragePathProvider`를 통해 application 초기화 시점에 한 번 결정한다.
- TCP frame 처리 규칙은 기존 `TcpIncomingStreamFrameEventCoordinator`와 하위 pipeline이 담당한다.

## TDD Checklist

- [x] transfer controller 초기화 시 TCP incoming subscription coordinator의 `start`가 호출되는 테스트를 작성한다.
- [x] dispose 시 coordinator `stop`이 호출되는 테스트를 작성한다.
- [x] TCP coordinator 시작 실패 시 transfer controller가 `isListening=false`와 오류 메시지를 표시하는 테스트를 작성한다.
- [x] TCP incoming receive path 준비 실패가 기존 transfer controller startup을 막지 않는 회귀 테스트를 작성한다.

## Implementation Checklist

- [x] 테스트용 `TcpIncomingListenerStreamSubscriptionCoordinator` override seam을 추가한다.
- [x] `TransferController`에 TCP incoming subscription 필드를 추가한다.
- [x] `_initialize`에서 기본 수신 경로를 로드하고 TCP incoming coordinator를 시작한다.
- [x] `_dispose`에서 TCP incoming coordinator를 중지한다.
- [x] 초기화 실패 시 기존 error logging과 사용자 오류 메시지를 유지한다.
- [x] receive path unavailable은 warning 후 TCP incoming subscription만 skip하도록 분리한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "starts TCP incoming listener subscription during initialization"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "stops TCP incoming listener subscription on dispose"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "reports initialization failure when TCP incoming subscription fails"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "keeps transfer controller listening when TCP incoming receive path is unavailable"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "receiver uses saved receive path when default receive path cannot be prepared"`
- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task040.md lib/application/transfer/tcp_incoming_listener_stream_subscription_coordinator.dart lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_controller_test.dart test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart`

## Completion Report

- Status: completed
- Notes:
  - `TransferController` now starts/stops the TCP incoming listener subscription through an interface provider.
  - TCP incoming receive path preparation failure no longer fails the legacy transfer engine startup.
  - TCP subscription `start()` failure still reports transfer engine initialization failure.
