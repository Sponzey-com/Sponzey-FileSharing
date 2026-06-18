# task007 - Data channel correctness, digest verification, 성능 튜닝

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- `DataTransferTuningPolicy`를 추가해 Data channel window, ACK batch, NACK batch, retransmission, MTU payload budget을 테스트 가능한 도메인 정책으로 분리했다.
- 기본 window를 `initial=32`, `max=256`, `receiver advertised=256`으로 확대하고, ACK batch threshold를 16으로 조정했다.
- DataFrameCodec의 payload budget 계산을 tuning policy와 같은 기준으로 맞춰 MTU 안전 범위를 한 곳에서 검증할 수 있게 했다.
- `TransferBenchmarkResult` schema를 추가해 route type, OS, build mode, file size, duration, average speed, loss, retry count, receiver digest verification을 기록할 수 있게 했다.
- DataFrame payload 변조 테스트를 추가해 receiver final digest mismatch가 sender/receiver 양쪽 실패로 전파되는지 확인했다.
- Data channel chunk 전송 중 product/info 수준 로그가 발생하지 않고, 전체 파일 경로나 payload 원문이 로그에 남지 않는지 테스트했다.
- fake Data network에 frame interceptor를 추가해 손실, 지연, 변조를 application 테스트에서 deterministic하게 재현할 수 있게 했다.
- 같은 장비/VM bridge 100MB release build benchmark와 OS별 수동 검증은 아직 수행하지 않았다.

## 목적

UDP Data channel이 빠르면서도 정확하게 동작하도록 correctness를 먼저 고정하고, 이후 benchmark 기준으로 chunk/window/ACK/retry 정책을 튜닝한다. sender 성공만으로 완료 처리하지 않고 receiver final file digest까지 확인한다.

## 기능 범위

1. receiver final digest verification과 완료 ACK 기준 확정
2. Data channel window, ACK batch, retransmission correctness 보강
3. benchmark harness와 성능 기준 기록

## 선행 조건

- [x] task005 route path 일치성 완료
- [x] task006 receiver storage lifecycle 완료
- [x] 현재 DataFrameCodec, RawUdpDataTransport, TransferController sender/receiver loop를 읽는다.

## 제외 범위

- multi-file UX는 task008에서 처리한다.
- release gate 문서화는 task011에서 처리한다.
- payload encryption 완성형 제품화는 현재 범위가 아니다.

## 계층별 변경 위치

- domain/application: transfer state, digest policy, retry/window model
- infrastructure: DataFrame codec, socket send/receive, file reader/writer, digest stream
- core: metrics logging throttle
- test: `test/domain/transfer`, `test/application/transfer`, `test/infrastructure/transfer`

## 실패 테스트 또는 수동 재현 기준

- [x] sender는 완료로 보이지만 receiver 파일이 없거나 digest mismatch인 실패 테스트를 작성한다.
- [x] out-of-order, duplicate, loss 상황에서 최종 파일이 손상되는 실패 테스트를 작성한다.
- [x] ACK가 chunk마다 발생해 속도가 떨어지는 조건을 benchmark 기준으로 기록한다.

## diagnostics/log 검토 기준

- [x] transfer metrics에 route type, file size, average speed, loss, retry count가 있는지 확인한다.
- [x] packet별 product/info 로그가 없는지 확인한다.
- [x] development log에도 payload 원문과 민감정보가 없는지 확인한다.

## 구현 체크리스트

- [x] receiver final file digest verification을 완료 상태의 필수 조건으로 둔다.
- [x] sender completed는 receiver complete ack와 digest 검증 결과 없이 확정하지 않는다.
- [x] digest mismatch는 sender/receiver 양쪽에 같은 transfer id로 실패 기록한다.
- [x] chunk size와 MTU budget을 재검토한다.
- [x] send window 기본값과 max window를 benchmark 기반으로 조정한다.
- [x] ACK batch threshold가 chunk마다 ACK를 만들지 않게 조정한다.
- [x] retransmission scheduler가 과도한 timer를 만들지 않게 한다.
- [x] progress event와 UI update를 throttle한다.
- [x] product/info 로그에서 packet별 로그를 제거한다.
- [x] receiver writer가 chunk별 open/close/flush를 하지 않게 확인한다.
- [x] benchmark result schema를 정의한다.

## 테스트 체크리스트

- [x] duplicate chunk 수신 테스트
- [x] out-of-order chunk 수신 테스트
- [x] packet loss와 retransmission 테스트
- [x] ACK batch가 chunk마다 발생하지 않는 테스트
- [x] retransmission retry count와 loss metric 계산 테스트
- [x] progress event 최소 interval 테스트
- [x] packet별 product/info 로그 미발생 테스트
- [x] sender completed가 receiver digest 검증 전 확정되지 않는 테스트
- [x] digest mismatch가 양쪽 transfer id로 실패 기록되는 테스트

## 수동 검증 체크리스트

- [ ] 같은 장비 2 인스턴스 100MB 전송
- [ ] macOS host -> Parallels Windows VM 100MB 전송
- [ ] Parallels Windows VM -> macOS host 100MB 전송
- [ ] Ubuntu 22.04 VM 또는 Linux 장비 100MB 전송
- [ ] 수신 파일 digest가 송신 파일과 동일함을 확인
- [ ] route type, OS, build mode, file size, speed, loss, retry count 기록

## 성능 기준

- [ ] 같은 장비 또는 VM bridge release build 기준 5 MB/s 이상
- [ ] 유선 LAN release build 기준 20 MB/s 목표
- [x] 손실 없는 local path에서 loss 0% 유지

## 완료 기준

- [x] receiver final file이 존재하고 digest가 일치해야 완료다.
- [ ] benchmark 결과가 문서나 diagnostics 기록으로 남는다.
- [x] correctness 테스트 통과 후 성능 튜닝이 반영된다.

## 회귀 금지 조건

- 속도 개선을 이유로 ACK/NACK correctness를 희생하지 않는다.
- sender UI만 보고 완료 처리하지 않는다.
- packet별 product log, packet별 MessageBus event, chunk별 파일 open/close를 재도입하지 않는다.
