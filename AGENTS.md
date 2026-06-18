# AGENTS.md

이 문서는 Sponzey FileSharing 저장소에서 작업하는 모든 에이전트와 개발자가 반드시 따를 기준이다.

## Project Direction

Sponzey FileSharing은 같은 로컬 네트워크에 연결된 장치들이 빠르고 간편하게 파일을 주고받기 위한 Flutter Desktop 기반 파일 전송 앱이다.

핵심 방향은 다음과 같다.

- UDP 기반 Peer 검색과 제어 통신으로 로컬 네트워크 안에서 낮은 지연의 연결 수립을 제공하고, 현재 TCP Data Channel 전환 phase에서는 파일 payload를 TCP stream으로 전송한다.
- 아이디와 패스워드 기반 인증으로 허가된 사용자 간 연결을 구성한다.
- 여러 노드와 동시에 연결되는 다중 접속 환경을 지원한다.
- 특정 노드로 보내는 개별 전송과 여러 노드로 보내는 일괄 전송을 모두 고려한다.
- Peer 검색과 Peer 연동/제어는 UDP 포트 역할을 분리해 운영한다. 파일 데이터 통신은 현재 TCP Data Channel 전환 phase의 기본 경로로 설계하며, 기존 UDP Data channel은 명시된 legacy/fallback 범위 밖에서 기본 전송 경로로 사용하지 않는다.
- 연결 가능한 모든 Ethernet 계열 인터페이스를 활용한다. 여기에는 물리 NIC, USB/Thunderbolt Ethernet, 내부 Ethernet bridge, VM bridge처럼 실제 내부망 peer와 통신 가능한 bridge 경로가 포함된다.
- 특정 IP 대역, VM 제품, NIC 이름, 개발자 장비 환경을 전제로 한 discovery/connect/transfer 로직을 넣지 않는다. 모든 경로 선택은 관찰된 interface, 수신 packet, 검증된 route probe 결과를 기준으로 한다.
- 현재 제품 기본 인증은 가입 없는 런타임 ID/PW 세션이다. 비밀번호, password-derived JWT, session key는 메모리에서만 유지하고 OS 보안 저장소나 임의 설정 파일에 영속 저장하지 않는다.
- 같은 ID/PW 그룹의 peer는 자동 인증, 자동 연결, 자동 수신을 기본 동작으로 한다. 허용 사용자 목록, 수신 전 승인, 계정 등록형 verifier 저장은 별도 phase에서 명시적으로 계획되지 않는 한 기본 경로에 넣지 않는다.
- 외부 서버 의존을 최소화하고, 사내망, 가정망, 연구실, 테스트 장비망 같은 내부 네트워크 환경에서 안정적으로 동작해야 한다.

작업 시 기능 편의성보다 로컬 네트워크 신뢰성, 인증 경계, 전송 안정성, 관찰 가능성, 테스트 가능성을 우선한다.

## Required Engineering Principles

다음 원칙은 선택 사항이 아니다. 새 코드와 수정 코드는 모두 이 기준을 따라야 한다.

- Layered Architecture를 예외 없이 유지한다.
- Clean Architecture를 예외 없이 적용해 도메인 규칙이 UI, Flutter, 데이터베이스, 네트워크 구현에 의존하지 않도록 한다.
- Tidy First 원칙에 따라 기능 변경 전 필요한 작은 정돈을 먼저 수행하되, 무관한 대규모 리팩터링은 하지 않는다.
- TDD를 기본 작업 방식으로 삼고 반드시 적용한다. 실패하는 테스트 또는 명확한 테스트 기준을 먼저 만들고, 구현 후 통과시키며, 마지막에 정리한다.
- 내부 프로시저 관리와 상태 관리는 상태 머신을 기준으로 설계하고, 절차가 있는 흐름을 임의 조건문 조합으로 구현하지 않는다.
- 계층 간 비동기 이벤트 전달과 내부 절차 알림은 MessageBus를 기준으로 설계한다.

테스트를 생략할 수 있는 경우는 문서, 주석, 단순 파일 이동처럼 런타임 동작이 바뀌지 않는 변경뿐이다. 그 외에는 변경 범위에 맞는 단위 테스트, 위젯 테스트, 통합 성격의 테스트 중 최소 하나를 추가하거나 갱신한다.

## Architecture Rules

현재 저장소의 기본 계층은 다음과 같다.

