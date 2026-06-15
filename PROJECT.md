# Sponzey FileSharing 개발 계획 및 아키텍처

## 1. 문서 목적

이 문서는 [README.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey Family/Sponzey FileSharing/README.md)의 제품 방향을 실제 개발 가능한 수준으로 구체화한 설계 문서다.

핵심 전제는 다음과 같다.

- 클라이언트 기술: Flutter
- 네트워크 전송 기반: UDP
- 인증 방식: ID/PW 기반, password-derived JWT 토큰 상호 인증
- 지원 플랫폼: macOS, Windows, Linux
- 제공 형태: 웹 없이 데스크톱 앱으로만 지원
- 사용 환경: 동일 로컬 네트워크 중심의 파일 공유

현재 제품 기준의 인증과 설정 전제는 다음과 같다.

- 가입 절차는 없다. 사용자는 실행 중인 앱 세션에서 ID/PW를 입력해 현재 세션을 시작한다.
- 비밀번호, password-derived JWT, 세션 키는 메모리에서만 유지하며 Keychain, Credential Manager, Secret Service, 임의 설정 파일에 저장하지 않는다.
- 같은 ID/PW 조합을 입력한 앱 인스턴스끼리 자동 인증, 자동 연결, 자동 수신을 수행한다.
- 허용 사용자 목록, 수신 전 승인, 계정 등록형 credential verifier 저장은 현재 제품 기본 경로가 아니라 향후 확장 후보로 둔다.

이 문서는 특히 다음 네 가지를 명확히 한다.

- 무엇을 1차 버전에서 만들 것인지
- 어떤 구조로 앱을 분리해서 구현할 것인지
- UDP 위에서 파일 전송 신뢰성을 어떻게 확보할 것인지
- 향후 확장 가능한 형태로 초기 설계를 어떻게 잡을 것인지

---

## 2. 제품 목표

Sponzey FileSharing의 목표는 같은 네트워크에 있는 장치들이 별도 웹 서비스 없이 서로를 발견하고, 인증된 상대에게 빠르게 파일을 전송할 수 있는 데스크톱 앱을 제공하는 것이다.

핵심 목표는 다음과 같다.

- 로컬 네트워크에서 빠른 파일 전송
- 사용 가능한 수준의 인증 체계 제공
- 1:1 전송과 1:N 전송 지원
- 여러 전송 세션을 동시에 처리
- macOS, Windows, Linux에서 동일한 사용자 경험 제공

### 2.1 제품이 해결하려는 문제

- 같은 사무실이나 연구실 네트워크에서 파일을 빠르게 주고받고 싶다.
- 외부 클라우드나 웹 서버를 두지 않고 내부망만으로 운영하고 싶다.
- 특정 사용자만 파일을 받을 수 있게 인증이 필요하다.
- 하나의 파일을 여러 장치에 배포해야 한다.

### 2.2 1차 버전 성공 기준

- 동일 네트워크에서 앱 실행 시 다른 노드를 자동 탐색할 수 있다.
- 가입 없이 ID/PW를 입력한 뒤 인증된 런타임 세션을 열 수 있다.
- 개별 파일 또는 여러 파일을 선택해 특정 노드에 전송할 수 있다.
- 하나의 파일을 여러 노드에 동시에 전송할 수 있다.
- 전송 실패, 재시도, 취소, 완료 이력이 UI에 표시된다.
- macOS, Windows, Linux에서 동일 프로토콜로 상호 운용된다.

---

## 3. 범위 정의

## 3.1 포함 범위

- Flutter 데스크톱 앱
- 로컬 네트워크 노드 탐색
- UDP 기반 제어/데이터 전송
- ID/PW 기반 로그인 및 password-derived JWT 세션 인증
- 같은 ID/PW 그룹 기반 자동 인증과 자동 연결
- 파일/폴더 선택 및 전송
- 다중 전송 큐
- 전송 이력 및 로그 조회
- 플랫폼별 파일 저장 경로 설정

## 3.2 제외 범위

- 웹 애플리케이션
- 외부 클라우드 저장소 연동
- 인터넷을 통한 원격 전송
- 중앙 웹 백엔드
- 브라우저 기반 수신/다운로드
- 모바일 앱

## 3.3 1차 버전에서 의도적으로 단순화할 부분

- 인터넷 NAT traversal 미지원
- 외부 계정 시스템 미도입
- 조직 단위 관리자 콘솔 미도입
- 그룹/조직 동기화 서버 미도입
- 실시간 공동 편집 기능 미지원
- 파일 버전 관리 미지원

---

## 4. 제품 요구사항

## 4.1 기능 요구사항

### FR-1. 런타임 사용자 세션

- 사용자는 가입 없이 앱 실행 중 ID와 비밀번호를 입력해 현재 실행 세션을 시작할 수 있어야 한다.
- 세션 정보는 `ID`, `비밀번호`, `장치 이름`, 내부 `instance_id`를 가진다.
- 비밀번호는 평문 저장 금지이며, 현재 제품에서는 해시 형태로도 영속 저장하지 않는다.
- password-derived JWT와 세션 키도 메모리에서만 유지해야 한다.
- 사용자는 앱 실행 후 로그인해야 주요 기능을 사용할 수 있다.

### FR-2. 노드 탐색

- 같은 서브넷 내 실행 중인 노드를 자동 탐색해야 한다.
- 사용자는 현재 온라인 노드 목록을 볼 수 있어야 한다.
- 노드 목록에는 상태, 사용자 ID, 장치 이름, 마지막 응답 시간, 지원 버전이 표시되어야 한다.

### FR-3. 연결 및 인증

