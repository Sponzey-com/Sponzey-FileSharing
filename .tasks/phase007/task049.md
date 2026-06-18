# Task 049. Data Frame Factory

## Goal

`TransferController` 내부의 outgoing/incoming Data channel frame 생성 규칙을 application 계층 factory로 분리한다. 컨트롤러는 context에서 필요한 값만 명시적으로 꺼내 전달하고, `DataFrame` 값 생성 규칙은 독립 테스트로 고정한다.

## Scope

- [x] outgoing DataFrame 생성 규칙을 factory로 분리한다.
- [x] incoming DataFrame 생성 규칙을 factory로 분리한다.
- [x] private context 타입은 factory에 전달하지 않는다.

## Functional Requirements

- [x] outgoing frame은 session hash, transfer id bytes, type, sequence를 그대로 사용한다.
- [x] outgoing frame의 기본 windowStart/windowSize는 remote window 값을 사용한다.
- [x] outgoing frame의 payload, ackBase, ackBitmapWords override를 보존한다.
- [x] incoming frame은 session hash, transfer id bytes, type, sequence를 그대로 사용한다.
- [x] incoming frame의 기본 windowStart는 next expected chunk 값을 사용한다.
- [x] incoming frame의 기본 windowSize는 호출자가 계산해 전달한 receiver window 값을 사용한다.

## Architecture Requirements

- [x] factory는 `lib/application/transfer`에 둔다.
- [x] factory는 Flutter, Riverpod, 파일 시스템, 네트워크 소켓, 타이머에 의존하지 않는다.
- [x] factory는 private controller context에 의존하지 않는다.
- [x] receiver window 계산은 기존 `TransferIncomingWindowCommand`를 통해 컨트롤러에서 명시적으로 전달한다.

## TDD Requirements

- [x] outgoing frame 기본/override 필드 테스트를 먼저 작성한다.
- [x] incoming frame 기본/override 필드 테스트를 먼저 작성한다.
- [x] 컨트롤러가 `TransferDataFrameFactory`에 위임하는 구조 테스트를 작성한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_data_frame_factory_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] `TransferDataFrameFactory`가 추가되어 있다.
- [x] `_dataFrame`과 `_incomingDataFrame`이 factory에 위임한다.
- [x] 변경 범위 테스트와 정적 분석이 통과한다.