- `lib/domain`: 엔티티, 값 객체, 도메인 서비스, 순수 비즈니스 규칙
- `lib/application`: 유스케이스, 상태 조합, 컨트롤러, 애플리케이션 흐름
- `lib/infrastructure`: UDP, 인증 토큰, 데이터베이스, 파일 시스템, 플랫폼 저장 경로/권한, 플랫폼 연동 구현
- `lib/presentation`: Flutter 화면, 위젯, 사용자 입력과 표시
- `lib/core`: 로깅, 에러 표현 등 계층 공통의 작은 기반
- `lib/app`: 앱 구성, 라우팅, 테마, 부트스트랩에 가까운 조립 코드

의존 방향은 항상 바깥쪽에서 안쪽으로 향해야 한다.

- `presentation`은 `application`을 사용할 수 있다.
- `application`은 `domain`을 사용할 수 있다.
- `infrastructure`는 `domain` 또는 필요한 추상 인터페이스를 구현할 수 있다.
- `domain`은 Flutter, Riverpod, Drift, 파일 시스템, UDP 소켓, 플랫폼 API에 의존하면 안 된다.
- 네트워크, 저장소, 플랫폼 구현 세부사항을 UI나 도메인에 직접 넣지 않는다.

새 기능을 추가할 때는 먼저 도메인 규칙과 유스케이스 경계를 정하고, 그 뒤 인프라와 프레젠테이션을 연결한다.

## State Machine Rules

인증, 피어 탐색, 연결, 파일 전송, 재시도, 실패 복구처럼 절차와 상태가 있는 기능은 상태 머신으로 관리한다.

- 내부 프로시저가 2단계 이상 상태 전이를 가지면 상태 머신 후보로 간주하고, 상태 모델 없이 구현하지 않는다.
- 상태는 명시적인 enum, sealed class, 값 객체 중 해당 계층에 맞는 형태로 표현한다.
- 상태 전이는 함수, 메서드, 컨트롤러 이벤트처럼 한 곳에서 추적 가능한 경로로 처리한다.
- UI 조건문, 콜백, 타이머, 네트워크 핸들러 안에 상태 전이 규칙을 흩어놓지 않는다.
- 허용되지 않는 전이는 무시하지 말고 실패, 경고, no-op 중 하나로 의도적으로 처리한다.
- 전이 조건, 부작용, 타임아웃, 재시도 횟수는 테스트로 고정한다.
- 상태 이름은 사용자 화면 문구가 아니라 도메인 절차를 기준으로 짓는다.

상태 머신은 Clean Architecture 경계를 따라 위치해야 한다. 순수한 전이 규칙은 `domain` 또는 `application`에 두고, 소켓, 파일 시스템, 타이머 같은 부작용은 `infrastructure`에서 명시적으로 주입하거나 실행한다.

## MessageBus Rules

피어 탐색, 인증, 파일 전송, 전송 큐, 로그성 이벤트처럼 여러 컴포넌트가 같은 사건을 관찰해야 하는 흐름은 MessageBus를 통해 전달한다.

- MessageBus는 계층 간 결합을 줄이기 위한 이벤트 전달 장치이지, 도메인 규칙을 숨기는 장소가 아니다.
- 이벤트 타입은 명시적으로 정의하고, 문자열 기반 임의 이벤트 이름으로 흐름을 만들지 않는다.
- 이벤트 payload는 불변 값 객체로 구성하고, mutable 객체나 UI 상태 객체를 그대로 전달하지 않는다.
- MessageBus를 전역 singleton처럼 직접 조회하지 않는다. 필요한 곳에 인터페이스로 주입한다.
- publish와 subscribe의 소유권, 생명주기, 해제 시점을 명확히 한다.
- 명령과 이벤트를 구분한다. 어떤 동작을 반드시 수행해야 하면 유스케이스나 컨트롤러 메서드로 호출하고, MessageBus에는 이미 발생한 사실을 알린다.
- 상태 머신 전이를 MessageBus 이벤트만으로 암묵적으로 발생시키지 않는다. 이벤트를 받는 쪽에서 허용된 전이인지 명시적으로 검증한다.
- 이벤트 순서, 중복 수신, 구독 해제, 실패한 subscriber 처리 방식은 테스트로 고정한다.

MessageBus 인터페이스는 `application` 또는 `core`에 둘 수 있다. 구체 구현은 `infrastructure`에 두고, Flutter UI는 MessageBus 구현체가 아니라 application 계층의 상태와 컨트롤러를 통해 관찰한다.

## Configuration Rules

외부 파일에 설정을 두는 방식은 최소화한다.

