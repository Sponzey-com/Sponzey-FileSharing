# Task 001 - 현재 구조 감사와 phase002 기준 정렬

## 목표

기존 코드와 문서가 phase002 개발 기준과 충돌하지 않도록 현재 상태를 감사하고, 상태 머신, MessageBus, UDP 포트 분리 작업을 시작하기 전 기준선을 확정한다.

이 태스크는 직접 기능을 많이 추가하기보다, 이후 작업이 흔들리지 않도록 현재 구현, 테스트, 문서, 설정 구조의 차이를 명확히 정리하는 작업이다.

## 연관 문서

- [README.md](../../README.md)
- [AGENTS.md](../../AGENTS.md)
- [phase002 plan.md](plan.md)
- [phase001 README](../phase001/README.md)

## 선행 조건

- phase001 태스크 파일이 `.tasks/phase001`에 보존되어 있어야 한다.
- 루트 `README.md`, `AGENTS.md`, `.tasks/phase002/plan.md`가 최신 방향을 담고 있어야 한다.

## 포함 기능

### 기능 1. 현재 구현 구조 감사

- `lib/app`, `lib/core`, `lib/domain`, `lib/application`, `lib/infrastructure`, `lib/presentation`의 현재 책임을 확인한다.
- 각 계층이 AGENTS의 의존 방향을 위반하는지 점검한다.
- 기존 controller, transport, repository, logger가 상태 머신과 MessageBus를 받아들일 수 있는 구조인지 확인한다.

### 기능 2. 포트와 설정 기준 감사

- `AppConfig`의 `discoveryPort`, `authPort`, timeout, interval 값을 확인한다.
- 루트 `plan.md` 목표 포트 체계인 `38400`, `38401`, `38410~38430`과 현재 코드 기본값의 차이를 기록한다.
- `authPort`를 `controlPort`로 migration할 범위와 호환 전략을 정리한다.

### 기능 3. 테스트 커버리지 지도 작성

- 현재 테스트가 application, infrastructure, widget 중 어디까지 커버하는지 정리한다.
- 상태 머신, MessageBus, 포트 분리, Discovery, Control, Data 전송에 필요한 누락 테스트를 식별한다.
- 이후 태스크별로 추가할 테스트 위치와 이름 규칙을 정한다.

## 구현 체크리스트

- [x] 현재 `lib` 디렉터리 구조를 계층별 책임 기준으로 점검했다.
- [x] `domain`에서 Flutter, Riverpod, Drift, UDP socket, 파일 시스템 의존이 없는지 확인했다.
- [x] `application` controller가 상태 머신과 MessageBus를 주입받을 수 있는지 확인했다.
- [x] `infrastructure` transport가 Discovery, Control, Data 역할로 분리 가능한지 확인했다.
- [x] `AppConfig`의 현재 포트와 목표 포트 체계 차이를 기록했다.
- [x] `authPort -> controlPort` migration 방식을 결정했다.
- [x] 단일 `dataPort`와 `dataPortRange` 중 MVP 적용 범위를 결정했다.
- [x] 기존 테스트 목록과 누락 테스트 목록을 `.tasks` 문서 또는 task 메모에 정리했다.
- [x] phase001 완료 체크와 실제 코드 상태가 불일치하는 항목을 식별했다.

## 테스트

- [x] 기존 `flutter test` 실행 가능 여부를 확인한다.
- [x] 현재 실패하는 테스트가 있다면 phase002 작업과 무관한 기존 실패인지 구분한다.
- [x] 이 태스크에서 코드 수정이 발생하면 관련 테스트를 추가하거나 갱신한다.

## 검증

- [x] 상태 머신 도입 전에 어떤 파일을 먼저 수정해야 하는지 목록이 있다.
- [x] MessageBus 도입 전에 application event 경계가 어디인지 설명할 수 있다.
- [x] 포트 migration이 기존 discovery/auth 테스트를 어떻게 바꿀지 설명할 수 있다.
- [x] 이후 태스크가 같은 결정을 반복하지 않도록 기준이 문서화되어 있다.

## 감사 결과

### 1. 계층 구조

현재 `lib` 구조는 phase002 계획의 큰 계층과 일치한다.

