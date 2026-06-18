# task042 - TCP Data Channel Control Packet Boundary

## Goal

TCP data channel endpoint negotiation에 사용할 control packet wire type과 encode/decode 필드를 추가한다. 이 태스크는 protocol boundary만 고정하며, 실제 송수신 핸들러와 connector 호출은 후속 task로 분리한다.

## Scope

- [x] `DATA_CHANNEL_OFFER`, `DATA_CHANNEL_CONNECT`, `DATA_CHANNEL_ACCEPT`, `DATA_CHANNEL_REJECT` packet type을 추가한다.
- [x] TCP data session id, endpoint host, endpoint port, direction 필드를 `AuthPacket` encode/decode에 추가한다.
- [x] TCP data channel control packet은 auth product log로 분류되지 않도록 transfer/control packet 필터에 포함한다.
- [x] 기존 auth/transfer packet decode 호환성을 유지한다.

## TDD Checklist

- [x] endpoint offer packet이 encode/decode 후 type, session id, host, port를 보존하는 테스트를 작성한다.
- [x] endpoint reject packet이 encode/decode 후 reject code/message와 data session id를 보존하는 테스트를 작성한다.
- [x] 기존 optional field 없는 legacy packet decode 테스트를 유지한다.
- [x] TCP data channel negotiation packet이 기존 transfer dispatcher에서 후속 task 전까지 `ignored`로 유지되는지 테스트한다.

## Implementation Checklist

- [x] `AuthPacketType`에 TCP data channel control wire types를 추가한다.
- [x] `AuthPacket` 생성자, 필드, encode map, decode factory에 data channel fields를 추가한다.
- [x] `RawUdpControlTransport` transfer packet log filter에 data channel control packet types를 추가한다.
- [x] 인증 컨트롤러와 기존 전송 제어 디스패처의 exhaustive switch에서 새 타입을 명시적으로 무시하도록 고정한다.

## Validation

- [x] `flutter test test/infrastructure/auth/auth_packet_test.dart --reporter compact`
- [x] `flutter test test/application/transfer/transfer_control_packet_dispatcher_test.dart --reporter compact`
- [x] `flutter analyze`
- [x] `git diff --check -- .tasks/task042.md lib/infrastructure/auth/auth_packet.dart lib/infrastructure/control/control_transport.dart lib/application/auth/peer_auth_controller.dart lib/application/transfer/transfer_control_packet_dispatcher.dart test/infrastructure/auth/auth_packet_test.dart test/application/transfer/transfer_controller_test.dart test/application/transfer/transfer_control_packet_dispatcher_test.dart`

## Completion Report

- Status: completed
- Notes:
  - TCP data channel negotiation wire boundary is now encoded/decoded and isolated from existing auth and UDP transfer dispatch flows.
  - Runtime negotiation handling remains intentionally deferred to the next task.
