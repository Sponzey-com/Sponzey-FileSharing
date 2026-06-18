# task009 - Diagnostics export, packet decision summary, redaction

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 목적

문제가 생길 때마다 로그를 추가하는 방식에서 벗어나, connection, auth, route, transfer, storage 문제를 한 번에 추적할 수 있는 diagnostics export를 제공한다. 민감정보는 반드시 제거한다.

## 기능 범위

1. diagnostics snapshot과 ring buffer 정리
2. packet decision summary 수집
3. redacted export bundle 생성

## 선행 조건

- [x] task002~task005의 peer/route/transfer id 기준 확인
- [x] 현재 AppLogger, diagnostics provider, debug UI 코드를 읽는다.
- [x] AGENTS.md Logging Rules를 확인한다.

## 제외 범위

- 외부 서버로 로그 업로드하지 않는다.
- telemetry, analytics, crash reporting은 현재 범위가 아니다.
- packet payload 원문 export는 하지 않는다.

## 계층별 변경 위치

- core: diagnostics event, redaction helper, log category
- application: auth/session/route/transfer snapshot builder
- infrastructure: packet decision summary adapter
- presentation: diagnostics panel 또는 export button
- test: `test/core`, `test/application/diagnostics`, widget test

## 실패 테스트 또는 수동 재현 기준

- [x] export에 JWT 원문 또는 session key가 포함되는 실패 테스트를 작성한다.
- [x] host/VM 연결 실패 상황에서 어떤 interface로 보냈는지 export로 알 수 없는 상황을 실패 기준으로 기록한다.
- [x] transfer 실패 상황에서 selected endpoint를 확인할 수 없는 상황을 실패 기준으로 기록한다.

## diagnostics/log 검토 기준

- [x] 현재 로그에 무엇을 보냈는지, 무엇을 받았는지, 왜 무시했는지가 남는지 확인한다.
- [x] self packet, group mismatch, malformed packet, stale route decision이 구분되는지 확인한다.
- [x] product/debug/development 레벨이 섞여 있는지 확인한다.

## 구현 체크리스트

- [x] diagnostics ring buffer 크기와 eviction 정책을 정의한다.
- [x] peer route snapshot에 peer id, route candidates, active route lease를 포함한다.
- [x] auth/session snapshot에 auth status, session id, safe claim summary를 포함한다.
- [x] transfer snapshot에 transfer id, session id, route lease id, state, last error를 포함한다.
- [x] storage snapshot에 save path status와 last storage error를 포함한다.
- [x] packet decision summary에 sent, received, ignoredSelf, groupMismatch, malformed, stale, routePromoted를 포함한다.
- [x] export bundle을 product, debug, environment summary 섹션으로 나눈다.
- [x] development-only packet detail은 기본 export에서 제외한다.
- [x] password, JWT 원문, session key, file payload, 전체 민감 경로를 redaction한다.
- [x] UI에서 export 생성 또는 diagnostics panel 확인이 가능하게 한다.

## 테스트 체크리스트

- [x] export에 비밀번호가 없다.
- [x] export에 JWT 원문이 없다.
- [x] export에 session key가 없다.
- [x] 파일 전체 경로는 basename 또는 축약 경로로만 표시된다.
- [x] route 후보와 active route가 포함된다.
- [x] 최근 transfer error code가 포함된다.
- [x] diagnostics buffer size가 제한된다.
- [x] self packet, group mismatch, stale route, route probe failure decision이 구분된다.
- [x] export bundle이 product/debug/development 섹션을 구분한다.

## 수동 검증 체크리스트

- [ ] host/VM 연결 실패 상황에서 export로 send/receive decision을 확인한다.
- [ ] transfer 실패 상황에서 selected endpoint를 확인한다.
- [ ] 저장 경로 실패 상황에서 storage error를 확인한다.
- [ ] export 파일을 열어 민감정보가 없는지 직접 확인한다.
- [ ] release gate에서 export bundle을 첨부할 수 있는지 확인한다.

## 완료 기준

- [x] 현장 문제의 첫 조치가 "로그 추가"가 아니라 "diagnostics export 확인"이 된다.
- [x] export만으로 discovery/auth/route/transfer/storage 흐름을 대략 추적할 수 있다.
- [x] redaction 테스트가 민감정보 누출을 막는다.

## 회귀 금지 조건

- password, JWT 원문, session key, file payload를 로그나 export에 포함하지 않는다.
- packet별 product/info 로그를 추가하지 않는다.
- diagnostics를 MessageBus 명령 실행 경로로 사용하지 않는다.
