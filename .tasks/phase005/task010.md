# task010 - Batch ACK/SACK, Retransmission Scheduler, RTT/Loss Metrics

## 목적

고속 UDP 전송에서 per-chunk ACK와 chunk별 Timer는 성능을 망친다. 이 태스크는 ACK/SACK batch, retransmission scheduler, RTT/loss metric을 session 단위로 구현해 안정성과 속도를 동시에 확보한다.

## 진행 현황

- [x] Data ACK는 pending set과 짧은 flush timer를 통해 batch 전송하며 bitmap으로 여러 chunk ACK를 전달한다.
- [x] sender는 Data ACK bitmap을 해석해 여러 chunk를 한 번에 acknowledged 처리한다.
- [x] chunk별 Timer 대신 session 단위 retransmission scan timer로 in-flight chunk timeout을 검사한다.
- [x] RTT, retry, loss, duplicate, throughput metric은 aggregate 상태와 throttle된 debug log로만 반영한다.
- [x] ACK frame 수가 chunk 수보다 적음을 fake DataTransport controller 테스트로 고정했다.
- [x] 관련 검증: `flutter test test/application/transfer test/domain/transfer`, `flutter analyze`

## 기능 범위

### 1. Batch ACK/SACK scheduler

- [x] receiver는 매 chunk마다 ACK를 보내지 않는다.
- [x] cumulative ack base와 SACK bitmap 또는 range list를 유지한다.
- [x] ACK는 packet count 또는 짧은 duration 기준으로 batch한다.
- [x] 마지막 chunk 수신, gap 해소, window pressure 변화 시 즉시 ACK를 보낼 수 있다.
- [x] ACK/SACK frame은 Data channel에서 처리하고 Control channel로 되돌리지 않는다.

### 2. Retransmission scheduler

- [x] sender는 chunk별 Timer 수천 개를 만들지 않는다.
- [x] session tick 기반 retransmission scan을 사용한다.
- [x] timeout scan이 missing chunk를 retransmission queue에 넣는다.
- [x] NACK range 수신 시 해당 chunk만 재전송 대상으로 잡는다.
- [x] retry 한도 초과 시 transfer failed가 된다.

### 3. RTT, loss, congestion metric

- [x] ACK 기준 RTT estimator를 갱신한다.
- [x] loss rate, retry count, duplicate count를 aggregate metric으로 반영한다.
- [x] repeated timeout은 congestion window 감소로 이어진다.
- [x] metrics는 UI와 diagnostics에 aggregate로만 전달한다.
- [x] product/info log에 per-packet metric을 남기지 않는다.

## 구현 지침

- ACK/NACK/SACK 판단의 순수 규칙은 domain/application 테스트로 검증한다.
- scheduler의 timer 구현은 infrastructure 또는 application orchestration에서 주입 가능해야 한다.
- fake clock 또는 deterministic scheduler로 테스트한다.
- ACK storm을 방지하는 테스트를 반드시 포함한다.
- metric은 throughput 계산에 필요한 최소값부터 시작한다.

## 예상 변경 위치

- [x] `lib/domain/transfer/`
- [x] `lib/application/transfer/`
- [x] `lib/infrastructure/transfer/`
- [x] `test/domain/transfer/`
- [x] `test/application/transfer/`

## 테스트

- [x] 100개 chunk 수신 시 ACK packet 수가 chunk 수보다 충분히 적다.
- [x] ACK interval timer가 마지막 ACK를 flush한다.
- [x] gap 감지 시 SACK bitmap 또는 NACK range가 생성된다.
- [x] timeout scan이 missing chunk를 재전송 대상으로 만든다.
- [x] NACK 수신 시 해당 chunk만 재전송된다.
- [x] repeated timeout은 congestion window를 줄인다.
- [x] ACK storm이 발생하지 않는다.
- [x] receiver buffer pressure가 증가하면 advertised window가 줄어든다.
- [x] RTT와 loss rate가 aggregate metric으로 업데이트된다.
- [x] metrics update가 per-packet MessageBus event로 폭증하지 않는다.

## 검증 명령

- [x] `flutter test test/domain/transfer`
- [x] `flutter test test/application/transfer`
- [x] `flutter analyze`

## 완료 기준

- [x] ACK는 batch/SACK 기반으로 동작한다.
- [x] retransmission은 session scheduler로 동작한다.
- [x] RTT, loss, retry metric이 aggregate로 유지된다.
- [x] ACK/NACK/SACK가 Control channel로 되돌아가지 않는다.

## 리스크와 주의사항

- timer를 chunk마다 만들지 않는다.
- ACK interval을 너무 길게 잡아 completion latency를 악화시키지 않는다.
- metrics 정확도를 위해 전송 루프에 과도한 logging 비용을 넣지 않는다.