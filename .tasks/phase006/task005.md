# task005 - Active route lease와 Data transfer path 일치성 보장

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- `TransferRouteSnapshot`을 추가해 transfer job이 시작 시점의 active route lease, control endpoint, data endpoint를 보존하도록 했다.
- sender는 인증 세션의 stale `peerAddress`가 아니라 `PeerPathStatus.active`인 route lease의 remote address/port로 `TRANSFER_INIT`을 전송한다.
- receiver도 `TRANSFER_INIT` 처리 시 active route lease를 요구하고, control datagram local endpoint가 없으면 selected route endpoint를 data bind 기준으로 사용한다.
- `TRANSFER_INIT_ACK`로 받은 data endpoint가 active route의 remote address와 다르면 chunk 전송 전에 `transfer_route_mismatch`로 실패한다.
- data socket bind local address가 route lease local address와 다르면 chunk 전송 전에 `transfer_data_bind_mismatch`로 실패한다.
- transfer 도중 selected route lease가 사라지거나 active가 아니면 failover 대신 현재 phase 정책인 controlled failure(`transfer_route_lease_expired`)로 중단한다.
- Transfer Queue에는 route local/remote와 route lease id prefix를 표시해 sender/receiver diagnostics를 대조할 수 있게 했다.
- macOS host/Parallels Windows VM 양방향 파일 전송 수동 검증은 아직 수행하지 않았다.

## 목적

연결에서 검증한 active route lease와 파일 전송에 사용하는 data endpoint가 동일한 경로 기준을 따르도록 고정한다. sender가 엉뚱한 endpoint나 loopback으로 보내는 문제를 제거한다.

## 기능 범위

1. control handshake data endpoint와 active route lease 연결
2. transfer job route snapshot 고정
3. data socket local bind와 route lease 일치성 검증

## 선행 조건

- [x] task002 route lease 기준 확인
- [x] task004 connected/data-ready 상태 기준 확인
- [x] 현재 TransferController, DataTransport, ControlTransport, DataEndpointManager 코드를 읽는다.

## 제외 범위

- receiver 저장 경로 준비 실패 처리는 task006에서 처리한다.
- Data channel 성능 튜닝은 task007에서 처리한다.
- persisted history는 task008에서 처리한다.

## 계층별 변경 위치

- domain/application: transfer route snapshot, route mismatch error
- application: transfer start preflight, transfer session state
- infrastructure: data socket bind local address, endpoint lease
- presentation: transfer diagnostics 표시
- test: `test/application/transfer`, `test/infrastructure/transfer`

## 실패 테스트 또는 수동 재현 기준

- [x] authenticated route가 `10.211.x.x`인데 transfer target이 `127.0.0.1`로 잡히는 실패 테스트를 작성한다.
- [x] route lease local address와 data socket bind address가 다른데 전송이 시작되는 실패 테스트를 작성한다.
- [x] sender queue에는 전송 중으로 보이나 receiver에는 아무 chunk도 오지 않는 수동 재현 기준을 기록한다.

## diagnostics/log 검토 기준

- [x] transfer start 시 peer id, transfer id, session id, route lease id가 로그에 남는지 확인한다.
- [x] selected local address, remote address, control endpoint, data endpoint가 diagnostics에 연결되는지 확인한다.
- [x] route mismatch와 data endpoint missing이 별도 error code로 남는지 확인한다.

## 구현 체크리스트

- [x] Control handshake에서 받은 data endpoint를 active route lease와 연결한다.
- [x] transfer 시작 전 route lease가 active이고 data-ready인지 확인한다.
- [x] transfer job 생성 시 route snapshot을 저장한다.
- [x] sender와 receiver 모두 transfer id, session id, route lease id를 가진다.
- [x] data socket bind local address가 route lease local address와 일치하는지 확인한다.
- [x] route mismatch면 data chunk 전송 전에 controlled failure로 전이한다.
- [x] loopback route는 같은 host multi-instance가 아닌 외부 peer 전송에 사용하지 않는다.
- [x] transfer 중 route lease가 만료되면 failover 또는 controlled failure 정책을 따른다.
- [x] diagnostics에 selected route를 표시한다.
- [x] sender/receiver diagnostics를 같은 transfer id로 대조할 수 있게 한다.

## 테스트 체크리스트

- [x] authenticated route가 `10.211.x.x`이면 data transfer target도 같은 remote address 계열을 사용한다.
- [x] 외부 peer transfer에서 loopback target이 선택되지 않는다.
- [x] route mismatch 감지 시 전송 시작 전에 실패한다.
- [x] receiver가 준비한 data endpoint가 sender transfer job에 반영된다.
- [x] duplicate route 후보가 있어도 transfer job route snapshot은 고정된다.
- [x] route lease local address와 data socket local bind address 불일치 시 실패한다.
- [x] transfer 중 route lease 만료 시 정책대로 failover 또는 controlled failure로 전이한다.

## 수동 검증 체크리스트

- [ ] macOS host -> Parallels Windows VM 파일 전송 성공
- [ ] Parallels Windows VM -> macOS host 파일 전송 성공
- [ ] macOS host -> macOS 두 번째 인스턴스 전송 성공
- [ ] transfer diagnostics에 selected route가 표시된다.
- [ ] sender diagnostics와 receiver diagnostics에서 transfer id/session id를 대조할 수 있다.

## 완료 기준

- [x] 연결 성공 경로와 파일 전송 경로가 불일치하지 않는다.
- [x] route mismatch는 silent timeout이 아니라 명확한 실패로 나타난다.
- [x] sender 성공 표시 전에 receiver data readiness가 확인된다.

## 회귀 금지 조건

- 검증되지 않은 route candidate로 data transfer를 시작하지 않는다.
- sender가 `127.0.0.1`을 외부 peer data endpoint로 쓰지 않는다.
- transfer path 선택을 UI 문자열이나 표시 IP에 의존하지 않는다.
