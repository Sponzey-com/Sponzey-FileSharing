# Task 007 - Control Port 기반 Peer 연동, 인증, secure session

## 목표

Discovery로 찾은 peer와 Control Port를 통해 link request, challenge/response, JWT 검증, session 생성, session key lifecycle을 처리한다.

인증 성공 전에는 파일 전송 세션을 절대 시작할 수 없어야 한다.

## 연관 문서

- [phase002 plan.md - UDP Peer 연동과 인증 계획](plan.md#9-udp-peer-연동과-인증-계획)
- [phase002 plan.md - 세션 키와 데이터 암호화](plan.md#95-세션-키와-데이터-암호화)
- [task003.md](task003.md)
- [task006.md](task006.md)

## 선행 조건

- [task003.md](task003.md)의 PeerLink/SecureSession 상태 모델이 있어야 한다.
- [task004.md](task004.md)의 MessageBus가 있어야 한다.
- [task006.md](task006.md)에서 peer discovery와 endpoint projection이 동작해야 한다.

## 포함 기능

### 기능 1. Control packet schema와 codec

- LinkRequest, LinkChallenge, LinkResponse, LinkAccepted, LinkRejected, SessionRefresh packet을 정의한다.
- TransferOffer 이전의 link/auth packet은 Control Port만 사용한다.
- malformed packet과 correlation mismatch를 안전하게 처리한다.

### 기능 2. Password-derived JWT 인증 흐름

- nonce, jti, iat, exp, protocolVersion을 포함한 짧은 수명의 token을 사용한다.
- 수신자는 nonce reuse와 jti replay를 감지한다.
- 허용 peer 정책과 credential verifier를 확인한다.

### 기능 3. Secure session lifecycle

- 인증 성공 후 ephemeral session key negotiation 인터페이스를 둔다.
- established 전에는 Data Port encrypted data 전송을 금지한다.
- session ttl 만료, refresh, revoke, destroy 흐름을 상태 머신에 연결한다.

## 구현 체크리스트

- [x] Control packet 타입과 codec을 구현했다.
- [x] LinkRequest/Challenge/Response/Accepted/Rejected 흐름을 구현했다.
- [x] PeerLinkStateMachine을 application controller와 연결했다.
- [x] password-derived JWT 생성/검증 흐름을 연결했다.
- [x] nonce cache와 jti replay cache 정책을 구현했다.
- [x] allowed peer 정책을 인증 흐름에 반영했다.
- [x] mutual auth required 정책이 있다면 흐름에 반영했다.
- [x] session key negotiation interface를 추가했다.
- [x] session key lifecycle 상태를 반영했다.
- [x] 인증 성공/실패/만료/거절 event를 MessageBus로 publish한다.
- [x] raw token, password, session key가 로그에 남지 않도록 했다.

## 테스트

- [x] 정상 challenge/response 인증 테스트를 작성했다.
- [x] 잘못된 password-derived signature 거부 테스트를 작성했다.
- [x] expired token 거부 테스트를 작성했다.
- [x] nonce reuse 거부 테스트를 작성했다.
- [x] jti replay 거부 테스트를 작성했다.
- [x] incompatible protocol 거부 테스트를 작성했다.
- [x] link timeout 처리 테스트를 작성했다.
- [x] rejected peer가 transfer offer를 보낼 수 없는 테스트를 작성했다.
- [x] mutual auth required인데 상대 인증 누락 시 실패 테스트를 작성했다.
- [x] session key negotiation failure 테스트를 작성했다.
- [x] session ttl 만료 후 transfer command 거부 테스트를 작성했다.
- [x] session destroy 후 key material 접근 금지 테스트를 작성했다.

## 검증

- [x] 인증 성공 전 TransferOffer가 거부된다.
- [x] 인증 실패 원인이 Product 또는 Debug 목적에 맞게 기록된다.
- [x] Control Port에는 대량 파일 chunk가 흐르지 않는다.
- [x] 인증 성공 후 Data 전송에 필요한 session context가 명확히 생성된다.

## 진행 결과

- `lib/infrastructure/control/control_packet.dart`
- `lib/application/auth/peer_auth_controller.dart`
- `lib/infrastructure/auth/jwt_token_service.dart`
- `lib/infrastructure/auth/shared_verifier_service.dart`
- `test/infrastructure/control/control_packet_test.dart`
- `test/infrastructure/auth/jwt_token_service_test.dart`
- `test/application/auth/peer_auth_controller_test.dart`

## 완료 기준

- Discovery로 발견한 peer와 Control Port 기반 인증 세션을 만들 수 있다.
- 인증되지 않은 peer는 어떤 파일 전송 절차에도 진입할 수 없다.
- Secure session lifecycle이 상태 머신과 테스트로 관리된다.
