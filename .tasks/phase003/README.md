# Sponzey FileSharing Phase 003 Task Index

이 디렉터리는 [plan.md](plan.md)의 멀티 Ethernet 인터페이스 전체 지원 계획을 실제 구현 가능한 작업 단위로 나눈 phase003 태스크 묶음이다.

Phase 003의 핵심 목표는 다음과 같다.

- 모든 유효 IPv4 네트워크 인터페이스를 명시적으로 스캔한다.
- Discovery target을 인터페이스별로 생성한다.
- 같은 peer의 여러 route candidate를 보존한다.
- Control/Auth 연결을 선택된 candidate 기준으로 검증한다.
- Data Port 전용 transport를 도입하고 선택된 interface endpoint로 전송한다.
- 경로 실패 시 같은 인터페이스 재시도 또는 다른 인터페이스 failover를 수행한다.
- UI와 진단 이벤트에서 활성 경로와 실패 원인을 설명 가능하게 만든다.

## 작성 원칙

- 한 태스크는 기능 2~3개 단위로 구성한다.
- 각 태스크는 구현 체크리스트, 테스트, 검증 기준, 완료 기준을 포함한다.
- 모든 체크리스트는 진행 상황을 추적할 수 있도록 checkbox로 작성한다.
- TDD를 기본으로 하며, 문서 전용 변경이 아닌 경우 테스트를 추가하거나 갱신한다.
- 실제 macOS/Windows/Linux multi-NIC 장비 검증은 수동 확인 항목으로 분리한다.

## 권장 수행 순서

- [ ] [task001.md](task001.md) - 네트워크 인터페이스 도메인 모델과 inventory
- [ ] [task002.md](task002.md) - Discovery target builder와 subnet 기반 broadcast
- [ ] [task003.md](task003.md) - Peer route candidate projection과 lifecycle
- [ ] [task004.md](task004.md) - Control path selection과 candidate probe
- [ ] [task005.md](task005.md) - Control transport local bind 확장
- [ ] [task006.md](task006.md) - Data Port 전용 transport와 interface bind
- [ ] [task007.md](task007.md) - Data path failover와 전송 복구
- [ ] [task008.md](task008.md) - UI projection과 네트워크 진단
- [ ] [task009.md](task009.md) - 플랫폼 체크리스트와 베타 검증 게이트

## 의존성 요약

- `task001`은 모든 phase003 작업의 기반이다.
- `task002`는 `task003`의 선행 조건이다.
- `task003`은 `task004`, `task008`의 선행 조건이다.
- `task004`는 `task005`, `task006`, `task007`의 선행 조건이다.
- `task005`는 Control/Auth 경로 검증의 구현 기반이다.
- `task006`은 Data Port 분리와 전송 경로 명시화의 구현 기반이다.
- `task007`은 `task006` 이후에만 안정적으로 구현할 수 있다.
- `task008`은 `task003` 이후 병행 가능하지만, active path 표시는 `task004` 이후 완성된다.
- `task009`는 전체 구현과 병행하되 최종 검증은 `task007`, `task008` 이후 수행한다.