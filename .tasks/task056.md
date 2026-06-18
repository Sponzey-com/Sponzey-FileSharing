# Task 056. Disable Legacy UDP Send Fallback For TCP Default Path

## Goal

파일 전송 기본 경로가 TCP data channel인 상태에서 outbound TCP channel이 없을 때 legacy UDP transfer init으로 fallback하지 않도록 막는다. TCP channel 부재는 TCP 전송 실패로 표시하고, UDP route lease 만료/변경 메시지가 TCP 전송 UI에 노출되지 않게 한다.

## Scope

- [x] `TransferController.sendFile`이 `missing_tcp_outgoing_data_channel`에서도 UDP transfer init으로 내려가지 않게 한다.
- [x] TCP send use case 실패 결과를 outgoing failed transfer job으로 projection한다.
- [x] TCP channel 부재 시 `transferInit` control packet이 발행되지 않는 회귀 테스트를 추가한다.
- [x] legacy UDP fallback은 `AppConfig.allowLegacyUdpDataFallback`이 bootstrap 시점에 명시된 경우에만 허용한다.

## Functional Requirements

- [x] 인증된 peer라도 TCP outbound data channel이 없으면 파일 전송은 failed job으로 끝난다.
- [x] 실패 메시지는 TCP channel 부재를 설명하고 legacy route lease 오류를 포함하지 않는다.
- [x] UDP `transferInit` packet은 TCP 기본 전송 경로에서 발행되지 않는다.

## Architecture Requirements

- [x] fallback 차단은 presentation이 아니라 application controller 경계에서 수행한다.
- [x] TCP 실패 job에는 `DataTransferCapability.tcpDataStreamV1`을 명시한다.
- [x] 기존 UDP 전송 코드는 legacy code로 남아도 기본 `sendFile` 경로에서는 호출하지 않는다.
- [x] fallback 선택은 런타임 중간 변경 없이 bootstrap config로만 주입한다.

## TDD Requirements

- [x] TCP channel 부재 시 `transferInit` 미발행 테스트를 먼저 작성한다.
- [x] 구현 후 기존 TCP connected 전송 테스트가 계속 통과해야 한다.
- [x] 변경 후 실패한 legacy fallback 테스트는 TCP 기본 정책에 맞게 별도 migration 대상임을 확인한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "does not fallback to legacy UDP transfer when TCP channel is missing" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "uses TCP send path without UDP transfer init when TCP channel is connected" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check`

## Follow-Up

기존 controller-level UDP data transfer 테스트를 TCP 기본 경로 또는 legacy UDP 전용 lower-level 테스트로 분리하는 작업은 `task058`의 정책 문서화와 이후 별도 migration task에서 추적한다.

## Done Criteria

- [x] TCP 기본 경로에서 UDP route lease 만료/변경 오류가 파일 전송 실패 원인으로 노출되지 않는다.
- [x] TCP channel이 없으면 명확한 TCP channel 부재 실패 job이 생성된다.
