# Task 003 - 인증, 전송 큐, 송수신 전송 상태 머신

## 목표

Peer 인증 연동, 전송 큐, 송신 전송, 수신 전송 절차를 상태 머신으로 분리한다.

이 태스크는 실제 UDP 메시지 송수신 구현 전에 절차의 성공, 실패, 취소, 재시도 경계를 테스트로 고정하는 작업이다.

## 연관 문서

- [phase002 plan.md - PeerLinkStateMachine](plan.md#66-peerlinkstatemachine)
- [phase002 plan.md - TransferQueueStateMachine](plan.md#67-transferqueuestatemachine)
- [phase002 plan.md - OutgoingTransferStateMachine](plan.md#68-outgoingtransferstatemachine)
- [phase002 plan.md - IncomingTransferStateMachine](plan.md#69-incomingtransferstatemachine)

## 선행 조건

- [task002.md](task002.md)가 완료되어 상태 머신 공통 타입이 있어야 한다.

## 포함 기능

### 기능 1. PeerLinkStateMachine과 SecureSession 상태

- discovered, linkRequested, challenge, authenticating, authenticated, rejected, expired, failed 흐름을 표현한다.
- 인증 성공 전 transfer offer가 금지되는 규칙을 고정한다.
- session key lifecycle을 별도 상태 또는 PeerLink 상태에 통합한다.

### 기능 2. TransferQueueStateMachine

- empty, queued, dispatching, running, throttled, draining, completed, failed, cancelled 상태를 표현한다.
- 1:N 전송을 parent job과 child session으로 분리하는 절차를 반영한다.
- 인증되지 않은 peer 대상으로 dispatch할 수 없도록 한다.

### 기능 3. Outgoing/Incoming Transfer StateMachine

- 송신 측 offer, accept 대기, file 준비, chunk 송신, ack 대기, retry, finish, cancel, fail을 표현한다.
- 수신 측 offer 수신, 정책 판단, 승인 대기, 저장 경로 준비, chunk 수신, retransmit 요청, checksum 검증, 완료/실패를 표현한다.
- 수신 정책 승인 전 파일 생성 금지, destination 준비 전 chunk write 금지 규칙을 고정한다.

## 구현 체크리스트

- [x] `PeerLinkStateMachine` 상태와 이벤트를 정의했다.
- [x] session key 상태 `none`, `negotiating`, `established`, `refreshing`, `expired`, `revoked`, `failed`, `destroyed`를 반영했다.
- [x] `TransferQueueStateMachine` 상태와 이벤트를 정의했다.
- [x] parent job과 child transfer session 관계를 상태 모델에 반영했다.
- [x] `OutgoingTransferStateMachine` 상태와 이벤트를 정의했다.
- [x] `IncomingTransferStateMachine` 상태와 이벤트를 정의했다.
- [x] 상태 머신이 UDP packet 타입에 직접 의존하지 않도록 추상 event를 사용했다.
- [x] cancel, timeout, max retry, checksum failure 같은 실패 경로를 모두 명시했다.
- [x] 상태 전이에 필요한 effect를 결과 타입으로 표현했다.

## 테스트

- [x] discovered 전 link request 금지 테스트를 작성했다.
- [x] token verified 전 transfer offer 금지 테스트를 작성했다.
- [x] session expired 후 transfer command 거부 테스트를 작성했다.
- [x] session key `established` 전 encrypted data 전송 금지 테스트를 작성했다.
- [x] 인증되지 않은 peer로 queue dispatch 금지 테스트를 작성했다.
- [x] 1:N job이 대상별 child session으로 분리되는 테스트를 작성했다.
- [x] 한 대상 실패가 다른 대상 성공 상태를 덮어쓰지 않는 테스트를 작성했다.
- [x] offerAccepted 전 Data Port 전송 금지 테스트를 작성했다.
- [x] filePrepared 전 chunk 송신 금지 테스트를 작성했다.
- [x] policyAllowed 또는 userAccepted 전 파일 생성 금지 테스트를 작성했다.
- [x] destinationPrepared 전 chunk write 금지 테스트를 작성했다.
- [x] checksum failure가 completed로 전이하지 않는 테스트를 작성했다.

## 검증

- [x] 인증과 전송 절차가 UI callback에 흩어지지 않고 상태 머신으로 설명된다.
- [x] 실패와 취소 상태가 성공 상태와 명확히 분리되어 있다.
- [x] 후속 controller가 상태 전이 결과를 보고 UDP 송신, 파일 IO, MessageBus publish를 실행할 수 있다.
- [x] 상태 머신 테스트만으로 주요 프로시저 오류를 재현할 수 있다.

## 진행 결과

- `lib/domain/peer_link/peer_link_state_machine.dart`
- `lib/domain/transfer/transfer_queue_state_machine.dart`
- `lib/domain/transfer/transfer_session_state_machine.dart`
- `lib/domain/receive_policy/receive_policy_state_machine.dart`
- `test/domain/peer_link/peer_link_state_machine_test.dart`
- `test/domain/transfer/transfer_queue_state_machine_test.dart`
- `test/domain/transfer/transfer_session_state_machine_test.dart`
- `test/domain/receive_policy/receive_policy_state_machine_test.dart`

## 완료 기준

- 인증, queue, 송신, 수신 전송 절차가 상태 머신으로 표현되어 있다.
- 후속 Control/Data Port 구현이 이 상태 머신을 기준으로 진행될 수 있다.