# Task 048. Data Frame Trace Mapper

## Goal

`TransferController._recordFrameTrace` 안의 `DataFrame` to `TransferFrameTrace` 변환 규칙을 application 계층의 순수 매퍼로 분리한다. 컨트롤러는 trace buffer 소유권과 저장만 담당하고, 진단 trace 값 구성은 독립적으로 테스트한다.

## Scope

- [x] `DataFrame`에서 `TransferFrameTrace`를 생성하는 매퍼를 추가한다.
- [x] trace 발생 시각은 매퍼 내부에서 조회하지 않고 호출자가 명시적으로 전달한다.
- [x] ring buffer 생성과 add 동작은 컨트롤러에 유지한다.

## Functional Requirements

- [x] frame type은 `frame.type.name`으로 기록한다.
- [x] sequence, chunkIndex, ackBase는 frame 값을 그대로 기록한다.
- [x] direction, endpoint, datagramBytes, decisionCode는 호출자가 전달한 값을 그대로 기록한다.
- [x] occurredAt은 호출자가 전달한 값을 그대로 기록한다.

## Architecture Requirements

- [x] 매퍼는 `lib/application/transfer`에 둔다.
- [x] 매퍼는 Flutter, Riverpod, 파일 시스템, 네트워크 소켓, 타이머에 의존하지 않는다.
- [x] 매퍼는 `TransferDiagnosticsRingBuffer`를 생성하거나 변경하지 않는다.

## TDD Requirements

- [x] frame 필드가 trace 필드로 정확히 복사되는 테스트를 먼저 작성한다.
- [x] 컨트롤러가 직접 `TransferFrameTrace(...)`를 생성하지 않고 매퍼를 사용하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_frame_trace_mapper_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferFrameTraceMapper`가 추가되어 있다.
- [x] `_recordFrameTrace`가 trace 값 생성을 매퍼에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
