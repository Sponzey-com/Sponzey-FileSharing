# Task 050. Transfer Job Metrics Command

## Goal

`TransferController`의 송신/수신 metric job 갱신 규칙을 application 계층 명령 객체로 분리한다. 컨트롤러는 context에서 metric 값을 읽고 계산한 뒤 명시적으로 전달하며, `TransferJob` snapshot을 어떻게 갱신할지는 독립 테스트로 고정한다.

## Scope

- [x] outgoing metric job 갱신 규칙을 순수 명령 객체로 분리한다.
- [x] incoming metric job 갱신 규칙을 순수 명령 객체로 분리한다.
- [x] private context 타입은 명령 객체에 전달하지 않는다.

## Functional Requirements

- [x] outgoing 갱신은 bytesTransferred, completedChunks, retryCount, duplicateCount, lossRate, throughput, rttMs, windowSize, updatedAt, message를 반영한다.
- [x] outgoing 갱신은 기존 status를 임의로 바꾸지 않는다.
- [x] incoming 갱신은 status를 `receiving`으로 설정한다.
- [x] incoming 갱신은 bytesTransferred, completedChunks, duplicateCount, throughput, windowSize, updatedAt, message를 반영한다.
- [x] peer, file, route, transfer id 같은 식별/경로 정보는 보존한다.

## Architecture Requirements

- [x] 명령 객체는 `lib/application/transfer`에 둔다.
- [x] 명령 객체는 Flutter, Riverpod, 파일 시스템, 네트워크 소켓, 타이머에 의존하지 않는다.
- [x] 명령 객체는 외부 환경 값이나 전역 시간을 조회하지 않는다.

## TDD Requirements

- [x] outgoing metric 갱신 테스트를 먼저 작성한다.
- [x] incoming metric 갱신 테스트를 먼저 작성한다.
- [x] 컨트롤러가 metric copyWith 규칙을 직접 들고 있지 않고 명령 객체를 사용하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_job_metrics_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferJobMetricsCommand`가 추가되어 있다.
- [x] `_updateOutgoingMetrics`와 `_updateIncomingMetrics`가 명령 객체에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
