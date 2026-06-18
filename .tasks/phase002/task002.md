# Task 002 - 상태 머신 공통 기반과 lifecycle/port/discovery 상태 모델

## 목표

상태 머신 기반 절차 관리를 위한 공통 타입을 만들고, 앱 lifecycle, UDP port lifecycle, discovery 절차를 테스트 가능한 상태 머신으로 분리한다.

이 태스크는 이후 인증, 전송, 수신 정책 상태 머신의 기반이 된다.

## 연관 문서

- [phase002 plan.md - 상태 머신 설계](plan.md#6-상태-머신-설계)
- [AGENTS.md - State Machine Rules](../../AGENTS.md#state-machine-rules)

## 선행 조건

- [task001.md](task001.md)가 완료되어 현재 구조와 테스트 기준이 정리되어 있어야 한다.

## 포함 기능

### 기능 1. 상태 머신 공통 타입

- 상태, 이벤트, 전이 결과, 부작용 요청을 표현할 최소 타입을 만든다.
- invalid transition 처리 정책을 명시한다.
- 상태 머신 자체는 가능한 순수 함수에 가깝게 유지한다.

### 기능 2. AppLifecycleStateMachine

- 앱 시작, 설정 로딩, 저장소 초기화, 포트 바인딩, 로그인 요구, 실행, 종료, 실패 상태를 관리한다.
- 포트 바인딩 실패 시 running으로 넘어가지 않도록 한다.
- 로그인 전 전송 명령이 거부되는 절차를 표현한다.

### 기능 3. UdpPortStateMachine과 DiscoveryStateMachine

- Discovery, Control, Data 포트 각각의 bind/listen/close/fail 상태를 표현한다.
- Discovery 시작, announce, listening, scanning, active, stale/offline peer 전이를 표현한다.
- timer와 socket 같은 부작용은 상태 머신 밖에서 실행되도록 전이 결과에 의도만 담는다.

## 구현 체크리스트

- [x] 상태 머신 공통 타입 위치를 정했다.
- [x] `TransitionResult` 또는 동등한 결과 타입을 만들었다.
- [x] 상태 전이 결과에 next state, emitted events, requested effects, warning/failure를 담을 수 있다.
- [x] invalid transition은 무시가 아니라 명시적인 no-op, warning, failure 중 하나로 처리된다.
- [x] `AppLifecycleStateMachine` 상태와 이벤트를 정의했다.
- [x] `UdpPortStateMachine` 상태와 이벤트를 정의했다.
- [x] `DiscoveryStateMachine` 상태와 이벤트를 정의했다.
- [x] Discovery peer 상태 `unknown`, `seen`, `online`, `stale`, `offline`, `blocked`, `incompatible`을 표현했다.
- [x] 상태 이름이 UI 문구가 아니라 도메인 절차 기준인지 확인했다.
- [x] 상태 머신 코드에 Flutter/Riverpod/socket/file system 의존이 없다.

## 테스트

- [x] App lifecycle 정상 전이 테스트를 작성했다.
- [x] 포트 바인딩 실패 시 `running`으로 전이하지 않는 테스트를 작성했다.
- [x] 로그인 전 transfer command가 거부되는 테스트를 작성했다.
- [x] UDP port가 `unbound -> binding -> bound -> listening`으로 전이하는 테스트를 작성했다.
- [x] `closed` 상태의 port 인스턴스를 재사용하지 않는 테스트를 작성했다.
- [x] Discovery start/announce/listen/stop 전이 테스트를 작성했다.
- [x] protocolVersion mismatch peer가 `incompatible`로 전이하는 테스트를 작성했다.
- [x] heartbeat timeout 후 `stale`, 추가 timeout 후 `offline` 전이 테스트를 작성했다.
- [x] invalid transition 처리 정책을 테스트했다.

## 검증

- [x] 상태 머신 단위 테스트가 UI 없이 실행된다.
- [x] socket, timer, DB 저장 같은 부작용은 상태 머신 내부에서 직접 실행되지 않는다.
- [x] 상태 전이 표를 보고 후속 controller가 어떤 effect를 실행해야 하는지 이해할 수 있다.
- [x] Development 로그에 상태 전이를 남길 수 있는 event metadata가 충분하다.

## 진행 결과

- `lib/core/state_machine/state_machine.dart`
- `lib/domain/app_lifecycle/app_lifecycle_state_machine.dart`
- `lib/domain/discovery/udp_port_state_machine.dart`
- `lib/domain/discovery/discovery_state_machine.dart`
- `test/domain/app_lifecycle/app_lifecycle_state_machine_test.dart`
- `test/domain/discovery/udp_port_state_machine_test.dart`
- `test/domain/discovery/discovery_state_machine_test.dart`

## 완료 기준

- App lifecycle, UDP port lifecycle, Discovery 절차가 상태 머신으로 표현되어 있다.
- 주요 전이가 테스트로 고정되어 있다.
- 후속 Discovery 구현이 상태 머신을 기준으로 동작할 수 있다.

## 메모

- 공통 타입을 과하게 일반화하지 않는다.
- 첫 구현은 현재 필요한 상태 머신을 명확히 표현하는 데 집중한다.