# Task 005 - PeerConnectionCoordinator와 Control path 선택

## 목표

peer별 route candidate 목록에서 실제 연결을 시도할 Control path를 선택하고, 선택 결과를 active path registry와 diagnostics에 연결한다.

Discovery는 후보를 수집하고, 연결 오케스트레이션은 별도 application coordinator가 담당해야 한다. MessageBus event만으로 handshake가 암묵 실행되지 않도록 명령 경로를 명확히 둔다.

## 연관 문서

- [plan.md - 4.5 연결 오케스트레이션 책임](plan.md#45-연결-오케스트레이션-책임)
- [plan.md - 5.4 Control path selection 연결](plan.md#54-control-path-selection-연결)
- [AGENTS.md - MessageBus Rules](../AGENTS.md#messagebus-rules)
- [task004.md](task004.md)

## 선행 조건

- [task004.md](task004.md)의 runtime candidate projection이 있어야 한다.
- `PeerPathSelectionPolicy`, `PeerConnectionPath`, `PeerPathRegistry`가 현재 코드와 맞는지 확인해야 한다.
- 자동 handshake 시작 책임을 `DiscoveryController`에서 분리할 준비가 되어 있어야 한다.

## 포함 기능

### 기능 1. PeerConnectionCoordinator 도입

- peer별 selectable candidate를 읽는다.
- path selection policy로 selected path를 만든다.
- selected path를 `PeerPathRegistry`에 저장한다.
- selected path event를 MessageBus로 발행한다.

### 기능 2. 자동 handshake 명령 경로 정리

- DiscoveryController는 peer/candidate 발견 사실만 알린다.
- coordinator가 명시적으로 `PeerAuthController.startHandshake`를 호출한다.
- 이미 authenticated 또는 in-progress 상태인 peer는 중복 handshake를 시작하지 않는다.
- 후보가 없으면 handshake를 시작하지 않고 diagnostics reason을 남긴다.

### 기능 3. candidate 실패와 다음 후보 전이

- selected candidate 실패 시 같은 peer의 다음 selectable candidate를 선택한다.
- failed/degraded candidate는 후순위가 된다.
- 모든 candidate 실패 시 peer link failed로 종료한다.

## 구현 체크리스트

- [x] `PeerConnectionCoordinator` 또는 동등한 application controller를 만들었다.
- [x] coordinator가 candidate provider/store를 읽는다.
- [x] coordinator가 `PeerPathSelectionPolicy`를 사용한다.
- [x] selected path를 `PeerPathRegistry`에 저장한다.
- [x] `PeerPathSelected` event를 MessageBus에 publish한다.
- [x] handshake 명령은 coordinator가 controller 메서드로 직접 호출한다.
- [x] MessageBus subscriber 안에 handshake 명령 경로를 숨기지 않았다.
- [x] authenticated/in-progress peer 중복 handshake 방지 로직을 넣었다.
- [x] 후보 없음 reason code를 남긴다.
- [x] candidate 실패 시 다음 candidate 선택 전이를 상태 머신 또는 명시적 함수로 표현했다.

## 테스트

- [x] 같은 subnet Ethernet candidate가 우선 선택되는 테스트를 작성했다.
- [x] bridge candidate가 host-only virtual candidate보다 먼저 선택되는 테스트를 작성했다.
- [x] 이전 성공 candidate가 우선 선택되는 테스트를 작성했다.
- [x] failed/degraded candidate가 후순위가 되는 테스트를 작성했다.
- [x] selected path가 registry와 diagnostics provider에 반영되는 테스트를 작성했다.
- [x] 후보가 없으면 handshake를 시작하지 않는 테스트를 작성했다.
- [x] 이미 authenticated peer는 중복 handshake를 시작하지 않는 테스트를 작성했다.
- [x] 첫 candidate 실패 후 다음 candidate가 선택되는 테스트를 작성했다.
- [x] MessageBus event만으로 handshake가 암묵 실행되지 않는 구조 테스트를 작성했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] coordinator/application/network 테스트가 통과한다.
- [x] DiscoveryController의 책임이 candidate 수집과 presence 갱신으로 줄었다.
- [x] active path selection reason이 Debug diagnostics에서 설명 가능하다.
- [x] Product UI에는 과도한 경로 정보가 노출되지 않는다.

## 구현 결과

- `PeerConnectionCoordinator`가 peer별 route candidate를 읽고 `PeerPathSelectionPolicy`로 selected Control path를 결정한다.
- 선택된 path는 `PeerPathRegistry`에 저장되고 `PeerPathSelected` MessageBus event로 발행된다.
- `DiscoveryController`의 자동 handshake 경로는 coordinator 호출로 정리되었고, MessageBus event만으로 handshake가 실행되지 않도록 테스트로 고정했다.
- authenticated 또는 handshake in-progress 상태의 peer는 중복 handshake를 시작하지 않는다.
- candidate 실패 시 projection에서 해당 candidate를 failed 처리하고, 다음 selectable candidate로 재시도한다.
- selectable candidate가 처음부터 없으면 `noSelectableRouteCandidate`, 모든 candidate가 실패하면 `allRouteCandidatesFailed` reason code로 종료한다.
- `PeerAuthController.startHandshake`는 선택된 path context를 받을 수 있도록 확장했다. 실제 socket/interface 송신 강제 적용은 다음 Control/Data 전송 단계에서 다룬다.

## 실행 결과

- `flutter analyze`: 통과
- `flutter test test/domain/network/peer_connection_path_test.dart test/application/network/peer_connection_coordinator_test.dart`: 통과
- `flutter test test/application/discovery/discovery_controller_test.dart test/application/auth/peer_auth_controller_test.dart test/application/network/network_diagnostics_provider_test.dart test/application/discovery/peer_route_candidate_projection_test.dart`: 통과
- `flutter test`: 통과, 173 tests
- 참고: 전체 테스트 중 기존 Drift multiple database warning이 출력되지만 실패는 아니다.

## 완료 기준

- peer별 route candidate에서 selected Control path가 만들어진다.
- handshake 시작 명령 경로가 application coordinator에 모인다.
- 실패한 경로와 다음 후보 선택이 테스트로 고정된다.
