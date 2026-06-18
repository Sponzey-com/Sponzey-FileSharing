# v0.0.20 이후 연결 안정화 및 제품화 개발 계획

## 0. 문서 상태

이 문서는 현재 구현 상태를 기준으로 한 다음 개발 계획이다. 이전 루트 계획과 태스크는 `.tasks/phase005`로 이동했고, 해당 phase는 고속 UDP Data Channel 전환 기록으로 보존한다.

이 문서의 목적은 새 기능 아이디어를 나열하는 것이 아니라, 현재 제품에서 덜 완성된 부분을 확인하고 다음 구현 순서를 고정하는 것이다. 우선 목표는 "연결이 안정적으로 잡히고, 잡힌 연결 경로로 파일이 안정적으로 전송되는 것"이다.

기준 문서:

- `AGENTS.md`: 작업 원칙, 계층 구조, TDD, 상태 머신, MessageBus, 설정/로그/UDP guardrail
- `PROJECT.md`: 제품 목표와 아키텍처 방향
- `README.md` / `README.ko.md`: 사용자에게 보이는 제품 설명
- `.tasks/phase005/plan.md`: Data channel 전환 설계와 완료 기록

## 1. 반드시 유지할 제품 방향

다음 원칙은 후속 개발에서 되돌리면 안 된다.

- Flutter Desktop 앱으로만 제공한다. 웹 클라이언트는 범위가 아니다.
- Discovery, Control, Data UDP 채널의 책임을 분리한다.
- Discovery는 peer presence와 경로 후보 수집만 담당한다.
- Control은 인증, 연결, 전송 협상, 취소, 완료 요약만 담당한다.
- Data는 인증된 transfer session의 raw binary file chunk만 담당한다.
- 같은 ID/PW를 입력한 peer끼리 자동 인증, 자동 연결, 자동 수신을 수행한다.
- 가입, 로컬 계정 생성, password hash/verifier 영속 저장은 현재 기본 제품 범위가 아니다.
- 비밀번호, JWT, session key는 메모리에서만 유지한다.
- 외부 설정 파일과 런타임 환경 변수 재주입으로 동작을 바꾸지 않는다.
- 사용 가능한 모든 Ethernet 계열 인터페이스를 활용한다.
- 물리 NIC, USB/Thunderbolt Ethernet, 내부 bridge, VM bridge, Parallels bridge처럼 peer와 실제 통신 가능한 경로는 모두 후보로 수집한다.
- UI에는 사용자에게 의미 있는 peer/전송 상태를 보여주되, 포트나 내부 route 후보가 불필요하게 흔들려 보이지 않게 한다.
- 특정 IP 대역, 특정 VM 제품, 특정 NIC 이름을 전제로 유니캐스트하거나 우선순위를 부여하지 않는다.
- peer identity와 route identity를 절대 같은 모델로 취급하지 않는다. peer는 하나이고, route는 여러 후보가 될 수 있다.
- 연결과 전송은 검증된 route lease를 통해서만 수행한다. route lease에는 local interface, local address, remote address, control endpoint, data endpoint, 검증 시각, 만료 정책이 포함되어야 한다.
- 앱 인스턴스는 프로세스 시작 시 내부 random instance id를 갖고, 자기 자신이 보낸 discovery/control/data packet은 peer 동기화나 자동 연결 흐름에 들어가지 않아야 한다.
- 네트워크/전송 문제 수정은 추측성 endpoint 변경보다 기존 diagnostics/log 검토를 먼저 수행한다. 로그가 부족하면 민감정보를 제외한 구조화 로그를 한 번에 충분히 추가한다.

## 2. 현재 구현 기준 정리

현재까지 구현된 것으로 보는 영역:

- macOS, Windows, Linux desktop 빌드 대상
- 런타임 ID/PW 로그인 세션
- password-derived JWT 기반 인증 흐름
- discovery group tag를 통한 같은 credential 그룹 필터링
- UDP discovery port와 data/control port 분리
- binary DataFrame 기반 Data channel 전송 경로
- 자동 수신 정책
- 기본 저장 경로 설정
- peer cache와 recent peer 표시
- multi-interface discovery candidate 수집과 broadcast 전송
- Parallels host/guest 환경에서 peer 발견이 가능했던 로그 기반 개선
- GitHub Actions 기반 macOS, Windows, Ubuntu 22.04 build/release workflow

아직 제품 완료로 보기 어려운 영역:

