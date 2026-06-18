# Task 005 - UDP 포트 모델, AppConfig migration, Data Port allocator

## 목표

Discovery, Control, Data UDP 채널의 책임을 코드 구조와 설정에 반영한다. 기존 `authPort` 중심 구조를 Control Port 개념으로 정리하고, Data Port 또는 Data Port Range를 명시적으로 도입한다.

## 연관 문서

- [phase002 plan.md - UDP 포트 분리 전략](plan.md#5-udp-포트-분리-전략)
- [AGENTS.md - Product-Specific Guardrails](../../AGENTS.md#product-specific-guardrails)

## 선행 조건

- [task001.md](task001.md)가 완료되어 현재 포트 구조와 migration 기준이 정리되어 있어야 한다.
- [task002.md](task002.md)의 `UdpPortStateMachine`이 있어야 한다.

## 포함 기능

### 기능 1. AppConfig 포트 모델 정리

- `discoveryPort`, `controlPort`, `dataPort` 또는 `dataPortRange`를 명확히 표현한다.
- 기존 `authPort`는 역할상 `controlPort`로 migration한다.
- 목표 기본 포트 `38400`, `38401`, `38410~38430`과 기존 `232xx` 기본값 사이 전환 전략을 코드와 테스트로 고정한다.

### 기능 2. UDP endpoint와 port role 모델

- `UdpPortRole`을 정의한다.
- `UdpEndpointConfig` 또는 동등한 값 객체를 만든다.
- Discovery/Control/Data transport가 포트 역할을 명시적으로 받도록 한다.

### 기능 3. Data Port allocator

- MVP에서 단일 Data Port를 쓸지, range allocator를 먼저 둘지 결정한다.
- range를 도입할 경우 config에 선언된 범위 안에서만 포트를 할당한다.
- OS 임의 포트 할당으로 실패를 숨기지 않는다.

## 구현 체크리스트

- [x] `AppConfig`에 Control Port 개념을 명확히 반영했다.
- [x] `authPort` 제거 또는 deprecated alias 유지 방식을 결정했다.
- [x] `dataPort` 또는 `dataPortRange`를 추가했다.
- [x] production 기본값을 목표 포트 체계로 옮길지, 별도 migration 단계로 둘지 결정했다.
- [x] 테스트용 AppConfig factory를 만들었다.
- [x] `UdpPortRole.discovery`, `UdpPortRole.control`, `UdpPortRole.data`를 정의했다.
- [x] 포트 바인딩 실패가 `UdpPortStateMachine` 이벤트로 변환된다.
- [x] Data Port allocator가 선언된 범위 밖 포트를 사용하지 않는다.
- [x] Discovery packet에 광고할 control/data endpoint 값을 만들 수 있다.
- [x] 런타임 중간에 포트 값을 변경하는 경로가 없다.

## 테스트

- [x] production config가 Discovery/Control/Data 포트 값을 가진다.
- [x] 테스트 config가 명시적 포트 세트를 주입할 수 있다.
- [x] `authPort` 호환 경로가 있다면 deprecation 테스트를 작성했다.
- [x] Data Port allocator가 range 안에서만 할당하는 테스트를 작성했다.
- [x] range exhausted 시 명확한 failure를 반환하는 테스트를 작성했다.
- [x] port bind failure가 상태 머신 failure로 이어지는 테스트를 작성했다.
- [x] runtime 중간 config 변경 경로가 없는지 구조적으로 확인했다.

## 검증

- [x] Discovery, Control, Data 채널 책임이 설정 이름만 봐도 구분된다.
- [x] 포트 충돌 시 임의 포트로 조용히 우회하지 않는다.
- [x] 다중 인스턴스 개발 테스트는 명시적 config로만 가능하다.
- [x] 방화벽 안내에 사용할 포트 역할 설명이 준비되어 있다.

## 진행 결과

- `lib/app/app_config.dart`
- `lib/core/network/udp_port_config.dart`
- `test/core/network/udp_port_config_test.dart`
- Discovery packet과 controller가 Control/Data endpoint 광고 값을 포함하도록 갱신했다.

## 완료 기준

- 후속 Discovery, Control, Data transport가 각자 명확한 포트 설정을 받을 수 있다.
- 포트 migration 기준과 테스트가 존재한다.
- AGENTS의 외부 설정/부트스트랩 원칙을 위반하지 않는다.
