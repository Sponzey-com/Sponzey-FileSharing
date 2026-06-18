# task043 - UDP Endpoint Label Formatter 분리

## Goal

전송 로그와 진단 메시지에 사용하는 UDP endpoint label formatting을 `TransferController`에서 분리한다. endpoint label은 네트워크 문제 분석에 쓰이지만, controller가 문자열 포맷 세부사항을 직접 가지지 않도록 한다.

## Scope

- [x] `TransferEndpointLabelFormatter`를 추가한다.
- [x] endpoint가 없으면 `any`를 반환하는 규칙을 테스트한다.
- [x] endpoint 값이 있으면 `address:port/bindMode` 형식을 반환하는 규칙을 테스트한다.
- [x] `TransferController._endpointLabel`이 formatter 호출만 수행하도록 변경한다.

## Out of Scope

- [x] UDP bind mode 모델은 변경하지 않는다.
- [x] endpoint 선택 정책은 변경하지 않는다.
- [x] 로그 호출 위치와 레벨은 변경하지 않는다.

## TDD Requirements

- [x] null local address, port, bind mode는 `any`로 표시한다.
- [x] 값이 모두 있으면 기존 형식을 유지한다.
- [x] `UdpInterfaceEndpoint` 객체를 formatter에 직접 넘기지 않는다.

## Validation

- [x] `flutter test test/application/transfer/transfer_endpoint_label_formatter_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`

## Done Criteria

- [x] endpoint label formatting이 controller가 아닌 formatter에 존재한다.
- [x] controller는 endpoint field를 formatter에 전달하는 adapter만 수행한다.
- [x] 테스트와 analyze가 통과한다.

## Completion Report

- [x] `TransferEndpointLabelFormatter`와 단위 테스트를 추가했다.
- [x] `_endpointLabel`은 endpoint field를 formatter에 전달하는 adapter만 수행한다.
- [x] controller 회귀 테스트와 정적 분석을 통과했다.

## Next Task

- [x] task044에서 남은 controller 책임을 재평가하고 다음 분리 단위를 정의한다.