- multi-interface route 선택이 UI와 전송에 항상 같은 기준으로 반영되는지 불완전하다.
- recent peer가 loopback과 실제 bridge IP 사이에서 흔들리는 현상이 있었다.
- 연결 완료 후 active path 검증과 data transfer path가 완전히 같은 endpoint를 쓰는지 더 고정해야 한다.
- 전송은 성공 사례가 있으나 수신 실패, 경로 오류, 저장 경로 준비 실패가 반복적으로 발생했다.
- Data channel 속도가 UDP 기대치에 비해 낮다는 보고가 있었다.
- transfer history는 영속 저장 기준이 약하다.
- multi-file, folder, 1:N 전송 UX는 아직 제품 수준으로 완성되지 않았다.
- diagnostics는 개발자에게 충분하지 않고, 사용자가 문제 상황을 전달하기 위한 export 형태가 없다.
- macOS 클릭/포커스 반응성이 여러 번 클릭해야 하는 증상으로 보고되었다.
- release gate가 "빌드 성공" 중심이고 실제 host/VM/다중 NIC 전송 성공을 강제하지 못한다.
- peer identity, route candidate, route lease, transfer endpoint snapshot의 경계가 문서와 테스트로 충분히 고정되지 않았다.
- self packet suppression이 discovery, control, data channel 전체에 걸쳐 검증되는지 불명확하다.
- 각 roadmap task가 어떤 계층의 테스트를 먼저 추가해야 하는지 명확하지 않다.

## 3. Gap Analysis

### G0. 계획 실행 방식의 계층/TDD 기준 부족

증상:

- 계획에는 해야 할 기능이 나열되어 있지만, 각 기능을 어느 계층에서 먼저 고정할지 충분히 강제하지 않는다.
- route, auth, transfer처럼 절차가 복잡한 영역은 UI나 controller 조건문으로 빠르게 땜질하면 다시 회귀한다.
- 네트워크 문제를 고칠 때 테스트보다 수동 실행 결과만 보고 수정하면, macOS host, Parallels VM, Windows, Linux 조합에서 회귀를 반복한다.

필요한 정리:

- 각 task는 domain/application 전이 규칙 테스트를 먼저 작성한다.
- socket, file system, platform API는 infrastructure adapter 테스트 또는 fake transport 테스트로 고정한다.
- UI는 application state projection만 표시하도록 테스트하고, protocol decision을 UI에서 수행하지 않는다.
- route selection, retry, timeout, stale peer cleanup은 상태 머신 테스트 없이는 완료 처리하지 않는다.
- MessageBus event는 이미 발생한 사실만 발행하고, 명령 실행 경로를 이벤트 이름으로 숨기지 않는다.
- 문서 task를 제외한 모든 task는 실패 테스트, 구현, 정리, 재실행 순서를 체크리스트에 포함해야 한다.

### G1. Peer identity와 route identity가 섞이는 문제

증상:

- 같은 peer가 `127.0.0.1`와 `10.x.x.x` 또는 `192.168.x.x` 같은 여러 endpoint로 표시될 수 있다.
- 하나의 peer가 여러 네트워크 경로 후보를 가지는 것은 정상이다.
- 하지만 UI가 route 후보를 peer identity처럼 보여주면 사용자는 peer가 바뀐 것으로 오해한다.
- 파일 전송이 잘 되는 경로와 UI에 표시되는 경로가 다르면 디버깅이 어려워진다.

필요한 정리:

- peer identity는 `peerId` 또는 내부 random instance id 기준으로 고정한다.
- route identity는 `localInterface + localAddress + remoteAddress + control/data endpoint` 기준으로 별도 관리한다.
- route lease는 route candidate 중 실제 probe와 handshake가 성공한 경로만 승격한다.
- route lease가 만료되면 peer identity는 유지하되 connected/data-ready 상태는 내려야 한다.
- UI는 peer identity를 중심으로 보여주고, 상세 진단에서만 route 후보를 보여준다.
- Recent Peers 기본 표시에서는 포트를 숨긴다.
- active route가 바뀌더라도 peer card가 흔들리지 않게 projection을 안정화한다.

완료 후 금지되는 상태:

- 같은 peer가 Recent Peers에 여러 줄로 중복 표시되는 상태
- peer card의 기본 표시 IP가 loopback과 bridge 주소 사이에서 계속 흔들리는 상태
- data transfer가 peer card 표시 route와 무관한 endpoint로 나가는 상태

### G2. 모든 Ethernet 인터페이스 사용 검증 부족

증상:

- Parallels VM과 macOS host 사이에서 발견이 안 되거나 한쪽만 보이는 문제가 반복됐다.
- 이전 수정에서 특정 VM IP를 가정하는 방향은 잘못된 접근이었다.
- 올바른 방향은 모든 사용 가능한 Ethernet 계열 인터페이스의 broadcast 주소로 discovery를 발산하고, 응답을 수집해 route 후보로 평가하는 것이다.

필요한 정리:

