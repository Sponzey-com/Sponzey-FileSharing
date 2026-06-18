# task040 - Transfer Metric Calculation 분리

## Goal

송수신 진행률에 표시되는 throughput과 loss rate 계산을 `TransferController`에서 분리한다. 시간 의존 값은 command 내부에서 조회하지 않고 `now` 인자로 명시적으로 받아 테스트 가능성을 유지한다.

## Scope

- [x] `TransferMetricCalculationCommand`를 추가한다.
- [x] throughput 계산에서 elapsed time과 transferred bytes edge case를 테스트한다.
- [x] loss rate 계산에서 retry count와 acknowledged chunk count edge case를 테스트한다.
- [x] `TransferController._throughputBytesPerSec`, `_lossRateFor`가 command 호출만 수행하도록 변경한다.

## Out of Scope

- [x] UI 표시 단위와 반올림 정책은 변경하지 않는다.
- [x] RTT 계산 정책은 변경하지 않는다.
- [x] retry 정책은 변경하지 않는다.

## TDD Requirements

- [x] elapsed time이 0 이하이거나 transferred bytes가 0 이하이면 throughput 0을 반환한다.
- [x] 1초 동안 2048 bytes 전송이면 throughput 2048을 반환한다.
- [x] acknowledged chunk와 retry가 없으면 loss rate 0을 반환한다.
- [x] retry / acknowledged+retry 비율로 loss rate를 계산한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_metric_calculation_command_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] throughput/loss 계산이 controller가 아닌 command에 존재한다.
- [x] controller는 context field와 `_now()` 결과를 command에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferMetricCalculationCommand`와 단위 테스트를 추가했다.
- [x] `_throughputBytesPerSec`와 `_lossRateFor`는 command 호출만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task041에서 transfer id/frame key formatting 등 남은 순수 helper를 정리한다.
