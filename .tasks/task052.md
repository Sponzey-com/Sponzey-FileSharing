# Task 052. TCP Connector Lifecycle Cleanup

## Goal

`TransferController`가 종료될 때 TCP listener뿐 아니라 outbound connector도 명시적으로 닫아 반복 실행, 테스트, 앱 종료 시 TCP socket/resource가 남지 않도록 한다.

## Scope

- [x] 테스트 하네스에서 `TcpDataConnectorPort`를 주입할 수 있게 한다.
- [x] `TransferController._dispose()`가 TCP incoming result subscription, TCP incoming subscription, TCP listener, TCP connector를 모두 정리한다.
- [x] TCP connector close는 idempotent 구현을 전제로 하며, 중복 close가 오류를 만들지 않도록 한다.

## Functional Requirements

- [x] transfer controller dispose 시 connector `close()`가 1회 이상 호출된다.
- [x] listener close 순서와 기존 subscription stop 동작을 깨뜨리지 않는다.
- [x] 실제 raw connector가 생성되지 않은 테스트에서도 명시 주입된 connector가 닫힌다.

## Architecture Requirements

- [x] lifecycle cleanup은 infrastructure 구현체 세부사항이 아니라 `TcpDataConnectorPort` 인터페이스를 통해 수행한다.
- [x] UI나 domain 계층에는 socket cleanup 세부사항을 노출하지 않는다.

## TDD Requirements

- [x] failing test: dispose 시 recording connector의 close count가 증가해야 한다.
- [x] implementation: `_dispose()`에서 connector port를 닫는다.
- [x] regression: 기존 TCP listener close 테스트와 transfer controller suite가 통과해야 한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "closes TCP data connector on dispose" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] connector lifecycle cleanup이 테스트로 고정되어 있다.
- [x] 전체 transfer controller 테스트가 통과한다.