- OS별 interface enumeration 결과를 로그와 테스트 가능한 값 객체로 정규화한다.
- loopback은 같은 장비 다중 인스턴스 테스트에는 사용할 수 있지만, VM/외부 peer 우선 경로로 승격하지 않는다.
- broadcast 지원 interface, point-to-point, link-local, IPv6, down interface를 명확히 구분한다.
- discovery send 로그에는 interface name, local address, broadcast address, port, 결과만 남긴다.
- packet 수신 로그에는 remote address, local bind address 추정값, group tag match 여부, decision을 남긴다.
- discovery response는 수신된 remote address를 그대로 route candidate로 등록하되, active route 승격은 별도 probe로 검증한다.
- VM bridge와 물리 LAN이 동시에 있는 경우 둘 다 후보로 유지하고, 특정 대역이라는 이유만으로 버리지 않는다.
- broadcast 실패 interface는 전체 discovery 실패가 아니라 해당 interface skip으로 처리한다.

완료 후 금지되는 상태:

- `10.211.x.x`, `192.168.x.x`처럼 특정 대역을 코드에서 특별 취급하는 상태
- 어떤 인터페이스로 broadcast를 보냈는지 diagnostics로 확인할 수 없는 상태
- 한 인터페이스 bind 실패가 전체 discovery engine 시작 실패로 이어지는 상태

### G3. 자동 연결 handshake의 상태 머신 완성도

증상:

- "연결 확인 중" 상태가 오래 유지되거나 실패/재시도만 반복된 사례가 있다.
- 먼저 뜬 인스턴스와 나중에 뜬 인스턴스의 UI 반응이 다르게 나타난 사례가 있다.
- 연결 경로 확인이 끝난 뒤에도 peer card 상태가 즉시 안정화되지 않았다.

필요한 정리:

- discovery, auth, route verification, connected 상태를 명시적인 state machine으로 분리한다.
- 같은 peer의 여러 route 후보에 대해 병렬 또는 순차 probe 정책을 명확히 한다.
- 하나의 route 실패가 peer 전체 실패로 오염되지 않게 한다.
- 인증 완료와 active path 확정은 다른 상태로 표현한다.
- connected로 표시하려면 최소 하나의 control route와 data route가 검증되어야 한다.
- self packet은 `ignoredSelf` decision으로 기록하고 connection state machine에 입력하지 않는다.
- handshake 중복 수신은 idempotent하게 처리하고, 성공한 session을 실패한 늦은 packet이 되돌리지 못하게 한다.
- stale peer cleanup은 peer cache 삭제와 online/connected 상태 하향을 구분한다.

### G4. Data channel 성능 목표 미달 가능성

증상:

- 전송이 되더라도 속도가 UDP 기대치보다 낮다는 보고가 있었다.
- 작은 window, 잦은 ACK, 과한 UI update, 파일 I/O flush, packet별 처리 비용이 병목이 될 수 있다.

필요한 정리:

- Data channel의 chunk size, send window, ACK batch, retransmission interval, UI update interval을 benchmark 기준으로 튜닝한다.
- product/info 로그에는 packet별 로그를 남기지 않는다.
- development 로그에서도 data packet 원문이나 민감 payload를 남기지 않는다.
- transfer progress event는 UI가 감당 가능한 주기로 throttle한다.
- 수신 writer는 chunk별 open/close/flush를 하지 않는다.
- 성능 튜닝은 correctness 테스트가 먼저 통과한 뒤 수행한다.
- throughput benchmark는 sender 기준 성공뿐 아니라 receiver final file 검증까지 포함한다.
- 성능 결과에는 route type, OS, build mode, file size, average speed, loss, retry count를 함께 기록한다.

완료 후 금지되는 상태:

- sender는 완료로 보이지만 receiver 파일이 없거나 손상된 상태
- 전송 속도 개선을 위해 ACK/NACK correctness를 희생하는 상태
- packet별 UI update 또는 product log가 전송 루프에 남아 있는 상태

### G5. 수신 저장 경로와 권한 오류

증상:

- "수신 임시파일을 준비하지 못했습니다", "기본 수신 경로를 준비하지 못했습니다"류의 오류가 반복됐다.
- macOS 저장 경로가 이상하게 보이거나, 설정 변경 후 앱 종료가 발생한 사례가 있었다.

필요한 정리:

- 기본 저장 경로 계산을 플랫폼별로 테스트한다.
- 설정 저장은 앱을 종료시키지 않아야 한다.
- 경로 준비 실패는 송신자와 수신자 각각에 다른 메시지로 표시한다.
- 수신자가 저장 경로를 준비하지 못하면 sender에는 retry 가능한 control failure로 전달한다.
- temp 파일, final 파일, overwrite policy, partial cleanup policy를 명시한다.
- 수신 준비 실패는 Data channel 시작 전에 Control response로 확정한다.
- receiver가 temp file을 준비하지 못한 상태에서 sender가 data chunk를 보내지 않도록 한다.
- 설정 저장 실패와 전송 수신 실패는 같은 오류 메시지로 뭉개지 않는다.

