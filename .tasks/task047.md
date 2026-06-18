# task047 - TCP Data Channel Offer Publisher

## Goal

TCP listener가 준비된 로컬 노드는 인증된 peer에게 `DATA_CHANNEL_OFFER`를 자동 발행한다. offer에는 검증된 route의 local control address와 TCP listener port를 사용해, peer가 잘못된 `0.0.0.0` 또는 stale route로 붙지 않도록 한다.

## Scope

- [x] TCP listener binding을 `TransferController`가 보관한다.
- [x] 인증 완료 peer가 생기면 해당 peer에게 `DATA_CHANNEL_OFFER`를 송신한다.
- [x] listener bind 직후 이미 인증된 peer가 있으면 offer를 송신한다.
- [x] selected route의 local endpoint address가 없으면 offer를 보내지 않는다.
- [x] 인증 완료 후 selected route가 늦게 준비되어도 path registry 변경을 트리거로 offer를 재시도한다.
- [x] dispose 이후 늦게 도착한 offer 처리와 offer 재시도가 `ref`를 읽지 않고 중단된다.

## TDD Checklist

- [x] 인증된 peer가 생기면 `DATA_CHANNEL_OFFER`가 송신되는 테스트를 작성한다.
- [x] offer packet이 selected route local address와 listener port를 포함하는지 테스트한다.
- [x] selected route가 준비된 뒤 path registry revision으로 offer가 재시도되는 테스트를 작성한다.
- [x] listener binding이 없거나 selected route가 없으면 offer를 보내지 않는 경로를 helper guard로 고정한다.

## Implementation Checklist

- [x] `_tcpDataListenerBinding`과 `_offeredTcpDataPeers`를 추가한다.
- [x] `ref.listen(peerAuthControllerProvider, ...)`에서 새 authenticated peer를 감지한다.
- [x] `ref.listen(peerPathRegistryRevisionProvider, ...)`에서 authenticated peer의 route 준비 이후 offer를 재시도한다.
- [x] `_sendTcpDataChannelOffer` helper를 추가해 packet 생성과 route local endpoint 선택을 캡슐화한다.
- [x] `_dispose`에서 binding과 offered peer set을 정리한다.
- [x] offer 수신/open 실패 로그 경로는 dispose 이후 no-op 처리한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "publishes TCP data channel offer after peer authentication" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task047.md lib/application/transfer/transfer_controller.dart test/application/transfer/transfer_controller_test.dart`

## Completion Report

- Status: completed
- Notes:
  - `DATA_CHANNEL_OFFER`는 TCP listener binding, authenticated peer, selected route가 모두 준비된 뒤 발행된다.
  - 인증과 route 선택 순서가 뒤바뀌어도 path registry revision을 통해 offer 발행을 재시도한다.
  - dispose 이후 늦게 들어온 offer 처리와 offer 재시도는 `ref.mounted` guard로 no-op 처리한다.
