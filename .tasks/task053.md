# Task 053. Hide UDP Metrics for TCP Transfer Jobs

## Goal

TCP data channel로 처리되는 전송 job에서 UDP 전송 전용 지표인 `Window`, `Retry`, `Loss`, `RTT`를 숨겨 UI 혼동을 제거한다.

## Scope

- [x] `TransferJob`에 전송 data capability를 명시하는 필드를 추가한다.
- [x] TCP 송신/수신 job 생성 시 `tcpDataStreamV1` capability를 설정한다.
- [x] Transfers UI는 TCP job에서 UDP window/retry/loss/rtt 지표를 표시하지 않는다.

## Functional Requirements

- [x] TCP outgoing completed job에는 속도와 ETA 등 일반 지표만 표시된다.
- [x] TCP incoming job에도 UDP 지표가 표시되지 않는다.
- [x] UDP legacy job은 기존 window/retry/loss/rtt 표시를 유지한다.

## Architecture Requirements

- [x] UI는 message 문자열이 아니라 `TransferJob`의 명시적 capability를 기준으로 표시 정책을 결정한다.
- [x] domain entity는 infra transport 구현체에 의존하지 않는다.
- [x] 기존 transfer history schema 변경은 이번 task 범위에서 수행하지 않는다.

## TDD Requirements

- [x] widget test로 TCP job에서 `Window`, `Retry`, `Loss`, `RTT` 텍스트가 보이지 않음을 먼저 고정한다.
- [x] 기존 transfer controller TCP E2E 테스트가 data capability를 검증한다.
- [x] presentation/widget test와 transfer controller test를 통과시킨다.

## Validation

- [x] `flutter test test/presentation/transfers/transfers_screen_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "sends and stores file payload over established TCP data channel" --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Done Criteria

- [x] TCP 전송 UI에서 UDP 전용 지표가 숨겨진다.
- [x] TCP/UDP 표시 기준이 문자열 추론이 아닌 domain field로 고정된다.