### G6. 전송 UX 완성도 부족

증상:

- 파일 전송은 가능하지만 실패와 성공의 정책이 송신/수신에서 다르게 보인다는 피드백이 있었다.
- 단일 파일 중심 UI가 남아 있고 multi-file/folder/1:N 전송은 제품 수준이 아니다.
- 취소, 재시도, 실패 원인, 수신 파일 열기/폴더 열기 흐름이 충분하지 않다.

필요한 정리:

- sender와 receiver 모두 같은 transfer state model을 사용한다.
- 실패 상태는 사용자 메시지와 개발자 진단 코드를 분리한다.
- 자동 수신 정책을 기준으로 approval UI는 제거하거나 향후 기능으로 비활성화한다.
- multi-file은 "각 파일 독립 transfer job"인지 "batch job 하위 file item"인지 명확히 한다.
- 자동 수신이 기본이므로 "승인 대기", "거절됨" 같은 상태 문구는 실제 정책과 맞을 때만 사용한다.
- sender가 보는 실패와 receiver가 기록한 실패는 같은 transfer id/session id로 대조 가능해야 한다.

### G7. 관찰 가능성 부족

증상:

- 문제가 생길 때마다 로그를 추가하는 방식은 비효율적이다.
- 연결, 인증, route, transfer, storage가 한 번에 추적되지 않으면 원인을 찾기 어렵다.

필요한 정리:

- debug log는 field 현장에서 재현 가능한 수준으로 충분히 남긴다.
- development log는 상세하지만 민감정보와 packet payload를 제외한다.
- diagnostics snapshot에는 인증 상태, peer id, route candidates, active route, data session id, transfer state, last error를 포함한다.
- 사용자가 전달할 수 있는 diagnostics export를 제공한다.
- 로그에는 비밀번호, JWT 원문, session key, 전체 파일 경로, 파일 내용이 남지 않아야 한다.
- network bug task는 기존 diagnostics 검토 결과를 task 문서에 남긴 뒤 수정한다.
- diagnostics에는 "무엇을 보냈는지", "무엇을 받았는지", "왜 무시했는지", "어떤 route로 승격했는지"가 결정 단위로 남아야 한다.
- export는 product log, debug snapshot, environment summary를 분리하고, development-only packet detail은 기본 export에서 제외한다.

### G8. 테스트와 release gate 부족

증상:

- CI build는 되지만 실제 host/VM transfer 성공을 보장하지 못한다.
- Parallels, Windows firewall, Ubuntu 22.04, multi NIC 환경은 자동화가 어렵더라도 수동 gate가 필요하다.

필요한 정리:

- unit/widget/infrastructure 테스트로 deterministic logic을 고정한다.
- local smoke script로 같은 장비 2개 인스턴스 discovery/auth/transfer를 검증한다.
- manual release checklist에 macOS host <-> Parallels Windows VM, macOS host <-> Ubuntu 22.04, Windows standalone을 포함한다.
- release tag 전에는 수동 benchmark 결과를 기록한다.
- release gate는 양방향 전송을 반드시 포함한다. host -> VM 성공만으로 통과 처리하지 않는다.
- release gate는 peer discovery, auth, route lease, data transfer, receiver file verification을 각각 확인한다.
- release gate 결과는 다음 tag 작업자가 볼 수 있는 문서나 artifact로 남긴다.

## 4. 우선순위 로드맵

### 공통 완료 기준

모든 구현 task는 다음 기준을 만족해야 완료 처리할 수 있다.

- [ ] 변경 동작을 설명하는 실패 테스트 또는 명확한 수동 재현 기준을 먼저 작성한다.
- [ ] 상태 전이가 있는 기능은 state machine 전이 테스트를 포함한다.
- [ ] MessageBus event를 추가하거나 변경하면 publish/subscribe, 중복, 해제, 실패 subscriber 처리를 테스트한다.
- [ ] network endpoint 또는 route 관련 변경은 hardcoded IP, NIC 이름, VM vendor 가정이 없음을 코드와 테스트로 확인한다.
- [ ] 민감정보가 product/debug/development log와 diagnostics export에 남지 않음을 확인한다.
- [ ] sender 성공뿐 아니라 receiver final file 존재와 digest 검증을 완료 기준에 포함한다.
- [ ] UI 변경은 application state projection을 표시하는지 확인하고, protocol decision을 UI에 넣지 않는다.
- [ ] task 문서의 기능 범위, 테스트, 검증 체크박스를 실제 수행 상태와 맞게 갱신한다.

### P0. 문서와 기준 정렬

목표:

- 현재 구현 방향과 문서가 충돌하지 않게 한다.
- 이전 phase 계획은 보존하되 현재 계획과 혼동하지 않게 한다.

체크리스트:

- [x] 기존 루트 `.tasks/plan.md`와 task 문서를 `.tasks/phase005`로 이동한다.
- [x] `.tasks/README.md`를 새 구조로 갱신한다.
- [x] `PROJECT.md`에서 로컬 계정, secure storage, 수동 승인 중심 문구를 현재 정책으로 수정한다.
- [x] `AGENTS.md`에 런타임 ID/PW, 메모리 전용 credential, 자동 인증/자동 수신 guardrail을 추가한다.
- [x] README/README.ko.md가 현재 인증/수신/멀티 인터페이스 정책과 완전히 일치하는지 점검한다.

검증:

- [x] 문서 내 `flutter_secure_storage`, `계정 생성`, `허용 사용자`가 현재 기본 경로처럼 표현되지 않는다.
- [x] `.tasks` 루트에는 새 plan, 인덱스, 현재 task 파일이 있고, 이전 Data Channel task 파일은 phase005에 보존된다.

### P1. Peer identity와 route projection 안정화

목표:

- peer는 하나로 보이고, 경로 후보는 내부적으로 관리한다.
- UI 기본 표시에서는 포트를 숨기고 안정적인 active address만 보여준다.
- loopback과 실제 Ethernet/bridge route가 섞여도 peer identity가 흔들리지 않는다.

기능 범위:

- peer identity model과 route candidate model 분리
- route lease model 도입 또는 기존 모델의 명시적 정리
- active route projection 규칙 정의
- Recent Peers / Peer List 표시 규칙 통일
- route candidate 변경 시 UI churn 방지
- loopback route 우선순위 하향
- self instance id 기반 자기 자신 packet suppression 확인

테스트:

- [ ] 동일 peer id에 `127.0.0.1`, `10.211.x.x`, `192.168.x.x` 후보가 들어와도 UI peer는 하나만 표시된다.
- [ ] authenticated session route가 있으면 Recent Peers는 해당 route address를 우선 표시한다.
- [ ] port는 기본 peer card에 표시되지 않는다.
- [ ] route 후보가 추가/삭제되어도 peer identity가 중복 생성되지 않는다.
- [ ] loopback route는 같은 host multi-instance test 외에는 active route 우선순위에서 밀린다.
- [ ] 자기 자신이 보낸 packet은 peer list, recent peer, route candidate, transfer target에 등록되지 않는다.
- [ ] route lease가 만료되어도 peer cache는 유지되고 connected/data-ready 상태만 내려간다.

검증:

- [ ] `flutter test`로 projection 테스트 통과
- [ ] macOS 두 인스턴스에서 recent peer가 하나로 유지
- [ ] macOS host와 Parallels VM에서 peer가 하나로 유지
- [ ] 앱 1개만 실행한 상태에서 자기 자신 peer가 표시되지 않음

완료 기준:

- 사용자는 한 장치가 여러 IP로 번갈아 보이는 현상을 보지 않는다.
- 진단 화면에서는 모든 route 후보를 확인할 수 있다.

### P2. Multi Ethernet Discovery 확정

목표:

- 가능한 모든 Ethernet 계열 인터페이스에 discovery broadcast를 정상 발산한다.
- 수신 packet을 route candidate로 안전하게 등록한다.
- 특정 VM IP나 특정 NIC를 가정하지 않는다.

기능 범위:

- interface classifier 정리
- broadcast target 계산 값 객체화
- per-interface discovery send 결과 debug log
- packet receive decision log
- Windows `errno 10022`, macOS `errno 48`, Linux bind conflict 회귀 테스트 보강
- discovery packet decision code 표준화
- route candidate 승격 전 probe contract 정의

테스트:

- [ ] broadcast 가능한 IPv4 interface만 discovery target이 된다.
- [ ] down interface, unsupported address, malformed broadcast는 skip reason과 함께 제외된다.
- [ ] loopback은 설정된 테스트 조건에서만 target이 된다.
- [ ] Windows에서 reuse 옵션 조합이 `errno 10022`를 발생시키지 않는다.
- [ ] Linux에서 preferred port 점유 시 fallback bind가 deterministic하게 동작한다.
- [ ] 특정 IP 대역을 하드코딩한 route selection branch가 없다.
- [ ] interface 하나의 bind/send 실패가 전체 discovery start 실패로 전파되지 않는다.

검증:

- [ ] macOS host -> Parallels Windows VM discovery 확인
- [ ] Parallels Windows VM -> macOS host discovery 확인
- [ ] macOS host -> Ubuntu 22.04 VM discovery 확인
- [ ] debug log에 interface별 send/receive decision이 남는다.
- [ ] diagnostics export로 어떤 interface가 broadcast 대상이었는지 확인 가능

