# Task 004 - password-derived JWT 상호 인증과 허용 사용자 정책

## 목표

디스커버리로 찾은 피어와 연결을 시작하고, password-derived JWT 기반으로 상호 인증 세션을 수립한다.

## 연관 문서

- [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)

## 선행 조건

- [task002.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task002.md)
- [task003.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task003.md)

## 포함 기능

### 기능 1. CONNECT/AUTH 핸드셰이크 패킷 구현

- `CONNECT_REQUEST`, `AUTH_CHALLENGE`, `AUTH_TOKEN`, `AUTH_TOKEN_ACK`, `AUTH_ACCEPT`, `AUTH_REJECT` 패킷 정의
- nonce, timestamp, protocol_version 포함
- 세션 ID 생성과 타임아웃 처리

### 기능 2. password-derived JWT 생성/검증

- 비밀번호 기반 파생키를 이용한 JWT 서명 생성
- claim 검증: `sub`, `device_id`, `peer_id`, `nonce`, `iat`, `exp`, `jti`
- `jti` replay cache 및 nonce 재사용 방지

### 기능 3. 허용 사용자 정책 및 인증 UI

- 허용 사용자 목록 관리
- 인증 성공/실패/거절 상태를 UI에 표시
- 미등록 피어에 대한 수동 승인 또는 차단 흐름 준비

## 구현 체크리스트

- [x] 인증 패킷 타입과 상태 머신이 정의되어 있다.
- [x] JWT 생성 시 password-derived signing key가 KDF를 통해 파생된다.
- [x] 토큰 만료 시간과 허용 clock skew 기준이 코드에 명시돼 있다.
- [x] 수신 측이 허용된 `user_id`와 verifier를 기준으로 JWT를 검증한다.
- [x] 인증 성공 시 세션 객체가 메모리에 생성된다.
- [x] 인증 실패 시 사용자 메시지와 내부 로그 코드가 분리되어 기록된다.

## 산출물

- 인증 프로토콜 구현
- JWT 서비스
- 허용 사용자 정책 저장/관리 UI
- 인증 상태 표시 컴포넌트

## 테스트

- [x] JWT 생성/검증 단위 테스트 작성
- [x] 만료 토큰, 잘못된 nonce, 잘못된 `jti`, 잘못된 verifier 테스트 작성
- [x] 인증 상태 머신 전이 테스트 작성
- [x] 두 노드 간 인증 성공/실패 통합 테스트 작성

## 검증

- [x] 허용된 사용자끼리만 인증 성공하는지 확인한다.
- [x] verifier가 없는 피어는 인증 거절되는지 확인한다.
- [x] 만료된 토큰 재사용 시 인증이 거절되는지 확인한다.
- [ ] 로그에 원문 비밀번호나 원문 JWT가 남지 않는지 확인한다.

## 완료 기준

- 파일 전송 시작 전에 세션 수립과 상호 인증이 재현 가능하게 동작한다.
- 인증 실패 원인을 UI와 로그에서 구분해 확인할 수 있다.

## 메모

- 중앙 서버가 없으므로 이 모델은 사전 등록형 허용 사용자 기반 인증이다.
- 세션 수립 이후 실제 데이터 암호화 키 교환은 다음 전송 태스크와 함께 연결된다.