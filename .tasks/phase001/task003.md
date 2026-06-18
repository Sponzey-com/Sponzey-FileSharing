# Task 003 - UDP 노드 탐색과 피어 목록 UI

## 목표

동일 로컬 네트워크에서 실행 중인 다른 노드를 자동 탐색하고, UI에 온라인 상태로 표시한다.

## 연관 문서

- [README.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/README.md)
- [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)

## 선행 조건

- [task001.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task001.md)
- [task002.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task002.md)

## 포함 기능

### 기능 1. UDP 브로드캐스트 기반 디스커버리 엔진

- `DISCOVER`, `DISCOVER_ACK` 패킷 구조 정의
- 브로드캐스트 송신과 유니캐스트 응답 수신 구현
- 프로토콜 버전, 사용자 ID, 장치 ID, 장치명, 상태 정보 교환

### 기능 2. 피어 레지스트리와 TTL 관리

- 마지막 응답 시간 기준 온라인/오프라인 판정
- 중복 노드 병합 정책 구현
- 메모리 상태와 로컬 DB 캐시 간 동기화

### 기능 3. 피어 목록 화면

- 온라인 노드 목록 표시
- 검색, 정렬, 상태 뱃지, 마지막 응답 시간 표시
- 수신 가능 여부와 프로토콜 버전 표시

## 구현 체크리스트

- [x] 디스커버리 포트와 패킷 포맷이 코드 상수로 정리되어 있다.
- [x] 앱 시작 후 주기적으로 `DISCOVER` 브로드캐스트를 송신한다.
- [x] 다른 노드의 응답을 수신해 피어 목록을 갱신한다.
- [x] TTL 만료 시 피어가 오프라인 또는 비활성 상태로 변경된다.
- [x] 피어 목록 화면에서 기본 검색/정렬이 가능하다.
- [x] 프로토콜 버전 불일치 노드가 UI에서 식별 가능하다.

## 산출물

- UDP discovery 서비스
- 피어 레지스트리
- 피어 목록 화면
- discovery 이벤트 로그

## 테스트

- [x] 패킷 직렬화/역직렬화 단위 테스트 작성
- [x] TTL 만료 및 상태 전이 테스트 작성
- [x] 피어 목록 정렬/필터링 상태 테스트 작성
- [x] 로컬 loopback 또는 mock socket 기반 discovery 통합 테스트 작성

## 검증

- [ ] 같은 네트워크의 두 장치에서 앱 실행 후 상호 발견되는지 확인한다.
- [ ] 한 장치를 종료했을 때 상대 앱에서 오프라인 처리되는지 확인한다.
- [x] 지원 버전이 다른 노드를 수동 주입해 UI 표시가 정상인지 확인한다.
- [ ] 로그에 discovery 송수신 이벤트가 과도하게 중복 기록되지 않는지 확인한다.

## 완료 기준

- 같은 네트워크에서 실행된 두 앱이 수 초 내 서로를 발견한다.
- 피어 목록 화면이 인증 태스크에서 사용할 수 있을 정도로 안정적이다.

## 메모

- 이 태스크에서는 피어를 보여주는 것까지가 목표다.
- 연결, 인증, 파일 전송 시작 버튼은 UI에 있어도 실제 동작은 다음 태스크에서 완성한다.