# Sponzey FileSharing Task Index

이 디렉터리는 phase별 작업 문서와 계획 문서를 정리한 루트 인덱스다.

## Current Plan

- [plan.md](plan.md) - v0.0.20 이후 연결 안정화, 파일 전송 신뢰성, 멀티 Ethernet, 제품화 개발 계획

## Current Plan Tasks

- [x] [task001.md](task001.md) - 문서/README 정렬, current scope audit, 공통 TDD/상태머신 완료 기준 정리
- [ ] [task002.md](task002.md) - peer identity, route candidate, route lease, self packet suppression 안정화
- [ ] [task003.md](task003.md) - multi Ethernet discovery target, broadcast send, receive decision 검증
- [ ] [task004.md](task004.md) - 자동 인증/연결 state machine, duplicate handshake, stale peer cleanup 정리
- [ ] [task005.md](task005.md) - active route lease와 data transfer path 일치성 보장
- [ ] [task006.md](task006.md) - 저장 경로, temp file, 수신 준비 lifecycle 안정화
- [ ] [task007.md](task007.md) - Data channel correctness, digest verification, 성능 튜닝, benchmark harness
- [ ] [task008.md](task008.md) - transfer UX, retry/cancel, persisted history, sender/receiver 상태 용어 통일
- [ ] [task009.md](task009.md) - diagnostics export, packet decision summary, redaction
- [ ] [task010.md](task010.md) - macOS/Windows/Linux platform hardening, firewall/path/click/input 검증
- [ ] [task011.md](task011.md) - release gate, 양방향 host/VM 전송 검증, benchmark 기록 체계
- 이전 고속 UDP Data Channel 태스크는 `.tasks/phase005`로 이동했다.

## Current Status Notes

- 루트 `.tasks/plan.md`는 현재 구현 이후의 남은 개발 방향을 추적한다.
- `.tasks/phase005`는 Data channel 전환 계획과 task001~task011 수행 기록을 보존한다.
- 새 phase를 시작하기 전에는 루트 plan의 gap analysis와 acceptance gate를 먼저 갱신한다.

## Phases

- [phase001](phase001/README.md) - 초기 MVP 및 제품 기초 구현
- [phase002](phase002/README.md) - 상태 머신, MessageBus, UDP 포트 분리, 인증/전송 기반 정리
- [phase003](phase003/README.md) - 멀티 Ethernet 인터페이스 전체 지원 계획과 태스크
- [phase004](phase004/plan.md) - peer 연결과 멀티 Ethernet active path 안정화 계획
- [phase005](phase005/plan.md) - 고속 UDP Data Channel 전환 기록과 태스크