- 새 YAML, JSON, dotenv, 임의 설정 파일을 추가하지 않는다. 불가피한 경우 변경 이유와 대안을 먼저 문서화한다.
- 런타임 중간에 환경 설정 값을 삽입하거나 변경하는 방식은 반드시 거부한다.
- 실행 중간에 외부 설정 파일을 다시 로드하거나, 운영 입력으로 프로세스 내부 환경 상수를 덮어쓰는 방식은 허용하지 않는다.
- 프로세스 시작 이후 전역 환경 변수, 외부 설정 파일, mutable singleton을 다시 읽어 동작을 바꾸지 않는다.
- 외부 환경 상수는 최초 부트스트랩 시점에만 받아들인다.
- 부트스트랩 이후 필요한 값은 프로그램 상수나 전역 조회가 아니라 명시적인 인자, 생성자 파라미터, provider override, 유스케이스 입력값으로 전달한다.
- 테스트에서는 환경을 숨겨 바꾸지 말고 테스트 대상에 필요한 값을 직접 주입한다.

현재 앱 구성의 기준점은 `AppConfig`와 `bootstrap(config: ...)`이다. 새 설정이 필요하면 먼저 `AppConfig`에 속해야 하는지, 유스케이스 입력값이어야 하는지, 저장 가능한 사용자 설정이어야 하는지를 구분한다.

## Logging Rules

로그는 세 가지 운영 목적을 기준으로 나눈다.

- Product: 프로덕트용 최소 로그. 사용자 영향이 있는 시작, 실패, 복구, 보안상 중요한 이벤트만 남긴다.
- Debug: 현장 확인용 디버그 로그. 배포 후 문제 재현과 상태 확인에 필요한 네트워크, 인증, 전송 흐름을 남긴다.
- Development: 개발 및 테스트 중 확인하기 위한 상세 로그. 패킷 세부 흐름, 내부 상태 전이, 테스트 보조 정보를 포함할 수 있다.

구현상 로그 레벨은 기존 `AppLogger`, `AppLogLevel`, `AppLogCategory`를 사용한다. 새 로깅 체계를 별도로 만들지 않는다.

- Product 목적 로그는 `info`, `warning`, `error`를 중심으로 사용한다.
- Debug 목적 로그는 `debug`를 사용하되 민감 정보는 기록하지 않는다.
- Development 목적 로그는 테스트와 개발 빌드에서만 의미가 있어야 하며 프로덕션 기본 로그에 섞이면 안 된다.
- 패스워드, 토큰, 파일 원문, 개인 식별 정보, 전체 경로처럼 민감할 수 있는 값은 로그에 남기지 않는다.
- 전송량, peer id, 세션 id, 상태 코드처럼 진단에 필요한 값은 축약하거나 안전한 형태로 남긴다.

## TDD Workflow

기능 변경은 다음 순서를 따른다.

1. 변경할 동작을 테스트로 표현한다.
2. 테스트가 실패하는 것을 확인한다.
3. 가장 작은 구현으로 테스트를 통과시킨다.
4. Tidy First 기준으로 중복, 이름, 계층 위반을 정리한다.
5. 관련 테스트를 다시 실행한다.

테스트 위치는 변경 계층에 맞춘다.

- 도메인 규칙: `test/domain`
- 애플리케이션 컨트롤러와 유스케이스: `test/application`
- 네트워크, 저장소, 파일 전송, 토큰 등 구현체: `test/infrastructure`
- 화면과 사용자 흐름: `test`의 위젯 테스트

현재 테스트 구조가 없는 계층에 테스트를 추가해야 한다면 기존 네이밍과 패턴을 따라 최소 구조만 만든다.

## Product-Specific Guardrails

네트워크와 파일 전송 변경은 다음 기준을 만족해야 한다.

