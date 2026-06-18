# task011 - UI Diagnostics, Ring Buffer, Benchmark, Release Gate

## 목적

Data Channel 전환 후 사용자는 빠른 전송 상태를 볼 수 있어야 하고, 개발자는 실패 원인을 로그 추가 없이 추적할 수 있어야 한다. 이 태스크는 Product UI, debug diagnostics, bounded ring buffer, benchmark와 release gate를 정리한다.

## 진행 현황

- [x] controller에 bounded `TransferDiagnosticsRingBuffer`를 연결해 Data frame 송수신 trace snapshot을 보관한다.
- [x] trace에는 direction, frame type, sequence, chunk index, ack base, datagram size, endpoint short, decision code만 저장한다.
- [x] diagnostics snapshot이 payload/full path/key material 없이 쌓이는지 application 테스트로 검증했다.
- [x] ring buffer capacity 초과 시 최신 항목만 유지되는 단위 테스트를 추가했다.
- [ ] Product UI에 debug diagnostics panel을 직접 노출하는 작업은 아직 남아 있다.
- [ ] macOS/Windows/Linux 10 MB, 100 MB 실제 전송 benchmark와 release gate 수동 검증은 아직 실행하지 않았다.
- [x] 관련 자동 검증: `flutter test test/application/transfer`, `flutter analyze`

## 기능 범위

### 1. Product UI aggregate 상태

- [ ] Product UI에는 진행률, 전송률, 남은 시간, 실패/재시도 상태만 표시한다.
- [ ] data endpoint, RTT, loss, retry는 기본 UI에 과도하게 노출하지 않는다.
- [ ] 긴 peer name, file name, endpoint에서도 overflow가 발생하지 않게 한다.
- [ ] 전송률은 acked bytes 또는 verified progress 기준으로 계산한다.
- [ ] 전송률이 0 B/s에 고착되지 않도록 state update 조건을 정리한다.

### 2. Debug diagnostics와 ring buffer

- [ ] Debug diagnostics에는 data endpoint, active path, chunk size, window, loss rate, retry count, RTT를 표시한다.
- [x] 실패한 transfer의 bounded ring buffer snapshot을 확인할 수 있게 한다.
- [ ] ring buffer는 timestamp, direction, frame type, sequence, chunk index, ack base, bitmap summary, datagram size, endpoint short, decision code 정도만 보관한다.
- [x] payload, full path, password, token, key material은 보관하지 않는다.
- [x] product/info log는 per-packet data log를 남기지 않는다.

### 3. Benchmark와 release gate

- [ ] 외부 설정 파일 없이 명시 인자로 실행 가능한 benchmark 또는 smoke 절차를 만든다.
- [ ] 측정 항목은 file size, elapsed ms, throughput MB/s, chunk size, datagram size, ACK count, retransmission count, loss rate, RTT estimate, selected local endpoint, remote data endpoint, OS, build mode, CPU rough sample, memory high-water mark, log line count, send failure count, receiver buffer pressure peak를 포함한다.
- [ ] macOS 동일 장비 2 인스턴스, macOS host to Windows Parallels bridged VM, macOS to macOS LAN, Windows to Windows LAN, Ubuntu 22.04 to macOS LAN, Ethernet + bridge candidate 동시 환경을 release gate 시나리오로 문서화한다.
- [ ] 10 MB와 100 MB 파일 전송 수동 검증 기준을 둔다.

## 구현 지침

- UI는 transport 구현체를 직접 호출하지 않는다. application state projection만 관찰한다.
- ring buffer는 bounded memory를 사용하고 문자열 포맷팅을 늦게 수행한다.
- diagnostics는 개발/현장 확인용이며 Product UI를 복잡하게 만들지 않는다.
- benchmark 값은 외부 config reload가 아니라 명시 인자 또는 provider override로만 전달한다.
- 수동 release gate 결과는 task checklist 또는 별도 benchmark note에 기록한다.

## 예상 변경 위치

- [ ] `lib/presentation/transfers/`
- [ ] `lib/presentation/peers/`
- [x] `lib/application/transfer/`
- [ ] `lib/core/logging/`
- [x] `test/` widget tests
- [ ] 필요 시 `scripts/`

## 테스트

- [ ] 전송률이 0 B/s에 고착되지 않는다.
- [ ] failed state에서 재시도 버튼 조건이 정확하다.
- [ ] 긴 file name과 peer name에서 overflow가 없다.
- [x] diagnostics는 payload, full path, password, token, key material을 노출하지 않는다.
- [x] diagnostics ring buffer는 bounded capacity를 초과하지 않는다.
- [ ] progress UI update가 per-packet으로 발생하지 않는다.
- [x] product/info log에 per-packet data frame 로그가 없다.

## 수동 검증

- [ ] 10 MB 파일 전송이 timeout 없이 완료된다.
- [ ] 100 MB 파일 전송이 release build에서 안정적으로 완료된다.
- [ ] 전송 중 UI가 멈추지 않는다.
- [ ] 전송 중 로그 파일이 비정상적으로 커지지 않는다.
- [ ] receiver 저장 파일 digest가 source와 일치한다.
- [ ] Windows firewall 차단 시 Data bind/connect 실패 reason이 명확하다.
- [ ] Parallels bridged VM에서 data endpoint가 control endpoint와 다르게 잡혀도 전송된다.
- [ ] 전송 시작 전 준비 시간이 파일 크기에 비례해 과도하게 증가하지 않는다.
- [ ] 같은 파일 2회 이상 반복 전송 시 speed와 loss metric 편차를 기록한다.

## 검증 명령

- [x] `flutter test`
- [x] `flutter analyze`
- [ ] macOS release 또는 profile build에서 10 MB, 100 MB 수동 전송
- [ ] Windows release 또는 profile build에서 Parallels VM 수동 전송
- [ ] Ubuntu 22.04 이상 Linux에서 수동 전송

## 완료 기준

- [ ] Product UI는 사용자가 필요한 전송 상태만 명확히 보여준다.
- [x] Debug diagnostics는 실패 원인을 ring buffer로 추적할 수 있다.
- [x] diagnostics와 log는 민감 정보를 노출하지 않는다.
- [ ] benchmark/release gate 기준이 문서화되고 최소 1개 실제 환경에서 실행 결과가 기록된다.

## 리스크와 주의사항

- diagnostics를 핑계로 per-packet product log를 되살리지 않는다.
- UI state update가 전송 루프를 압박하지 않도록 throttle한다.
- benchmark는 절대 속도보다 regressions와 병목 위치를 찾는 데 우선 사용한다.