완료 기준:

- VM IP를 하드코딩하지 않고도 host/VM 양방향 discovery가 재현된다.

### P3. 자동 인증/연결 상태 머신 완성

목표:

- 인증, 연결, route verification, data readiness를 명확한 상태 전이로 관리한다.
- UI가 "연결 확인 중"에 오래 멈추지 않는다.

기능 범위:

- peer connection state machine 명시화
- route probe 상태와 auth state 분리
- 같은 peer의 여러 route 후보 probe 정책 정의
- stale peer TTL과 disconnect 처리
- 앱 종료 또는 heartbeat timeout 후 peer 제거/오프라인 전환
- duplicate handshake packet idempotency 처리
- route failure와 peer failure 분리

테스트:

- [ ] discovery packet 수신 후 `discovered -> authenticating -> authenticated -> routeChecking -> connected` 전이가 고정된다.
- [ ] auth 실패 route는 peer 전체를 실패시키지 않고 해당 route만 실패 처리한다.
- [ ] active route가 사라지면 다른 route 후보로 failover 시도한다.
- [ ] peer heartbeat가 끊기면 일정 시간 후 offline으로 전환한다.
- [ ] 종료된 앱이 recent peer에 무기한 connected로 남지 않는다.
- [ ] 늦게 도착한 실패 packet이 이미 connected인 session을 failed로 되돌리지 못한다.
- [ ] 동일 `CONNECT_REQUEST` 재수신은 중복 session을 만들지 않는다.

검증:

- [ ] macOS 두 인스턴스 중 하나 종료 시 다른 쪽 UI에서 offline 전환
- [ ] Parallels VM 종료 시 host에서 stale 상태 정리
- [ ] 연결 완료까지 걸린 시간이 diagnostics에 표시

완료 기준:

- 자동 인증과 자동 연결이 사용자 개입 없이 완료되고, 실패 시 이유가 명확히 표시된다.

### P4. Data transfer path 일치성 보장

목표:

- 연결에서 확정한 active route와 파일 전송 data endpoint가 같은 route family를 사용한다.
- sender가 엉뚱한 endpoint로 전송하지 않는다.

기능 범위:

- Control handshake에서 data endpoint 교환 결과와 active route 연결
- sender/receiver transfer job에 route snapshot 저장
- data session start 전 route preflight
- transfer 중 active route 변경 정책 정의
- route mismatch error code 추가
- Data socket bind local address와 route lease local address 일치성 확인
- transfer id, session id, route lease id를 diagnostics에 연결

테스트:

- [ ] authenticated route가 `10.211.x.x`이면 data transfer target도 같은 remote address 계열을 사용한다.
- [ ] loopback route로 인증됐을 때 외부 peer transfer에는 loopback target을 쓰지 않는다.
- [ ] transfer 시작 후 route mismatch가 감지되면 명확한 실패로 중단한다.
- [ ] receiver가 준비한 data endpoint가 sender queue에 반영된다.
- [ ] duplicate peer route 후보가 있어도 transfer job route snapshot은 고정된다.
- [ ] route lease local address와 data socket local bind address가 불일치하면 전송 시작 전 실패한다.
- [ ] transfer 중 route lease 만료 시 정책에 따라 failover 또는 controlled failure로 전이한다.

검증:

- [ ] macOS host -> Windows VM 파일 전송 성공
- [ ] Windows VM -> macOS host 파일 전송 성공
- [ ] transfer diagnostics에 selected route가 표시
- [ ] sender diagnostics와 receiver diagnostics의 transfer id/session id가 대조 가능

완료 기준:

- peer 연결 성공 경로와 파일 전송 경로가 서로 다르게 선택되는 문제가 재발하지 않는다.

### P5. 저장 경로와 수신 lifecycle 안정화

목표:

- 자동 수신은 항상 예측 가능한 기본 경로에 저장한다.
- 저장 경로 준비 실패는 앱 종료 없이 명확한 오류로 처리한다.

기능 범위:

- 플랫폼별 기본 저장 경로 resolver 테스트
- 설정 저장 실패/성공 상태 처리
- temp file 생성, rename, cleanup 정책
- overwrite 또는 duplicate filename 정책
- 수신 준비 실패 control response 명확화

테스트:

- [ ] macOS 기본 경로는 `~/Downloads/Sponzey FileSharing` 계열로 계산된다.
- [ ] Windows 기본 경로는 사용자 Downloads 하위로 계산된다.
- [ ] Linux 기본 경로는 XDG Downloads 또는 fallback home 하위로 계산된다.
- [ ] 저장 경로 권한 실패 시 앱은 종료되지 않는다.
- [ ] temp 파일 준비 실패는 sender에 retry 가능/불가능 사유를 전달한다.
- [ ] 완료 파일 rename 실패 시 partial 파일 cleanup 정책이 실행된다.