- Discovery, Control, Data 채널의 책임을 섞지 않는다.
- Discovery는 Peer 검색과 presence에만 사용하고, 인증 토큰이나 파일 정보를 싣지 않는다.
- Discovery에는 JWT, session key, raw password, password-derived reusable verifier처럼 인증에 재사용 가능한 값을 싣지 않는다. 같은 ID/PW 그룹 필터링이 필요하면 인증 재료와 분리된 discovery-only tag를 사용한다.
- Control은 인증, 세션 협상, TCP Data channel 협상, 전송 제어에 사용하고, 대량 파일 payload를 싣지 않는다.
- Data는 인증된 세션의 파일 payload 송수신에 사용한다. 현재 TCP Data Channel 전환 phase의 기본 Data 경로는 TCP stream이며, Discovery와 Control은 UDP를 유지한다.
- peer identity와 route identity를 분리한다. 하나의 peer는 여러 route candidate를 가질 수 있으며, route lease는 TCP connect input과 diagnostics context로 사용한다. 전송 가능 여부와 파일 전송 대상 선택은 인증된 TCP data session을 기준으로 안정화한다.
- route lease 또는 TCP data session lease에는 최소한 local interface, local address, remote address, control endpoint, data endpoint, 검증 시각, 만료 정책이 포함되어야 한다. TCP Data 기본 경로에서 파일 전송은 검증되지 않은 route candidate 또는 인증되지 않은 TCP data session으로 시작하지 않는다.
- 앱 인스턴스는 내부 random instance id로 자기 자신이 보낸 discovery/control/data packet을 구분하고, self packet은 peer 목록, 자동 연결, 파일 전송 target에 진입시키지 않는다.
- 가입, 로컬 계정 생성, password hash/verifier 영속 저장, Keychain/Credential Manager/Secret Service 저장은 현재 기본 제품 범위가 아니다. 필요한 경우 별도 task와 threat model, migration plan을 먼저 작성해야 한다.
- 인증 비밀은 로그인 세션의 명시적 인자와 주입된 session context로만 전달한다. 전역 singleton, 외부 설정 파일, 런타임 환경 변수 재조회로 인증 상태를 만들지 않는다.
- 인증된 peer는 기본 저장 경로로 자동 수신한다. 수신 전 승인 UI나 허용 목록 정책을 추가하려면 현재 자동 수신 정책과 충돌하지 않는 상태 머신 전이를 먼저 정의해야 한다.
- Data channel의 대량 파일 payload는 raw binary payload를 기준으로 설계한다. JSON/base64 file payload 전송은 호환 fallback이나 테스트 목적이 아닌 기본 경로로 사용하지 않는다.
- UDP 또는 TCP 전송 성능을 해치는 per-packet 또는 per-frame product/info 로그, per-packet 또는 per-frame MessageBus event, chunk별 파일 open/flush/close, chunk별 독립 timer 남발을 기본 구현으로 두지 않는다.
- TCP Data channel 변경에는 frame size, stream framing, backpressure, timeout, throughput smoke 또는 benchmark 기준을 함께 정의한다. UDP Data legacy/fallback 변경에는 packet size, ACK/NACK 빈도, retransmission 기준을 별도로 정의한다.
- TCP Data 기본 경로에서는 stream framing, partial read, coalesced read, socket close, timeout, backpressure를 명시적으로 고려한다. UDP Data legacy/fallback 경로에서는 패킷 손실, 중복, 재전송, 타임아웃, 순서 어긋남을 명시적으로 고려한다.
- 인증되지 않은 peer가 전송 흐름에 진입하지 못하도록 한다.
- 인증 성공 후 데이터 통신에 사용할 세션 문맥과 세션 키 lifecycle을 명확히 관리한다.
- 다중 접속과 1:N 전송에서 공유 상태가 섞이지 않도록 세션, peer, transfer job 경계를 분리한다.
- 전송, 인증, 탐색의 진행 상태는 상태 머신으로 표현하고, 임의 boolean 조합으로 절차를 관리하지 않는다.
- 전송, 인증, 탐색에서 여러 컴포넌트가 알아야 하는 사건은 MessageBus 이벤트로 발행하되, 명령 실행 경로를 MessageBus에 숨기지 않는다.
- 네트워크/전송 장애 수정은 기존 diagnostics와 log를 먼저 확인하고 원인을 좁힌 뒤 수행한다. 로그가 부족하면 민감정보를 제외한 구조화 로그를 충분히 추가하고, 이후 같은 유형의 문제를 재현할 수 있는 테스트나 smoke 기준을 남긴다.
- 파일 수신 정책과 저장 위치는 사용자가 예측할 수 있어야 하며, 임의 경로 쓰기를 허용하지 않는다.
- UI는 전송 상태, 실패, 재시도 가능 여부를 명확히 보여야 한다.

## Task Tracking

작업 문서는 `.tasks` 아래 phase별 디렉터리로 관리한다. 현재 구현 기준의 우선 개발 방향은 `.tasks/plan.md`를 먼저 확인한다. 태스크를 수행할 때는 해당 phase의 `README.md`, `plan.md`, 개별 task 문서의 선행 조건, 체크리스트, 테스트, 검증 기준을 확인한다.

새 phase를 만들 때는 기존 phase를 임의로 수정하지 말고 새 디렉터리로 분리한다.

## Change Discipline

- 기존 계층, 네이밍, Riverpod provider 패턴을 우선한다.
- 새 의존성은 꼭 필요한 경우에만 추가하고, 테스트 가능성과 플랫폼 영향을 함께 검토한다.
- 코드 생성 파일은 직접 수정하지 않는다. Drift 등 생성물이 필요하면 정해진 생성 명령을 사용한다.
- 사용자 변경사항을 되돌리지 않는다.
- unrelated cleanup은 하지 않는다.
- 구현을 마친 뒤 가능한 범위에서 `flutter test` 또는 변경 범위에 맞는 테스트를 실행한다.
