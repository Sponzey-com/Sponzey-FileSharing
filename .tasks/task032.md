# task032 - TCP Data Listener Event Stream Port Contract

## Goal

TCP listener orchestration이 `RawTcpDataListener` concrete 타입에 묶이지 않도록 `TcpDataListenerPort`에 accepted, hello, hello error, stream frame, stream frame error 이벤트 stream 계약을 명시한다.

## Scope

- [x] `TcpDataListenerPort`에 hello stream 계약을 추가한다.
- [x] `TcpDataListenerPort`에 hello error stream 계약을 추가한다.
- [x] `TcpDataListenerPort`에 stream frame 계약을 추가한다.
- [x] `TcpDataListenerPort`에 stream frame error 계약을 추가한다.
- [x] `RawTcpDataListener`가 interface 계약을 구현하도록 `override`를 명시한다.

## Architecture Notes

- listener orchestration은 이후 task에서 port 타입에만 의존해야 한다.
- 이 task는 런타임 동작 변경이 아니라 port 경계 정리다.
- socket, codec, frame 처리 로직은 변경하지 않는다.

## TDD Checklist

- [x] `TcpDataListenerPort` interface 타입으로 accepted/hello/frame stream을 사용할 수 있는 테스트를 작성한다.
- [x] 기존 raw TCP listener loopback 테스트가 그대로 통과하는지 확인한다.

## Implementation Checklist

- [x] `TcpDataListenerPort.hellos` getter를 추가한다.
- [x] `TcpDataListenerPort.helloErrors` getter를 추가한다.
- [x] `TcpDataListenerPort.frames` getter를 추가한다.
- [x] `TcpDataListenerPort.frameErrors` getter를 추가한다.
- [x] `RawTcpDataListener` getter에 `@override`를 추가한다.

## Validation

- [x] `flutter test test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task032.md lib/application/transfer/tcp_data_channel_ports.dart lib/infrastructure/transfer_data/raw_tcp_data_channel_transport.dart test/infrastructure/transfer_data/raw_tcp_data_channel_transport_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Moved TCP listener event streams into the `TcpDataListenerPort` contract.
  - Verified raw TCP listener tests can consume hello/frame streams through the interface type.
