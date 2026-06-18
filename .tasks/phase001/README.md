# Sponzey FileSharing Task Index

이 디렉터리는 [README.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/README.md)와 [plan.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/plan.md)를 기준으로 쪼갠 개발 태스크 묶음이다.

각 태스크 문서는 다음 원칙을 따른다.

- 한 파일당 기능 2~3개
- 구현 체크리스트, 테스트, 검증 기준 포함
- 선행 태스크와 완료 기준 명시
- 체크박스로 진행 상태 추적 가능

권장 수행 순서는 아래와 같다.

- [x] [task001.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task001.md) - Flutter Desktop 골격과 공통 기반 구축
- [x] [task002.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task002.md) - 로컬 계정, 설정 저장소, 보안 저장소 구축
- [ ] [task003.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task003.md) - UDP 노드 탐색과 피어 목록 UI
- [x] [task004.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task004.md) - password-derived JWT 상호 인증과 허용 사용자 정책
- [x] [task005.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task005.md) - 단일 파일 전송 MVP와 수신 파이프라인
- [x] [task006.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task006.md) - UDP 신뢰성 보강, 재전송, 성능 측정
- [ ] [task007.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task007.md) - 다중 파일, 1:N 전송, 전송 큐 관리
- [ ] [task008.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task008.md) - 수신 정책, 이력/로그, 설정 화면 고도화
- [ ] [task009.md](/Users/dongwooshin/WorkPlaces/AtomSoft/Sponzey%20Family/Sponzey%20FileSharing/tasks/task009.md) - 플랫폼 안정화, 패키징, 베타 검증

의존성 요약:

- `task001`은 모든 후속 태스크의 기반이다.
- `task002`는 `task004`의 선행 조건이다.
- `task003`은 `task004`, `task005`의 선행 조건이다.
- `task004`는 `task005`, `task006`, `task007`의 선행 조건이다.
- `task005`는 `task006`의 선행 조건이다.
- `task006`은 `task007`, `task008`, `task009`의 선행 조건이다.
- `task007`과 `task008`은 병행 가능하지만 둘 다 `task009` 전에 끝나는 편이 좋다.