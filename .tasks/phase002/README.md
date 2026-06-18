# Sponzey FileSharing Phase 002 Task Index

이 디렉터리는 [plan.md](plan.md)를 기준으로 실제 구현 가능한 작업 단위로 나눈 상세 태스크 묶음이다.

Phase 002의 핵심 목표는 기존 phase001 구현 위에 다음 구조를 명확히 얹는 것이다.

- 상태 머신 기반 내부 절차 관리
- MessageBus 기반 내부 이벤트 전달
- Discovery / Control / Data UDP 포트 역할 분리
- UDP 기반 Peer 검색, 인증 연동, 파일 데이터 전송
- 인증 후 세션 문맥과 세션 키 lifecycle 관리
- Selective Repeat ARQ와 Sliding Window 기반 전송 신뢰성 고도화

## 작성 원칙

- 한 태스크는 기능 2~3개 단위로 구성한다.
- 각 태스크는 구현 체크리스트, 테스트, 검증 기준, 완료 기준을 포함한다.
- 모든 체크리스트는 진행 상황을 추적할 수 있도록 checkbox로 작성한다.
- TDD를 기본으로 하며, 문서 전용 변경이 아닌 경우 테스트를 추가하거나 갱신한다.
- 기존 `.tasks/phase001` 문서는 보존하고, 새 기준 작업은 이 phase에서 진행한다.

## 권장 수행 순서

- [x] [task001.md](task001.md) - 현재 구조 감사와 phase002 기준 정렬
- [x] [task002.md](task002.md) - 상태 머신 공통 기반과 lifecycle/port/discovery 상태 모델
- [x] [task003.md](task003.md) - 인증, 전송 큐, 송수신 전송 상태 머신
- [x] [task004.md](task004.md) - MessageBus 기반과 typed application event 체계
- [x] [task005.md](task005.md) - UDP 포트 모델, AppConfig migration, Data Port allocator
- [x] [task006.md](task006.md) - Discovery Port 기반 Peer 검색 고도화
- [x] [task007.md](task007.md) - Control Port 기반 Peer 연동, 인증, secure session
- [ ] [task008.md](task008.md) - Data Port 기반 단일 파일 전송 MVP와 streaming IO _(Data Port transport 분리, cancel packet 후속 남음)_
- [x] [task009.md](task009.md) - UDP 신뢰성 보강, selective ack, sliding window
- [ ] [task010.md](task010.md) - 다중 파일, 1:N 전송, 전송 큐 확장 _(queue cancel 후속 남음)_
- [ ] [task011.md](task011.md) - 수신 정책, 이력, 로그/진단 고도화 _(history persistence 후속 남음)_
- [ ] [task012.md](task012.md) - 플랫폼 안정화, 패키징, 베타 검증 게이트 _(수동 검증 및 history 재실행 검증 제외)_

## 의존성 요약

- `task001`은 모든 phase002 작업의 기준점이다.
- `task002`와 `task004`는 이후 application flow의 공통 기반이다.
- `task005`는 `task006`, `task007`, `task008`의 선행 조건이다.
- `task006`은 `task007`의 선행 조건이다.
- `task007`은 `task008`, `task009`, `task010`의 선행 조건이다.
- `task008`은 `task009`, `task010`, `task011`의 선행 조건이다.
- `task009`는 안정적인 `task010` 수행의 선행 조건이다.
- `task011`과 `task012`는 병행 가능하지만, 둘 다 베타 전에는 완료되어야 한다.
