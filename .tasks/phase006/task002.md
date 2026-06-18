# task002 - Peer identity, route candidate, route lease 안정화

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- 자동 테스트 기준 구현과 검증은 완료했다.
- macOS 단일/이중 인스턴스, macOS host와 Parallels VM 동시 실행 검증은 아직 수행하지 않았으므로 수동 검증과 최종 완료 체크는 남긴다.

## 목적

하나의 peer가 여러 네트워크 경로 후보를 가질 수 있다는 사실을 제품 모델에 명확히 반영한다. UI에서는 peer가 하나로 안정적으로 보이고, 내부에서는 route candidate와 검증된 route lease를 분리해 관리한다. 자기 자신이 보낸 packet은 peer, route, transfer 대상에 들어가지 않아야 한다.

## 기능 범위

1. peer identity와 route candidate 분리
2. route lease 모델 또는 기존 모델의 명시적 정리
3. self packet suppression 전체 경로 검증

## 선행 조건

- [x] task001 완료 또는 문서 기준 정렬 확인
- [x] 현재 peer model, discovery model, recent peer projection 코드를 읽는다.
- [x] dashboard, peer list, transfer target selection에서 어떤 peer projection을 쓰는지 확인한다.

## 제외 범위

- 실제 socket bind 정책 변경은 task003에서 처리한다.
- auth handshake 상태 머신 변경은 task004에서 처리한다.
- data transfer endpoint 적용은 task005에서 처리한다.

## 계층별 변경 위치

- domain: peer id, instance id, route candidate, route lease value object 또는 기존 모델 보강
- application: peer registry, route projection, stale/active route selection
- infrastructure: discovery/control/data packet에서 instance id 추출 및 self decision 전달
- presentation: Recent Peers, Peer List, transfer target display projection
- test: `test/domain`, `test/application`, `test/presentation`

## 실패 테스트 또는 수동 재현 기준

- [x] 같은 peer가 `127.0.0.1`, `10.211.x.x`, `192.168.x.x` 후보를 보내면 Recent Peers에 여러 줄로 중복 표시되는 실패 테스트를 작성한다.
- [x] 자기 자신 packet을 수신했을 때 peer list에 자기 자신이 추가되는 실패 테스트를 작성한다.
- [x] active route가 변경될 때 peer card 기본 표시가 loopback과 bridge 주소 사이에서 흔들리는 실패 재현 기준을 기록한다.

## diagnostics/log 검토 기준

- [x] 기존 diagnostics에서 peer id, device name, remote endpoint, active session endpoint가 어떻게 표시되는지 확인한다.
- [x] 자기 자신 packet이 현재 로그에서 구분되는지 확인한다.
- [x] route candidate 추가, route lease 승격, route lease 만료 결정이 로그에 남는지 확인한다.

## 구현 체크리스트

- [x] peer identity 기준을 `peerId` 또는 내부 random instance id 중심으로 명확히 한다.
- [x] route candidate key를 `localInterface`, `localAddress`, `remoteAddress`, `controlEndpoint` 기준으로 정한다. `dataEndpoint` 적용은 task005 범위로 유지한다.
- [x] route candidate와 route lease를 구분한다.
- [x] route lease는 probe 또는 handshake가 성공한 candidate만 승격되도록 한다.
- [x] route lease에 검증 시각과 candidate TTL 기반 만료 정책을 포함한다.
- [x] route lease가 만료되면 peer identity는 유지하고 connected/data-ready 상태만 하향한다.
- [x] self instance id를 discovery/control/data packet decision과 peer id projection 기준에 반영한다.
- [x] self packet은 `ignoredSelf` decision으로 처리하고 peer registry에 들어가지 않게 한다.
- [x] Recent Peers 기본 표시에서 port를 숨긴다.
- [x] 상세 diagnostics에서만 route candidate 목록과 port를 확인할 수 있게 한다.
- [x] transfer target selection은 peer identity 기준으로 보여주되 내부에는 active route lease id를 연결한다.

## 테스트 체크리스트

- [x] 동일 peer id에 여러 endpoint 후보가 들어와도 peer projection은 하나만 생성된다.
- [x] authenticated session route가 있으면 Recent Peers는 해당 route address를 우선 표시한다.
- [x] 기본 peer card에는 port가 표시되지 않는다.
- [x] route 후보 추가/삭제가 peer identity 중복을 만들지 않는다.
- [x] loopback route는 같은 host multi-instance 외에는 active route 우선순위에서 밀린다.
- [x] self packet은 peer list, recent peer, route candidate, transfer target에 등록되지 않는다.
- [x] route lease 만료 후 peer cache는 유지되고 connected/data-ready 상태만 내려간다.
- [x] UI widget test에서 Recent Peers가 endpoint 변화에도 한 peer card로 유지된다.

## 수동 검증 체크리스트

- [ ] 앱 1개만 실행했을 때 자기 자신 peer가 표시되지 않는다.
- [ ] macOS에서 앱 2개 실행 시 peer가 하나로 표시된다.
- [ ] macOS host와 Parallels VM 실행 시 같은 장치가 여러 줄로 표시되지 않는다.
- [ ] Recent Peers에서 IP는 보이더라도 port는 보이지 않는다.
- [ ] diagnostics에서는 route candidate 전체를 확인할 수 있다.

## 완료 기준

- [x] peer identity, route candidate, route lease의 경계가 코드와 테스트로 고정된다.
- [x] UI 기본 표시가 route 후보 변화로 흔들리지 않는다.
- [x] self packet이 peer 동기화와 transfer target에 들어가지 않는다.

## 회귀 금지 조건

- 하나의 peer가 endpoint 수만큼 여러 peer로 표시되면 안 된다.
- loopback route가 VM/외부 peer active route로 우선 승격되면 안 된다.
- 검증되지 않은 route candidate로 파일 전송을 시작하면 안 된다.