- `lib/app`: `AppConfig`, 라우터, 테마, 앱 조립 코드가 있다.
- `lib/core`: 에러 표현과 로거 기반이 있다.
- `lib/domain`: `AllowedPeer`, `AppSettings`, `PeerAuthSession`, `PeerNode`, `TransferJob`, `UserAccount`, `PasswordHasher`가 있으며 Flutter, Riverpod, Drift, UDP socket, 파일 시스템 의존은 확인되지 않았다.
- `lib/application`: auth, discovery, settings, transfer controller와 overview provider가 있다.
- `lib/infrastructure`: UDP auth/discovery transport, packet codec, repositories, database, platform, transfer file service가 있다.
- `lib/presentation`: auth, dashboard, peers, transfers, history, settings 화면과 shell/shared widget이 있다.

확인된 구조상 주의점:

- `application` 계층이 `infrastructure` provider와 packet/transport 구현 경계를 직접 import한다.
- `DiscoveryController`, `PeerAuthController`, `TransferController`는 현재 orchestration, packet handling, transport 호출, 일부 상태 절차를 함께 들고 있다.
- phase002에서는 controller를 즉시 대규모로 찢지 말고, 상태 머신과 MessageBus 인터페이스를 먼저 추가한 뒤 controller가 그 결과를 실행하도록 점진적으로 이동한다.

### 2. 상태 머신 도입 전 우선 수정 대상

다음 파일들이 상태 머신 연결의 1차 대상이다.

- `lib/application/discovery/discovery_controller.dart`
- `lib/application/auth/peer_auth_controller.dart`
- `lib/application/transfer/transfer_controller.dart`
- `lib/application/settings/settings_controller.dart`
- `lib/app/app_config.dart`

상태 머신은 새 domain 또는 core 하위에 순수 타입으로 먼저 추가한다.

권장 위치:

```text
lib/core/state_machine/
lib/domain/discovery/
lib/domain/peer_link/
lib/domain/transfer/
test/domain/
```

### 3. MessageBus 도입 전 event 경계

MessageBus가 관찰해야 할 1차 event 경계는 다음과 같다.

- Discovery: peer seen, peer updated, peer stale, peer offline, incompatible peer, discovery started/stopped
- UDP Port: port bind requested, port bound, port bind failed, port closed
- Auth/Link: link requested, challenge issued/received, auth accepted/rejected, session expired
- Transfer: transfer offered, accepted, rejected, started, progressed, retried, completed, failed, cancelled
- Diagnostics/Security: malformed packet, replay rejected, port conflict, sensitive logging violation candidate

명령 실행 경로는 MessageBus로 숨기지 않는다. 사용자 명령은 controller/use case 메서드로 들어가고, 상태 전이와 side effect 이후에 이미 발생한 사실만 publish한다.

### 4. 포트와 설정 감사

현재 `AppConfig.production()` 기본값:

```text
discoveryPort: 23201
authPort: 23200
protocolVersion: 1.0
authTokenLifetime: 20s
authAllowedClockSkew: 5s
authHandshakeTimeout: 15s
discoveryBroadcastInterval: 3s
discoveryStaleAfter: 10s
discoveryOfflineAfter: 30s
defaultLogLevel: info
```

`.tasks/phase002/plan.md` 목표 포트 체계:

```text
Discovery Port: 38400/udp
Control Port: 38401/udp
Data Port: 38410/udp
Data Port Range: 38410~38430/udp
```

Migration 결정:

- `authPort`는 역할상 `controlPort`로 migration한다.
- 호환 기간에는 `authPort` alias를 유지할 수 있지만 새 코드와 테스트는 `controlPort`를 기준으로 작성한다.
- Discovery 기본값은 목표 체계에 맞춰 `38400`으로 이동한다.
- Control 기본값은 목표 체계에 맞춰 `38401`로 이동한다.
- MVP는 단일 `dataPort = 38410`으로 시작한다.
- 1:N 병렬 전송 또는 성능 안정화 단계에서 `dataPortRange = 38410~38430` allocator를 추가한다.
- 포트 변경은 부트스트랩 config 변경으로만 처리하고 런타임 중간 변경은 허용하지 않는다.

기존 테스트 영향:

- `peer_auth_controller_test.dart`, `discovery_controller_test.dart`, `transfer_controller_test.dart`는 이미 일부 테스트 config에서 `38400`, `38401`을 사용한다.
- 테스트 helper의 `authPort` 인자는 `controlPort`로 이름 변경이 필요하다.
- transfer 테스트는 현재 auth/control transport 위에서 데이터 전송까지 수행하므로, Data Port 분리 후 fake network를 Discovery/Control/Data channel로 나눠야 한다.

### 5. Discovery, Control, Data 분리 가능성