- 앱은 발견한 상대 노드에 자동 연결 요청을 보낼 수 있어야 한다.
- 상대 노드는 같은 ID/PW 그룹임을 확인하면 별도 승인 없이 자동 인증해야 한다.
- 인증 과정은 password를 기반으로 서명한 짧은 수명의 JWT 토큰을 교환하는 형태여야 한다.
- 인증 후에만 파일 전송 세션을 시작할 수 있어야 한다.

### FR-4. 파일 전송

- 사용자는 파일 선택 후 단일 대상에게 전송할 수 있어야 한다.
- 여러 파일을 한 세션으로 묶어 전송할 수 있어야 한다.
- 여러 대상에게 동일 파일을 동시에 전송할 수 있어야 한다.
- 수신자는 인증된 peer의 파일을 기본 저장 경로에 자동 저장할 수 있어야 한다.

### FR-5. 전송 상태 관리

- 각 전송은 `대기`, `인증 중`, `전송 중`, `재시도 중`, `완료`, `실패`, `취소` 상태를 가져야 한다.
- 전송 속도, 진행률, 남은 시간 추정, 재전송 횟수를 표시해야 한다.

### FR-6. 수신 정책

- 인증된 peer의 파일 자동 수신
- 저장 폴더 사용자 지정
- 기본 저장 경로 준비 실패 시 명확한 오류 표시
- 수신 전 승인과 허용 사용자 목록은 향후 확장 기능으로 분리

### FR-7. 이력 및 로그

- 최근 전송 이력을 조회할 수 있어야 한다.
- 실패 원인과 시간, 상대 노드, 파일명, 크기를 볼 수 있어야 한다.

## 4.2 비기능 요구사항

### NFR-1. 성능

- 동일 LAN 환경에서 안정적인 고속 전송을 목표로 한다.
- UI 스레드는 대용량 파일 전송 중에도 반응성을 유지해야 한다.

### NFR-2. 안정성

- UDP 기반이더라도 누락 패킷 복구를 지원해야 한다.
- 앱 재실행 후 완료/실패 이력은 유지되어야 한다.
- 부분 전송 상태를 기반으로 재시도 가능한 구조를 목표로 한다.

### NFR-3. 보안

- 비밀번호 평문 저장 금지
- 인증 전 민감 데이터 전송 금지
- 인증 토큰은 password-derived signing key 기반 JWT 형식으로 생성되어야 한다.
- 인증 토큰은 짧은 만료 시간, nonce, `jti`를 포함해 재사용 공격을 줄여야 한다.
- 세션 키 기반으로 파일 데이터 암호화 지원

### NFR-4. 확장성

- 전송 프로토콜은 버전 필드를 가져야 한다.
- UI, 도메인, 네트워크 계층은 느슨하게 결합되어야 한다.

### NFR-5. 운영성

- 릴리스 빌드에 로그 레벨 정책이 있어야 한다.
- 장애 분석을 위한 로컬 로그 저장 기능이 필요하다.

---

## 5. 상위 아키텍처

Sponzey FileSharing은 "각 앱 인스턴스가 송신자이자 수신자이며 동시에 로컬 서버 역할도 수행하는 분산형 데스크톱 앱" 구조를 기본으로 한다.

즉, 별도 웹 서비스 없이 각 데스크톱 앱이 다음 역할을 모두 가진다.

- UI 클라이언트
- 사용자 인증 주체
- 로컬 파일 접근 주체
- UDP 통신 엔드포인트
- 파일 수신 서버
- 세션/전송 상태 관리자

### 5.1 상위 컴포넌트

1. Flutter Desktop UI
2. Application Layer
3. Domain Layer
4. Infrastructure Layer
5. Local Persistence
6. UDP Networking Engine

### 5.2 계층별 책임

#### 1) Presentation Layer

- 로그인 화면
- 노드 탐색 화면
- 전송 큐 화면
- 수신함/이력 화면
- 설정 화면
- 알림/다이얼로그

#### 2) Application Layer

- 로그인/로그아웃 흐름 제어
- 노드 탐색 시작/중지
- 연결 요청 생성
- 파일 전송 작업 생성
- 다중 대상 전송 오케스트레이션
- 재시도 및 실패 복구 정책 실행

#### 3) Domain Layer

- UserAccount
- PeerNode
- TransferSession
- TransferTask
- TransferChunk
- AuthChallenge
- ReceivePolicy
- SessionKey

#### 4) Infrastructure Layer

- UDP 소켓 관리
- 브로드캐스트/유니캐스트 송수신
- 파일 읽기/쓰기
- SQLite 저장소
- 플랫폼 저장 경로와 권한 처리
- 로그 저장

---

## 6. Flutter 애플리케이션 구조

Flutter는 UI 기술이지만, 이 프로젝트에서는 데스크톱 앱이므로 네트워크 처리, 파일 IO, 암호화, 동시성 제어를 포함한 앱 구조 설계가 중요하다.

권장 구조는 다음과 같다.

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    errors/
    logger/
    utils/
  domain/
    entities/
    value_objects/
    repositories/
    services/
  application/
    auth/
    discovery/
    transfer/
    settings/
    history/
  infrastructure/
    crypto/
    database/
    file_system/
    network/
    platform/
    repositories/
  presentation/
    auth/
    dashboard/
    peers/
    transfers/
    history/
    settings/
