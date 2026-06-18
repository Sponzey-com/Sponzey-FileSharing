# Task 009 - UDP 신뢰성 보강, selective ack, sliding window

## 목표

UDP 기반 파일 전송에서 손실, 중복, 순서 어긋남, 지연 ack를 복구할 수 있도록 Selective Repeat ARQ와 Sliding Window 기반 신뢰성 보강을 구현한다.

## 연관 문서

- [phase002 plan.md - 신뢰성 보강](plan.md#104-신뢰성-보강)
- [task008.md](task008.md)

## 선행 조건

- [task008.md](task008.md)의 단일 파일 전송 MVP가 있어야 한다.

## 포함 기능

### 기능 1. Selective ack/nack와 missing chunk detector

- 수신자는 chunk bitmap 또는 set으로 수신 상태를 관리한다.
- ACK는 selective ack 정보를 포함할 수 있어야 한다.
- NACK는 누락 chunk 범위 또는 목록을 요청할 수 있어야 한다.

### 기능 2. Sliding Window와 retry policy

- 송신자는 window 크기 안에서 여러 chunk를 연속 전송한다.
- timeout 또는 NACK 수신 시 누락 chunk만 재전송한다.
- max retry 초과 시 failed로 전이한다.

### 기능 3. RTT estimator, degraded 상태, throughput 계측

- RTT를 측정해 timeout을 조정한다.
- 재전송이 반복되면 window size를 축소한다.
- peer별 throughput, retry count, degraded event를 기록한다.

## 구현 체크리스트

- [x] selective ack packet 구조를 정의했다.
- [x] nack range 또는 nack list 구조를 정의했다.
- [x] missing chunk detector를 구현했다.
- [x] 수신 chunk bitmap 또는 set을 구현했다.
- [x] sliding window sender를 구현했다.
- [x] inflight chunk tracking을 구현했다.
- [x] retry timeout 정책을 구현했다.
- [x] max retry 정책을 구현했다.
- [x] RTT estimator를 구현했다.
- [x] window shrink/recovery 정책을 구현했다.
- [x] throughput 측정을 구현했다.
- [x] retry/degraded event를 MessageBus로 publish했다.
- [x] Transfer 상태 머신과 retry/degraded/failed 전이를 연결했다.

## 테스트

- [x] 일부 chunk drop 후 selective retransmit 테스트를 작성했다.
- [x] duplicate chunk 수신 테스트를 작성했다.
- [x] out-of-order chunk 수신 테스트를 작성했다.
- [x] delayed ack 처리 테스트를 작성했다.
- [x] nack range 기반 재전송 테스트를 작성했다.
- [x] max retry exceeded 실패 테스트를 작성했다.
- [x] RTT estimator timeout 조정 테스트를 작성했다.
- [x] window shrink/recovery 테스트를 작성했다.
- [x] 파일 checksum 최종 검증 테스트를 작성했다.
- [x] 10%, 20%, 30% packet loss fault injection 테스트 후보를 작성했다.

## 검증

- [x] 제어 가능한 손실 환경에서 재전송으로 전송 완료가 가능하다.
- [x] 손실이 과도한 경우 무한 재시도하지 않고 실패한다.
- [x] Debug 로그에 retry, RTT, throughput 요약이 남는다.
- [x] Product 로그에는 사용자 영향 실패만 최소한으로 남는다.
- [x] UI에는 재시도 중, 실패, 완료 상태가 명확히 표시된다.

## 진행 결과

- `lib/domain/transfer/transfer_reliability.dart`
- `lib/application/transfer/transfer_rtt_estimator.dart`
- `lib/application/transfer/transfer_controller.dart`
- `test/domain/transfer/transfer_reliability_test.dart`
- `test/application/transfer/transfer_controller_test.dart`

## 완료 기준

- UDP 손실, 중복, 순서 어긋남을 기본적으로 복구할 수 있다.
- 신뢰성 정책이 테스트로 고정되어 있다.
- 다중 파일/1:N 전송으로 확장 가능한 전송 엔진이 준비되어 있다.
