# Task 002 - Discovery 보안 경계와 discovery group tag 분리

## 목표

Discovery packet에서 인증에 재사용 가능한 password-derived 값을 제거하고, peer 검색 전용 group tag로 분리한다.

Discovery는 peer 검색과 presence만 담당해야 한다. 같은 ID/PW 사용자끼리만 발견되도록 필터링은 필요하지만, 그 식별자가 JWT signing key, challenge 검증, session key 생성에 재사용되면 안 된다.

## 연관 문서

- [plan.md - 4.3 Discovery 보안 경계](plan.md#43-discovery-보안-경계)
- [plan.md - 5.2 Discovery 보안 경계 정리](plan.md#52-discovery-보안-경계-정리)
- [AGENTS.md - Product-Specific Guardrails](../AGENTS.md#product-specific-guardrails)

## 선행 조건

- [task001.md](task001.md)의 `pairingProof` 감사가 완료되어 있어야 한다.
- 현재 `DiscoveryPacket`, `DiscoveryController`, `LocalInstanceRegistry`의 group 필터링 흐름을 확인해야 한다.
- 기존 packet decode 호환성을 유지해야 한다.

## 포함 기능

### 기능 1. discovery-only group tag 모델

- `pairingProof`의 의미를 인증 verifier에서 discovery-only tag로 분리한다.
- 새 필드명은 `discoveryGroupTag` 또는 동등한 이름을 사용한다.
- 기존 packet의 `pairingProof`는 migration 기간 동안 decode 가능하게 유지한다.
- tag 생성은 Control/Auth signing key derivation과 별도 함수로 분리한다.

### 기능 2. Discovery packet과 local registry migration

- `DiscoveryPacket` encode/decode에 새 group tag field를 추가한다.
- 기존 packet을 수신하면 legacy field를 fallback으로 읽되, 새 송신은 새 field를 우선한다.
- `LocalInstancePresence`에도 discovery group tag를 반영한다.
- 같은 장비 다중 인스턴스 local registry 필터링도 새 tag 기준으로 동작하게 한다.

### 기능 3. 로그와 이벤트 민감 정보 보호

- group tag 전체값을 Product/Debug 로그에 남기지 않는다.
- diagnostics에는 앞부분 preview 또는 hash preview만 표시한다.
- MessageBus event payload에 tag 전체값을 넣지 않는다.

## 구현 체크리스트

- [x] discovery-only group tag 생성 함수를 `application` 또는 `infrastructure/auth` 경계에 맞게 배치했다.
- [x] group tag 생성 함수가 JWT signing key derivation과 별도 코드 경로를 사용한다.
- [x] `DiscoveryPacket`에 새 group tag field를 추가했다.
- [x] `DiscoveryPacket.decode`가 legacy `pairingProof` packet을 읽을 수 있다.
- [x] 새 송신 packet은 새 group tag field를 사용한다.
- [x] `DiscoveryController._matchesCurrentPairingGroup`가 새 group tag를 기준으로 동작한다.
- [x] `LocalInstanceRegistry` 저장/조회가 새 group tag를 사용한다.
- [x] group tag 전체값이 `DiscoveryState`와 diagnostics에 저장되지 않도록 했다.
- [x] 기존 `pairingProof` 명칭은 deprecated 또는 내부 migration 용도로만 남겼다.

## 테스트

- [x] 새 Discovery packet encode/decode 테스트를 작성했다.
- [x] legacy `pairingProof` packet decode 호환 테스트를 작성했다.
- [x] group tag가 같으면 Discovery 후보로 들어오지만 인증 완료로 취급되지 않는 테스트를 작성했다.
- [x] group tag가 달라지면 peer가 무시되는 테스트를 작성했다.
- [x] JWT token validation이 discovery group tag를 사용하지 않는 테스트를 작성했다.
- [x] Local registry entry가 새 group tag 기준으로 필터링되는 테스트를 작성했다.
- [x] 로그/event snapshot에 raw password, JWT, token, verifier 전체값, group tag 전체값이 없는지 검증했다.

## 검증

- [x] `flutter analyze`가 통과한다.
- [x] `test/infrastructure/discovery/discovery_packet_test.dart`가 통과한다.
- [x] discovery controller 관련 테스트가 통과한다.
- [x] auth/JWT 관련 테스트가 통과한다.
- [x] Discovery, Control, Data 책임 분리 원칙과 충돌하지 않는다.

## 구현 결과

- `DiscoveryGroupTagService`를 추가해 Discovery 전용 group tag를 별도 HMAC context로 생성한다.
- `DiscoveryPacket` 송신 schema는 `discoveryGroupTag`를 사용하고, legacy `pairingProof` JSON은 decode fallback으로만 유지한다.
- `LocalInstancePresence` 저장 schema도 `discoveryGroupTag`를 사용하고, 기존 registry 파일의 `pairingProof`는 읽을 수 있게 유지한다.
- `DiscoveryController`는 `SharedVerifierService.deriveVerifierBase64`를 더 이상 Discovery 필터링에 사용하지 않는다.
- `DiscoveryState`와 diagnostics UI는 group tag 전체값이 아니라 preview만 보관/표시한다.
- JWT 생성/검증은 계속 `SharedVerifierService` 기반 signing key를 사용하며 discovery group tag로 검증되지 않는다.

## 실행 결과

- `flutter test test/infrastructure/discovery/discovery_packet_test.dart test/infrastructure/discovery/local_instance_registry_test.dart test/application/discovery/discovery_controller_test.dart test/application/discovery/peer_route_candidate_projection_test.dart test/infrastructure/auth/jwt_token_service_test.dart`
- `flutter analyze`
- `flutter test`

전체 테스트는 통과했다. `flutter test` 중 Drift multiple database debug warning이 출력되지만 테스트 실패는 아니며, task002 변경 범위의 실패는 없다.

## 완료 기준

- Discovery packet에는 인증에 재사용 가능한 verifier가 없다.
- 같은 ID/PW peer 필터링은 discovery-only group tag로 유지된다.
- 기존 packet decode 호환성이 깨지지 않는다.
- 인증 완료는 오직 Control/Auth challenge-response 이후에만 발생한다.