```

### 6.1 상태 관리

권장 선택은 `Riverpod` 또는 `Bloc`다. 이 문서에서는 구조적 테스트와 비동기 흐름 가독성을 고려해 `Riverpod`를 기본 권장안으로 둔다.

이유는 다음과 같다.

- 데스크톱 앱에서 상태가 많다.
- 네트워크 이벤트와 UI 이벤트를 명확히 분리할 수 있다.
- Provider 단위 테스트가 쉽다.
- 의존성 주입과 상태 수명주기 관리가 편하다.

### 6.2 동시성 전략

Flutter 메인 isolate에 모든 네트워크/파일 작업을 몰아두면 UI 끊김 위험이 크다. 따라서 다음 전략을 사용한다.

- 메인 isolate: UI, 화면 상태, 사용자 입력 처리
- 네트워크 isolate: UDP 송수신, 패킷 파싱, ACK/NACK 처리
- 파일 처리 isolate: 대용량 파일 chunk 읽기/해시 계산
- 암호화 isolate: 세션 암호화/복호화, 체크섬 계산

초기 구현에서는 네트워크 isolate와 파일 처리 isolate를 우선 분리하고, CPU 부하가 커질 때 암호화 isolate를 추가한다.

---

## 7. 네트워크 아키텍처

## 7.1 기본 방향

UDP를 전송 기반으로 사용하되, TCP가 제공하던 일부 신뢰성 기능을 애플리케이션 레벨에서 재구성한다.

핵심 설계 원칙은 다음과 같다.

- 탐색은 UDP 브로드캐스트 또는 멀티캐스트
- 인증 및 제어 메시지는 UDP 유니캐스트
- 파일 데이터도 UDP 기반으로 전송
- 패킷 손실, 순서 뒤바뀜, 중복 수신을 고려한 자체 제어 프로토콜 구현

## 7.2 포트 분리 전략

권장 포트 예시는 다음과 같다.

- `38400/udp`: 노드 탐색 브로드캐스트
- `38401/udp`: 인증 및 제어 채널
- `38410~38430/udp`: 파일 전송 데이터 채널 동적 할당

이렇게 분리하면 탐색과 실제 파일 전송이 서로 영향을 덜 주고, 디버깅도 쉬워진다.

## 7.3 노드 탐색 방식

### Discovery Broadcast

앱은 주기적으로 브로드캐스트 패킷을 송신한다.

포함 정보:

- 프로토콜 버전
- 앱 버전
- 사용자 ID
- 표시 이름
- 장치 ID
- 장치 이름
- OS 타입
- 현재 상태
- 인증 가능 여부
- 지원 기능 목록
- 응답 포트

다른 노드는 이를 수신해 피어 목록에 반영한다.

### Discovery Response

브로드캐스트 수신 노드는 응답 패킷을 유니캐스트로 회신한다.

응답 정보:

- 자기 장치 정보
- 현재 수신 가능 여부
- 최대 동시 세션 수
- 호환 프로토콜 버전

### 오프라인 판정

- 마지막 응답 시간이 일정 시간 초과 시 오프라인 처리
- 예: 10초 동안 heartbeat 없음 -> 일시 오프라인
- 예: 30초 동안 없음 -> 목록에서 비활성 표시

## 7.4 연결 및 인증 흐름

권장 흐름은 다음과 같다.

1. 송신자가 피어를 선택한다.
2. 송신자가 `CONNECT_REQUEST`를 보낸다.
3. 수신자가 `AUTH_CHALLENGE`를 회신한다.
4. 송신자가 비밀번호 기반 파생키로 서명한 `AUTH_TOKEN` JWT를 생성해 전송한다.
5. 수신자가 현재 런타임 세션의 password-derived key material로 JWT를 검증한다.
6. 필요 시 수신자도 자기 비밀번호 기반 `AUTH_TOKEN_ACK` JWT를 회신해 상호 인증을 완료한다.
7. 인증 성공 시 `AUTH_ACCEPT`와 세션 정보를 보낸다.
8. 양측은 세션 키를 확정하고 파일 전송을 시작한다.

### 인증 모델 권장안

완전한 중앙 인증 서버 없이 동작해야 하므로, 현재 제품은 로컬 계정 저장소가 아니라 실행 중 입력된 ID/PW를 기준으로 같은 그룹의 노드를 자동 인증한다.

즉:

- 각 앱은 가입 없이 ID/PW를 입력해 현재 런타임 세션을 시작한다.
- Discovery에는 인증 재료를 싣지 않고, 인증 재료와 분리된 discovery-only group tag만 사용한다.
- Control 채널에서 challenge, nonce, 짧은 수명 JWT를 교환해 같은 ID/PW 그룹인지 확인한다.
- 별도 허용 목록이나 수신 전 승인 없이 인증 성공 peer는 자동 연결, 자동 수신 대상이 된다.
- password, password-derived JWT, session key는 프로세스 메모리에서만 유지하며 영속 저장하지 않는다.

이 구조는 외부 서버 없이도 동작하고, 내부망 도구라는 제품 방향과 맞다.

## 7.5 비밀번호 저장 및 검증

비밀번호 관련 저장 정책:

- 비밀번호 평문 저장 금지
- 현재 제품에서는 비밀번호 해시, 솔트, verifier를 영속 저장하지 않는다.
- 부트스트랩 이후 인증에 필요한 값은 전역 환경이나 외부 설정 파일에서 다시 읽지 않고, 로그인 세션과 유스케이스 인자로 명시적으로 전달한다.
- 향후 계정 등록형 정책을 도입할 경우에만 `Argon2id` 해시 저장, 사용자별 랜덤 솔트, 해시 파라미터 metadata 저장을 별도 phase로 검토한다.
- JWT 서명키는 비밀번호 원문이 아니라 `password-derived key material`에서 파생해야 한다.

JWT 인증 구현 원칙:

- JWT는 웹 로그인용 bearer token이 아니라 P2P 인증용 서명 포맷으로 사용한다.
- 알고리즘은 대칭 서명(`HS256` 또는 동급)을 사용하되, 검증된 라이브러리로만 처리한다.
- 서명키는 `password + salt + challenge nonce`에서 직접 쓰지 말고 KDF를 거쳐 파생한다.
- 토큰 만료 시간은 매우 짧게 둔다. 예: 15초 ~ 60초
- 필수 claim: `sub`, `device_id`, `peer_id`, `nonce`, `iat`, `exp`, `jti`, `protocol_version`
- 수신자는 `nonce`와 `jti`를 캐시해 재전송 공격을 감지한다.

현재 영속 저장하지 않는 항목:

- user_id
- password_hash
- password_salt
- hash_algorithm
- hash_params
- allowed_peers
- peer_credential_verifiers

저장 가능한 항목은 네트워크 진단과 UX에 필요한 비민감 metadata로 제한한다.

- peer cache
- 최근 경로 상태
- 사용자 설정 저장 경로
- 로그 레벨
- 향후 전송 이력 metadata

## 7.6 전송 세션 키

JWT 기반 인증만으로 끝내지 않고, 인증 성공 후 세션 단위 키를 생성한다.

권장 순서:

1. `AUTH_CHALLENGE`에서 nonce 교환
2. 송신자가 password-derived JWT 생성 및 전송
3. 수신자가 JWT 검증
4. 필요 시 수신자가 응답 JWT 전송
5. 상호 인증 완료 후 X25519 기반 일회성 키 교환
6. HKDF로 세션 키 파생
7. 이후 파일 chunk는 AES-GCM 또는 ChaCha20-Poly1305로 암호화

이렇게 하면 로컬 네트워크라도 데이터 평문 노출 위험을 줄일 수 있다.

### 현실적 구현 메모

Flutter/Dart에서 암호화 라이브러리 성숙도와 플랫폼 차이를 고려해 초기 버전은 다음 우선순위를 둔다.

- 1차: 인증 챌린지 + password-derived JWT + 세션 키 기반 대칭 암호화
- 2차: 더 강한 PAKE 계열 인증(SRP/SPAKE2) 검토 또는 JWT 서명키 파생 구조 강화

---

## 8. UDP 위 파일 전송 프로토콜 설계

UDP는 빠르지만 신뢰성이 없다. 따라서 파일 전송을 위해서는 자체 프로토콜이 필요하다.

## 8.1 패킷 종류

패킷 타입 예시:

- `DISCOVER`
- `DISCOVER_ACK`
- `CONNECT_REQUEST`
- `AUTH_CHALLENGE`
- `AUTH_TOKEN`
- `AUTH_TOKEN_ACK`
- `AUTH_ACCEPT`
- `AUTH_REJECT`
- `TRANSFER_INIT`
- `TRANSFER_INIT_ACK`
- `CHUNK`
- `CHUNK_ACK`
- `CHUNK_NACK`
- `WINDOW_UPDATE`
- `TRANSFER_COMPLETE`
- `TRANSFER_COMPLETE_ACK`
- `TRANSFER_CANCEL`
- `HEARTBEAT`
- `ERROR`

## 8.2 공통 헤더

모든 패킷은 공통 헤더를 가진다.

```text
version
packet_type
session_id
transfer_id
sequence_no
ack_no
timestamp
sender_device_id
receiver_device_id
payload_length
header_checksum
payload_checksum
flags
```

## 8.3 전송 단위

파일 -> 세션 -> 파일 메타데이터 -> chunk 스트림 구조로 나눈다.

- 세션: 사용자 간 인증 이후 유지되는 통신 단위
- 전송: 개별 파일 또는 파일 묶음 작업
- chunk: 실제 UDP 데이터 조각

## 8.4 chunk 크기 전략

IP fragmentation을 줄이기 위해 1차 버전 chunk payload는 보수적으로 잡는다.

권장값:

- 기본 payload: `1024B ~ 1200B`
- 헤더/암호화 태그 포함 시 MTU 1500 이내 유지

추후 최적화:

- 로컬 네트워크 환경 측정 후 적응형 payload 크기 조정
- MTU 추정 기반 튜닝

## 8.5 신뢰성 확보 방식

권장 방식은 `Selective Repeat ARQ + Sliding Window`다.

핵심 동작:

- 송신자는 window 크기만큼 chunk를 연속 전송
- 수신자는 받은 chunk를 bitmap 또는 set으로 기록
- 누락된 chunk만 `NACK` 또는 window ack 결과로 요청
- 송신자는 timeout 또는 NACK 수신 시 재전송

이 방식을 택하는 이유:

- 단순 stop-and-wait보다 훨씬 빠르다.
- TCP 전체를 재구현하지 않으면서도 LAN에서 충분한 성능을 낼 수 있다.
- 특정 패킷만 재전송하면 되므로 대용량 파일에 유리하다.

## 8.6 재전송 정책

- 초기 timeout: 예: 300ms
- RTT 측정 후 동적 timeout 조정
- 최대 재전송 횟수 초과 시 세션 실패 처리
- 일정 횟수 이상 실패 시 window 크기 축소

## 8.7 흐름 제어

수신자의 디스크 쓰기 속도나 CPU 상태가 느리면 송신 속도를 조절해야 한다.

필드 예시:

- receiver_window_size
- receiver_buffer_usage
- disk_write_backlog

수신자가 `WINDOW_UPDATE`로 현재 허용 가능한 inflight chunk 수를 알려준다.

## 8.8 무결성 검증

무결성 검증은 두 단계로 나눈다.

### 패킷 단위

- 각 chunk별 checksum 또는 AEAD 인증 태그 검증

### 파일 단위

- 전체 파일 SHA-256 검증
- 최종 `TRANSFER_COMPLETE` 전에 수신자가 해시 일치 여부 확인

## 8.9 이어받기 지원

1차 버전 필수는 아니지만 구조는 미리 반영한다.

필요 개념:

- transfer_id 고정
- 수신 측 보유 chunk map 저장
- 재연결 후 missing chunk 목록 재요청

이 설계를 초기에 포함하면 이후 재개 기능 추가가 훨씬 쉬워진다.

---

## 9. 인증 및 권한 모델

## 9.1 인증 주체

각 데스크톱 앱은 자기 로컬 계정을 저장하지 않고, 실행 중 입력된 ID/PW로 현재 런타임 인증 주체를 가진다.

예시:

- 사용자 A가 자신의 PC에서 ID/PW 입력
- 사용자 B의 PC를 탐색
- A와 B가 같은 ID/PW 그룹이면 Control handshake가 자동으로 성공
- 인증된 뒤에는 별도 승인 없이 파일 자동 수신

추가 전제:

- A가 B에게 인증받으려면 B가 같은 password-derived key material을 현재 메모리 세션에서 재현할 수 있어야 한다.
- Discovery 단계에서는 비밀번호, JWT, verifier, session key를 보내지 않는다.
- 같은 ID/PW가 아닌 노드는 peer 목록에는 보일 수 있어도 인증 세션과 파일 전송 흐름에는 진입하지 못해야 한다.
- 즉, 현재 구조는 "사전 등록형 계정 인증"이 아니라 "동일 런타임 credential 그룹 기반 P2P 인증"이다.

## 9.2 권한 정책

현재 수신 노드는 최소 다음 정책을 가진다.

- 같은 ID/PW 그룹으로 인증된 peer는 자동 수신
- 인증되지 않은 peer는 전송 흐름 진입 차단
- 기본 저장 경로가 준비되지 않으면 수신 거절과 명확한 오류 표시

향후 확장 후보:

- 특정 사용자 ID만 허용
- 수신 요청마다 수동 승인
- 특정 파일 크기 이상은 수동 승인
- 허용/차단 목록 관리

## 9.3 권장 인증 흐름 세부안

### 옵션 A. 현실적 MVP

- 수신자가 nonce 발급
- 송신자가 `password-derived signing key`로 짧은 수명의 JWT 생성
- JWT에 `sub`, `device_id`, `nonce`, `iat`, `exp`, `jti` 포함
- 수신자가 현재 메모리 세션의 password-derived key material로 JWT 서명과 claim 검증
- 필요 시 수신자도 자기 JWT를 반환해 상호 인증
- 성공 시 세션 키 교환

장점:

- 구현 난이도가 비교적 낮다.
- 토큰 구조가 명확해 디버깅과 프로토콜 버전 관리가 쉽다.
- 초기 제품 출시 속도가 빠르다.

주의점:

- 프로토콜 설계를 잘못하면 오프라인 사전 대입 공격면이 생길 수 있다.
- JWT 자체가 보안을 보장하지 않으므로 서명키 파생, 짧은 만료 시간, nonce 재사용 방지가 필수다.

### 옵션 B. 강화 버전

- SRP 또는 SPAKE2 같은 PAKE 기반 인증

장점:

- 비밀번호 기반 인증에서 보안성이 더 높다.

단점:

- 라이브러리 선정과 검증 비용이 크다.

### 권장 결정

로드맵은 다음처럼 잡는다.

- MVP: 옵션 A
- 보안 강화 릴리스: 옵션 B 검토 및 전환

---

## 10. 다중 접속 및 1:N 전송 구조

README에서 강조한 다중 접속과 일괄 전송은 초기 아키텍처에서 반드시 분리 설계해야 한다.

## 10.1 핵심 원칙

- 하나의 UI 작업이 여러 실제 전송 세션으로 분해될 수 있어야 한다.
- 각 수신자는 독립된 전송 상태를 가져야 한다.
- 한 대상 실패가 다른 대상 전송을 중단시키면 안 된다.

## 10.2 전송 모델

예를 들어 사용자가 1개 파일을 5명에게 보낼 경우:

- UI에서는 하나의 "일괄 전송 작업"으로 보인다.
- 내부적으로는 대상별 `TransferSession` 5개가 생성된다.
- 파일 해시는 1회 계산하고 재사용한다.
- chunk 버퍼도 가능하면 공유 캐시를 사용한다.

## 10.3 병렬 처리 제어

권장 정책:

- 동시 세션 수 제한 예: 기본 3~5
- 나머지는 대기열로 이동
- CPU/디스크/네트워크 상태를 보고 제한값 조정 가능

---

## 11. 데이터 저장소 설계

## 11.1 로컬 DB 선택

권장:

- `SQLite` + `drift`

이유:

- Flutter 데스크톱과 궁합이 좋다.
- 이력, 설정, 전송 상태 저장에 적합하다.
- 마이그레이션 관리가 편하다.

## 11.2 주요 테이블

현재 제품은 사용자 credential을 DB에 저장하지 않는다. 따라서 `users` 테이블은 현재 기본 스키마가 아니다.

현재 기본 저장 대상:

### settings

- id
- device_name
- default_save_path
- receive_policy
- log_level
- created_at
- updated_at

### peers

- id
- peer_user_id
- peer_device_id
- peer_display_name
- peer_device_name
- os_type
- last_seen_at
- last_ip
- last_port
- protocol_version
- trust_status

향후 전송 이력 영속화 대상:

### transfer_jobs

- id
- batch_id
- sender_user_id
- receiver_user_id
- receiver_device_id
- direction
- status
- total_bytes
- transferred_bytes
- retry_count
- created_at
- updated_at
- completed_at

### transfer_files

- id
- transfer_job_id
- original_name
- relative_path
- file_size
- sha256
- chunk_count
- save_path

### transfer_chunks

- id
- transfer_job_id
- file_id
- sequence_no
- status
- last_sent_at
- acked_at
- retry_count

### settings

- id
- auto_receive_enabled
- receive_policy
- default_save_path
- max_parallel_transfers
- discovery_interval_ms
- log_level

### logs

- id
- category
- level
- message
- metadata_json
- created_at

## 11.3 보안 정보 저장

현재 제품에서는 사용자 비밀번호, password-derived JWT, 세션 키를 영속 저장하지 않는다. 민감 정보는 프로세스 메모리에만 유지하고 세션 종료 시 폐기한다.

영속 저장 가능한 항목:

- DB: 일반 메타데이터, peer cache, 설정, 향후 전송 이력 metadata
- 파일 시스템: 사용자가 지정한 수신 파일과 로그 파일
- 메모리: 비밀번호, password-derived key material, JWT, session key

향후 계정 등록, 장기 장치 키, 암호화용 로컬 마스터 키처럼 영속 비밀이 필요해질 때만 OS 보안 저장소를 별도 phase로 도입한다. Linux에서는 Secret Service 의존성이 있을 수 있으므로 해당 phase의 배포 문서에 명시해야 한다.

---

## 12. UI/UX 구조

웹이 아니라 데스크톱 앱이므로 마우스 중심 생산성 UX가 중요하다.

## 12.1 주요 화면

### 1) 초기 설정 / 로그인 화면

- 가입 없는 ID/PW 세션 시작
- 장치 이름 설정
- 기본 저장 경로 선택

### 2) 대시보드

- 온라인 피어 수
- 진행 중 전송
- 최근 수신 파일
- 오류/경고 요약

### 3) 피어 목록 화면

- 자동 탐색된 노드 목록
- 검색/정렬
- 상태 표시
- 인증 상태와 활성 네트워크 경로 표시
- 허용/차단/즐겨찾기는 향후 확장 기능

### 4) 전송 화면

- 드래그 앤 드롭
- 파일 선택
- 대상 선택
- 개별 전송 / 일괄 전송
- 진행률 바
- 속도/재시도 표시

### 5) 수신함 / 이력 화면

- 수신 완료 파일 목록
- 발신/수신 이력
- 실패 사유
- 저장 경로 바로가기

### 6) 설정 화면

- 보안 정책
- 자동 수신 정책
- 저장 위치
- 포트 설정
- 로그 레벨

## 12.2 데스크톱 특화 UX

- 파일 드래그 앤 드롭 지원
- 우클릭 컨텍스트 메뉴
- 전송 완료 토스트 알림
- 수신 요청 팝업
- 최소화 시 트레이 동작은 2차 버전 검토

---

## 13. 플랫폼별 고려사항

## 13.1 macOS

- 앱 서명/배포 시 네트워크 접근 관련 설정 확인
- 사용자 선택 디렉터리 접근 권한 흐름 검토
- 방화벽 승인 안내 필요
- notarization 배포를 고려하면 릴리스 파이프라인을 조기에 준비하는 것이 좋다

## 13.2 Windows

- Windows Defender Firewall 예외 또는 허용 안내 필요
- 긴 경로, 한글 경로, 권한 문제 테스트 필요
- 설치 프로그램에 런타임 의존성 포함 검토

## 13.3 Linux

- 최소 지원 기준은 Ubuntu 22.04 LTS로 고정한다.
- Linux 릴리스 산출물은 Ubuntu 22.04에서 빌드해 더 최신 glibc/GTK/libsecret 런타임에 의존하지 않도록 한다.
- 다른 배포판은 GTK 3, libsecret, glibc, Flutter desktop 런타임이 Ubuntu 22.04와 동등하거나 그 이상일 때 지원 가능 후보로 본다.
- 배포 포맷(AppImage, deb, rpm) 전략 필요
- 영속 비밀을 도입하는 별도 phase에서만 Secret Service 또는 keyring 의존성 검토
- 배포판별 파일 경로/권한 차이 확인 필요

## 13.4 공통 플랫폼 이슈

- 파일 경로 구분자 차이
- 특수문자/유니코드 파일명 처리
- 대용량 파일 처리 시 메모리 사용량
- 백신/보안 소프트웨어에 의한 UDP 차단

---

## 14. 추천 기술 스택

## 14.1 Flutter / Dart

- Flutter stable
- Dart stable

## 14.2 주요 패키지 후보

- 상태 관리: `flutter_riverpod`
- 라우팅: `go_router`
- DB: `drift`, `sqlite3`
- 파일 선택: `file_picker`
- 경로 처리: `path`, `path_provider`
- 암호화: `cryptography` 또는 검증된 대체 패키지
- 로깅: `logger` 또는 자체 래퍼

현재 제품 기본 경로에서는 로그인 비밀번호와 세션 비밀을 저장하지 않으므로 OS 보안 저장소는 필수 패키지가 아니다. 영속 장치 키나 계정 등록형 정책을 도입할 때만 별도 의사결정 후 추가한다.

## 14.3 네트워크 구현

Dart의 `RawDatagramSocket` 기반 직접 구현을 우선 권장한다.

이유:

- UDP 헤더 위 동작 제어가 필요하다.
- 커스텀 재전송/윈도우/패킷 구조를 직접 다뤄야 한다.
- 서드파티 추상화가 오히려 제약이 될 가능성이 높다.

---

## 15. 모듈 설계 상세

## 15.1 Auth Module

책임:

- 가입 없는 런타임 로그인 세션 시작
- 메모리 기반 비밀번호 검증 재료 관리
- password-derived JWT 생성/검증
- 챌린지 응답 생성
- 세션 키 초기화

주요 클래스 예시:

- `AuthController`
- `LoginUseCase`
- `RegisterUserUseCase`
- `PasswordHasher`
- `JwtTokenService`
- `ChallengeResponder`
- `SessionKeyService`

## 15.2 Discovery Module

책임:

- 브로드캐스트 송신
- 피어 응답 수신
- 온라인 목록 갱신
- peer TTL 관리

주요 클래스 예시:

- `DiscoveryService`
- `PeerRegistry`
- `PeerHeartbeatManager`

## 15.3 Transfer Module

책임:

- 전송 작업 생성
- 파일 메타데이터 작성
- chunk 생성
- ACK/NACK 처리
- 재전송 정책 적용
- 진행률 갱신

주요 클래스 예시:

- `TransferCoordinator`
- `TransferSessionManager`
- `ChunkScheduler`
- `RetryPolicy`
- `TransferProgressTracker`

## 15.4 Receive Module

책임:

- 수신 요청 검증
- 정책 기반 승인
- 임시 파일 쓰기
- 최종 무결성 검증
- 완료 후 파일 이동

주요 클래스 예시:

- `ReceiveCoordinator`
- `ReceivePolicyService`
- `ChunkAssembler`
- `IntegrityVerifier`

## 15.5 Logging/Diagnostics Module

책임:

- 이벤트 로깅
- 오류 로그
- 패킷 추적 샘플링
- 디버그 모드 진단 UI

---

## 16. 에러 처리 전략

예상 오류 범주는 다음과 같다.

- 인증 실패
- 지원하지 않는 프로토콜 버전
- 포트 사용 중
- 방화벽 차단
- 패킷 손실 과다
- 디스크 쓰기 실패
- 저장 공간 부족
- 사용자 취소
- 세션 타임아웃

오류 처리 원칙:

- 사용자 메시지와 개발 로그를 분리
- UI는 이해 가능한 문장으로 안내
- 로그는 진단 가능한 구조화 데이터로 저장

예:

- 사용자 메시지: "상대 장치 인증에 실패했습니다."
- 내부 로그: `AUTH_RESPONSE_INVALID_HMAC`, `peer=abc`, `session=xyz`

---

## 17. 로깅 및 관측성

1차 버전에서도 최소한의 운영성은 필요하다.

권장 로그 범주:

- app.lifecycle
- auth
- discovery
- transfer.control
- transfer.data
- storage
- ui.actions
- system.error

권장 정책:

- 기본: info
- 개발 모드: debug
- 릴리스: warn 이상 저장, 오류는 항상 저장

로그 파일은 순환 정책을 가져야 한다.

- 예: 파일 10MB 초과 시 롤오버
- 최근 5개 보관

---

## 18. 보안 설계 원칙

## 18.1 최소 원칙

- 비밀번호 평문 저장 금지
- 비밀번호, JWT, 세션 키 영속 저장 금지
- 인증 전 파일 데이터 전송 금지
- 인증되지 않은 peer의 파일 자동 수신 금지
- JWT는 짧은 수명과 1회성 nonce를 가져야 한다.
- 세션 종료 시 메모리 내 민감 상태 정리

## 18.2 권장 추가 보호

- 세션 키 TTL
- 특정 횟수 이상 인증 실패 시 일시 차단
- 브루트포스 방지용 backoff
- 향후 허용 목록 관리 가능성
- 로그에 비밀번호/원문 토큰 기록 금지
- `jti` replay cache 운영
- 허용 clock skew 범위 제한

## 18.3 남는 리스크

UDP 기반 자체 프로토콜은 구현 품질에 따라 취약점이 생길 수 있다. 따라서 다음을 반드시 수행해야 한다.

- 프로토콜 문서화
- 패킷 파서 경계값 테스트
- 인증/암호화 흐름 리뷰
- 릴리스 전 내부 보안 점검

---

## 19. 테스트 전략

## 19.1 단위 테스트

- 비밀번호 해시/검증
- password-derived JWT 생성/검증
- 패킷 직렬화/역직렬화
- chunk 분할/조립
- retry 정책
- session state transition

## 19.2 통합 테스트

- discovery 송수신
- auth handshake
- 단일 파일 전송
- 다중 파일 전송
- 손실 패킷 재전송
- 다중 대상 병렬 전송

## 19.3 플랫폼 테스트

- macOS <-> Windows
- Windows <-> Linux
- macOS <-> Linux
- 동일 OS 간 전송

## 19.4 장애 테스트

- 10%, 20%, 30% 패킷 손실 시뮬레이션
- 패킷 순서 뒤섞임
- 중복 패킷 주입
- 디스크 쓰기 실패
- 저장 공간 부족
- 수신 중 앱 종료 후 재실행

## 19.5 성능 테스트

- 소형 파일 다건 전송
- 대형 파일 단건 전송
- 1:N 배포 성능
- CPU/메모리 점유 측정
- window size별 처리량 비교

---

## 20. 개발 단계별 로드맵

아래 로드맵은 현실적인 순서를 기준으로 한다. 인증과 전송 신뢰성은 후반에 덧붙이는 것이 아니라 초기에 구조로 박아 넣어야 한다.

## Phase 0. 설계 확정

기간 예시: 3~5일

작업:

- 요구사항 확정
- 프로토콜 스펙 초안 작성
- 데이터 모델 설계
- 패키지/아키텍처 기준 확정

산출물:

- 프로젝트 초기 구조
- 프로토콜 문서
- DB 스키마 초안

## Phase 1. Flutter 데스크톱 골격 구축

기간 예시: 4~6일

작업:

- Flutter desktop 프로젝트 생성
- macOS/Windows/Linux 빌드 확인
- 라우팅/상태관리/테마/로그 구조 도입
- 기본 화면 골격 작성

완료 기준:

- 로그인/대시보드/피어/전송/설정 화면 골격 동작

## Phase 2. 런타임 로그인 및 설정 저장

기간 예시: 4~6일

작업:

- 가입 없는 ID/PW 로그인
- 비밀번호와 세션 비밀의 메모리 전용 lifecycle
- 설정 저장
- 기본 수신 경로 저장

완료 기준:

- ID/PW 입력 후 현재 세션 시작 가능
- 앱 재실행 후 사용자 설정은 유지되지만 비밀번호는 다시 입력해야 함

## Phase 3. 노드 탐색

기간 예시: 5~7일

작업:

- UDP 브로드캐스트 송수신
- 피어 목록 갱신
- heartbeat/TTL 처리
- 피어 목록 UI 반영

완료 기준:

- 동일 네트워크에서 상호 발견 가능

## Phase 4. 인증 핸드셰이크

기간 예시: 5~8일

작업:

- CONNECT/AUTH 프로토콜 구현
- 같은 ID/PW 그룹 자동 인증
- 인증 성공/실패 UI 표시
- 세션 수립

완료 기준:

- 인증된 peer만 세션 생성 가능

## Phase 5. 단일 파일 전송 MVP

기간 예시: 7~10일

작업:

- TRANSFER_INIT
- chunk 전송/수신
- ACK/NACK
- 임시 저장
- 완료 검증

완료 기준:

- 인증된 노드 간 단일 파일 전송 성공

## Phase 6. 신뢰성/성능 개선

기간 예시: 7~10일

작업:

- sliding window
- 재전송 튜닝
- timeout 동적 조정
- 속도/진행률 표시

완료 기준:

- 손실 환경에서도 안정적인 전송

## Phase 7. 다중 파일, 다중 대상 전송

기간 예시: 5~8일

작업:

- batch 전송
- 1:N 전송
- 큐 관리
- 동시 세션 제한

완료 기준:

- 여러 대상에 동시에 전송 가능

## Phase 8. 이력, 로그, 설정 고도화

기간 예시: 4~6일

작업:

- 전송 이력
- 오류 상세
- 로그 뷰어
- 정책 설정 화면

## Phase 9. 플랫폼 안정화 및 패키징

기간 예시: 5~8일

작업:

- macOS/Windows/Linux 교차 테스트
- 방화벽/권한 이슈 보정
- 설치/배포 스크립트 준비

## Phase 10. 베타 검증

기간 예시: 1~2주

작업:

- 실사용 네트워크 테스트
- 패킷 손실/혼잡 테스트
- UI 개선
- 버그 수정

---

## 21. 우선순위 정리

## Must Have

- Flutter 데스크톱 앱
- 로컬 로그인
- 노드 탐색
- 인증 세션
- 단일 파일 전송
- 전송 상태 표시
- macOS/Windows/Linux 상호 운용

## Should Have

- 다중 파일 전송
- 1:N 전송
- 재전송 최적화
- 이력/로그 화면

## Could Have

- 이어받기
- 트레이 앱
- 폴더 단위 전송
- 즐겨찾기/별칭

---

## 22. 예상 리스크와 대응

## 리스크 1. UDP 기반 구현 복잡도

설명:

- 손실, 순서 뒤바뀜, 재전송, 흐름 제어를 직접 구현해야 한다.

대응:

- 프로토콜을 작은 단계로 구현
- 패킷 테스트 자동화
- 단일 파일 MVP 후 window 최적화

## 리스크 2. 보안 설계 미흡

설명:

- ID/PW 기반 인증을 빠르게 구현하다가 취약한 프로토콜이 될 수 있다.

대응:

- 비밀번호 평문 절대 금지
- challenge-response 적용
- 세션 암호화 적용
- 차후 PAKE 검토

## 리스크 3. 플랫폼별 방화벽/권한 차이

설명:

- OS별 UDP 차단 또는 파일 접근 권한 차이로 동작 불일치가 생길 수 있다.

대응:

- 초기부터 3개 OS 병행 검증
- 플랫폼별 체크리스트 운영

## 리스크 4. 대용량 파일 메모리 사용

설명:

- chunk 버퍼 관리가 잘못되면 메모리 사용량이 급증할 수 있다.

대응:

- 스트리밍 기반 파일 읽기/쓰기
- window 크기 제한
- isolate 분리

---

## 23. 최종 권장 구현 방향

이 프로젝트는 단순한 "파일 보내기 앱"처럼 보여도 실제 난점은 네트워크 프로토콜과 인증 모델에 있다. 따라서 권장 구현 방향은 다음과 같다.

1. Flutter 데스크톱 앱을 먼저 안정적으로 세팅한다.
2. 가입 없는 런타임 ID/PW 세션과 메모리 전용 credential lifecycle을 먼저 만든다.
3. UDP 탐색과 인증 제어 채널을 먼저 완성한다.
4. 파일 전송은 단일 파일, 단일 대상부터 만든다.
5. 그 위에 sliding window, 다중 대상, 이력, 최적화를 얹는다.

즉, "UI 먼저, 전송 나중"이 아니라 "앱 골격 -> 인증 -> 제어 프로토콜 -> 파일 전송 -> 병렬화" 순서가 맞다.

---

## 24. 초기 구현 권장 결론

초기 버전에서 가장 현실적이고 균형 잡힌 선택은 아래와 같다.

- Flutter desktop 단일 코드베이스
- `Riverpod` 기반 상태 관리
- `SQLite + drift` 로컬 저장소
- 로그인 비밀번호/JWT/session key 메모리 전용 관리
- `RawDatagramSocket` 기반 UDP 직접 구현
- password-derived JWT 기반 런타임 상호 인증
- 인증 후 세션 키 기반 파일 암호화
- Selective Repeat ARQ 기반 신뢰성 보강
- 단일 파일 전송 MVP 후 다중 대상 확장

이 방향이면 README의 핵심 요구사항인 `Flutter`, `UDP`, `ID/PW`, `macOS/Windows/Linux`, `앱 전용` 조건을 모두 만족하면서 실제 개발 가능한 수준의 구조를 만들 수 있다.
