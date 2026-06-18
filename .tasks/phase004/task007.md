# Task 007 - 자동 인증 path context와 active path 상태 전이

## 목표

Control/Auth handshake 전체가 같은 selected path context를 유지하고, 인증 성공/실패 결과가 active path 상태로 반영되도록 한다.

이 태스크가 끝나면 “발견됨”과 “인증됨”이 분리되어 보이며, 인증 성공 후 `PeerConnectionPath.active`가 diagnostics와 UI에서 확인되어야 한다.

## 연관 문서

- [plan.md - 5.6 자동 인증 상태와 active path 전이](plan.md#56-자동-인증-상태와-active-path-전이)
- [plan.md - 7. 완료 기준](plan.md#7-완료-기준)
- [task005.md](task005.md)
- [task006.md](task006.md)

## 선행 조건

- [task005.md](task005.md)의 coordinator가 selected path를 만든다.
- [task006.md](task006.md)의 ControlTransport local bind가 동작한다.
- `PeerAuthSession`, `_HandshakeContext`, `PeerPathRegistry`의 책임을 확인해야 한다.

## 포함 기능

### 기능 1. selected path context 전파

- `PeerAuthController.startHandshake`가 selected path를 인자로 받는다.
- `_HandshakeContext`에 path id, candidate id, local endpoint를 저장한다.
- `CONNECT_REQUEST`, `AUTH_CHALLENGE`, `AUTH_TOKEN`, `AUTH_ACCEPT`, `AUTH_REJECT`가 같은 path context를 사용한다.

### 기능 2. 인증 성공/실패 상태 전이

- 인증 시작 시 path 상태를 `authenticating`으로 전이한다.
- 인증 성공 시 `authSucceeded`를 적용하고 active path로 등록한다.
- 인증 실패, reject, timeout 시 path를 failed/degraded로 표시한다.
- 실패한 candidate는 다음 선택에서 후순위가 된다.

### 기능 3. session cleanup과 stale/offline 정리

- peer offline/stale 시 authenticated session과 active path를 정리한다.
- 이미 authenticated인 peer에 중복 handshake를 시작하지 않는다.
- 종료된 앱이 계속 연결된 것처럼 남지 않도록 presence와 auth session을 동기화한다.

## 구현 체크리스트

- [x] `startHandshake` signature가 selected path를 받을 수 있게 바뀌었다.
- [x] 기존 호출자는 coordinator를 통해 selected path를 넘긴다.
- [x] `_HandshakeContext`에 path id, candidate id, local endpoint를 추가했다.
- [x] connect request 송신에 path context를 사용한다.
- [x] challenge 응답 송신에 path context를 사용한다.
- [x] token 송신에 path context를 사용한다.
- [x] accept/reject 송신에 path context를 사용한다.
- [x] 인증 성공 시 `PeerPathRegistry`에 active path를 기록한다.
- [x] 인증 실패 시 path failure reason을 기록한다.
- [x] timeout 시 candidate를 failed로 표시하고 다음 coordinator retry에서 다음 candidate가 선택된다.
- [x] stale/offline peer sync 시 active path와 session이 정리된다.

## 테스트

- [x] selected endpoint로 `CONNECT_REQUEST`가 전송되는 테스트를 작성했다.
- [x] challenge/token/accept/reject가 같은 path context를 유지하는 테스트를 작성했다.
- [x] 인증 성공 후 active path 상태가 `active`가 되는 테스트를 작성했다.
- [x] JWT reject 시 path가 failed가 되는 테스트를 작성했다.
- [x] handshake timeout 시 candidate가 failed가 되고 다음 candidate가 선택되는 테스트를 작성했다.
- [x] 모든 candidate 실패 시 peer session이 failed가 되는 테스트를 작성했다.
- [x] authenticated peer에 중복 handshake가 시작되지 않는 테스트를 작성했다.
- [x] stale/offline peer가 session과 active path에서 정리되는 테스트를 작성했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] peer auth/application/network 테스트가 통과한다.
- [x] 연결 완료를 `PeerAuthSession.authenticated`와 `PeerConnectionPath.active` 양쪽에서 확인할 수 있다.
- [x] 실패 원인이 auth reject, timeout, bind failure, peer offline으로 구분된다.
- [x] token/password/session key가 로그나 UI에 노출되지 않는다.

## 구현 결과

- `PeerConnectionPathStateMachine`은 별도 probe packet 없이 `discovered -> authenticating -> active` 전이를 허용한다.
- `PeerConnectionPath`는 `failureReasonCode`를 보관해 auth reject, timeout, bind failure 같은 실패 원인을 diagnostics에서 추적할 수 있다.
- `PeerPathRegistry`는 `applyEvent`, `markFailed`, revision mutation provider를 통해 path 상태 변경을 UI/diagnostics provider가 감지할 수 있게 한다.
- `PeerAuthController.startHandshake`는 selected path를 registry에 등록하고 즉시 `authStarted`를 적용한다.
- selected path로 시작한 handshake는 `CONNECT_REQUEST`, `AUTH_TOKEN`, `AUTH_ACCEPT`, `AUTH_REJECT`에서 같은 local endpoint context를 유지한다.
- 수신 측 `CONNECT_REQUEST`는 `ControlDatagram.localEndpoint`를 context에 보존해 challenge/reject/accept 응답에서 동일 local endpoint를 사용한다.
- 인증 성공은 `PeerAuthSession.authenticated`와 `PeerConnectionPath.active`를 함께 만든다.
- 인증 reject, timeout, control bind failure는 selected path를 `failed`로 바꾸고 실패 사유를 남긴다.
- timeout 또는 명시 retry 전에 실패한 candidate는 `RouteCandidateStatus.failed`로 전환되어 다음 선택에서 제외된다.
- stale/offline/incompatible peer 또는 peer 목록에서 사라진 peer는 auth session, handshake context, active path가 함께 정리된다.
- 이미 authenticated이거나 handshake가 진행 중인 peer에는 직접 `startHandshake`를 다시 호출해도 중복 session을 만들지 않는다.

## 실행 결과

- `flutter test test/domain/network/peer_connection_path_test.dart test/application/auth/peer_auth_controller_test.dart test/application/network/peer_connection_coordinator_test.dart test/application/network/network_diagnostics_provider_test.dart` 통과
- `flutter analyze` 통과
- `flutter test` 통과, 192개 테스트 통과
- 전체 테스트 중 Drift 다중 database 생성 경고가 출력되지만 실패는 아니다. 기존 테스트 구조에서 발생하는 경고로 확인했다.

## 완료 기준

- 자동 handshake는 selected path context를 잃지 않는다.
- 인증 성공 시 active path가 등록된다.
- 인증 실패 시 다음 후보 또는 최종 실패가 상태 머신 기준으로 설명된다.
- 종료된 peer가 연결 상태로 남지 않는다.