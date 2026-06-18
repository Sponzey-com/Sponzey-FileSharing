# Task 007 - Data path failover와 전송 복구

## 목표

전송 중 선택된 Data path가 실패하거나 품질이 저하될 때 같은 interface 내 port 재시도 또는 다른 route candidate로 failover하여 전송을 복구한다.

이 태스크는 UDP 신뢰성 보강과 멀티 인터페이스 후보를 결합해, 단일 NIC 장애가 전체 peer/transfer 실패로 즉시 이어지지 않게 만드는 작업이다.

## 연관 문서

- [plan.md - DataPathFailoverStateMachine](plan.md#103-datapathfailoverstatemachine)
- [plan.md - Data path failover](plan.md#phase-003-007-data-path-failover)
- [task006.md](task006.md)

## 선행 조건

- [task006.md](task006.md)의 DataTransport와 selected data endpoint가 있어야 한다.
- [task003.md](task003.md)의 peer route candidate 목록이 있어야 한다.
- phase002의 selective ack/sliding window/retry 로직이 있어야 한다.

## 포함 기능

### 기능 1. DataPathFailoverStateMachine

- bind, ready, transferring, degraded, retryingSameInterface, failingOverInterface, failed, completed 상태를 표현한다.
- bind failure, packet loss exceeded, RTT degraded, failover success/failure 이벤트를 표현한다.
- 전송 세션별로 독립적인 상태를 유지한다.

### 기능 2. same interface retry

- 같은 local interface의 Data Port range에서 다른 port로 retry한다.
- retry 성공 시 같은 peer path를 유지하되 Data endpoint만 갱신한다.
- retry 실패 시 alternate route candidate failover로 넘어간다.

### 기능 3. alternate interface failover

- 다른 reachable candidate를 선택한다.
- Control path가 아직 유효한지 검증하거나 필요한 경우 Control re-probe를 수행한다.
- 전송 중 chunk/ack 상태를 보존하고 누락 chunk만 재전송한다.
- 1:N 전송에서 한 peer의 failover가 다른 peer 세션을 오염시키지 않는다.

## 구현 체크리스트

- [x] `DataPathFailoverStateMachine`을 정의했다.
- [x] `DataPathStatus` enum을 정의했다.
- [x] `DataPathFailoverEvent`를 정의했다.
- [x] bind failure 전이를 구현했다.
- [x] same interface retry 전이를 구현했다.
- [x] alternate interface failover 전이를 구현했다.
- [x] failover 실패 시 transfer failed 전이를 구현했다.
- [x] failover 성공 시 transfer session이 계속 진행되도록 했다.
- [x] packet loss threshold 기준을 정했다.
- [x] RTT degraded 기준을 정했다.
- [ ] TransferController가 DataPath failover effect를 실행한다.
- [ ] retransmission queue와 failover가 충돌하지 않도록 했다.
- [ ] 1:N child session별 DataPath 상태를 분리했다.
- [x] MessageBus에 `dataPathDegraded`, `dataPathFailoverStarted`, `dataPathFailoverSucceeded`, `dataPathFailoverFailed` 이벤트를 추가했다.

## 테스트

- [x] data bind 실패 시 same interface 다음 port로 retry하는 테스트를 작성했다.
- [x] same interface retry 성공 시 transfer가 계속되는 테스트를 작성했다.
- [x] same interface range exhausted 시 alternate candidate로 넘어가는 테스트를 작성했다.
- [x] alternate candidate 성공 시 누락 chunk만 재전송되는 테스트를 작성했다.
- [x] alternate candidate도 실패하면 transfer failed가 되는 테스트를 작성했다.
- [x] RTT degraded가 degraded event를 발생시키는 테스트를 작성했다.
- [x] packet loss threshold 초과가 failover를 요청하는 테스트를 작성했다.
- [x] failover 후 ACK/NACK window 상태가 유지되는 테스트를 작성했다.
- [x] 1:N 전송에서 한 peer failover가 다른 peer transfer 상태를 변경하지 않는 테스트를 작성했다.
- [x] MessageBus failover event chain의 correlationId가 유지되는 테스트를 작성했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] 관련 단위/Application 테스트가 통과한다.
- [x] failover는 상태 머신 전이로 설명 가능하다.
- [x] 무한 failover/retry loop가 없다.
- [ ] Product 로그에는 최종 사용자 영향 실패만 남고, Debug 로그에는 경로 변경 요약이 남는다.

## 완료 기준

- Data path 장애 시 같은 interface retry 또는 다른 interface failover가 가능하다.
- failover 중에도 transfer session의 chunk/ack 상태가 보존된다.
- 다중 peer 전송에서 peer별 failover가 독립적으로 관리된다.

## 메모

- 전송 중 path failover는 race condition 위험이 높다. 작은 상태 전이 단위와 fake transport 테스트를 우선한다.
- 실제 NIC 비활성화 검증은 task009 수동 체크리스트에서 다룬다.