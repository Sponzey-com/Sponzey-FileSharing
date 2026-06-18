# task037 - Data Frame Route Context Gate 분리

## Goal

Data channel frame을 처리하기 전에 해당 frame route가 요구하는 incoming/outgoing transfer context가 있는지 판단하는 규칙을 `TransferController` 밖으로 분리한다. 알 수 없는 전송이나 방향이 맞지 않는 frame이 다른 전송 상태를 오염시키지 않도록 context gate를 독립 테스트로 고정한다.

## Scope

- [x] `TransferDataFrameRouteContextCommand`를 추가한다.
- [x] incoming route는 incoming context가 있을 때만 허용하는 규칙을 테스트한다.
- [x] outgoing route는 outgoing context가 있을 때만 허용하는 규칙을 테스트한다.
- [x] `TransferController._hasDataFrameRouteContext`가 command decision만 사용하도록 변경한다.

## Out of Scope

- [x] Data frame dispatcher의 frame type 매핑은 변경하지 않는다.
- [x] transfer id lookup 방식은 변경하지 않는다.
- [x] frame trace logging 정책은 변경하지 않는다.

## TDD Requirements

- [x] expected direction이 incoming이면 incoming context 존재 여부만 gate 결과에 반영한다.
- [x] expected direction이 outgoing이면 outgoing context 존재 여부만 gate 결과에 반영한다.
- [x] 반대 방향 context만 존재할 때는 false를 반환한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_data_frame_route_context_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] context gate 판단 규칙이 controller가 아닌 command에 존재한다.
- [x] controller는 context lookup 결과를 command에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferDataFrameRouteContextCommand`와 단위 테스트를 추가했다.
- [x] `_hasDataFrameRouteContext`는 incoming/outgoing context lookup 결과를 command에 전달하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task038에서 incoming chunk write failure message mapping을 command로 분리한다.
