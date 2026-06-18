# task049 - TCP Data Channel Auto Establishment Smoke

## Goal

인증된 peer 간 `DATA_CHANNEL_OFFER` 발행, TCP connect, hello 수신, inbound/outbound registry 등록이 실제 raw TCP loopback transport로 end-to-end 연결되는지 검증한다.

## Scope

- [x] `TransferController` 기반 두 노드가 인증된 뒤 selected route를 기준으로 TCP offer를 발행한다.
- [x] offer 수신 노드는 raw TCP connector로 상대 listener에 연결한다.
- [x] listener 노드는 hello를 검증하고 inbound registry에 session을 등록한다.
- [x] connector 노드는 outbound registry에 session을 등록한다.
- [x] registry 등록 이후 파일 전송은 UDP transfer init 대신 TCP send path로 진입할 수 있어야 한다.

## TDD Checklist

- [x] fake outbound command가 아닌 default raw TCP provider를 사용하는 integration 성격의 테스트를 작성한다.
- [x] 송신자 outbound registry와 수신자 inbound registry가 각각 같은 auth session 기준으로 등록되는지 확인한다.
- [x] hello peer id가 receiver 기준 authenticated peer id로 검증되는지 확인한다.
- [x] 테스트 종료 시 raw connector/listener socket을 닫아 비동기 이벤트 누수를 방지한다.

## Implementation Checklist

- [x] `transfer_controller_test.dart`에 loopback TCP auto establishment 테스트를 추가한다.
- [x] 필요한 경우 test helper에 registry wait helper를 추가한다.
- [x] 실패 시 provider wiring, listener subscription, hello expectation, registry promotion 중 원인을 좁혀 수정한다.
- [x] 기존 UDP fallback 전송 테스트는 변경하지 않는다.
- [x] hello expectation resolver가 provider 생성 시점 auth state를 캡처하지 않고 resolve 시점 최신 auth state를 읽도록 수정한다.

## Validation

- [x] `flutter test test/application/transfer/transfer_controller_test.dart --plain-name "establishes TCP data channel registries from control offer" --reporter compact`
- [x] `flutter test test/application/transfer/transfer_controller_test.dart --reporter compact`
- [x] `flutter test test/infrastructure/transfer/tcp_transfer_pipeline_providers_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task049.md test/application/transfer/transfer_controller_test.dart lib/application/transfer/transfer_controller.dart lib/infrastructure/transfer/tcp_transfer_pipeline_providers.dart`

## Completion Report

- Status: completed
- Notes:
  - 실제 raw TCP loopback transport로 control offer 이후 outbound/inbound registry가 모두 등록되는 것을 검증했다.
  - inbound resolver는 최신 `PeerAuthState`를 resolve 시점에 읽도록 수정했다.