검증:

- [ ] macOS에서 설정 저장 후 앱 유지
- [ ] Windows에서 기본 경로 자동 생성
- [ ] 권한 없는 경로 설정 후 명확한 오류 표시

완료 기준:

- "수신 임시파일을 준비하지 못했습니다"류 오류는 재현 가능한 원인 코드와 함께 표시된다.

### P6. Data channel 성능 튜닝

목표:

- UDP 사용에 걸맞은 체감 전송 속도를 달성한다.
- 성능 개선이 correctness를 깨지 않도록 benchmark와 테스트를 같이 둔다.

기능 범위:

- chunk size와 MTU budget 재검토
- send window 기본값과 max window benchmark 기반 조정
- ACK batch threshold 조정
- retransmission scheduler 비용 점검
- progress/log throttle 적용
- OS socket send/receive buffer 검토
- receiver final digest verification 기준 확정
- benchmark result schema 정의

테스트:

- [ ] ACK batch가 chunk마다 발생하지 않는다.
- [ ] duplicate/out-of-order/loss 시에도 수신 파일이 정확히 복원된다.
- [ ] retransmission retry count와 loss metric이 정확히 계산된다.
- [ ] progress event는 정해진 최소 interval보다 자주 publish되지 않는다.
- [ ] packet별 product/info 로그가 발생하지 않는다.
- [ ] sender completed 상태는 receiver complete ack와 digest 검증 결과 없이 확정되지 않는다.
- [ ] receiver final file digest mismatch는 sender/receiver 양쪽에 같은 transfer id로 실패 기록된다.

Benchmark:

- [ ] 같은 장비 2 인스턴스 100MB 전송
- [ ] macOS host -> Parallels Windows VM 100MB 전송
- [ ] Parallels Windows VM -> macOS host 100MB 전송
- [ ] Ubuntu 22.04 VM 또는 Linux 장비 100MB 전송

초기 성능 기준:

- 같은 장비 또는 VM bridge: release build 기준 5 MB/s 이상
- 유선 LAN: release build 기준 20 MB/s 목표
- 손실 없는 local path에서 loss 0% 유지

완료 기준:

- 성능 결과가 release note 또는 diagnostics benchmark 기록으로 남는다.

### P7. Transfer UX와 History 제품화

목표:

- 송신/수신 상태가 같은 정책으로 표시된다.
- 전송 이력과 실패 원인을 재시작 후에도 확인할 수 있다.

기능 범위:

- persisted transfer history schema
- transfer job repository
- sender/receiver status text 통일
- cancel/retry action
- 완료 파일 열기/폴더 열기
- multi-file UI와 1:N 전송 UX 분리

테스트:

- [ ] 완료/실패 transfer job이 DB에 저장된다.
- [ ] 앱 재시작 후 최근 이력이 표시된다.
- [ ] retry 가능한 실패와 retry 불가능 실패가 구분된다.
- [ ] 수신 job과 송신 job이 동일한 state vocabulary를 사용한다.
- [ ] multi-file drop 시 batch와 file item이 올바르게 생성된다.

검증:

- [ ] 단일 파일 송신/수신 이력 표시
- [ ] 실패 후 재시도 UI 동작
- [ ] 완료 후 저장 폴더 열기

완료 기준:

- 사용자는 전송 실패가 누구의 어떤 문제인지 UI에서 구분할 수 있다.

### P8. Diagnostics와 Log Export

목표:

- 문제 발생 시 로그를 다시 추가하지 않고도 원인을 좁힐 수 있다.
- 사용자가 진단 정보를 안전하게 전달할 수 있다.

기능 범위:

- diagnostics ring buffer 정리
- peer route snapshot export
- auth/session state snapshot export
- transfer session snapshot export
- log redaction 검증
- debug panel 또는 export button
- packet decision summary 수집
- release gate용 diagnostics bundle 포맷 정의

테스트:

- [ ] export에는 비밀번호, JWT 원문, session key가 없다.
- [ ] 파일 전체 경로는 필요 시 basename 또는 축약 경로로만 표시된다.
- [ ] route 후보와 active route가 포함된다.
- [ ] 최근 transfer error code가 포함된다.
- [ ] diagnostics buffer size가 제한된다.
- [ ] 자기 자신 packet, group mismatch, stale route, route probe failure decision이 구분된다.
- [ ] export bundle은 product/debug/development 섹션을 구분한다.

검증:

- [ ] host/VM 연결 실패 상황에서 export로 send/receive decision 확인 가능
- [ ] transfer 실패 상황에서 selected endpoint 확인 가능

완료 기준:

- 현장 문제를 재현할 때 첫 조치가 "로그 추가"가 아니라 "diagnostics export 확인"이 된다.

### P9. macOS/Windows/Linux 제품 안정화

목표:

- 각 OS에서 클릭, 입력, 경로, 방화벽, 소켓 권한 문제가 제품 수준으로 정리된다.

기능 범위:

- macOS 클릭/포커스 반응성 점검
- Windows firewall 안내와 UDP port 허용 가이드
- Linux Ubuntu 22.04 minimum 문서와 build dependency 확인
- release build smoke script 정리
- platform-specific path permission guide

테스트:

- [ ] macOS UI widget test로 primary action button hit target 확인
- [ ] Windows settings/path smoke checklist 작성
- [ ] Ubuntu 22.04 build workflow 유지
- [ ] platform guide가 README/README.ko.md에 반영된다.

검증:

- [ ] macOS에서 버튼이 단일 클릭으로 반응
- [ ] Windows에서 로그인 입력/버튼 활성화 정상
- [ ] Linux 22.04에서 실행/종료 정상

완료 기준:

- 각 OS별 알려진 실행 전제와 문제 해결 절차가 문서화된다.

### P10. Release Gate 강화

목표:

- tag를 찍기 전에 빌드뿐 아니라 핵심 네트워크 시나리오를 확인한다.

기능 범위:

- release checklist 문서
- local smoke command 정리
- benchmark 기록 양식
- GitHub Actions artifact 검증
- manual gate 결과 기록 위치 정의

체크리스트:

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] macOS debug run smoke
- [ ] Windows release build
- [ ] Linux Ubuntu 22.04 build
- [ ] macOS host <-> macOS second instance discovery/auth/transfer
- [ ] macOS host <-> Parallels Windows VM discovery/auth/transfer
- [ ] macOS host <-> Ubuntu 22.04 discovery/auth/transfer
- [ ] diagnostics export redaction 확인
- [ ] benchmark 결과 기록

완료 기준:

- release tag는 최소 네트워크/전송 smoke 결과와 함께 생성한다.

## 5. 작업 분할 제안

다음 task 파일 생성 시 이 순서를 따른다.

- `.tasks/task001.md`: 문서/README 정렬, current scope audit, 공통 TDD/상태머신 완료 기준 정리
- `.tasks/task002.md`: peer identity, route candidate, route lease, self packet suppression 안정화
- `.tasks/task003.md`: multi Ethernet discovery target, broadcast send, receive decision 검증
- `.tasks/task004.md`: 자동 인증/연결 state machine, duplicate handshake, stale peer cleanup 정리
- `.tasks/task005.md`: active route lease와 data transfer path 일치성 보장
- `.tasks/task006.md`: 저장 경로, temp file, 수신 준비 lifecycle 안정화
- `.tasks/task007.md`: Data channel correctness, digest verification, 성능 튜닝, benchmark harness
- `.tasks/task008.md`: transfer UX, retry/cancel, persisted history, sender/receiver 상태 용어 통일
- `.tasks/task009.md`: diagnostics export, packet decision summary, redaction
- `.tasks/task010.md`: macOS/Windows/Linux platform hardening, firewall/path/click/input 검증
- `.tasks/task011.md`: release gate, 양방향 host/VM 전송 검증, benchmark 기록 체계

각 task는 반드시 다음 형식을 가진다.

- 기능 범위 2~3개
- 구현 체크박스
- 테스트 체크박스
- 수동 검증 체크박스
- 완료 기준
- 선행 조건과 제외 범위
- 계층별 변경 위치
- 실패 테스트 또는 수동 재현 기준
- diagnostics/log 검토 결과
- 회귀 금지 조건

## 6. Out of Scope

다음은 현재 연결 안정화 1차 목표에 포함하지 않는다.

- 인터넷 NAT traversal
- 외부 relay 서버
- 모바일 앱
- 웹 수신 페이지
- 조직 관리자 콘솔
- 계정 등록형 인증 저장소
- 수신 전 승인 workflow
- 서버 기반 사용자 동기화
- E2E payload encryption의 완성형 제품화
- 대규모 배포 관리 기능

## 7. 다음 실행 순서

1. README/README.ko.md를 현재 인증/자동 수신/멀티 인터페이스 정책과 맞춘다.
2. `.tasks/task001.md`부터 위 작업 분할 기준으로 상세 task를 생성한다.
3. 공통 완료 기준을 task001에 고정하고, 이후 task는 해당 기준을 복사해서 시작한다.
4. peer identity, route candidate, route lease, self packet suppression 테스트를 먼저 작성한다.
5. 모든 Ethernet discovery target과 receive decision 로그를 테스트로 고정한다.
6. host/Parallels VM 양방향 discovery/auth/transfer를 release gate에 편입한다.