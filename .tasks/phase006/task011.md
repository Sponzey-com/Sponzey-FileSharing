# task011 - Release gate, 양방향 host/VM 전송 검증, benchmark 기록

## 상태

- [x] 진행 전
- [x] 진행 중
- [x] 구현 완료
- [x] 테스트 완료
- [ ] 수동 검증 완료
- [ ] 완료

## 목적

릴리즈 태그를 찍기 전에 빌드 성공뿐 아니라 실제 네트워크 핵심 시나리오를 검증한다. macOS host, Parallels Windows VM, Ubuntu 22.04 조합에서 discovery, auth, route lease, data transfer, receiver file verification을 양방향으로 확인하고 결과를 기록한다.

## 기능 범위

1. release checklist와 benchmark 기록 양식
2. local smoke command 또는 수동 검증 절차 정리
3. GitHub Actions artifact와 실제 전송 검증 연결

## 선행 조건

- [x] task002~task010 주요 기능 완료
- [x] diagnostics export가 동작한다.
- [ ] macOS host, Parallels Windows VM, Ubuntu 22.04 VM 또는 Linux 장비 접근 가능

## 제외 범위

- 외부 cloud relay 검증은 하지 않는다.
- 인터넷 NAT traversal은 검증하지 않는다.
- 모바일/웹 클라이언트 검증은 하지 않는다.

## 계층별 변경 위치

- scripts: smoke/release helper command
- docs/tasks: release checklist, benchmark template
- workflow: GitHub Actions artifact 확인 절차
- test: existing unit/widget/infrastructure suite 실행

## 실패 테스트 또는 수동 재현 기준

- [x] host -> VM만 성공하고 VM -> host가 실패하면 release gate 실패다.
- [x] sender completed지만 receiver file digest 확인이 없으면 release gate 실패다.
- [x] diagnostics export redaction 확인 없이 release gate를 통과하면 실패다.

## diagnostics/log 검토 기준

- [x] 각 수동 시나리오마다 diagnostics export를 생성한다.
- [x] export에서 route lease id, transfer id, session id를 확인한다.
- [x] benchmark 결과와 diagnostics timestamp를 대조할 수 있게 기록한다.

## 구현 체크리스트

- [x] release checklist 문서를 작성한다.
- [x] benchmark 결과 기록 template을 작성한다.
- [x] local smoke command가 가능하면 정리한다.
- [x] macOS, Windows, Linux artifact 확인 절차를 문서화한다.
- [x] 수동 gate 결과를 남길 위치를 정한다.
- [x] release 전 필수 테스트 명령을 정한다.
- [x] 양방향 host/VM 전송 검증 절차를 작성한다.
- [x] diagnostics export redaction 확인 절차를 포함한다.
- [x] release failure 시 rollback 또는 tag 보류 기준을 정한다.

## 테스트 체크리스트

- [x] `flutter analyze`
- [x] `flutter test`
- [x] 변경 범위별 targeted test
- [x] macOS build smoke
- [ ] Windows build smoke
- [ ] Linux Ubuntu 22.04 build smoke
- [x] diagnostics redaction test
- [x] transfer correctness/digest tests

## 수동 검증 체크리스트

- [ ] macOS host <-> macOS second instance discovery
- [ ] macOS host <-> macOS second instance auth
- [ ] macOS host <-> macOS second instance transfer
- [ ] macOS host -> Parallels Windows VM discovery/auth/transfer/digest
- [ ] Parallels Windows VM -> macOS host discovery/auth/transfer/digest
- [ ] macOS host -> Ubuntu 22.04 discovery/auth/transfer/digest
- [ ] Ubuntu 22.04 -> macOS host discovery/auth/transfer/digest
- [ ] 각 시나리오 diagnostics export 저장
- [ ] 100MB benchmark 결과 기록
- [ ] release artifact 다운로드 및 실행 확인

## benchmark 기록 항목

- [ ] app version/tag
- [ ] source OS와 target OS
- [ ] route type, 예: same host, VM bridge, wired LAN
- [ ] file size
- [ ] average speed
- [ ] peak speed
- [ ] retry count
- [ ] loss percent
- [ ] sender final state
- [ ] receiver final state
- [ ] receiver digest result
- [ ] diagnostics export filename

## 완료 기준

- [ ] release tag는 네트워크/전송 smoke 결과와 함께 생성된다.
- [ ] 양방향 host/VM 전송이 확인된다.
- [ ] receiver file digest까지 확인한 benchmark 결과가 남는다.

## 회귀 금지 조건

- CI build 성공만으로 release gate를 통과하지 않는다.
- sender 성공 상태만으로 전송 성공을 판단하지 않는다.
- diagnostics export 없이 현장 네트워크 실패를 "확인 완료"로 처리하지 않는다.