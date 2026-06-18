# task025 - TCP Incoming Payload Writer Infrastructure Adapter

## Goal

TCP 수신 스트림 프레임이 application 계층의 `TcpIncomingTransferPayloadWriterPort`를 통해 실제 수신 writer 세션에 안전하게 기록되도록 인프라 어댑터를 구현한다.

## Scope

- [x] TCP 수신 payload writer 세션을 `peerId + authSessionId + transferId` 단위로 독립 관리한다.
- [x] 등록된 세션에 대해서만 `open`, `writeChunk`, `verify`, `finalize`, `complete`, `cancel`, `cleanup`, `fail`을 수행한다.
- [x] digest 검증, finalize, discard는 기존 `TransferFileService` 경계를 재사용한다.
- [x] 누락된 세션, write 실패, digest mismatch, finalize 실패는 명시적인 `AppException`으로 변환한다.
- [x] UI, controller, UDP 데이터 채널에는 직접 연결하지 않는다.

## Architecture Notes

- 어댑터는 `lib/infrastructure/transfer`에 둔다.
- application 계층은 `TcpIncomingTransferPayloadWriterPort` 추상화만 알고, `TransferFileService`와 파일 시스템 구현은 모른다.
- writer session key는 TCP channel context의 key를 그대로 사용한다.
- 세션 registry는 전역 singleton이 아니라 생성자 주입으로 전달한다.
- 대량 데이터 chunk는 MessageBus나 로그로 흘리지 않고 writer에만 전달한다.

## TDD Checklist

- [x] 등록된 writer session에 chunk payload가 append되는 테스트를 먼저 작성한다.
- [x] digest 검증 성공 후 finalize가 기존 `TransferFileService.finalizeIncomingFile`을 호출하는 테스트를 작성한다.
- [x] 등록되지 않은 key의 write/finalize가 명시 코드로 실패하는 테스트를 작성한다.
- [x] digest mismatch가 finalize로 진행되지 않는 테스트를 작성한다.
- [x] cancel/cleanup/fail이 writer close와 draft discard를 수행하고 registry에서 제거되는 테스트를 작성한다.

## Implementation Checklist

- [x] `TcpIncomingTransferPayloadWriterSession` 값 객체를 추가한다.
- [x] `TcpIncomingTransferPayloadWriterSessionRegistry` 인터페이스와 in-memory 구현을 추가한다.
- [x] `TcpIncomingTransferPayloadWriterAdapter`가 `TcpIncomingTransferPayloadWriterPort`를 구현하도록 한다.
- [x] adapter는 `IncomingDigestingTransferWriter`와 `TransferFileService`를 사용해 append, digest, finalize, discard를 수행한다.
- [x] writer session lifecycle이 transfer key 단위로 격리되도록 한다.

## Validation

- [x] `flutter test test/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task025.md lib/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter.dart test/infrastructure/transfer/tcp_incoming_transfer_payload_writer_adapter_test.dart`

## Completion Report

- Status: completed
- Notes:
  - Added the infrastructure writer session registry and adapter for TCP incoming payloads.
  - Registered sessions now own chunk append, digest verification, finalize, cancel, cleanup, and failure cleanup boundaries.
  - Missing sessions and digest mismatches are explicit `AppException` failures instead of silent no-ops.
