# task041 - Data Frame Transfer Key Formatter 분리

## Goal

Data channel frame의 `transferIdBytes`를 `_transferIdByFrameKey` lookup key로 변환하는 규칙을 `TransferController`에서 분리한다. 송수신 frame lookup key가 일관되게 생성되어 전송 세션이 섞이지 않도록 순수 formatter로 고정한다.

## Scope

- [x] `TransferDataFrameKeyFormatter`를 추가한다.
- [x] bytes 입력을 base64Url 문자열로 변환하는 규칙을 테스트한다.
- [x] `TransferController._frameKey`가 formatter 호출만 수행하도록 변경한다.

## Out of Scope

- [x] transfer id 생성 방식은 변경하지 않는다.
- [x] `_transferIdByFrameKey` map ownership은 변경하지 않는다.
- [x] safe log masking helper는 별도 task에서 처리한다.

## TDD Requirements

- [x] 동일한 byte sequence는 동일한 key를 반환한다.
- [x] base64Url encoding 결과를 그대로 반환한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_data_frame_key_formatter_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] frame key formatting이 controller가 아닌 formatter에 존재한다.
- [x] controller는 `Uint8List`를 formatter에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferDataFrameKeyFormatter`와 단위 테스트를 추가했다.
- [x] `_frameKey`는 formatter 호출만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task042에서 transfer log-safe formatter를 분리한다.
