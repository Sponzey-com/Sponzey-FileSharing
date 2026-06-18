# task041 - TransferController TCP Listener Bind Lifecycle

## Goal

`TransferController`가 TCP incoming listener subscription을 시작하기 전에 TCP data listener를 실제로 bind한다. 이 작업은 TCP data channel이 실사용 가능한 local endpoint를 갖도록 만드는 최소 runtime wiring이다.

## Scope

- [x] 기본 수신 경로가 준비된 경우 `TcpDataListenerPort.bind`를 호출한다.
- [x] TCP listener bind request는 외부 설정 파일 없이 bootstrap/runtime dependency로 주입된 port interface만 사용한다.
- [x] 초기 구현은 `0.0.0.0:0` ephemeral listener를 사용해 OS가 실제 port를 배정하도록 한다.
- [x] TCP listener bind 성공 후 incoming subscription을 시작한다.
- [x] `TransferController._dispose`에서 TCP listener를 close한다.
- [x] TCP listener bind 실패는 transfer controller 초기화 실패로 노출한다.

## Architecture Notes

- controller는 `TcpDataListenerPort` interface만 사용하고 `ServerSocket` 또는 raw socket implementation을 직접 알지 않는다.
- bound endpoint를 control/discovery에 광고하는 작업은 후속 task로 분리한다.
- 수신 경로가 준비되지 않은 경우에는 task040 정책에 따라 TCP listener bind와 subscription을 모두 skip하고 기존 UDP transfer engine은 계속 시작한다.

## TDD Checklist

- [x] 기본 수신 경로가 준비되면 listener `bind`가 subscription `start`보다 먼저 호출되는 테스트를 작성한다.
- [x] dispose 시 bound TCP listener `close`가 호출되는 테스트를 작성한다.
- [x] listener bind 실패 시 transfer controller가 `isListening=false`와 오류 메시지를 표시하는 테스트를 작성한다.
- [x] 수신 경로가 준비되지 않으면 listener bind를 호출하지 않고 기존 transfer controller가 listening 상태로 유지되는 테스트를 작성한다.

## Implementation Checklist

- [x] 테스트 하네스에 `TcpDataListenerPort` override 옵션을 추가한다.
- [x] `TransferController`에 TCP listener port 필드를 추가한다.
- [x] `_initialize`에서 `TcpDataListenerBindRequest(host: '0.0.0.0', port: 0)`로 bind한다.
- [x] bind 성공 후 incoming subscription을 시작한다.
- [x] `_dispose`에서 subscription stop 이후 listener close를 호출한다.
- [x] TCP listener bind success 로그를 기본 product/debug transfer log에 남기지 않도록 유지한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "binds TCP data listener before incoming subscription starts"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "closes TCP data listener on dispose"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "reports initialization failure when TCP data listener bind fails"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "does not bind TCP data listener when incoming receive path is unavailable"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "ignores unknown Data channel frames without creating transfer job"`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "does not emit transfer metric debug logs during noisy delivery"`
- [x] `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task041.md lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_controller_test.dart lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart`

## Completion Report

- Status: completed
- Notes:
  - Transfer controller now binds the TCP data listener before starting incoming frame subscriptions.
  - Dispose stops the incoming subscription before closing the listener.
  - Listener bind success remains silent to preserve existing transfer log noise guarantees.
