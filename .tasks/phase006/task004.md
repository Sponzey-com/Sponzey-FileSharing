# task004 - 자동 인증/연결 상태 머신 완성

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 진행 메모

- `PeerAuthSessionStateMachine`을 추가해 outbound/inbound auth 전이를 도메인 상태 머신으로 고정했다.
- `CONNECT_REQUEST` 중복 수신은 같은 session이면 기존 nonce로 challenge를 재전송하고, 이미 authenticated인 peer면 세션을 downgrade하지 않는다.
- incoming handshake에서 관찰된 control route를 route candidate/path로 승격해 authenticated session과 active path 기준을 맞췄다.
- Product UI의 connected/send 가능 기준은 `PeerAuthStatus.authenticated` 단독이 아니라 `PeerPathStatus.active`까지 요구하도록 변경했다.
- 작은 peer card에서 상태 문구와 버튼이 overflow 되지 않도록 card grid 높이를 보정했다.
- macOS/Parallels VM 실제 자동 연결과 종료 후 stale/offline 전환 수동 검증은 아직 수행하지 않았다.

## 목적

discovery 이후 자동 인증, route verification, connected/data-ready 전이를 명확한 상태 머신으로 관리한다. 중복 handshake, 늦게 도착한 실패 packet, stale peer cleanup이 정상 session을 오염시키지 않게 한다.

## 기능 범위

1. peer connection state machine 명시화
2. duplicate handshake와 late packet idempotency 처리
3. stale peer TTL과 offline/down transition 정리

## 선행 조건

- [x] task002의 peer identity/route lease 기준을 확인한다.
- [x] task003의 discovery decision code를 확인한다.
- [x] 현재 auth controller, discovery controller, peer provider, session registry 코드를 읽는다.

## 제외 범위

- data transfer 경로 일치성은 task005에서 처리한다.
- file receiver lifecycle은 task006에서 처리한다.
- UI redesign은 하지 않고 상태 표시 최소 변경만 허용한다.

## 계층별 변경 위치

- domain/application: connection state, transition rule, route probe policy
- infrastructure: control packet 수신 결과를 application event로 전달
- core/application: MessageBus event type 정리
- presentation: connected, route checking, offline 표시 projection
- test: `test/domain`, `test/application`, widget projection test

## 실패 테스트 또는 수동 재현 기준

- [x] 이미 connected인 session에 늦은 auth failure가 도착해 failed로 바뀌는 실패 테스트를 작성한다.
- [x] 동일 `CONNECT_REQUEST` 재수신이 중복 session을 만드는 실패 테스트를 작성한다.
- [x] 앱 종료 후 상대 UI에 무기한 connected로 남는 수동 재현 기준을 기록한다.

## diagnostics/log 검토 기준

- [x] discovery accepted 이후 auth start, challenge sent, token verified, route checking, connected 전이가 로그에 남는지 확인한다.
- [x] handshake duplicate, ignored late packet, stale peer cleanup decision이 구분되는지 확인한다.
- [x] peer failure와 route failure가 로그에서 구분되는지 확인한다.

## 구현 체크리스트

- [x] connection state enum 또는 sealed state를 정의/정리한다.
- [x] `discovered -> authenticating -> authenticated -> routeChecking -> connected` 정상 전이를 고정한다.
- [x] auth failure, route failure, timeout, stale cleanup 전이를 명시한다.
- [x] 인증 완료와 active route 확정을 별도 상태로 표현한다.
- [x] connected 표시 기준을 최소 하나의 active control route 검증으로 정의한다. Data endpoint 세부 검증은 task005 범위로 유지한다.
- [x] 중복 `CONNECT_REQUEST`는 기존 session을 재사용하거나 no-op 처리한다.
- [x] 늦게 도착한 실패 packet은 현재 session generation과 맞지 않으면 무시한다.
- [x] self packet은 state machine 입력 전에 제외한다.
- [x] active route가 사라지면 다른 candidate failover 또는 controlled offline으로 전이한다.
- [x] heartbeat/TTL 기준으로 stale peer를 offline 처리한다.
- [x] peer cache 삭제와 online/connected 상태 하향을 분리한다.
- [x] MessageBus에는 이미 발생한 상태 변경 event만 publish한다.

## 테스트 체크리스트

- [x] 정상 connection transition 테스트가 있다.
- [x] auth 실패 route가 peer 전체를 failed로 만들지 않는다.
- [x] route failure가 다른 route candidate failover를 유도한다.
- [x] peer heartbeat timeout 후 offline으로 전이한다.
- [x] 종료된 앱이 recent peer에 무기한 connected로 남지 않는다.
- [x] 늦은 실패 packet이 connected session을 failed로 되돌리지 못한다.
- [x] 동일 `CONNECT_REQUEST` 재수신이 중복 session을 만들지 않는다.
- [x] MessageBus event 순서와 중복 publish 기준을 테스트한다.

## 수동 검증 체크리스트

- [ ] macOS 두 인스턴스 실행 후 자동 연결까지 상태가 자연스럽게 진행된다.
- [ ] 한 인스턴스 종료 시 다른 쪽 UI가 offline/stale로 전환된다.
- [ ] Parallels VM 종료 시 host에서 stale 상태가 정리된다.
- [ ] 연결 확인 중 상태가 무기한 유지되지 않는다.
- [ ] diagnostics에서 연결 완료까지 걸린 시간을 확인할 수 있다.

## 완료 기준

- [x] 자동 인증과 자동 연결이 사용자 개입 없이 완료된다.
- [x] 실패 시 peer failure와 route failure가 구분되어 표시된다.
- [x] stale peer가 UI와 내부 state에서 정리된다.

## 회귀 금지 조건

- UI callback이나 timer 내부에 상태 전이 규칙을 흩어놓지 않는다.
- 실패 route 하나가 peer 전체를 오프라인으로 오염시키지 않는다.
- MessageBus event를 명령 실행 경로로 사용하지 않는다.
