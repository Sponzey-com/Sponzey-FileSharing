# Task 010 - 다중 파일, 1:N 전송, 전송 큐 확장

## 목표

단일 파일 전송을 확장해 다중 파일과 여러 peer 대상 1:N 전송을 지원한다. 하나의 UI 작업은 parent job으로 보이고, 내부적으로 대상별 child transfer session으로 분리되어야 한다.

## 연관 문서

- [phase002 plan.md - 다중 파일과 1:N 전송](plan.md#phase-009-다중-파일과-1n-전송)
- [task003.md](task003.md)
- [task009.md](task009.md)

## 선행 조건

- [task008.md](task008.md)의 단일 파일 전송이 동작해야 한다.
- [task009.md](task009.md)의 retry/window 기반 신뢰성 정책이 있어야 한다.

## 포함 기능

### 기능 1. Parent TransferJob과 child TransferSession

- 사용자의 하나의 전송 요청을 parent job으로 만든다.
- 대상 peer별 child session을 생성한다.
- 대상별 성공, 실패, 취소 상태가 독립적으로 유지된다.

### 기능 2. 다중 파일 metadata와 파일 hash 재사용

- 여러 파일 metadata를 TransferOffer에 포함한다.
- 파일 hash와 chunk metadata는 1:N 전송에서 재사용한다.
- mutable buffer 공유로 세션 상태가 섞이지 않게 한다.

### 기능 3. Queue concurrency와 Data Port 전략

- 동시 전송 세션 수 제한을 둔다.
- 단일 Data Port multiplexing과 Data Port Range 할당 중 채택 전략을 구현한다.
- queue cancel, drain, throttled 상태를 표현한다.

## 구현 체크리스트

- [x] parent TransferJob 모델을 확정했다.
- [x] child TransferSession 모델을 확정했다.
- [x] 다중 파일 TransferOffer schema를 구현했다.
- [x] 파일별 metadata, checksum, chunkCount를 생성한다.
- [x] 파일 hash와 metadata 재사용 전략을 구현했다.
- [x] 대상별 TransferSession 상태를 독립적으로 관리한다.
- [x] queue concurrency limit을 적용했다.
- [x] throttled 상태를 상태 머신에 연결했다.
- [ ] queue cancel을 구현했다.
- [x] queue drain 완료 이벤트를 구현했다.
- [x] 1:N에서 일부 peer 실패와 일부 peer 성공을 분리 집계한다.
- [x] UI projection용 aggregate status를 만든다.

## 테스트

- [x] 여러 파일 순차 전송 테스트를 작성했다.
- [x] 여러 파일 중 하나 실패 시 job 상태 집계 테스트를 작성했다.
- [x] 1:N 전송에서 일부 peer 성공, 일부 peer 실패 테스트를 작성했다.
- [ ] 하나의 peer cancel이 다른 peer에 영향 없는 테스트를 작성했다.
- [x] queue concurrency limit 테스트를 작성했다.
- [x] queue throttled/draining 전이 테스트를 작성했다.
- [ ] parent job cancel 시 child session cancel 전파 테스트를 작성했다.
- [x] 파일 hash 재사용이 mutable state 공유로 이어지지 않는 테스트를 작성했다.
- [x] Data Port range 또는 multiplexing 전략 테스트를 작성했다.

## 검증

- [x] 사용자가 여러 파일을 선택해 전송할 수 있다.
- [x] 여러 peer를 선택해 1:N 전송을 시작할 수 있다.
- [x] UI에서 parent job과 peer별 child result가 모두 이해 가능하게 표시된다.
- [x] 한 peer의 네트워크 실패가 다른 peer 전송을 중단시키지 않는다.

## 진행 결과

- `lib/domain/transfer/batch_transfer_plan.dart`
- `lib/domain/transfer/transfer_queue_state_machine.dart`
- `lib/application/transfer/transfer_controller.dart`
- `test/domain/transfer/batch_transfer_plan_test.dart`
- `test/application/transfer/transfer_controller_test.dart`

## 남은 비수동 후속

- parent/queue cancel 전파는 cancel packet 구현과 함께 마무리해야 한다.

## 완료 기준

- 다중 파일과 1:N 전송이 전송 큐를 통해 관리된다.
- 대상별 결과가 독립적으로 보존된다.
- phase의 핵심 제품 목표인 개별/일괄 전송 구조가 구현된다.