현재 transport 구조:

- `DiscoveryTransport`와 `RawUdpDiscoveryTransport`가 별도로 존재한다.
- `AuthTransport`와 `RawUdpAuthTransport`가 별도로 존재한다.
- 파일 전송 제어와 chunk 데이터가 현재 `AuthPacket` 및 `AuthTransport` 흐름에 함께 있다.

판단:

- Discovery와 Control 분리는 이미 시작되어 있다.
- `AuthTransport`는 `ControlTransport`로 migration하는 것이 맞다.
- Data 통신은 새 `DataTransport` 또는 `TransferDataTransport`로 분리해야 한다.
- `AuthPacket`에 transfer packet이 섞여 있으므로 Control packet과 Data packet schema 분리가 필요하다.

### 6. 테스트 커버리지 지도

현재 테스트 파일:

- Application auth: `auth_controller_test.dart`, `peer_auth_controller_test.dart`
- Application discovery: `discovery_controller_test.dart`, `discovery_sorting_test.dart`
- Application settings: `settings_controller_test.dart`
- Application transfer: `transfer_controller_test.dart`, `transfer_rtt_estimator_test.dart`
- Infrastructure auth: `jwt_token_service_test.dart`, `raw_udp_auth_transport_test.dart`
- Infrastructure crypto: `argon2id_password_hasher_test.dart`
- Infrastructure discovery: `discovery_packet_test.dart`, `local_instance_registry_test.dart`, `raw_udp_discovery_transport_test.dart`
- Infrastructure repositories: allowed peer, peer, settings, user repository tests
- Infrastructure transfer: `transfer_file_service_test.dart`
- Widget: `widget_test.dart`

누락 테스트:

- 상태 머신 순수 단위 테스트가 없다.
- MessageBus publish/subscribe/unsubscribe/subscriber failure 테스트가 없다.
- Discovery/Control/Data 포트 역할 분리 테스트가 없다.
- `controlPort` migration 테스트가 없다.
- Data Port allocator 또는 `dataPortRange` 테스트가 없다.
- Control packet과 Data packet schema 분리 테스트가 없다.
- session key lifecycle 테스트가 없다.
- sensitive logging 금지 검증은 phase001 일부 항목에 미완료로 남아 있다.

권장 신규 테스트 위치:

```text
test/domain/state_machine/
test/domain/discovery/
test/domain/peer_link/
test/domain/transfer/
test/core/message_bus/
test/application/network/
test/infrastructure/control/
test/infrastructure/transfer_data/
```

### 7. phase001 상태와 실제 코드 불일치

phase001 문서상 완료되지 않은 항목이 남아 있다.

- `task003`: 실제 두 장비 상호 discovery, 장치 종료 후 offline 처리, discovery 로그 중복 확인이 미완료다.
- `task004`: 원문 비밀번호와 원문 JWT가 로그에 남지 않는지 검증이 미완료다.
- `task005`: 100MB 이상 파일, 저장 경로 권한 오류, 실패 후 임시 파일 처리 검증이 미완료다.
- `task007`: 다중 파일, 1:N, queue 관련 항목이 미완료다.
- `task008`: 수신 정책, 이력, 로그/설정 고도화 항목이 미완료다.
- `task009`: 플랫폼 안정화, 패키징, 교차 플랫폼 검증이 미완료다.

phase002 작업에서는 위 항목을 새 구조 기준으로 다시 수행하되, phase001 문서는 덮어쓰지 않는다.

### 8. 테스트 실행 결과

실행 명령:

```sh
flutter test
```

결과:

- 전체 테스트 통과: `45 passed`
- 실패 테스트 없음

주의:

- `transfer_controller_test.dart` 실행 중 Drift의 multiple database warning이 반복 출력된다.
- 현재는 실패가 아니지만, 테스트 격리와 DB executor lifecycle 정리 후보로 기록한다.

## 완료 기준

- [x] phase002 구현 기준선이 명확하다.
- [x] 포트 이름과 기본값 migration 방향이 정해져 있다.
- [x] 상태 머신과 MessageBus를 구현할 테스트 위치가 정해져 있다.
- [x] 기존 phase001 문서를 덮어쓰지 않고 새 phase 작업이 시작 가능한 상태다.

## 메모

- 이 태스크는 Tidy First 성격이다. 무관한 리팩터링을 시작하지 않는다.
- 필요한 정리만 하고, 실제 기능 구현은 후속 태스크에서 진행한다.